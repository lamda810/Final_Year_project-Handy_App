import { Request, Response } from 'express';
import mongoose from 'mongoose';
import { randomBytes } from 'crypto';
import {
  Booking,
  Customer,
  Worker,
  Review,
  asyncHandler,
  successResponse,
  errorResponse,
  notFoundResponse,
  paginatedResponse,
  HTTP_STATUS,
  DEFAULTS,
  BookingStatus,
  IBooking,
} from '@handy-go/shared';
import { config } from '../config/index.js';
import matchingService from '../services/matching.service.js';
import notificationService from '../services/notification.service.js';
import pricingService from '../services/pricing.service.js';

/**
 * Create a new booking
 * POST /api/bookings
 */
export const createBooking = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { serviceCategory, problemDescription, address, scheduledDateTime, isUrgent, images } = req.body;

  // Get customer profile
  const customer = await Customer.findOne({ user: userId });
  if (!customer) {
    return notFoundResponse(res, 'Customer profile not found');
  }

  // Check max active bookings limit
  const activeBookingsCount = await Booking.countDocuments({
    customer: customer._id,
    status: { $in: ['PENDING', 'ACCEPTED', 'IN_PROGRESS'] },
  });

  if (activeBookingsCount >= config.booking.maxActiveBookingsPerCustomer) {
    return errorResponse(
      res,
      `Maximum ${config.booking.maxActiveBookingsPerCustomer} active bookings allowed`,
      HTTP_STATUS.BAD_REQUEST
    );
  }

  // Analyze problem with AI
  const problemAnalysis = await matchingService.analyzeProblem(problemDescription, serviceCategory);

  // Estimate price
  const priceEstimate = await matchingService.estimatePrice({
    serviceCategory,
    problemDescription,
    city: address.city,
  });

  // Estimate duration
  const durationEstimate = await matchingService.estimateDuration({
    serviceCategory,
    problemDescription,
  });

  // Find matching workers
  const { workers: matchedWorkers, totalAvailable } = await matchingService.findWorkers({
    serviceCategory,
    location: address.coordinates,
    scheduledDateTime: new Date(scheduledDateTime),
    isUrgent,
    problemComplexity: problemAnalysis.urgencyLevel,
  });

  // Generate cryptographically secure booking number with collision retry
  const generateBookingNumber = async (maxRetries = 5): Promise<string> => {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const randomPart = randomBytes(4).toString('hex').substring(0, 5).toUpperCase();
      const candidate = `HG-${today}-${randomPart}`;
      const exists = await Booking.findOne({ bookingNumber: candidate }).lean();
      if (!exists) return candidate;
    }
    // Fallback: append timestamp millis for guaranteed uniqueness
    const fallback = randomBytes(6).toString('hex').toUpperCase();
    return `HG-${today}-${fallback}`;
  };

  const bookingNumber = await generateBookingNumber();

  // Create booking
  const booking = new Booking({
    bookingNumber,
    customer: customer._id,
    serviceCategory,
    problemDescription,
    aiDetectedServices: problemAnalysis.detectedServices,
    address: {
      full: address.full,
      city: address.city,
      coordinates: address.coordinates,
    },
    scheduledDateTime: new Date(scheduledDateTime),
    isUrgent,
    status: 'PENDING',
    pricing: {
      estimatedPrice: priceEstimate.estimatedPrice.average,
    },
    estimatedDuration: durationEstimate.estimatedMinutes,
    images: {
      before: images || [],
      after: [],
    },
    timeline: [
      {
        status: 'PENDING',
        timestamp: new Date(),
        note: 'Booking created',
      },
    ],
  });

  await booking.save();

  // Increment customer's total bookings
  customer.totalBookings += 1;
  await customer.save();

  return successResponse(
    res,
    {
      booking,
      estimatedPrice: priceEstimate,
      estimatedDuration: durationEstimate,
      matchedWorkers: matchedWorkers.slice(0, 3), // Return top 3 workers
      totalAvailableWorkers: totalAvailable,
      aiAnalysis: problemAnalysis,
    },
    'Booking created successfully',
    HTTP_STATUS.CREATED
  );
});

/**
 * Select worker for booking
 * POST /api/bookings/:bookingId/select-worker
 */
export const selectWorker = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { bookingId } = req.params;
  const { workerId } = req.body;

  // Get customer
  const customer = await Customer.findOne({ user: userId });
  if (!customer) {
    return notFoundResponse(res, 'Customer profile not found');
  }

  // Find booking
  const booking = await Booking.findOne({
    _id: bookingId,
    customer: customer._id,
    status: 'PENDING',
  });

  if (!booking) {
    return notFoundResponse(res, 'Booking not found or not in pending status');
  }

  // Verify worker exists and is available
  const worker = await Worker.findById(workerId);
  if (!worker || worker.status !== 'ACTIVE') {
    return errorResponse(res, 'Worker not available', HTTP_STATUS.BAD_REQUEST);
  }

  // Assign worker to booking
  booking.worker = new mongoose.Types.ObjectId(workerId);
  booking.timeline.push({
    status: 'WORKER_ASSIGNED',
    timestamp: new Date(),
    note: `Worker ${worker.firstName} ${worker.lastName} assigned`,
  });

  await booking.save();

  // Notify worker about new booking request
  await notificationService.notifyNewBookingRequest(
    worker.user.toString(),
    booking.serviceCategory,
    booking.bookingNumber
  );

  // Notify customer about worker assignment
  await notificationService.notifyWorkerAssigned(
    userId,
    `${worker.firstName} ${worker.lastName}`,
    booking.bookingNumber
  );

  // Populate worker info for response
  const populatedBooking = await Booking.findById(bookingId)
    .populate('worker', 'firstName lastName profileImage rating trustScore contactPhone');

  return successResponse(res, populatedBooking, 'Worker selected successfully');
});

