import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';
import {
  successResponse,
  paginatedResponse,
  errorResponse,
  notFoundResponse,
  logger,
  USER_ROLES_OBJ,
} from '@handy-go/shared';

type UserRole = 'CUSTOMER' | 'WORKER' | 'ADMIN';
type BookingStatus = 'PENDING' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
type WorkerStatus = 'PENDING_VERIFICATION' | 'ACTIVE' | 'SUSPENDED' | 'REJECTED';
type SOSPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
type SOSStatus = 'ACTIVE' | 'RESOLVED' | 'ESCALATED' | 'FALSE_ALARM';
type OTTPurpose = 'REGISTRATION' | 'LOGIN' | 'PASSWORD_RESET';

interface DevUser {
  id: string;
  phone: string;
  email?: string;
  role: UserRole;
  isVerified: boolean;
  isActive: boolean;
  password: string;
}

interface DevCustomer {
  _id: string;
  user: DevUser;
  firstName: string;
  lastName: string;
  profileImage?: string;
  addresses: Array<{
    _id?: string;
    label: string;
    address: string;
    city: string;
    coordinates?: {
      lat: number;
      lng: number;
    };
    isDefault: boolean;
  }>;
  totalBookings: number;
  createdAt: string;
}

const sanitizeUser = (user: DevUser) => ({
  id: user.id,
  phone: user.phone,
  email: user.email,
  role: user.role,
  isVerified: user.isVerified,
  isActive: user.isActive,
});

const sanitizeCustomer = (customer: DevCustomer | undefined | null) =>
  customer
    ? {
        ...customer,
        user: sanitizeUser(customer.user),
      }
    : null;

const sanitizeWorker = (worker: DevWorker | undefined | null) =>
  worker
    ? {
        ...worker,
        user: sanitizeUser(worker.user),
      }
    : null;

interface DevWorker {
  _id: string;
  user: DevUser;
  firstName: string;
  lastName: string;
  cnic: string;
  cnicVerified: boolean;
  skills: Array<{
    category: string;
    experience: number;
    hourlyRate: number;
    isVerified: boolean;
  }>;
  rating: {
    average: number;
    count: number;
  };
  trustScore: number;
  totalJobsCompleted: number;
  status: WorkerStatus;
  createdAt: string;
}

interface DevBooking {
  _id: string;
  bookingNumber: string;
  customer: {
    _id: string;
    firstName: string;
    lastName: string;
    phone: string;
  };
  worker?: {
    _id: string;
    firstName: string;
    lastName: string;
    phone: string;
  };
  serviceCategory: string;
  problemDescription: string;
  address: {
    full: string;
    city: string;
  };
  scheduledDateTime: string;
  status: BookingStatus;
  pricing: {
    estimatedPrice: number;
    finalPrice?: number;
    platformFee?: number;
  };
  timeline: Array<{
    status: string;
    timestamp: string;
    note?: string;
  }>;
  createdAt: string;
  updatedAt: string;
}

interface DevSOS {
  _id: string;
  booking?: {
    bookingNumber: string;
    serviceCategory: string;
  };
  initiatedBy: {
    userType: 'CUSTOMER' | 'WORKER';
    userId: {
      _id: string;
      phone: string;
    };
  };
  priority: SOSPriority;
  reason: string;
  description: string;
  location: {
    coordinates: [number, number];
    address?: string;
  };
  status: SOSStatus;
  createdAt: string;
}

interface LocalOtpRecord {
  code: string;
  identifier: string;
  purpose: OTTPurpose;
  expiresAt: number;
}

interface LocalTempTokenRecord {
  identifier: string;
  purpose: OTTPurpose;
  expiresAt: number;
}

const createToken = (userId: string, role: UserRole, expiresInSeconds: number) =>
  jwt.sign({ userId, role }, config.jwt.secret, { expiresIn: expiresInSeconds });
const createTempToken = (identifier: string, purpose: OTTPurpose) =>
  jwt.sign({ identifier, purpose, kind: 'local-dev-temp' }, config.jwt.secret, { expiresIn: '15m' });
const verifyTempToken = (token: string): LocalTempTokenRecord | null => {
  try {
    const decoded = jwt.verify(token, config.jwt.secret, {
      ignoreExpiration: true,
    }) as jwt.JwtPayload & {
      identifier?: string;
      purpose?: OTTPurpose;
      kind?: string;
      exp?: number;
    };

    if (decoded.kind !== 'local-dev-temp' || !decoded.identifier || !decoded.purpose || !decoded.exp) {
      return null;
    }

    return {
      identifier: decoded.identifier,
      purpose: decoded.purpose,
      expiresAt: decoded.exp * 1000,
    };
  } catch {
    return null;
  }
};

const daysAgo = (days: number) => new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
const hoursAgo = (hours: number) => new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();

const users: DevUser[] = [
  {
    id: 'admin-local-1',
    phone: '+920000000000',
    email: 'admin@local.handygo',
    role: 'ADMIN',
    isVerified: true,
    isActive: true,
    password: 'admin12345',
  },
  {
    id: 'customer-1-user',
    phone: '+923001234567',
    email: 'ali@example.com',
    role: 'CUSTOMER',
    isVerified: true,
    isActive: true,
    password: 'customer123',
  },
  {
    id: 'customer-2-user',
    phone: '+923009876543',
    email: 'fatima@example.com',
    role: 'CUSTOMER',
    isVerified: true,
    isActive: true,
    password: 'customer123',
  },
  {
    id: 'worker-1-user',
    phone: '+923111111111',
    email: 'umer.worker@example.com',
    role: 'WORKER',
    isVerified: true,
    isActive: true,
    password: 'worker123',
  },
  {
    id: 'worker-2-user',
    phone: '+923222222222',
    email: 'hina.worker@example.com',
    role: 'WORKER',
    isVerified: true,
    isActive: true,
    password: 'worker123',
  },
  {
    id: 'worker-3-user',
    phone: '+923333333333',
    email: 'waqas.worker@example.com',
    role: 'WORKER',
    isVerified: true,
    isActive: false,
    password: 'worker123',
  },
];

const customers: DevCustomer[] = [
  {
    _id: 'customer-1',
    user: users[1]!,
    firstName: 'Ali',
    lastName: 'Khan',
    addresses: [
      { label: 'Home', address: '12 Main Street', city: 'Karachi', isDefault: true },
    ],
    totalBookings: 4,
    createdAt: daysAgo(6),
  },
  {
    _id: 'customer-2',
    user: users[2]!,
    firstName: 'Fatima',
    lastName: 'Noor',
    addresses: [
      { label: 'Office', address: '88 Business Ave', city: 'Lahore', isDefault: true },
    ],
    totalBookings: 2,
    createdAt: daysAgo(18),
  },
];

