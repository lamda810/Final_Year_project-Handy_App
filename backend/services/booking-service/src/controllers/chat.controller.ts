import { Request, Response } from 'express';
import {
  Booking,
  Customer,
  Worker,
  ChatMessage,
  asyncHandler,
  successResponse,
  notFoundResponse,
} from '@handy-go/shared';

/**
 * Resolve the booking and verify the requesting user is a participant
 * (the booking's customer or its assigned worker).
 */
const findBookingForParticipant = async (
  bookingId: string,
  userId: string,
  userRole: string
) => {
  if (userRole === 'CUSTOMER') {
    const customer = await Customer.findOne({ user: userId });
    if (!customer) return null;
    return Booking.findOne({ _id: bookingId, customer: customer._id });
  }

  const worker = await Worker.findOne({ user: userId });
  if (!worker) return null;
  return Booking.findOne({ _id: bookingId, worker: worker._id });
};

/**
 * Get chat messages for a booking
 * GET /api/bookings/:bookingId/messages
 */
export const getMessages = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId } = req.params;

  const booking = await findBookingForParticipant(bookingId!, req.user!.id, req.user!.role);
  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  const messages = await ChatMessage.find({ booking: booking._id })
    .sort({ createdAt: 1 })
    .limit(200)
    .lean();

  return successResponse(res, messages, 'Messages retrieved');
});

/**
 * Send a chat message on a booking
 * POST /api/bookings/:bookingId/messages
 */
export const sendMessage = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId } = req.params;
  const { message } = req.body as { message: string };

  const booking = await findBookingForParticipant(bookingId!, req.user!.id, req.user!.role);
  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  const chatMessage = await ChatMessage.create({
    booking: booking._id,
    sender: req.user!.id,
    senderType: req.user!.role,
    message,
  });

  return successResponse(res, chatMessage, 'Message sent', 201);
});
