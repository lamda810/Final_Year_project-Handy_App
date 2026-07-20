import { Booking, Worker, asyncHandler, successResponse, errorResponse, notFoundResponse, paginatedResponse, HTTP_STATUS, DEFAULTS, } from '@handy-go/shared';
import notificationService from '../services/notification.service.js';
import pricingService from '../services/pricing.service.js';
import matchingService from '../services/matching.service.js';
// 'contactPhone' is the optional alternate number set on the Customer
// profile; nested-populating 'user' with 'phone' provides the fallback
// login phone for the worker's "call customer" button when no
// contactPhone is set.
const customerPopulateWithPhone = {
    path: 'customer',
    select: 'user firstName lastName contactPhone',
    populate: { path: 'user', select: 'phone' },
};
/**
 * Get available bookings for worker
 * GET /api/bookings/worker/available
 */
export const getAvailableBookings = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    if (worker.status !== 'ACTIVE') {
        return errorResponse(res, 'Worker account not active', HTTP_STATUS.FORBIDDEN);
    }
    // Find bookings assigned to this worker that are pending acceptance
    const bookings = await Booking.find({
        worker: worker._id,
        status: 'PENDING',
    })
        .populate('customer', 'firstName lastName profileImage contactPhone')
        .sort({ createdAt: -1 });
    return successResponse(res, bookings, 'Available bookings retrieved');
});
/**
 * Get worker bookings
 * GET /api/bookings/worker
 */
export const getWorkerBookings = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { status, page = '1', limit = '20' } = req.query;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const pageNum = parseInt(page);
    const limitNum = Math.min(parseInt(limit), DEFAULTS.MAX_PAGINATION_LIMIT);
    const skip = (pageNum - 1) * limitNum;
    const filter = { worker: worker._id };
    if (status) {
        filter.status = status;
    }
    const [bookings, total] = await Promise.all([
        Booking.find(filter)
            .populate('customer', 'firstName lastName profileImage addresses contactPhone')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limitNum),
        Booking.countDocuments(filter),
    ]);
    return paginatedResponse(res, bookings, pageNum, limitNum, total, 'Bookings retrieved');
});
/**
 * Accept booking
 * POST /api/bookings/:bookingId/accept
 */
export const acceptBooking = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { bookingId } = req.params;
    const { estimatedArrivalMinutes } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const booking = await Booking.findOne({
        _id: bookingId,
        worker: worker._id,
        status: 'PENDING',
    }).populate(customerPopulateWithPhone);
    if (!booking) {
        return notFoundResponse(res, 'Booking not found or not assigned to you');
    }
    // Update booking status
    booking.status = 'ACCEPTED';
    booking.timeline.push({
        status: 'ACCEPTED',
        timestamp: new Date(),
        note: `Accepted by ${worker.firstName} ${worker.lastName}`,
    });
    await booking.save();
    // Update worker availability if urgent
    if (booking.isUrgent) {
        worker.availability.isAvailable = false;
        await worker.save();
    }
    // Notify customer
    await notificationService.notifyWorkerAccepted(booking.customer.user.toString(), `${worker.firstName} ${worker.lastName}`, booking.bookingNumber, estimatedArrivalMinutes);
    return successResponse(res, booking, 'Booking accepted successfully');
});
/**
 * Reject booking
 * POST /api/bookings/:bookingId/reject
 */
export const rejectBooking = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { bookingId } = req.params;
    const { reason } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const booking = await Booking.findOne({
        _id: bookingId,
        worker: worker._id,
        status: 'PENDING',
    }).populate(customerPopulateWithPhone);
    if (!booking) {
        return notFoundResponse(res, 'Booking not found or not assigned to you');
    }
    // Remove worker from booking
    const rejectedWorkerId = worker._id.toString();
    booking.worker = undefined;
    booking.timeline.push({
        status: 'WORKER_REJECTED',
        timestamp: new Date(),
        note: `Rejected by worker. Reason: ${reason}`,
    });
    await booking.save();
    // Try to auto-replace with another worker
    const bookingIdStr = bookingId ?? booking._id.toString();
    const replacementResult = await matchingService.autoReplaceWorker(bookingIdStr, [rejectedWorkerId]);
    if (replacementResult.success && replacementResult.newWorkerId) {
        // Notify customer about replacement
        const newWorker = await Worker.findById(replacementResult.newWorkerId);
        if (newWorker) {
            await notificationService.notifyWorkerAssigned(booking.customer.user.toString(), `${newWorker.firstName} ${newWorker.lastName}`, booking.bookingNumber);
        }
    }
    else {
        // Notify customer that worker rejected and no replacement found
        await notificationService.sendNotification({
            recipientId: booking.customer.user.toString(),
            type: 'BOOKING',
            title: 'Worker Unavailable',
            body: 'Your assigned worker is unavailable. Please select another worker.',
            data: { bookingNumber: booking.bookingNumber, action: 'SELECT_WORKER' },
        });
    }
    return successResponse(res, { success: true, replacementFound: replacementResult.success }, 'Booking rejected');
});
/**
 * Start job
 * POST /api/bookings/:bookingId/start
 */
