import { Request, Response } from 'express';
import {
  Booking,
  Customer,
  Worker,
  ChatMessage,
  asyncHandler,
  successResponse,
  errorResponse,
  notFoundResponse,
  HTTP_STATUS,
} from '@handy-go/shared';
import notificationService from '../services/notification.service.js';

/**
 * Resolve the booking and verify the requesting user is a participant
 * (the booking's customer or its assigned worker). Also returns which side
 * the requester is on, since offer endpoints need to know who is proposing.
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
 * Booking statuses in which a price can still be negotiated — once a job
 * has started the price is locked in (negotiatedPrice already applied).
 */
const NEGOTIABLE_STATUSES = ['PENDING', 'ACCEPTED'];

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

/**
 * Resolve the OTHER participant's User id on a booking (to notify them),
 * given the populated-or-not customer/worker refs.
 */
const otherPartyUserId = async (booking: any, userRole: string): Promise<string | null> => {
  if (userRole === 'CUSTOMER') {
    if (!booking.worker) return null;
    const worker = await Worker.findById(booking.worker);
    return worker ? worker.user.toString() : null;
  }
  const customer = await Customer.findById(booking.customer);
  return customer ? customer.user.toString() : null;
};

/**
 * Propose a price offer (or counter-offer) on a booking.
 * POST /api/bookings/:bookingId/offers
 */
export const proposeOffer = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId } = req.params;
  const { amount } = req.body as { amount: number };

  const booking = await findBookingForParticipant(bookingId!, req.user!.id, req.user!.role);
  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  if (!NEGOTIABLE_STATUSES.includes(booking.status)) {
    return errorResponse(res, 'Price can no longer be negotiated on this booking', HTTP_STATUS.BAD_REQUEST);
  }

  // Superseding any still-pending offer on this booking — only one offer
  // can be "live" at a time, so an older unanswered offer is moot once a
  // new one is proposed by either side.
  await ChatMessage.updateMany(
    { booking: booking._id, messageType: { $in: ['PRICE_OFFER', 'PRICE_COUNTER'] }, offerStatus: 'PENDING' },
    { offerStatus: 'SUPERSEDED' }
  );

  const isFirstOffer = !(await ChatMessage.exists({
    booking: booking._id,
    messageType: { $in: ['PRICE_OFFER', 'PRICE_COUNTER'] },
  }));

  const chatMessage = await ChatMessage.create({
    booking: booking._id,
    sender: req.user!.id,
    senderType: req.user!.role,
    message: `Proposed a price of Rs. ${amount}`,
    messageType: isFirstOffer ? 'PRICE_OFFER' : 'PRICE_COUNTER',
    offerAmount: amount,
    offerStatus: 'PENDING',
  });

  const recipientId = await otherPartyUserId(booking, req.user!.role);
  if (recipientId) {
    await notificationService.sendNotification({
      recipientId,
      type: 'BOOKING',
      title: 'New price offer',
      body: `Rs. ${amount} proposed for booking ${booking.bookingNumber}`,
      data: { bookingNumber: booking.bookingNumber, action: 'PRICE_OFFER', amount },
    });
  }

  return successResponse(res, chatMessage, 'Offer sent', 201);
});

/**
 * Accept a pending price offer — locks the amount into
 * booking.pricing.negotiatedPrice.
 * POST /api/bookings/:bookingId/offers/:offerId/accept
 */
export const acceptOffer = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId, offerId } = req.params;

  const booking = await findBookingForParticipant(bookingId!, req.user!.id, req.user!.role);
  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  const offer = await ChatMessage.findOne({
    _id: offerId,
    booking: booking._id,
    messageType: { $in: ['PRICE_OFFER', 'PRICE_COUNTER'] },
    offerStatus: 'PENDING',
  });
  if (!offer) {
    return notFoundResponse(res, 'Offer not found or no longer pending');
  }

  // A party cannot accept their own offer — it must be answered by the
  // other side.
  if (offer.senderType === req.user!.role) {
    return errorResponse(res, 'Waiting for the other party to respond to this offer', HTTP_STATUS.BAD_REQUEST);
  }

  offer.offerStatus = 'ACCEPTED';
  await offer.save();

  booking.pricing = { ...booking.pricing, negotiatedPrice: offer.offerAmount };
  booking.timeline.push({
    status: booking.status,
    timestamp: new Date(),
    note: `Price negotiated to Rs. ${offer.offerAmount}`,
  });
  await booking.save();

  const acceptedNotice = await ChatMessage.create({
    booking: booking._id,
    sender: req.user!.id,
    senderType: req.user!.role,
    message: `Accepted the price of Rs. ${offer.offerAmount}`,
    messageType: 'PRICE_ACCEPTED',
    offerAmount: offer.offerAmount,
    offerStatus: 'ACCEPTED',
    offerRef: offer._id,
  });

  const recipientId = await otherPartyUserId(booking, req.user!.role);
  if (recipientId) {
    await notificationService.sendNotification({
      recipientId,
      type: 'BOOKING',
      title: 'Price offer accepted',
      body: `Rs. ${offer.offerAmount} agreed for booking ${booking.bookingNumber}`,
      data: { bookingNumber: booking.bookingNumber, action: 'PRICE_ACCEPTED', amount: offer.offerAmount },
    });
  }

  return successResponse(res, { booking, message: acceptedNotice }, 'Offer accepted');
});

/**
 * Reject a pending price offer.
 * POST /api/bookings/:bookingId/offers/:offerId/reject
 */
export const rejectOffer = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId, offerId } = req.params;

  const booking = await findBookingForParticipant(bookingId!, req.user!.id, req.user!.role);
  if (!booking) {
    return notFoundResponse(res, 'Booking not found');
  }

  const offer = await ChatMessage.findOne({
    _id: offerId,
    booking: booking._id,
    messageType: { $in: ['PRICE_OFFER', 'PRICE_COUNTER'] },
    offerStatus: 'PENDING',
  });
  if (!offer) {
    return notFoundResponse(res, 'Offer not found or no longer pending');
  }

  if (offer.senderType === req.user!.role) {
    return errorResponse(res, 'Waiting for the other party to respond to this offer', HTTP_STATUS.BAD_REQUEST);
  }

  offer.offerStatus = 'REJECTED';
  await offer.save();

  const rejectedNotice = await ChatMessage.create({
    booking: booking._id,
    sender: req.user!.id,
    senderType: req.user!.role,
    message: `Rejected the price of Rs. ${offer.offerAmount}`,
    messageType: 'PRICE_REJECTED',
    offerAmount: offer.offerAmount,
    offerStatus: 'REJECTED',
    offerRef: offer._id,
  });

  const recipientId = await otherPartyUserId(booking, req.user!.role);
  if (recipientId) {
    await notificationService.sendNotification({
      recipientId,
      type: 'BOOKING',
      title: 'Price offer rejected',
      body: `Rs. ${offer.offerAmount} was rejected for booking ${booking.bookingNumber}`,
      data: { bookingNumber: booking.bookingNumber, action: 'PRICE_REJECTED', amount: offer.offerAmount },
    });
  }

  return successResponse(res, rejectedNotice, 'Offer rejected');
});
