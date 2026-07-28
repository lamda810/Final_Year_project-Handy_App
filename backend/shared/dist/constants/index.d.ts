/**
 * Handy Go - Shared Constants
 * Contains all constant values used across the platform
 */
export declare const SERVICE_CATEGORIES: readonly ["PLUMBING", "ELECTRICAL", "CLEANING", "AC_REPAIR", "CARPENTER", "PAINTING", "MECHANIC", "GENERAL_HANDYMAN"];
export type ServiceCategory = (typeof SERVICE_CATEGORIES)[number];
export declare const USER_ROLES: readonly ["CUSTOMER", "WORKER", "ADMIN"];
export type UserRole = (typeof USER_ROLES)[number];
export declare const USER_ROLES_OBJ: {
    CUSTOMER: "CUSTOMER";
    WORKER: "WORKER";
    ADMIN: "ADMIN";
};
export declare const BOOKING_STATUS: readonly ["PENDING", "ACCEPTED", "IN_PROGRESS", "COMPLETED", "CANCELLED", "DISPUTED"];
export type BookingStatus = (typeof BOOKING_STATUS)[number];
export declare const PAYMENT_STATUS: readonly ["PENDING", "COMPLETED", "REFUNDED", "FAILED"];
export type PaymentStatus = (typeof PAYMENT_STATUS)[number];
export declare const PAYMENT_METHODS: readonly ["CASH", "WALLET", "CARD", "JAZZCASH", "EASYPAISA"];
export type PaymentMethod = (typeof PAYMENT_METHODS)[number];
export declare const WORKER_STATUS: readonly ["AVAILABLE", "BUSY", "OFFLINE"];
export type WorkerStatus = (typeof WORKER_STATUS)[number];
export declare const WORKER_VERIFICATION_STATUS: readonly ["PENDING_VERIFICATION", "ACTIVE", "SUSPENDED", "INACTIVE", "REJECTED"];
export type WorkerVerificationStatus = (typeof WORKER_VERIFICATION_STATUS)[number];
export declare const SOS_PRIORITY: readonly ["LOW", "MEDIUM", "HIGH", "CRITICAL"];
export type SOSPriority = (typeof SOS_PRIORITY)[number];
export declare const SOS_PRIORITY_OBJ: {
    LOW: "LOW";
    MEDIUM: "MEDIUM";
    HIGH: "HIGH";
    CRITICAL: "CRITICAL";
};
export declare const SOS_STATUS: readonly ["ACTIVE", "RESOLVED", "ESCALATED", "FALSE_ALARM"];
export type SOSStatus = (typeof SOS_STATUS)[number];
export declare const WITHDRAWAL_STATUS: readonly ["PENDING", "APPROVED", "REJECTED", "PAID"];
export type WithdrawalStatus = (typeof WITHDRAWAL_STATUS)[number];
export declare const MIN_WITHDRAWAL_AMOUNT = 500;
export declare const OTP_PURPOSES: readonly ["REGISTRATION", "LOGIN", "PASSWORD_RESET", "JOB_START", "JOB_END"];
export type OTPPurpose = (typeof OTP_PURPOSES)[number];
export declare const NOTIFICATION_TYPES: readonly ["BOOKING", "PAYMENT", "SOS", "SYSTEM", "PROMOTION"];
export type NotificationType = (typeof NOTIFICATION_TYPES)[number];
export declare const DAYS_OF_WEEK: readonly ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
export type DayOfWeek = (typeof DAYS_OF_WEEK)[number];
export declare const CANCELLATION_PARTIES: readonly ["CUSTOMER", "WORKER", "ADMIN", "SYSTEM"];
export type CancellationParty = (typeof CANCELLATION_PARTIES)[number];
export declare const SUPPORTED_LANGUAGES: readonly ["en", "ur"];
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];
export declare const PLATFORM_FEE_PERCENTAGE = 10;
export declare const DEFAULTS: {
    readonly SERVICE_RADIUS_KM: 10;
    readonly TRUST_SCORE: 50;
    readonly OTP_EXPIRY_MINUTES: 5;
    readonly OTP_MAX_ATTEMPTS: 3;
    readonly JWT_EXPIRES_IN: "7d";
    readonly JWT_REFRESH_EXPIRES_IN: "30d";
    readonly BOOKING_ACCEPTANCE_TIMEOUT_MINUTES: 5;
    readonly NOTIFICATION_RETENTION_DAYS: 30;
    readonly PAGINATION_LIMIT: 20;
    readonly MAX_PAGINATION_LIMIT: 100;
};
export declare const HTTP_STATUS: {
    readonly OK: 200;
    readonly CREATED: 201;
    readonly NO_CONTENT: 204;
    readonly BAD_REQUEST: 400;
    readonly UNAUTHORIZED: 401;
    readonly FORBIDDEN: 403;
    readonly NOT_FOUND: 404;
    readonly CONFLICT: 409;
    readonly UNPROCESSABLE_ENTITY: 422;
    readonly TOO_MANY_REQUESTS: 429;
    readonly INTERNAL_SERVER_ERROR: 500;
    readonly SERVICE_UNAVAILABLE: 503;
};
export declare const ERROR_CODES: {
    readonly INVALID_CREDENTIALS: "AUTH001";
    readonly TOKEN_EXPIRED: "AUTH002";
    readonly TOKEN_INVALID: "AUTH003";
    readonly OTP_EXPIRED: "AUTH004";
    readonly OTP_INVALID: "AUTH005";
    readonly OTP_MAX_ATTEMPTS: "AUTH006";
    readonly PHONE_ALREADY_EXISTS: "AUTH007";
    readonly EMAIL_ALREADY_EXISTS: "AUTH008";
    readonly USER_NOT_FOUND: "USER001";
    readonly USER_INACTIVE: "USER002";
    readonly WORKER_NOT_VERIFIED: "USER003";
    readonly INVALID_CNIC: "USER004";
    readonly CNIC_ALREADY_EXISTS: "USER005";
    readonly BOOKING_NOT_FOUND: "BOOK001";
    readonly INVALID_STATUS_TRANSITION: "BOOK002";
    readonly WORKER_NOT_AVAILABLE: "BOOK003";
    readonly CANNOT_CANCEL_BOOKING: "BOOK004";
    readonly BOOKING_ALREADY_RATED: "BOOK005";
    readonly PAYMENT_FAILED: "PAY001";
    readonly INSUFFICIENT_BALANCE: "PAY002";
    readonly REFUND_FAILED: "PAY003";
    readonly VALIDATION_ERROR: "GEN001";
    readonly RATE_LIMIT_EXCEEDED: "GEN002";
    readonly INTERNAL_ERROR: "GEN003";
    readonly SERVICE_UNAVAILABLE: "GEN004";
};
export declare const PAKISTANI_CITIES: readonly ["Karachi", "Lahore", "Islamabad", "Rawalpindi", "Faisalabad", "Multan", "Peshawar", "Quetta", "Sialkot", "Gujranwala", "Hyderabad", "Abbottabad", "Bahawalpur", "Sargodha", "Sukkur"];
//# sourceMappingURL=index.d.ts.map