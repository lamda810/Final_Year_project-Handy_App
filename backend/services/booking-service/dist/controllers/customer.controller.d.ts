import { Request, Response } from 'express';
/**
 * Create a new booking
 * POST /api/bookings
 */
export declare const createBooking: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Select worker for booking
 * POST /api/bookings/:bookingId/select-worker
 */
export declare const selectWorker: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get customer bookings
 * GET /api/bookings/customer
 */
export declare const getCustomerBookings: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get booking details
 * GET /api/bookings/:bookingId
 */
export declare const getBookingDetails: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Cancel booking
 * POST /api/bookings/:bookingId/cancel
 */
export declare const cancelBooking: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Rate booking
 * POST /api/bookings/:bookingId/rate
 */
export declare const rateBooking: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Request/reveal the job-start or job-end OTP for a booking, so the
 * customer can read it aloud to the worker as proof of presence. Generates
 * a fresh dummy code (always "123456" — see OTP.createOTP) each time it's
 * called, same as the auth OTP flows.
 * GET /api/bookings/:bookingId/job-otp?purpose=JOB_START|JOB_END
 */
export declare const getJobOtp: (req: Request, res: Response, next: import("express").NextFunction) => void;
//# sourceMappingURL=customer.controller.d.ts.map