const workers: DevWorker[] = [
  {
    _id: 'worker-1',
    user: users[3]!,
    firstName: 'Umer',
    lastName: 'Shah',
    cnic: '42101-1234567-1',
    cnicVerified: true,
    skills: [
      { category: 'PLUMBING', experience: 5, hourlyRate: 1200, isVerified: true },
      { category: 'GENERAL_HANDYMAN', experience: 4, hourlyRate: 1000, isVerified: true },
    ],
    rating: { average: 4.7, count: 31 },
    trustScore: 91,
    totalJobsCompleted: 58,
    status: 'ACTIVE',
    createdAt: daysAgo(22),
  },
  {
    _id: 'worker-2',
    user: users[4]!,
    firstName: 'Hina',
    lastName: 'Adeel',
    cnic: '35202-7654321-2',
    cnicVerified: false,
    skills: [{ category: 'CLEANING', experience: 3, hourlyRate: 900, isVerified: false }],
    rating: { average: 4.2, count: 11 },
    trustScore: 73,
    totalJobsCompleted: 17,
    status: 'PENDING_VERIFICATION',
    createdAt: daysAgo(4),
  },
  {
    _id: 'worker-3',
    user: users[5]!,
    firstName: 'Waqas',
    lastName: 'Raza',
    cnic: '37405-1111111-5',
    cnicVerified: true,
    skills: [{ category: 'ELECTRICAL', experience: 6, hourlyRate: 1400, isVerified: true }],
    rating: { average: 4.8, count: 44 },
    trustScore: 88,
    totalJobsCompleted: 70,
    status: 'SUSPENDED',
    createdAt: daysAgo(30),
  },
];

const bookings: DevBooking[] = [
  {
    _id: 'booking-1',
    bookingNumber: 'HG-1001',
    customer: { _id: customers[0]!._id, firstName: 'Ali', lastName: 'Khan', phone: customers[0]!.user.phone },
    worker: { _id: workers[0]!._id, firstName: 'Umer', lastName: 'Shah', phone: workers[0]!.user.phone },
    serviceCategory: 'PLUMBING',
    problemDescription: 'Kitchen sink leakage',
    address: { full: '12 Main Street, Karachi', city: 'Karachi' },
    scheduledDateTime: hoursAgo(4),
    status: 'COMPLETED',
    pricing: { estimatedPrice: 1800, finalPrice: 2000, platformFee: 300 },
    timeline: [
      { status: 'PENDING', timestamp: daysAgo(2) },
      { status: 'ACCEPTED', timestamp: daysAgo(2) },
      { status: 'IN_PROGRESS', timestamp: hoursAgo(8) },
      { status: 'COMPLETED', timestamp: hoursAgo(2) },
    ],
    createdAt: daysAgo(2),
    updatedAt: hoursAgo(2),
  },
  {
    _id: 'booking-2',
    bookingNumber: 'HG-1002',
    customer: { _id: customers[1]!._id, firstName: 'Fatima', lastName: 'Noor', phone: customers[1]!.user.phone },
    worker: { _id: workers[0]!._id, firstName: 'Umer', lastName: 'Shah', phone: workers[0]!.user.phone },
    serviceCategory: 'GENERAL_HANDYMAN',
    problemDescription: 'Wall shelf installation',
    address: { full: '88 Business Ave, Lahore', city: 'Lahore' },
    scheduledDateTime: hoursAgo(12),
    status: 'IN_PROGRESS',
    pricing: { estimatedPrice: 1500, platformFee: 225 },
    timeline: [
      { status: 'PENDING', timestamp: daysAgo(1) },
      { status: 'ACCEPTED', timestamp: hoursAgo(18) },
      { status: 'IN_PROGRESS', timestamp: hoursAgo(12) },
    ],
    createdAt: daysAgo(1),
    updatedAt: hoursAgo(12),
  },
  {
    _id: 'booking-3',
    bookingNumber: 'HG-1003',
    customer: { _id: customers[0]!._id, firstName: 'Ali', lastName: 'Khan', phone: customers[0]!.user.phone },
    serviceCategory: 'CLEANING',
    problemDescription: 'Deep cleaning service',
    address: { full: '12 Main Street, Karachi', city: 'Karachi' },
    scheduledDateTime: hoursAgo(1),
    status: 'PENDING',
    pricing: { estimatedPrice: 2500, platformFee: 375 },
    timeline: [{ status: 'PENDING', timestamp: hoursAgo(6) }],
    createdAt: hoursAgo(6),
    updatedAt: hoursAgo(6),
  },
  {
    _id: 'booking-4',
    bookingNumber: 'HG-1004',
    customer: { _id: customers[1]!._id, firstName: 'Fatima', lastName: 'Noor', phone: customers[1]!.user.phone },
    serviceCategory: 'ELECTRICAL',
    problemDescription: 'Ceiling fan repair',
    address: { full: '88 Business Ave, Lahore', city: 'Lahore' },
    scheduledDateTime: daysAgo(5),
    status: 'CANCELLED',
    pricing: { estimatedPrice: 1700, platformFee: 0 },
    timeline: [
      { status: 'PENDING', timestamp: daysAgo(5) },
      { status: 'CANCELLED', timestamp: daysAgo(4), note: 'Customer cancelled' },
    ],
    createdAt: daysAgo(5),
    updatedAt: daysAgo(4),
  },
];

const sosAlerts: DevSOS[] = [
  {
    _id: 'sos-1',
    booking: { bookingNumber: 'HG-1002', serviceCategory: 'GENERAL_HANDYMAN' },
    initiatedBy: { userType: 'CUSTOMER', userId: { _id: customers[1]!.user.id, phone: customers[1]!.user.phone } },
    priority: 'HIGH',
    reason: 'Worker not responding',
    description: 'Customer feels unsafe after delayed service start.',
    location: { coordinates: [74.3436, 31.5204], address: 'Lahore' },
    status: 'ACTIVE',
    createdAt: hoursAgo(3),
  },
  {
    _id: 'sos-2',
    initiatedBy: { userType: 'WORKER', userId: { _id: workers[0]!.user.id, phone: workers[0]!.user.phone } },
    priority: 'MEDIUM',
    reason: 'Route issue',
    description: 'Worker reported a road blockage near the customer location.',
    location: { coordinates: [67.0011, 24.8607], address: 'Karachi' },
    status: 'ESCALATED',
    createdAt: hoursAgo(9),
  },
];

