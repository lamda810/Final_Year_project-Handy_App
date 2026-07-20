import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as customerController from '../controllers/customer.controller.js';
import { validate } from '@handy-go/shared';
import { createBookingSchema, selectWorkerSchema, cancelBookingSchema, rateBookingSchema, } from '../validators/booking.validators.js';
const router = Router();
// All routes require authentication as CUSTOMER
router.use(authenticate);
router.use(authorize('CUSTOMER'));
/**
 * @route   POST /api/bookings
 * @desc    Create a new booking
 * @access  Private (Customer)
 */
router.post('/', validate(createBookingSchema), customerController.createBooking);
/**
 * @route   POST /api/bookings/:bookingId/select-worker
 * @desc    Select worker for booking
 * @access  Private (Customer)
 */
router.post('/:bookingId/select-worker', validate(selectWorkerSchema), customerController.selectWorker);
/**
 * @route   GET /api/bookings/customer
 * @desc    Get customer's bookings
 * @access  Private (Customer)
 */
router.get('/customer', customerController.getCustomerBookings);
/**
 * @route   GET /api/bookings/:bookingId
 * @desc    Get booking details
 * @access  Private (Customer)
 */
router.get('/:bookingId', customerController.getBookingDetails);
/**
 * @route   POST /api/bookings/:bookingId/cancel
 * @desc    Cancel booking
 * @access  Private (Customer)
 */
router.post('/:bookingId/cancel', validate(cancelBookingSchema), customerController.cancelBooking);
/**
 * @route   POST /api/bookings/:bookingId/rate
 * @desc    Rate completed booking
 * @access  Private (Customer)
 */
router.post('/:bookingId/rate', validate(rateBookingSchema), customerController.rateBooking);
export default router;
//# sourceMappingURL=customer.routes.js.map