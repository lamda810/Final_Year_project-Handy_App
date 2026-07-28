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
];
// User Roles - Array version for iteration
export const USER_ROLES = ['CUSTOMER', 'WORKER', 'ADMIN'];
// User Roles - Object version for easy access (USER_ROLES_OBJ.ADMIN)
export const USER_ROLES_OBJ = {
    CUSTOMER: 'CUSTOMER',
    WORKER: 'WORKER',
    ADMIN: 'ADMIN',
};
// Booking Status
export const BOOKING_STATUS = [
    'PENDING',
    'ACCEPTED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED',
    'DISPUTED',
];
// Payment Status
export const PAYMENT_STATUS = ['PENDING', 'COMPLETED', 'REFUNDED', 'FAILED'];
// Payment Methods
export const PAYMENT_METHODS = ['CASH', 'WALLET', 'CARD', 'JAZZCASH', 'EASYPAISA'];
// Worker Status
export const WORKER_STATUS = ['AVAILABLE', 'BUSY', 'OFFLINE'];
// Worker Verification Status
export const WORKER_VERIFICATION_STATUS = [
    'PENDING_VERIFICATION',
    'ACTIVE',
    'SUSPENDED',
    'INACTIVE',
    'REJECTED',
];
// SOS Priority Levels - Array version
export const SOS_PRIORITY = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
// SOS Priority Levels - Object version for easy access
export const SOS_PRIORITY_OBJ = {
    LOW: 'LOW',
    MEDIUM: 'MEDIUM',
    HIGH: 'HIGH',
    CRITICAL: 'CRITICAL',
};
// SOS Status
export const SOS_STATUS = ['ACTIVE', 'RESOLVED', 'ESCALATED', 'FALSE_ALARM'];
// Withdrawal Status
export const WITHDRAWAL_STATUS = ['PENDING', 'APPROVED', 'REJECTED', 'PAID'];
// Minimum amount a worker may withdraw in a single request (PKR)
export const MIN_WITHDRAWAL_AMOUNT = 500;
// OTP Purposes
export const OTP_PURPOSES = ['REGISTRATION', 'LOGIN', 'PASSWORD_RESET', 'JOB_START', 'JOB_END'];
// Notification Types
export const NOTIFICATION_TYPES = ['BOOKING', 'PAYMENT', 'SOS', 'SYSTEM', 'PROMOTION'];
// Days of Week
export const DAYS_OF_WEEK = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
// Cancellation Parties
export const CANCELLATION_PARTIES = ['CUSTOMER', 'WORKER', 'ADMIN', 'SYSTEM'];
// Languages Supported
export const SUPPORTED_LANGUAGES = ['en', 'ur'];
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
};
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
};
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
};
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
];
//# sourceMappingURL=index.js.map