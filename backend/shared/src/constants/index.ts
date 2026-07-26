/**
 * Handy Go - Shared Constants
 * Contains all constant values used across the platform
 */

// Service Categories offered by the platform
export const SERVICE_CATEGORIES = [
  'PLUMBING',
  'ELECTRICAL',
  'CLEANING',
  'AC_REPAIR',
  'CARPENTER',
  'PAINTING',
  'MECHANIC',
  'GENERAL_HANDYMAN',
] as const;

export type ServiceCategory = (typeof SERVICE_CATEGORIES)[number];

// User Roles - Array version for iteration
export const USER_ROLES = ['CUSTOMER', 'WORKER', 'ADMIN'] as const;
export type UserRole = (typeof USER_ROLES)[number];

// User Roles - Object version for easy access (USER_ROLES_OBJ.ADMIN)
export const USER_ROLES_OBJ = {
  CUSTOMER: 'CUSTOMER' as const,
  WORKER: 'WORKER' as const,
  ADMIN: 'ADMIN' as const,
};

// Booking Status
export const BOOKING_STATUS = [
  'PENDING',
  'ACCEPTED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
  'DISPUTED',
] as const;
export type BookingStatus = (typeof BOOKING_STATUS)[number];

// Payment Status
export const PAYMENT_STATUS = ['PENDING', 'COMPLETED', 'REFUNDED', 'FAILED'] as const;
export type PaymentStatus = (typeof PAYMENT_STATUS)[number];

// Payment Methods
export const PAYMENT_METHODS = ['CASH', 'WALLET', 'CARD', 'JAZZCASH', 'EASYPAISA'] as const;
export type PaymentMethod = (typeof PAYMENT_METHODS)[number];

// Worker Status
export const WORKER_STATUS = ['AVAILABLE', 'BUSY', 'OFFLINE'] as const;
export type WorkerStatus = (typeof WORKER_STATUS)[number];

// Worker Verification Status
export const WORKER_VERIFICATION_STATUS = [
  'PENDING_VERIFICATION',
  'ACTIVE',
  'SUSPENDED',
  'INACTIVE',
  'REJECTED',
] as const;
export type WorkerVerificationStatus = (typeof WORKER_VERIFICATION_STATUS)[number];

// SOS Priority Levels - Array version
export const SOS_PRIORITY = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const;
export type SOSPriority = (typeof SOS_PRIORITY)[number];

// SOS Priority Levels - Object version for easy access
export const SOS_PRIORITY_OBJ = {
  LOW: 'LOW' as const,
  MEDIUM: 'MEDIUM' as const,
  HIGH: 'HIGH' as const,
  CRITICAL: 'CRITICAL' as const,
};

// SOS Status
export const SOS_STATUS = ['ACTIVE', 'RESOLVED', 'ESCALATED', 'FALSE_ALARM'] as const;
export type SOSStatus = (typeof SOS_STATUS)[number];

// OTP Purposes
export const OTP_PURPOSES = ['REGISTRATION', 'LOGIN', 'PASSWORD_RESET', 'JOB_START', 'JOB_END'] as const;
export type OTPPurpose = (typeof OTP_PURPOSES)[number];

// Notification Types
export const NOTIFICATION_TYPES = ['BOOKING', 'PAYMENT', 'SOS', 'SYSTEM', 'PROMOTION'] as const;
export type NotificationType = (typeof NOTIFICATION_TYPES)[number];

// Days of Week
export const DAYS_OF_WEEK = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] as const;
export type DayOfWeek = (typeof DAYS_OF_WEEK)[number];

// Cancellation Parties
export const CANCELLATION_PARTIES = ['CUSTOMER', 'WORKER', 'ADMIN', 'SYSTEM'] as const;
export type CancellationParty = (typeof CANCELLATION_PARTIES)[number];

// Languages Supported
export const SUPPORTED_LANGUAGES = ['en', 'ur'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

// Platform Fee Percentage
export const PLATFORM_FEE_PERCENTAGE = 10;

// Default Values
export const DEFAULTS = {
  SERVICE_RADIUS_KM: 10,
  TRUST_SCORE: 50,
  OTP_EXPIRY_MINUTES: 5,
  OTP_MAX_ATTEMPTS: 3,
  JWT_EXPIRES_IN: '7d',
  JWT_REFRESH_EXPIRES_IN: '30d',
  BOOKING_ACCEPTANCE_TIMEOUT_MINUTES: 5,
  NOTIFICATION_RETENTION_DAYS: 30,
  PAGINATION_LIMIT: 20,
  MAX_PAGINATION_LIMIT: 100,
} as const;

// HTTP Status Codes
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
} as const;

// Error Codes
export const ERROR_CODES = {
  // Auth Errors
  INVALID_CREDENTIALS: 'AUTH001',
  TOKEN_EXPIRED: 'AUTH002',
  TOKEN_INVALID: 'AUTH003',
  OTP_EXPIRED: 'AUTH004',
  OTP_INVALID: 'AUTH005',
  OTP_MAX_ATTEMPTS: 'AUTH006',
  PHONE_ALREADY_EXISTS: 'AUTH007',
  EMAIL_ALREADY_EXISTS: 'AUTH008',

  // User Errors
  USER_NOT_FOUND: 'USER001',
  USER_INACTIVE: 'USER002',
  WORKER_NOT_VERIFIED: 'USER003',
  INVALID_CNIC: 'USER004',
  CNIC_ALREADY_EXISTS: 'USER005',

  // Booking Errors
  BOOKING_NOT_FOUND: 'BOOK001',
  INVALID_STATUS_TRANSITION: 'BOOK002',
  WORKER_NOT_AVAILABLE: 'BOOK003',
  CANNOT_CANCEL_BOOKING: 'BOOK004',
  BOOKING_ALREADY_RATED: 'BOOK005',

  // Payment Errors
  PAYMENT_FAILED: 'PAY001',
  INSUFFICIENT_BALANCE: 'PAY002',
  REFUND_FAILED: 'PAY003',

  // General Errors
  VALIDATION_ERROR: 'GEN001',
  RATE_LIMIT_EXCEEDED: 'GEN002',
  INTERNAL_ERROR: 'GEN003',
  SERVICE_UNAVAILABLE: 'GEN004',
} as const;

// Pakistani Cities
export const PAKISTANI_CITIES = [
  'Karachi',
  'Lahore',
  'Islamabad',
  'Rawalpindi',
  'Faisalabad',
  'Multan',
  'Peshawar',
  'Quetta',
  'Sialkot',
  'Gujranwala',
  'Hyderabad',
  'Abbottabad',
  'Bahawalpur',
  'Sargodha',
  'Sukkur',
] as const;