const localSettings = {
  general: {
    platformName: 'Handy Go Local',
    supportEmail: 'support@local.handygo',
    supportPhone: '+92 300 0000000',
    defaultLanguage: 'en',
    maintenanceMode: false,
  },
  notifications: {
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: false,
    sosAlertEmail: true,
    sosAlertSms: false,
    bookingUpdates: true,
    marketingEmails: false,
  },
  platform: {
    platformFeePercent: 15,
    minBookingAmount: 500,
    maxServiceRadius: 25,
    cancellationFeePercent: 10,
    workerVerificationRequired: true,
    autoAssignWorkers: false,
  },
  security: {
    twoFactorAuth: false,
    sessionTimeout: 30,
    maxLoginAttempts: 5,
    passwordExpiry: 90,
  },
};

const localOtpStore = new Map<string, LocalOtpRecord>();

const normalizeIdentifier = (phone?: string, email?: string) => {
  const normalizedEmail = email?.trim().toLowerCase();
  const normalizedPhone = phone?.trim();
  return normalizedEmail || normalizedPhone || '';
};

const findUserByIdentifier = (identifier: string) =>
  users.find(
    (item) => item.phone === identifier || item.email?.toLowerCase() === identifier.toLowerCase(),
  );

const normalizeServiceCategory = (value: string) =>
  value
    .trim()
    .replaceAll(/[^A-Za-z0-9]+/g, '_')
    .replaceAll(/_+/g, '_')
    .replaceAll(/^_|_$/g, '')
    .toUpperCase();

const buildMatchedWorkers = (serviceCategory: string, lat?: number, lng?: number) => {
  const normalizedCategory = normalizeServiceCategory(serviceCategory);

  return workers
    .filter((worker) => worker.status === 'ACTIVE')
    .filter((worker) =>
      worker.skills.some((skill) => normalizeServiceCategory(skill.category) === normalizedCategory),
    )
    .map((worker, index) => {
      const primarySkill = worker.skills.find(
        (skill) => normalizeServiceCategory(skill.category) === normalizedCategory,
      ) ?? worker.skills[0];
      const safeLat = typeof lat === 'number' ? lat : 0;
      const safeLng = typeof lng === 'number' ? lng : 0;
      const distance = safeLat === 0 && safeLng === 0 ? 2.5 + index * 1.2 : 1.8 + index * 0.9;

      return {
        workerId: worker._id,
        name: `${worker.firstName} ${worker.lastName}`,
        profileImage: undefined,
        rating: worker.rating.average,
        ratingCount: worker.rating.count,
        trustScore: worker.trustScore,
        distance: Number(distance.toFixed(1)),
        estimatedArrival: 15 + index * 8,
        matchScore: Number((96 - index * 7).toFixed(1)),
        hourlyRate: primarySkill?.hourlyRate ?? 1000,
        skills: worker.skills.map((skill) => skill.category),
      };
    })
    .sort((a, b) => b.matchScore - a.matchScore);
};

const buildPriceEstimate = (hourlyRates: number[], isUrgent?: boolean) => {
  const minRate = hourlyRates.length === 0 ? 800 : hourlyRates.reduce((a, b) => a < b ? a : b);
  const maxRate = hourlyRates.length === 0 ? 1800 : hourlyRates.reduce((a, b) => a > b ? a : b);
  const adjustedMin = isUrgent ? minRate + 200 : minRate;
  const adjustedMax = isUrgent ? maxRate + 300 : maxRate;

  return {
    estimatedPrice: {
      min: adjustedMin,
      max: adjustedMax,
      average: Number(((adjustedMin + adjustedMax) / 2).toFixed(0)),
    },
    breakdown: {
      laborCost: {
        min: Number((adjustedMin * 0.75).toFixed(0)),
        max: Number((adjustedMax * 0.75).toFixed(0)),
      },
      estimatedMaterials: {
        min: Number((adjustedMin * 0.1).toFixed(0)),
        max: Number((adjustedMax * 0.1).toFixed(0)),
      },
      platformFee: Number((adjustedMax * 0.15).toFixed(0)),
    },
  };
};

const findCustomerByUserId = (userId: string) => customers.find((item) => item.user.id === userId);
const findWorkerByUserId = (userId: string) => workers.find((item) => item.user.id === userId);
const issueOtpCode = () => '123456';
const isOtpExpired = (record: LocalOtpRecord) => record.expiresAt < Date.now();
const getAuthenticatedCustomer = (req: Request) => {
  if (!req.user?.id || req.user.role !== USER_ROLES_OBJ.CUSTOMER) {
    return null;
  }

  return findCustomerByUserId(req.user.id) ?? null;
};
const getAuthenticatedWorker = (req: Request) => {
  if (!req.user?.id || req.user.role !== USER_ROLES_OBJ.WORKER) {
    return null;
  }

  return findWorkerByUserId(req.user.id) ?? null;
};
const buildWorkerProfileResponse = (worker: DevWorker) => ({
  _id: worker._id,
  user: sanitizeUser(worker.user),
  firstName: worker.firstName,
  lastName: worker.lastName,
  profileImage: undefined,
  cnic: worker.cnic,
  cnicVerified: worker.cnicVerified,
  cnicFrontImage: null,
  cnicBackImage: null,
  cnicFrontStatus: worker.cnicVerified ? 'verified' : 'pending',
  cnicBackStatus: worker.cnicVerified ? 'verified' : 'pending',
  profilePhotoStatus: 'pending',
  verificationNotes: worker.status === 'REJECTED' ? 'Please update your documents.' : null,
  skills: worker.skills,
  currentLocation: null,
  serviceRadius: 10,
  availability: {
    isAvailable: worker.status === 'ACTIVE',
    schedule: [],
  },
  rating: worker.rating,
  trustScore: worker.trustScore,
  totalJobsCompleted: worker.totalJobsCompleted,
  totalEarnings: worker.totalJobsCompleted * 1250,
  bankDetails: null,
  status: worker.status,
  createdAt: worker.createdAt,
  updatedAt: new Date().toISOString(),
});
const buildLocalAuthPayload = (user: DevUser) => {
  const workerProfile = user.role === USER_ROLES_OBJ.WORKER ? findWorkerByUserId(user.id) : null;

  return {
    user: sanitizeUser(user),
    customer: user.role === USER_ROLES_OBJ.CUSTOMER ? sanitizeCustomer(findCustomerByUserId(user.id)) : null,
    worker: user.role === USER_ROLES_OBJ.WORKER ? sanitizeWorker(workerProfile) : null,
    accessToken: createToken(user.id, user.role, 60 * 60 * 24 * 7),
    refreshToken: createToken(user.id, user.role, 60 * 60 * 24 * 30),
  };
};

const filterBySearch = <T>(items: T[], needle: string, getText: (item: T) => string) => {
  if (!needle) return items;
  const normalized = needle.toLowerCase();
  return items.filter((item) => getText(item).toLowerCase().includes(normalized));
};

