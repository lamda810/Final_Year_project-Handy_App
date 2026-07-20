import { Router, IRouter } from 'express';
import { authenticate, authorize, validate } from '@handy-go/shared';
import * as chatController from '../controllers/chat.controller.js';
import * as customerController from '../controllers/customer.controller.js';
import { sendMessageSchema } from '../validators/booking.validators.js';

const router: IRouter = Router();

// Routes shared by customers AND workers. Middleware is applied per-route
// (not router.use) so unmatched paths fall through to the customer router
// instead of being rejected here. The :bookingId param is constrained to a
// Mongo ObjectId so literal paths like /customer are not shadowed.

/**
 * @route   GET /api/bookings/:bookingId
 * @desc    Get booking details (controller handles CUSTOMER/WORKER scoping)
 * @access  Private (Customer or Worker participant)
 */
router.get(
  '/:bookingId([0-9a-fA-F]{24})',
  authenticate,
  authorize('CUSTOMER', 'WORKER'),
  customerController.getBookingDetails
);

/**
 * @route   GET /api/bookings/:bookingId/messages
 * @desc    Get chat messages for a booking
 * @access  Private (Customer or Worker participant)
 */
router.get(
  '/:bookingId([0-9a-fA-F]{24})/messages',
  authenticate,
  authorize('CUSTOMER', 'WORKER'),
  chatController.getMessages
);

/**
 * @route   POST /api/bookings/:bookingId/messages
 * @desc    Send a chat message on a booking
 * @access  Private (Customer or Worker participant)
 */
router.post(
  '/:bookingId([0-9a-fA-F]{24})/messages',
  authenticate,
  authorize('CUSTOMER', 'WORKER'),
  validate(sendMessageSchema),
  chatController.sendMessage
);

export default router;
