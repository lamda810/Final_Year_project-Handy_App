import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as adminController from '../controllers/admin.controller.js';
import { validate } from '@handy-go/shared';
import { adminUpdateBookingSchema } from '../validators/booking.validators.js';
const router = Router();
// All routes require authentication as ADMIN
router.use(authenticate);
router.use(authorize('ADMIN'));
/**
 * @route   GET /api/bookings/admin
 * @desc    Get all bookings (paginated with filters)
 * @access  Private (Admin)
 */
router.get('/', adminController.getAllBookings);
/**
 * @route   GET /api/bookings/admin/stats
 * @desc    Get booking statistics
 * @access  Private (Admin)
 */
router.get('/stats', adminController.getBookingStats);
/**
 * @route   GET /api/bookings/admin/:bookingId
 * @desc    Get booking by ID
 * @access  Private (Admin)
 */
router.get('/:bookingId', adminController.getBookingById);
/**
 * @route   PUT /api/bookings/admin/:bookingId
 * @desc    Update booking
 * @access  Private (Admin)
 */
router.put('/:bookingId', validate(adminUpdateBookingSchema), adminController.updateBooking);
/**
 * @route   PUT /api/bookings/admin/:bookingId/reassign
 * @desc    Reassign worker to booking
 * @access  Private (Admin)
 */
router.put('/:bookingId/reassign', adminController.reassignWorker);
export default router;
//# sourceMappingURL=admin.routes.js.map