export const startJob = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { bookingId } = req.params;
    const { beforeImages } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const booking = await Booking.findOne({
        _id: bookingId,
        worker: worker._id,
        status: 'ACCEPTED',
    }).populate(customerPopulateWithPhone);
    if (!booking) {
        return notFoundResponse(res, 'Booking not found or not in accepted status');
    }
    // Update booking status
    booking.status = 'IN_PROGRESS';
    booking.actualStartTime = new Date();
    if (beforeImages && beforeImages.length > 0) {
        booking.images.before = [...booking.images.before, ...beforeImages];
    }
    booking.timeline.push({
        status: 'IN_PROGRESS',
        timestamp: new Date(),
        note: 'Job started',
    });
    await booking.save();
    // Update worker status
    worker.availability.isAvailable = false;
    await worker.save();
    // Notify customer
    await notificationService.notifyJobStarted(booking.customer.user.toString(), booking.serviceCategory, booking.bookingNumber);
    return successResponse(res, booking, 'Job started successfully');
});
/**
 * Complete job
 * POST /api/bookings/:bookingId/complete
 */
export const completeJob = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { bookingId } = req.params;
    const { afterImages, finalPrice, materialsCost, notes } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const booking = await Booking.findOne({
        _id: bookingId,
        worker: worker._id,
        status: 'IN_PROGRESS',
    }).populate(customerPopulateWithPhone);
    if (!booking) {
        return notFoundResponse(res, 'Booking not found or not in progress');
    }
    // The price is decided at booking creation (estimatedPrice) and the
    // worker no longer re-enters it on completion — only fall back to a
    // client-sent finalPrice if one is explicitly provided.
    const laborCost = typeof finalPrice === 'number' ? finalPrice : (booking.pricing.estimatedPrice || 0);
    // Calculate pricing
    const pricing = pricingService.calculatePricing({
        laborCost,
        materialsCost: materialsCost || 0,
    });
    // Calculate actual duration
    const actualDuration = booking.actualStartTime
        ? Math.round((Date.now() - booking.actualStartTime.getTime()) / (1000 * 60))
        : booking.estimatedDuration;
    // Update booking
    booking.status = 'COMPLETED';
    booking.actualEndTime = new Date();
    booking.actualDuration = actualDuration;
    booking.pricing = {
        ...booking.pricing,
        finalPrice: pricing.total,
        laborCost: pricing.laborCost,
        materialsCost: pricing.materialsCost,
        platformFee: pricing.platformFee,
    };
    if (afterImages && afterImages.length > 0) {
        booking.images.after = [...booking.images.after, ...afterImages];
    }
    booking.timeline.push({
        status: 'COMPLETED',
        timestamp: new Date(),
        note: notes || 'Job completed',
    });
    await booking.save();
    // Update worker stats
    worker.totalJobsCompleted += 1;
    worker.totalEarnings += pricingService.calculateWorkerEarnings(pricing.total, pricing.platformFee);
    worker.availability.isAvailable = true;
    await worker.save();
    // Notify customer
    await notificationService.notifyJobCompleted(booking.customer.user.toString(), pricing.total, booking.bookingNumber);
    return successResponse(res, booking, 'Job completed successfully');
});
/**
 * Update worker location during booking
 * PUT /api/bookings/:bookingId/location
 */
export const updateLocation = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { bookingId } = req.params;
    const { coordinates } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const booking = await Booking.findOne({
        _id: bookingId,
        worker: worker._id,
        status: { $in: ['ACCEPTED', 'IN_PROGRESS'] },
    });
    if (!booking) {
        return notFoundResponse(res, 'Active booking not found');
    }
    // Add location to tracking array
    if (!booking.workerLocation) {
        booking.workerLocation = [];
    }
    booking.workerLocation.push({
        coordinates: {
            lat: coordinates.lat,
            lng: coordinates.lng,
        },
        timestamp: new Date(),
    });
    // Keep only last 100 location points
    if (booking.workerLocation.length > 100) {
        booking.workerLocation = booking.workerLocation.slice(-100);
    }
    await booking.save();
    // Also update worker's current location
    await worker.updateLocation(coordinates.lat, coordinates.lng);
    return successResponse(res, { success: true }, 'Location updated');
});
//# sourceMappingURL=worker.controller.js.map