const paginate = <T>(items: T[], page: number, limit: number) => {
  const start = (page - 1) * limit;
  return items.slice(start, start + limit);
};

const computeBookingStats = (period: 'day' | 'week' | 'month') => {
  const now = new Date();
  const start = new Date(now);

  if (period === 'day') start.setDate(now.getDate() - 1);
  if (period === 'week') start.setDate(now.getDate() - 7);
  if (period === 'month') start.setMonth(now.getMonth() - 1);

  const filtered = bookings.filter((booking) => new Date(booking.createdAt) >= start);
  const summary = {
    totalBookings: filtered.length,
    completedBookings: filtered.filter((booking) => booking.status === 'COMPLETED').length,
    cancelledBookings: filtered.filter((booking) => booking.status === 'CANCELLED').length,
    pendingBookings: filtered.filter((booking) => booking.status === 'PENDING').length,
    inProgressBookings: filtered.filter((booking) => booking.status === 'IN_PROGRESS').length,
    acceptedBookings: filtered.filter((booking) => booking.status === 'ACCEPTED').length,
    totalRevenue: filtered
      .filter((booking) => booking.status === 'COMPLETED')
      .reduce((sum, booking) => sum + (booking.pricing.finalPrice || booking.pricing.estimatedPrice || 0), 0),
    totalPlatformFees: filtered.reduce((sum, booking) => sum + (booking.pricing.platformFee || 0), 0),
    averageRating: 4.6,
  };

  const dailyBreakdown = Array.from({ length: 7 }, (_, index) => {
    const date = new Date();
    date.setDate(now.getDate() - (6 - index));
    const key = date.toISOString().slice(0, 10);
    const sameDay = filtered.filter((booking) => booking.createdAt.slice(0, 10) === key);
    return {
      _id: key,
      bookings: sameDay.length,
      completed: sameDay.filter((booking) => booking.status === 'COMPLETED').length,
      revenue: sameDay.reduce(
        (sum, booking) => sum + (booking.status === 'COMPLETED' ? booking.pricing.finalPrice || booking.pricing.estimatedPrice || 0 : 0),
        0,
      ),
    };
  });

  const categoryMap = new Map<string, { _id: string; count: number; revenue: number }>();
  filtered.forEach((booking) => {
    const current = categoryMap.get(booking.serviceCategory) ?? {
      _id: booking.serviceCategory,
      count: 0,
      revenue: 0,
    };
    current.count += 1;
    current.revenue += booking.pricing.finalPrice || booking.pricing.estimatedPrice || 0;
    categoryMap.set(booking.serviceCategory, current);
  });

  return {
    period,
    startDate: start,
    endDate: now,
    summary,
    dailyBreakdown,
    categoryBreakdown: Array.from(categoryMap.values()).sort((a, b) => b.count - a.count),
  };
};

