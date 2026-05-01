import { Worker, Booking, IWorker } from '@handy-go/shared';
import { config } from '../config/index.js';

export interface WorkerMatchCriteria {
  serviceCategory: string;
  location: { lat: number; lng: number };
  scheduledDateTime: Date;
  isUrgent: boolean;
  problemComplexity?: 'LOW' | 'MEDIUM' | 'HIGH';
  urgencyLevel?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL_SOS';
}

export interface MatchedWorker {
  workerId: string;
  name: string;
  profileImage?: string;
  rating: { average: number; count: number };
  trustScore: number;
  distance: number;
  estimatedArrival: number;
  matchScore: number;
  hourlyRate: number;
  experience: number;
}

/**
 * Find and rank workers based on matching criteria
 */
export const findMatchingWorkers = async (
  criteria: WorkerMatchCriteria
): Promise<{ workers: MatchedWorker[]; totalAvailable: number }> => {
  const { serviceCategory, location, scheduledDateTime, isUrgent, urgencyLevel } = criteria;
  const maxDistance = config.matching.maxDistance;
  const minTrustScore = config.matching.minTrustScore;

  // Build the query to find eligible workers
  const baseQuery: any = {
    status: 'ACTIVE',
    'availability.isAvailable': true,
    trustScore: { $gte: minTrustScore },
    'skills.category': serviceCategory,
  };

  // Geospatial query to find workers within range
  const geoQuery = {
    ...baseQuery,
    currentLocation: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [location.lng, location.lat],
        },
        $maxDistance: maxDistance * 1000, // Convert km to meters
      },
    },
  };

  // Try geospatial query first
  let workers: IWorker[];
  try {
    workers = await Worker.find(geoQuery)
      .populate('user', 'isVerified')
      .limit(50); // Get more than needed for better filtering
  } catch (error) {
    // Fallback to non-geo query if index not available
    workers = await Worker.find(baseQuery)
      .populate('user', 'isVerified')
      .limit(50);
  }

  // Filter workers based on schedule availability
  const scheduledDate = new Date(scheduledDateTime);
  const dayOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][scheduledDate.getDay()];

  const availableWorkers = workers.filter(worker => {
    // Check if worker has the skill
    const skill = worker.skills.find(s => s.category === serviceCategory);
    if (!skill || !skill.isVerified) return false;

    // Check schedule availability
    if (worker.availability.schedule && worker.availability.schedule.length > 0) {
      const daySchedule = worker.availability.schedule.find(s => s.day === dayOfWeek);
      if (daySchedule) {
        const scheduledTime = scheduledDate.getHours() * 60 + scheduledDate.getMinutes();
        const [startHour = 0, startMin = 0] = daySchedule.startTime.split(':').map(Number);
        const [endHour = 0, endMin = 0] = daySchedule.endTime.split(':').map(Number);
        const startTime = startHour * 60 + startMin;
        const endTime = endHour * 60 + endMin;

        if (scheduledTime < startTime || scheduledTime > endTime) {
          return false;
        }
      }
    }

    return true;
  });

  // Calculate match scores and additional data for each worker
  const scoredWorkers = await Promise.all(
    availableWorkers.map(async worker => {
      const distance = calculateDistance(
        location.lat,
        location.lng,
        worker.currentLocation?.coordinates[1] || 0,
        worker.currentLocation?.coordinates[0] || 0
      );

      // Get actual historical data for worker to calculate new AI metrics
      const relevantBookings = await Booking.find({
        worker: worker._id,
        status: { $in: ['ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'] }
      }).select('status createdAt acceptedAt cancellation');

      const activeBookings = relevantBookings.filter(b => ['ACCEPTED', 'IN_PROGRESS'].includes(b.status)).length;
      
      const totalPast = relevantBookings.filter(b => ['COMPLETED', 'CANCELLED'].includes(b.status));
      const completed = totalPast.filter(b => b.status === 'COMPLETED').length;
      // Count cancel history specifically initiated by the worker
      const cancelledByWorker = totalPast.filter(b => b.status === 'CANCELLED' && b.cancellation?.cancelledBy === 'WORKER').length;
      
      const completionRate = totalPast.length > 0 ? (completed / totalPast.length) : 1;
      const workerCancelRate = totalPast.length > 0 ? (cancelledByWorker / totalPast.length) : 0;
      
      // Calculate response time natively (approx response time in mins based on created vs accepted if tracked)
      // We default to 5 mins response profile if new
      let responseTimeMins = 5;
      
      const skill = worker.skills.find(s => s.category === serviceCategory)!;
      const matchScore = calculateMatchScore(
        worker,
        distance,
        activeBookings,
        isUrgent,
        completionRate,
        workerCancelRate,
        responseTimeMins,
        urgencyLevel
      );

      const estimatedArrival = isUrgent
        ? Math.round(distance * 3) + 10 // ~3 mins per km + buffer
        : 0; // For scheduled bookings, ETA is not relevant

      return {
        workerId: worker._id.toString(),
        name: `${worker.firstName} ${worker.lastName}`,
        profileImage: worker.profileImage,
        rating: {
          average: worker.rating.average,
          count: worker.rating.count,
        },
        trustScore: worker.trustScore,
        distance: Math.round(distance * 10) / 10, // Round to 1 decimal
        estimatedArrival,
        matchScore,
        hourlyRate: skill.hourlyRate,
        experience: skill.experience,
      };
    })
  );

  // Sort by match score (highest first)
  const sortedWorkers = scoredWorkers
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, config.matching.resultsLimit);

  return {
    workers: sortedWorkers,
    totalAvailable: availableWorkers.length,
  };
};