/**
 * Get customer bookings
 * GET /api/bookings/customer
 */
export const getCustomerBookings = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { status, page = '1', limit = '20' } = req.query;

  const customer = await Customer.findOne({ user: userId });
  if (!customer) {
    return notFoundResponse(res, 'Customer profile not found');
  }

  const pageNum = parseInt(page as string);
  const limitNum = Math.min(parseInt(limit as string), DEFAULTS.MAX_PAGINATION_LIMIT);
  const skip = (pageNum - 1) * limitNum;

  const filter: any = { customer: customer._id };
  if (status) {
    filter.status = status;
  }

  const [bookings, total] = await Promise.all([
    Booking.find(filter)
      .populate('worker', 'firstName lastName profileImage rating trustScore contactPhone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum),
    Booking.countDocuments(filter),
  ]);

  return paginatedResponse(res, bookings, pageNum, limitNum, total, 'Bookings retrieved');
});

/**
 * Get booking details
 * GET /api/bookings/:bookingId
 */
export const getBookingDetails = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const userRole = req.user!.role;
  const { bookingId } = req.params;

  let booking;

  // 'contactPhone' is the optional alternate number set on the Customer/
  // Worker profile; nested-populating 'user' with 'phone' provides the
  // fallback login phone for calling when no contactPhone is set.
  const workerPopulate = {
    path: 'worker',
    select: 'firstName lastName profileImage rating trustScore currentLocation contactPhone user',
    populate: { path: 'user', select: 'phone' },
  };
  const customerPopulate = {
    path: 'customer',
    select: 'firstName lastName profileImage contactPhone user',
    populate: { path: 'user', select: 'phone' },
  };

  if (userRole === 'CUSTOMER') {
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
      return notFoundResponse(res, 'Customer profile not found');
    }
    booking = await Booking.findOne({ _id: bookingId, customer: customer._id })
      .populate(workerPopulate)
      .populate(customerPopulate);
  } else if (userRole === 'WORKER') {
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
      return notFoundResponse(res, 'Worker profile not found');
    }
    booking = await Booking.findOne({ _id: bookingId, worker: worker._id })
      .populate(workerPopulate)
      .populate(customerPopulate);
  } else {
    // Admin can view any booking
    booking = await Booking.findById(bookingId)
      .populate(workerPopulate)
      .populate(customerPopulate);
  }

  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  // Get review if completed
  let review = null;
  if (booking.status === 'COMPLETED') {
    review = await Review.findOne({ booking: bookingId });
  }

  return successResponse(res, { booking, review }, 'Booking details retrieved');
});

/**
 * Cancel booking
 * POST /api/bookings/:bookingId/cancel
 */
export const cancelBooking = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { bookingId } = req.params;
  const { reason } = req.body;

  const customer = await Customer.findOne({ user: userId });
  if (!customer) {
    return notFoundResponse(res, 'Customer profile not found');
  }

  const booking = await Booking.findOne({
    _id: bookingId,
    customer: customer._id,
    status: { $in: ['PENDING', 'ACCEPTED'] },
  }).populate('worker', 'user firstName lastName');

  if (!booking) {
    return notFoundResponse(res, 'Booking not found or cannot be cancelled');
  }

  // Calculate cancellation fee
  const hoursBeforeScheduled = (booking.scheduledDateTime.getTime() - Date.now()) / (1000 * 60 * 60);
  const cancellationFee = pricingService.calculateCancellationFee(
    booking.pricing.estimatedPrice || 0,
    hoursBeforeScheduled
  );

  // Update booking status
  booking.status = 'CANCELLED' as BookingStatus;
  booking.cancellation = {
    cancelledBy: 'CUSTOMER',
    reason,
    timestamp: new Date(),
    fee: cancellationFee,
  };
  booking.timeline.push({
    status: 'CANCELLED',
    timestamp: new Date(),
    note: `Cancelled by customer. Reason: ${reason}`,
  });

  await booking.save();

  // Notify worker if assigned
  if (booking.worker) {
    await notificationService.notifyBookingCancelled(
      (booking.worker as any).user.toString(),
      'customer',
      booking.bookingNumber
    );
  }

  return successResponse(res, { booking, cancellationFee }, 'Booking cancelled successfully');
});

/**
 * Rate booking
 * POST /api/bookings/:bookingId/rate
 */
export const rateBooking = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { bookingId } = req.params;
  const { rating, review, categories } = req.body;

  const customer = await Customer.findOne({ user: userId });
  if (!customer) {
    return notFoundResponse(res, 'Customer profile not found');
  }

  const booking = await Booking.findOne({
    _id: bookingId,
    customer: customer._id,
    status: 'COMPLETED',
  }).populate('worker');

  if (!booking) {
    return notFoundResponse(res, 'Booking not found or not completed');
  }

  // Check if already rated
  const existingReview = await Review.findOne({ booking: bookingId });
  if (existingReview) {
    return errorResponse(res, 'Booking already rated', HTTP_STATUS.CONFLICT);
  }

  // Create review
  const newReview = new Review({
    booking: booking._id,
    customer: customer._id,
    worker: booking.worker!._id,
    rating,
    review: review || '',
    categories: categories || {},
  });

  await newReview.save();

  // Update booking with rating
  booking.rating = {
    score: rating,
    review: review || '',
    createdAt: new Date(),
  };
  await booking.save();

  // Notify worker
  await notificationService.notifyRatingReceived(
    (booking.worker as any).user.toString(),
    rating,
    booking.bookingNumber
  );

  return successResponse(res, newReview, 'Rating submitted successfully');
});