export const createLocalDevPublicRouter = (): ReturnType<typeof Router> => {
  const router = Router();

  router.post('/api/auth/send-otp', (req: Request, res: Response) => {
    const { phone, email, purpose } = req.body as {
      phone?: string;
      email?: string;
      purpose?: OTTPurpose;
    };

    if (!purpose || !['REGISTRATION', 'LOGIN', 'PASSWORD_RESET'].includes(purpose)) {
      return errorResponse(res, 'Invalid OTP purpose', 400);
    }

    const identifier = normalizeIdentifier(phone, email);
    if (!identifier) {
      return errorResponse(res, 'Phone or email is required', 400);
    }

    const existingUser = findUserByIdentifier(identifier);
    if ((purpose === 'LOGIN' || purpose === 'PASSWORD_RESET') && !existingUser) {
      return errorResponse(res, 'No account found for this identifier', 404);
    }

    if (purpose === 'REGISTRATION' && existingUser) {
      return errorResponse(res, 'An account already exists for this identifier', 409);
    }

    localOtpStore.set(identifier, {
      code: issueOtpCode(),
      identifier,
      purpose,
      expiresAt: Date.now() + 5 * 60 * 1000,
    });

    logger.info('Local dev OTP issued', { identifier, purpose, code: '123456' });

    return successResponse(
      res,
      {
        otpId: `otp-${identifier.replace(/[^a-zA-Z0-9]/g, '')}`,
      },
      'OTP sent successfully',
    );
  });

  router.post('/api/auth/verify-otp', (req: Request, res: Response) => {
    const { phone, email, code, purpose } = req.body as {
      phone?: string;
      email?: string;
      code?: string;
      purpose?: OTTPurpose;
    };

    const identifier = normalizeIdentifier(phone, email);
    if (!identifier || !code || !purpose) {
      return errorResponse(res, 'Identifier, code, and purpose are required', 400);
    }

    const otpRecord = localOtpStore.get(identifier);
    if (!otpRecord || otpRecord.purpose !== purpose || isOtpExpired(otpRecord)) {
      return errorResponse(res, 'OTP not found or expired', 400);
    }

    if (otpRecord.code !== code) {
      return errorResponse(res, 'Invalid OTP code', 400);
    }

    localOtpStore.delete(identifier);

    return successResponse(
      res,
      {
        isNewUser: !findUserByIdentifier(identifier),
        tempToken: createTempToken(identifier, purpose),
      },
      'OTP verified successfully',
    );
  });

  router.post('/api/auth/login', (req: Request, res: Response) => {
    const { phone, email, password } = req.body as {
      phone?: string;
      email?: string;
      password?: string;
    };
    const normalizedEmail = email?.trim().toLowerCase();
    const user = users.find((item) => {
      const emailMatches = normalizedEmail ? item.email?.toLowerCase() === normalizedEmail : false;
      const phoneMatches = phone ? item.phone === phone : false;
      return (emailMatches || phoneMatches) && item.password === password;
    });

    if (!user) {
      return errorResponse(res, 'Invalid credentials', 401);
    }

    if (!user.isActive) {
      return errorResponse(res, 'Your account has been deactivated', 403);
    }

    const workerProfile = user.role === USER_ROLES_OBJ.WORKER
      ? workers.find((item) => item.user.id === user.id)
      : null;

    if (workerProfile?.status === 'SUSPENDED') {
      return errorResponse(res, 'Your worker account has been suspended', 403);
    }

    logger.info('Local dev user logged in', { phone: user.phone, role: user.role });

    return successResponse(res, buildLocalAuthPayload(user), 'Login successful');
  });

  router.post('/api/auth/logout', (_req: Request, res: Response) =>
    successResponse(res, null, 'Logout successful'),
  );

  router.post('/api/auth/register/customer', (req: Request, res: Response) => {
    const { tempToken, firstName, lastName, phone, password } = req.body as {
      tempToken?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      password?: string;
    };

    if (!tempToken || !firstName || !lastName || !password) {
      return errorResponse(res, 'Missing required registration fields', 400);
    }

    const tokenPayload = verifyTempToken(tempToken);
    if (!tokenPayload || tokenPayload.purpose !== 'REGISTRATION') {
      return errorResponse(res, 'Invalid or expired verification token', 401);
    }

    const identifier = tokenPayload.identifier;
    const identifierIsEmail = identifier.includes('@');
    const finalPhone = phone?.trim() || (!identifierIsEmail ? identifier : '');
    const finalEmail = identifierIsEmail ? identifier : undefined;

    if (!finalPhone) {
      return errorResponse(res, 'Phone number is required for customer registration', 400);
    }

    const existingUser = findUserByIdentifier(finalPhone) || (finalEmail ? findUserByIdentifier(finalEmail) : undefined);
    if (existingUser) {
      if (existingUser.role === USER_ROLES_OBJ.CUSTOMER) {
        return successResponse(res, buildLocalAuthPayload(existingUser), 'Registration successful');
      }
      return errorResponse(res, 'An account already exists for this identifier', 409);
    }

    const newUser: DevUser = {
      id: `customer-${users.length + 1}-user`,
      phone: finalPhone,
      email: finalEmail,
      role: 'CUSTOMER',
      isVerified: true,
      isActive: true,
      password,
    };
    users.push(newUser);

    const newCustomer: DevCustomer = {
      _id: `customer-${customers.length + 1}`,
      user: newUser,
      firstName,
      lastName,
      addresses: [],
      totalBookings: 0,
      createdAt: new Date().toISOString(),
    };
    customers.push(newCustomer);

    return successResponse(res, buildLocalAuthPayload(newUser), 'Registration successful');
  });

  router.post('/api/auth/register/worker', (req: Request, res: Response) => {
    const { tempToken, firstName, lastName, phone, password, cnic, skills } = req.body as {
      tempToken?: string;
      firstName?: string;
      lastName?: string;
      phone?: string;
      password?: string;
      cnic?: string;
      skills?: Array<{ category: string; experience: number; hourlyRate: number }>;
    };

    if (!tempToken || !firstName || !lastName || !password || !cnic) {
      return errorResponse(res, 'Missing required registration fields', 400);
    }

    const tokenPayload = verifyTempToken(tempToken);
    if (!tokenPayload || tokenPayload.purpose !== 'REGISTRATION') {
      return errorResponse(res, 'Invalid or expired verification token', 401);
    }

    const identifier = tokenPayload.identifier;
    const identifierIsEmail = identifier.includes('@');
    const finalPhone = phone?.trim() || (!identifierIsEmail ? identifier : '');
    const finalEmail = identifierIsEmail ? identifier : undefined;

    if (!finalPhone) {
      return errorResponse(res, 'Phone number is required for worker registration', 400);
    }

    const existingUser = findUserByIdentifier(finalPhone) || (finalEmail ? findUserByIdentifier(finalEmail) : undefined);
    if (existingUser) {
      if (existingUser.role === USER_ROLES_OBJ.WORKER) {
        return successResponse(res, buildLocalAuthPayload(existingUser), 'Registration successful');
      }
      return errorResponse(res, 'An account already exists for this identifier', 409);
    }

    const newUser: DevUser = {
      id: `worker-${users.length + 1}-user`,
      phone: finalPhone,
      email: finalEmail,
      role: 'WORKER',
      isVerified: true,
      isActive: true,
      password,
    };
    users.push(newUser);

    const newWorker: DevWorker = {
      _id: `worker-${workers.length + 1}`,
      user: newUser,
      firstName,
      lastName,
      cnic,
      cnicVerified: false,
      skills: (skills ?? []).map((skill) => ({ ...skill, isVerified: false })),
      rating: { average: 0, count: 0 },
      trustScore: 50,
      totalJobsCompleted: 0,
      status: 'PENDING_VERIFICATION',
      createdAt: new Date().toISOString(),
    };
    workers.push(newWorker);

    return successResponse(res, buildLocalAuthPayload(newUser), 'Registration successful');
  });

  router.post('/api/auth/forgot-password', (req: Request, res: Response) => {
    const { phone, email } = req.body as { phone?: string; email?: string };
    const identifier = normalizeIdentifier(phone, email);

    if (!identifier || !findUserByIdentifier(identifier)) {
      return errorResponse(res, 'No account found for this identifier', 404);
    }

    localOtpStore.set(identifier, {
      code: issueOtpCode(),
      identifier,
      purpose: 'PASSWORD_RESET',
      expiresAt: Date.now() + 5 * 60 * 1000,
    });

    logger.info('Local dev password reset OTP issued', { identifier, code: '123456' });

    return successResponse(res, { otpId: `otp-reset-${Date.now()}` }, 'OTP sent successfully');
  });

  router.post('/api/auth/reset-password', (req: Request, res: Response) => {
    const { tempToken, password, newPassword } = req.body as {
      tempToken?: string;
      password?: string;
      newPassword?: string;
    };

    const tokenPayload = tempToken ? verifyTempToken(tempToken) : null;
    if (!tokenPayload || tokenPayload.purpose !== 'PASSWORD_RESET') {
      return errorResponse(res, 'Invalid or expired verification token', 401);
    }

    const user = findUserByIdentifier(tokenPayload.identifier);
    if (!user) {
      return errorResponse(res, 'User not found', 404);
    }

    user.password = (newPassword || password || '').trim();
    if (!user.password) {
      return errorResponse(res, 'New password is required', 400);
    }

    return successResponse(res, null, 'Password reset successful');
  });

  return router;
};

