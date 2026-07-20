import { Request, Response } from 'express';
import {
  Worker,
  User,
  Booking,
  asyncHandler,
  successResponse,
  errorResponse,
  notFoundResponse,
  HTTP_STATUS,
} from '@handy-go/shared';

/**
 * Get worker profile
 * GET /api/users/worker/profile
 */
export const getProfile = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;

  const worker = await Worker.findByUserId(userId);

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  return successResponse(res, worker, 'Profile retrieved successfully');
});

/**
 * Update worker profile
 * PUT /api/users/worker/profile
 */
export const updateProfile = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { firstName, lastName, email, profileImage, contactPhone, skills, serviceRadius, availability, bankDetails } = req.body;

  const worker = await Worker.findOne({ user: userId });

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  // Update worker fields
  if (firstName) worker.firstName = firstName;
  if (lastName) worker.lastName = lastName;
  if (profileImage) worker.profileImage = profileImage;
  if (contactPhone !== undefined) worker.contactPhone = contactPhone || undefined;
  if (skills) {
    worker.skills = skills.map((skill: any) => ({
      ...skill,
      isVerified: worker.skills.find(s => s.category === skill.category)?.isVerified || false,
    }));
  }
  if (serviceRadius) worker.serviceRadius = serviceRadius;
  if (availability) worker.availability = availability;
  if (bankDetails) worker.bankDetails = bankDetails;

  // Update email in User model if provided
  if (email) {
    const existingEmail = await User.findOne({ email: email.toLowerCase(), _id: { $ne: userId } });
    if (existingEmail) {
      return errorResponse(res, 'Email already in use', HTTP_STATUS.CONFLICT);
    }
    await User.findByIdAndUpdate(userId, { email: email.toLowerCase() });
  }

  await worker.save();

  const updatedWorker = await Worker.findByUserId(userId);

  return successResponse(res, updatedWorker, 'Profile updated successfully');
});

/**
 * Update worker location
 * PUT /api/users/worker/location
 */
export const updateLocation = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { coordinates } = req.body;

  if (!coordinates || typeof coordinates.lat !== 'number' || typeof coordinates.lng !== 'number') {
    return errorResponse(res, 'Valid coordinates are required', HTTP_STATUS.BAD_REQUEST);
  }

  const worker = await Worker.findOne({ user: userId });

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  await worker.updateLocation(coordinates.lat, coordinates.lng);

  return successResponse(res, { success: true }, 'Location updated');
});

/**
 * Update worker availability
 * PUT /api/users/worker/availability
 */
export const updateAvailability = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { isAvailable } = req.body;

  if (typeof isAvailable !== 'boolean') {
    return errorResponse(res, 'isAvailable must be a boolean', HTTP_STATUS.BAD_REQUEST);
  }

  const worker = await Worker.findOne({ user: userId });

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  worker.availability.isAvailable = isAvailable;
  await worker.save();

  return successResponse(res, { isAvailable: worker.availability.isAvailable }, 'Availability updated');
});

/**
 * Add document
 * POST /api/users/worker/documents
 */
export const addDocument = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { type, url } = req.body;

  if (!type || !url) {
    return errorResponse(res, 'Document type and URL are required', HTTP_STATUS.BAD_REQUEST);
  }

  const worker = await Worker.findOne({ user: userId });

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  worker.documents.push({
    type,
    url,
    verified: false,
    uploadedAt: new Date(),
  });

  await worker.save();

  return successResponse(res, worker.documents, 'Document added successfully');
});

/**
 * Get earnings
 * GET /api/users/worker/earnings
 */
export const getEarnings = asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const { startDate, endDate } = req.query;

  const worker = await Worker.findOne({ user: userId });

  if (!worker) {
    return notFoundResponse(res, 'Worker profile not found');
  }

  // Build date filter
  const dateFilter: any = { worker: worker._id, status: 'COMPLETED' };
  if (startDate) {
    dateFilter.createdAt = { $gte: new Date(startDate as string) };
  }
  if (endDate) {
    dateFilter.createdAt = { ...dateFilter.createdAt, $lte: new Date(endDate as string) };
  }

  // Get completed bookings
  const bookings = await Booking.find(dateFilter).select('pricing createdAt');

  // Calculate earnings
  const total = bookings.reduce((sum, booking) => sum + (booking.pricing.finalPrice || 0), 0);
  const platformFees = bookings.reduce((sum, booking) => sum + (booking.pricing.platformFee || 0), 0);
  const netEarnings = total - platformFees;

  // Group by date for breakdown
  const breakdown: Record<string, number> = {};
  bookings.forEach(booking => {
    const date = booking.createdAt?.toISOString().split('T')[0];
    if (date) {
      breakdown[date] = (breakdown[date] || 0) + (booking.pricing.finalPrice || 0) - (booking.pricing.platformFee || 0);
    }
  });

  return successResponse(res, {
    totalEarnings: total,
    platformFees,
    netEarnings,
    bookingsCount: bookings.length,
    breakdown,
  }, 'Earnings retrieved successfully');
});