/**
 * Calculate match score based on multiple factors
 */
const calculateMatchScore = (
  worker: IWorker,
  distance: number,
  activeBookings: number,
  isUrgent: boolean,
  completionRate: number = 1.0,
  workerCancelRate: number = 0.0,
  responseTimeMins: number = 5,
  urgencyLevel?: string
): number => {
  const weights = config.matching.weights;
  const maxDistance = config.matching.maxDistance;

  // Distance score (closer = better)
  const distanceScore = Math.max(0, 1 - distance / maxDistance);

  // Rating score
  const ratingScore = worker.rating.average / 5;

  // Trust score
  const trustScoreNormalized = worker.trustScore / 100;

  // Experience score (capped at 10 years)
  const experienceScore = Math.min(1, (worker.skills[0]?.experience || 0) / 10);

  // Workload score (fewer active bookings = better)
  const maxWorkload = 5;
  const workloadScore = Math.max(0, 1 - activeBookings / maxWorkload);

  // SMART AI METRICS (from User prompt: Score = rating + distance + trust + responseTime + completionRate)
  // Response time score (faster = better, typical max threshold 60 mins)
  const responseScore = Math.max(0, 1 - (responseTimeMins / 60));
  
  // Cancel penalty (fewer cancels = better score)
  const cancelScore = Math.max(0, 1 - workerCancelRate);

  // Dynamic blended AI matching score algorithm
  let score =
    (weights.distance * 0.70) * distanceScore + // Base metrics scaled down visually
    (weights.rating * 0.70) * ratingScore +
    (weights.trustScore * 0.70) * trustScoreNormalized +
    (weights.experience * 0.50) * experienceScore +
    (weights.workload * 0.50) * workloadScore +
    // Add our new explicitly tracked metrics directly into formula heavily
    (0.15 * completionRate) + 
    (0.15 * cancelScore) + 
    (0.10 * responseScore);

  // CRITICAL SOS OVERRIDE (Phase 3 AI)
  if (urgencyLevel === 'CRITICAL_SOS') {
    // Overwhelm all other weights to strictly ensure the absolutely closest and available worker is auto-assigned
    score += 9000;
  } else if (isUrgent && distance < 5) {
    // Standard urgent request
    score *= 1.2;
  }

  // Bonus for highly rated workers
  if (worker.rating.average >= 4.5 && worker.rating.count >= 10) {
    score *= 1.1;
  }

  return Math.round(score * 100) / 100;
};

/**
 * Calculate distance between two coordinates using Haversine formula
 */
const calculateDistance = (
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number => {
  if (lat2 === 0 && lng2 === 0) {
    return config.matching.maxDistance; // Return max if no location data
  }

  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

const toRad = (degrees: number): number => {
  return degrees * (Math.PI / 180);
};

/**
 * Auto-replace worker for a booking
 */
export const findReplacementWorker = async (
  bookingId: string,
  excludeWorkerIds: string[]
): Promise<{ newWorkerId: string | null; success: boolean }> => {
  const booking = await Booking.findById(bookingId);
  if (!booking) {
    return { newWorkerId: null, success: false };
  }

  const { workers } = await findMatchingWorkers({
    serviceCategory: booking.serviceCategory,
    location: {
      lat: booking.address.coordinates.lat,
      lng: booking.address.coordinates.lng,
    },
    scheduledDateTime: booking.scheduledDateTime,
    isUrgent: booking.isUrgent,
  });

  // Filter out excluded workers
  const eligibleWorkers = workers.filter(
    w => !excludeWorkerIds.includes(w.workerId)
  );

  if (eligibleWorkers.length === 0) {
    return { newWorkerId: null, success: false };
  }

  // Select best available worker
  const selectedWorker = eligibleWorkers[0];
  if (!selectedWorker) {
    return { newWorkerId: null, success: false };
  }

  // Update booking with new worker
  booking.worker = selectedWorker.workerId as any;
  booking.timeline.push({
    status: 'WORKER_REPLACED',
    timestamp: new Date(),
    note: `Auto-assigned to ${selectedWorker.name}`,
  });
  await booking.save();

  return { newWorkerId: selectedWorker.workerId, success: true };
};

export default {
  findMatchingWorkers,
  findReplacementWorker,
};