export const createLocalDevProtectedRouter = (): ReturnType<typeof Router> => {
  const router = Router();

  router.get('/api/users/customer/profile', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    return successResponse(res, sanitizeCustomer(customer), 'Customer profile retrieved');
  });

  router.patch('/api/users/customer/profile', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    const { firstName, lastName, email, phone, profileImage } = req.body as {
      firstName?: string;
      lastName?: string;
      email?: string;
      phone?: string;
      profileImage?: string;
      preferredLanguage?: string;
    };

    if (firstName) customer.firstName = firstName;
    if (lastName) customer.lastName = lastName;
    if (email) customer.user.email = email.toLowerCase();
    if (phone) customer.user.phone = phone;
    if (profileImage) customer.profileImage = profileImage;

    return successResponse(res, sanitizeCustomer(customer), 'Customer profile updated');
  });

  router.get('/api/users/customer/addresses', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    return successResponse(res, customer.addresses, 'Customer addresses retrieved');
  });

  router.post('/api/users/customer/addresses', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    const {
      label,
      address,
      city,
      coordinates,
      isDefault,
    } = req.body as {
      label?: string;
      address?: string;
      city?: string;
      coordinates?: { lat?: number; lng?: number };
      isDefault?: boolean;
    };

    if (!label?.trim() || !address?.trim() || !city?.trim()) {
      return errorResponse(res, 'label, address, and city are required', 400);
    }

    const newAddress = {
      _id: `address-${customer._id}-${customer.addresses.length + 1}`,
      label: label.trim(),
      address: address.trim(),
      city: city.trim(),
      ...(coordinates?.lat != null && coordinates.lng != null
          ? {
              coordinates: {
                lat: Number(coordinates.lat),
                lng: Number(coordinates.lng),
              },
            }
          : {}),
      isDefault: Boolean(isDefault),
    };

    if (newAddress.isDefault) {
      customer.addresses = customer.addresses.map((item) => ({
        ...item,
        isDefault: false,
      }));
    }

    customer.addresses.push(newAddress);

    return successResponse(res, newAddress, 'Customer address added');
  });

  router.get('/api/users/worker/profile', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    return successResponse(res, buildWorkerProfileResponse(worker), 'Worker profile retrieved');
  });

  router.patch('/api/users/worker/profile', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const {
      firstName,
      lastName,
      email,
      phone,
      skills,
      bankDetails,
      serviceRadius,
    } = req.body as {
      firstName?: string;
      lastName?: string;
      email?: string;
      phone?: string;
      skills?: DevWorker['skills'];
      bankDetails?: unknown;
      serviceRadius?: number;
    };

    if (firstName) worker.firstName = firstName;
    if (lastName) worker.lastName = lastName;
    if (phone) worker.user.phone = phone;
    if (email) worker.user.email = email.toLowerCase();
    if (Array.isArray(skills)) worker.skills = skills;
    void bankDetails;
    void serviceRadius;

    return successResponse(res, buildWorkerProfileResponse(worker), 'Worker profile updated');
  });

  router.post('/api/users/worker/location', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const { lat, lng } = req.body as { lat?: number; lng?: number };
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      return errorResponse(res, 'lat and lng are required', 400);
    }

    return successResponse(res, { lat, lng, workerId: worker._id }, 'Location updated');
  });

  router.post('/api/users/worker/availability', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const { isAvailable } = req.body as { isAvailable?: boolean };
    if (typeof isAvailable !== 'boolean') {
      return errorResponse(res, 'isAvailable must be a boolean', 400);
    }

    if (worker.status !== 'SUSPENDED' && worker.status !== 'REJECTED') {
      worker.status = isAvailable ? 'ACTIVE' : 'PENDING_VERIFICATION';
    }

    return successResponse(res, { isAvailable }, 'Availability updated');
  });

  router.get('/api/users/worker/earnings', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const relatedBookings = bookings.filter((booking) => booking.worker?._id === worker._id);
    const totalEarnings = relatedBookings.reduce(
      (sum, booking) => sum + (booking.pricing.finalPrice ?? booking.pricing.estimatedPrice ?? 0),
      0,
    );

    return successResponse(
      res,
      {
        totalEarnings,
        completedJobs: worker.totalJobsCompleted,
        breakdown: relatedBookings.map((booking) => ({
          bookingId: booking._id,
          bookingNumber: booking.bookingNumber,
          amount: booking.pricing.finalPrice ?? booking.pricing.estimatedPrice ?? 0,
          status: booking.status,
          date: booking.updatedAt,
        })),
      },
      'Worker earnings retrieved',
    );
  });

  router.post('/api/matching/find-workers', (req: Request, res: Response) => {
    const {
      serviceCategory,
      lat,
      lng,
      scheduledDateTime,
      isUrgent,
    } = req.body as {
      serviceCategory?: string;
      lat?: number;
      lng?: number;
      scheduledDateTime?: string;
      isUrgent?: boolean;
    };

    if (!serviceCategory?.trim()) {
      return errorResponse(res, 'serviceCategory is required', 400);
    }

    const matchingWorkers = buildMatchedWorkers(serviceCategory, lat, lng);
    const hourlyRates = matchingWorkers.map((worker) => worker.hourlyRate);

    void scheduledDateTime;

    return successResponse(
      res,
      {
        workers: matchingWorkers,
        totalAvailable: matchingWorkers.length,
        priceEstimate: buildPriceEstimate(hourlyRates, isUrgent),
      },
      'Matching workers retrieved',
    );
  });

  router.post('/api/bookings', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    const {
      serviceCategory,
      problemDescription,
      address,
      scheduledDateTime,
      isUrgent,
      paymentMethod,
      images,
    } = req.body as {
      serviceCategory?: string;
      problemDescription?: string;
      address?: {
        full?: string;
        city?: string;
        coordinates?: { lat?: number; lng?: number };
      };
      scheduledDateTime?: string;
      isUrgent?: boolean;
      paymentMethod?: string;
      images?: string[];
    };

    if (!serviceCategory?.trim() || !problemDescription?.trim() || !address?.full?.trim() || !address.city?.trim()) {
      return errorResponse(res, 'serviceCategory, problemDescription, and address are required', 400);
    }

    const matchedWorkers = buildMatchedWorkers(
      serviceCategory,
      address.coordinates?.lat,
      address.coordinates?.lng,
    );
    const priceEstimate = buildPriceEstimate(
      matchedWorkers.map((worker) => worker.hourlyRate),
      isUrgent,
    );
    const nowIso = new Date().toISOString();
    const bookingId = `booking-${bookings.length + 1}`;
    const bookingNumber = `HG-${1000 + bookings.length + 1}`;
    const normalizedCategory = normalizeServiceCategory(serviceCategory);

    const newBooking: DevBooking = {
      _id: bookingId,
      bookingNumber,
      customer: {
        _id: customer._id,
        firstName: customer.firstName,
        lastName: customer.lastName,
        phone: customer.user.phone,
      },
      serviceCategory: normalizedCategory,
      problemDescription: problemDescription.trim(),
      address: {
        full: address.full.trim(),
        city: address.city.trim(),
      },
      scheduledDateTime: scheduledDateTime ?? nowIso,
      status: 'PENDING',
      pricing: {
        estimatedPrice: priceEstimate.estimatedPrice.average,
        platformFee: priceEstimate.breakdown.platformFee,
      },
      timeline: [
        {
          status: 'PENDING',
          timestamp: nowIso,
          note: 'Booking created in local mode',
        },
      ],
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    bookings.unshift(newBooking);
    customer.totalBookings += 1;
    void paymentMethod;
    void images;

    return successResponse(
      res,
      {
        booking: {
          ...newBooking,
          address: {
            ...newBooking.address,
            ...(address.coordinates?.lat != null && address.coordinates.lng != null
                ? {
                    coordinates: {
                      lat: Number(address.coordinates.lat),
                      lng: Number(address.coordinates.lng),
                    },
                  }
                : {}),
          },
          isUrgent: Boolean(isUrgent),
          payment: {
            method: paymentMethod ?? 'CASH',
            status: 'PENDING',
          },
          images: {
            before: images ?? [],
            after: [],
          },
          customer: {
            _id: customer._id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            profileImage: customer.profileImage,
            addresses: customer.addresses,
            preferredLanguage: 'en',
            totalBookings: customer.totalBookings,
          },
        },
        matchedWorkers,
      },
      'Booking created successfully',
    );
  });

  router.post('/api/bookings/:bookingId/select-worker', (req: Request, res: Response) => {
    const booking = bookings.find((item) => item._id === req.params.bookingId);
    if (!booking) {
      return notFoundResponse(res, 'Booking not found');
    }

    const { workerId } = req.body as { workerId?: string };
    if (!workerId) {
      return errorResponse(res, 'workerId is required', 400);
    }

    const worker = workers.find((item) => item._id === workerId);
    if (!worker) {
      return notFoundResponse(res, 'Worker not found');
    }

    booking.worker = {
      _id: worker._id,
      firstName: worker.firstName,
      lastName: worker.lastName,
      phone: worker.user.phone,
    };
    booking.status = 'ACCEPTED';
    booking.updatedAt = new Date().toISOString();
    booking.timeline.push({
      status: 'ACCEPTED',
      timestamp: booking.updatedAt,
      note: 'Worker assigned in local mode',
    });

    return successResponse(
      res,
      {
        ...booking,
        worker: {
          _id: worker._id,
          firstName: worker.firstName,
          lastName: worker.lastName,
          phone: worker.user.phone,
          rating: worker.rating.average,
          totalJobs: worker.totalJobsCompleted,
        },
      },
      'Worker selected successfully',
    );
  });

  router.get('/api/bookings/:bookingId', (req: Request, res: Response) => {
    const booking = bookings.find((item) => item._id === req.params.bookingId);
    if (!booking) {
      return notFoundResponse(res, 'Booking not found');
    }

    const customer = customers.find((item) => item._id === booking.customer._id);
    const worker = booking.worker
      ? workers.find((item) => item._id === booking.worker!._id)
      : null;

    return successResponse(
      res,
      {
        ...booking,
        address: {
          ...booking.address,
          coordinates:
              booking.address.city.toLowerCase() === 'karachi'
                  ? { lat: 24.8607, lng: 67.0011 }
                  : { lat: 31.5204, lng: 74.3587 },
        },
        customer: customer
            ? {
                _id: customer._id,
                firstName: customer.firstName,
                lastName: customer.lastName,
                profileImage: customer.profileImage,
                addresses: customer.addresses,
                preferredLanguage: 'en',
                totalBookings: customer.totalBookings,
              }
            : booking.customer,
        worker: worker
            ? {
                _id: worker._id,
                firstName: worker.firstName,
                lastName: worker.lastName,
                phone: worker.user.phone,
                rating: worker.rating.average,
                totalJobs: worker.totalJobsCompleted,
              }
            : booking.worker,
        estimatedDuration: worker ? 18 : 30,
      },
      'Booking details retrieved',
    );
  });

  router.get('/api/bookings/:bookingId/location', (req: Request, res: Response) => {
    const booking = bookings.find((item) => item._id === req.params.bookingId);
    if (!booking) {
      return notFoundResponse(res, 'Booking not found');
    }

    const city = booking.address.city.toLowerCase();
    const baseLocation =
      city === 'karachi'
        ? { lat: 24.8607, lng: 67.0011 }
        : { lat: 31.5204, lng: 74.3587 };

    return successResponse(
      res,
      {
        location: {
          coordinates: baseLocation,
          etaMinutes: booking.status === 'IN_PROGRESS' ? 8 : booking.status === 'ACCEPTED' ? 18 : 0,
        },
      },
      'Worker location retrieved',
    );
  });

  router.post('/api/bookings/:bookingId/cancel', (req: Request, res: Response) => {
    const booking = bookings.find((item) => item._id === req.params.bookingId);
    if (!booking) {
      return notFoundResponse(res, 'Booking not found');
    }

    const { reason } = req.body as { reason?: string };
    booking.status = 'CANCELLED';
    booking.updatedAt = new Date().toISOString();
    booking.timeline.push({
      status: 'CANCELLED',
      timestamp: booking.updatedAt,
      note: reason?.trim() || 'Cancelled by customer in local mode',
    });

    return successResponse(res, null, 'Booking cancelled successfully');
  });

  router.get('/api/bookings/customer', (req: Request, res: Response) => {
    const customer = getAuthenticatedCustomer(req);
    if (!customer) {
      return errorResponse(res, 'Customer profile not found', 404);
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const status = String(req.query.status || '');

    let items = bookings
      .filter((booking) => booking.customer._id === customer._id)
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));

    if (status && status.toLowerCase() !== 'all') {
      items = items.filter((booking) => booking.status === status.toUpperCase());
    }

    return successResponse(
      res,
      {
        bookings: paginate(items, page, limit),
        pagination: {
          page,
          limit,
          total: items.length,
          totalPages: Math.max(1, Math.ceil(items.length / limit)),
        },
      },
      'Customer bookings retrieved',
    );
  });

  router.get('/api/notifications', (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const unreadOnly = String(req.query.unreadOnly || 'false') === 'true';

    const items = [
      {
        _id: 'notification-1',
        type: 'BOOKING',
        title: 'Worker assigned',
        body: 'Your booking HG-1001 has been assigned.',
        data: { bookingId: 'booking-1' },
        isRead: false,
        createdAt: hoursAgo(2),
      },
      {
        _id: 'notification-2',
        type: 'SYSTEM',
        title: 'Welcome to Handy Go',
        body: 'Your local demo environment is ready.',
        data: {},
        isRead: true,
        readAt: hoursAgo(4),
        createdAt: hoursAgo(5),
      },
    ].filter((item) => (unreadOnly ? !item.isRead : true));

    return successResponse(
      res,
      {
        notifications: paginate(items, page, limit),
        pagination: {
          page,
          limit,
          total: items.length,
          totalPages: Math.max(1, Math.ceil(items.length / limit)),
        },
      },
      'Notifications retrieved',
    );
  });

  router.get('/api/notifications/unread-count', (_req: Request, res: Response) =>
    successResponse(res, { count: 1 }, 'Unread count retrieved'),
  );

  router.post('/api/notifications/read-all', (_req: Request, res: Response) =>
    successResponse(res, null, 'All notifications marked as read'),
  );

  router.post('/api/notifications/:notificationId/read', (req: Request, res: Response) =>
    successResponse(res, { notificationId: req.params.notificationId }, 'Notification marked as read'),
  );

  router.get('/api/bookings/worker/available', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const workerCategories = new Set(worker.skills.map((skill) => skill.category));
    const items = bookings
      .filter((booking) => booking.status === 'PENDING')
      .filter((booking) => !booking.worker)
      .filter((booking) => workerCategories.has(booking.serviceCategory))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));

    return successResponse(res, items, 'Available bookings retrieved');
  });

  router.get('/api/bookings/worker', (req: Request, res: Response) => {
    const worker = getAuthenticatedWorker(req);
    if (!worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const status = String(req.query.status || '');

    let items = bookings
      .filter((booking) => booking.worker?._id === worker._id)
      .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));

    if (status) {
      items = items.filter((booking) => booking.status === status);
    }

    return successResponse(
      res,
      {
        bookings: paginate(items, page, limit),
        total: items.length,
        page,
        limit,
      },
      'Worker bookings retrieved',
    );
  });

  router.get('/api/users/admin/customers', (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const search = String(req.query.search || '');
    const status = String(req.query.status || '');

    let items = filterBySearch(customers, search, (customer) =>
      `${customer.firstName} ${customer.lastName} ${customer.user.phone} ${customer.user.email ?? ''}`,
    );

    if (status === 'active') items = items.filter((customer) => customer.user.isActive);
    if (status === 'inactive') items = items.filter((customer) => !customer.user.isActive);

    return paginatedResponse(res, paginate(items, page, limit), page, limit, items.length, 'Customers retrieved');
  });

  router.get('/api/users/admin/workers', (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const search = String(req.query.search || '');
    const verificationStatus = String(req.query.verificationStatus || '');

    let items = filterBySearch(workers, search, (worker) =>
      `${worker.firstName} ${worker.lastName} ${worker.cnic} ${worker.user.phone}`,
    );

    if (verificationStatus) {
      items = items.filter((worker) => worker.status === verificationStatus);
    }

    return paginatedResponse(res, paginate(items, page, limit), page, limit, items.length, 'Workers retrieved');
  });

  router.get('/api/users/admin/workers/pending', (_req: Request, res: Response) =>
    successResponse(
      res,
      workers.filter((worker) => worker.status === 'PENDING_VERIFICATION'),
      'Pending workers retrieved',
    ),
  );

  router.put('/api/users/admin/workers/:workerId/verify', (req: Request, res: Response) => {
    const worker = workers.find((item) => item._id === req.params.workerId);
    if (!worker) return notFoundResponse(res, 'Worker not found');

    const { status } = req.body as { status?: WorkerStatus };
    if (!status) return errorResponse(res, 'Status is required', 400);

    worker.status = status;
    worker.cnicVerified = status === 'ACTIVE';
    worker.skills = worker.skills.map((skill) => ({ ...skill, isVerified: status === 'ACTIVE' }));

    return successResponse(res, worker, `Worker ${status === 'ACTIVE' ? 'approved' : 'updated'} successfully`);
  });

  router.put('/api/users/admin/users/:userId/status', (req: Request, res: Response) => {
    const user = users.find((item) => item.id === req.params.userId);
    if (!user) return notFoundResponse(res, 'User not found');

    const { isActive } = req.body as { isActive?: boolean };
    if (typeof isActive !== 'boolean') return errorResponse(res, 'isActive must be a boolean', 400);

    user.isActive = isActive;
    const worker = workers.find((item) => item.user.id === user.id);
    if (worker) {
      worker.status = isActive ? (worker.cnicVerified ? 'ACTIVE' : 'PENDING_VERIFICATION') : 'SUSPENDED';
    }

    return successResponse(res, { isActive }, `User ${isActive ? 'activated' : 'deactivated'} successfully`);
  });

  router.get('/api/bookings/admin', (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const status = String(req.query.status || '');
    const serviceCategory = String(req.query.serviceCategory || '');

    let items = [...bookings].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    if (status) items = items.filter((booking) => booking.status === status);
    if (serviceCategory) items = items.filter((booking) => booking.serviceCategory === serviceCategory);

    return paginatedResponse(res, paginate(items, page, limit), page, limit, items.length, 'Bookings retrieved');
  });

  router.get('/api/bookings/admin/stats', (req: Request, res: Response) => {
    const period = (String(req.query.period || 'week') as 'day' | 'week' | 'month');
    return successResponse(res, computeBookingStats(period), 'Statistics retrieved');
  });

  router.put('/api/bookings/admin/:bookingId', (req: Request, res: Response) => {
    const booking = bookings.find((item) => item._id === req.params.bookingId);
    if (!booking) return notFoundResponse(res, 'Booking not found');

    const { status, notes } = req.body as { status?: BookingStatus; notes?: string };
    if (status) {
      booking.status = status;
      booking.updatedAt = new Date().toISOString();
      booking.timeline.push({
        status,
        timestamp: booking.updatedAt,
        note: notes || `Status updated to ${status} by local admin`,
      });
    }

    return successResponse(res, booking, 'Booking updated successfully');
  });

  router.get('/api/sos/admin/active', (req: Request, res: Response) => {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const items = [...sosAlerts].sort((a, b) => b.createdAt.localeCompare(a.createdAt));

    return paginatedResponse(res, paginate(items, page, limit), page, limit, items.length, 'SOS alerts retrieved');
  });

  router.post('/api/sos/admin/:sosId/assign', (req: Request, res: Response) => {
    const sos = sosAlerts.find((item) => item._id === req.params.sosId);
    if (!sos) return notFoundResponse(res, 'SOS not found');
    return successResponse(res, sos, 'SOS assigned to you');
  });

  router.post('/api/sos/admin/:sosId/resolve', (req: Request, res: Response) => {
    const sos = sosAlerts.find((item) => item._id === req.params.sosId);
    if (!sos) return notFoundResponse(res, 'SOS not found');

    sos.status = 'RESOLVED';
    return successResponse(res, sos, 'SOS resolved successfully');
  });

  router.post('/api/sos/admin/:sosId/escalate', (req: Request, res: Response) => {
    const sos = sosAlerts.find((item) => item._id === req.params.sosId);
    if (!sos) return notFoundResponse(res, 'SOS not found');

    sos.status = 'ESCALATED';
    return successResponse(res, sos, 'SOS escalated successfully');
  });

  router.get('/api/local-dev/settings', (_req: Request, res: Response) =>
    successResponse(res, localSettings, 'Local settings retrieved'),
  );

  return router;
};
