import { Router, IRouter } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as workerController from '../controllers/worker.controller.js';
import { validate } from '@handy-go/shared';
import {
  acceptBookingSchema,
  rejectBookingSchema,
  startJobWithOtpSchema,
  completeJobWithOtpSchema,
  updateLocationSchema,
} from '../validators/booking.validators.js';

const router: IRouter = Router();

// All routes require authentication as WORKER
router.use(authenticate);
router.use(authorize('WORKER'));

/**
 * @route   GET /api/bookings/worker/available
 * @desc    Get bookings available for acceptance
 * @access  Private (Worker)
 */
router.get('/available', workerController.getAvailableBookings);

/**
 * @route   GET /api/bookings/worker
 * @desc    Get worker's bookings
 * @access  Private (Worker)
 */
router.get('/', workerController.getWorkerBookings);

/**
 * @route   POST /api/bookings/:bookingId/accept
 * @desc    Accept booking
 * @access  Private (Worker)
 */
router.post('/:bookingId/accept', validate(acceptBookingSchema), workerController.acceptBooking);

/**
 * @route   POST /api/bookings/:bookingId/reject
 * @desc    Reject booking
 * @access  Private (Worker)
 */
router.post('/:bookingId/reject', validate(rejectBookingSchema), workerController.rejectBooking);

/**
 * @route   POST /api/bookings/:bookingId/start
 * @desc    Start job (requires the JOB_START OTP the customer reads aloud)
 * @access  Private (Worker)
 */
router.post('/:bookingId/start', validate(startJobWithOtpSchema), workerController.startJob);

/**
 * @route   POST /api/bookings/:bookingId/complete
 * @desc    Complete job (requires the JOB_END OTP the customer reads aloud)
 * @access  Private (Worker)
 */
router.post('/:bookingId/complete', validate(completeJobWithOtpSchema), workerController.completeJob);

/**
 * @route   PUT /api/bookings/:bookingId/location
 * @desc    Update worker location for booking
 * @access  Private (Worker)
 */
router.put('/:bookingId/location', validate(updateLocationSchema), workerController.updateLocation);

export default router;
