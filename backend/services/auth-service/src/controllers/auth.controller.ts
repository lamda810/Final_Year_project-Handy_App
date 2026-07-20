import { Request, Response, NextFunction } from 'express';
import {
  User,
  Customer,
  Worker,
  TokenBlacklist,
  asyncHandler,
  successResponse,
  createdResponse,
  errorResponse,
  unauthorizedResponse,
  conflictResponse,
  validationErrorResponse,
  normalizePhoneNumber,
  normalizeCNIC,
  HTTP_STATUS,
  ERROR_CODES,
  OTPPurpose,
  logger,
} from '@handy-go/shared';
import {
  sendOTPSchema,
  verifyOTPSchema,
  registerCustomerSchema,
  registerWorkerSchema,
  loginSchema,
  refreshTokenSchema,
  resetPasswordSchema,
  validate,
} from '../validators/auth.validators.js';
import { createAndSendOTP, verifyOTPCode } from '../services/otp.service.js';
import {
  generateTokenPair,
  generateTempToken,
  verifyTempToken,
  verifyRefreshToken,
  verifyAccessToken,
  generateAccessToken,
} from '../services/token.service.js';

/**
 * Send OTP
 * POST /api/auth/send-otp
 */
export const sendOTP = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{ phone: string; purpose: OTPPurpose }>(sendOTPSchema, req.body);

  if (error) {
    const errors = error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }));
    return validationErrorResponse(res, errors);
  }

  const phone = normalizePhoneNumber(value.phone);
  const { purpose } = value;

  // Check if user exists for LOGIN/PASSWORD_RESET
  if (purpose === 'LOGIN' || purpose === 'PASSWORD_RESET') {
    const existingUser = await User.findOne({ phone });
    if (!existingUser) {
      return errorResponse(res, 'No account found with this phone number', HTTP_STATUS.NOT_FOUND);
    }
  }

  // Check if user already exists for REGISTRATION
  if (purpose === 'REGISTRATION') {
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return conflictResponse(res, 'An account with this phone number already exists');
    }
  }

  // Create and send OTP
  const result = await createAndSendOTP(phone, purpose);

  if (!result.success) {
    return errorResponse(res, result.error || 'Failed to send OTP', HTTP_STATUS.INTERNAL_SERVER_ERROR);
  }

  return successResponse(res, { otpId: result.otpId }, 'OTP sent successfully');
});

/**
 * Verify OTP
 * POST /api/auth/verify-otp
 */
export const verifyOTP = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{ phone: string; code: string; purpose: OTPPurpose }>(
    verifyOTPSchema,
    req.body
  );

  if (error) {
    const errors = error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }));
    return validationErrorResponse(res, errors);
  }

  const phone = normalizePhoneNumber(value.phone);
  const { code, purpose } = value;

  // Verify OTP
  const result = await verifyOTPCode(phone, code, purpose);

  if (!result.success) {
    return errorResponse(res, result.error || 'OTP verification failed', HTTP_STATUS.BAD_REQUEST);
  }

  // Check if user exists
  const existingUser = await User.findOne({ phone });
  const isNewUser = !existingUser;

  // Generate temp token for registration/password reset flow
  const tempToken = generateTempToken(phone, purpose);

  return successResponse(
    res,
    { isNewUser, tempToken },
    'OTP verified successfully'
  );
});

/**
 * Register Customer
 * POST /api/auth/register/customer
 */
export const registerCustomer = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{
    tempToken: string;
    firstName: string;
    lastName: string;
    email?: string;
    password: string;
  }>(registerCustomerSchema, req.body);

  if (error) {
    const errors = error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }));
    return validationErrorResponse(res, errors);
  }

  // Verify temp token
  let tokenPayload;
  try {
    tokenPayload = verifyTempToken(value.tempToken);
  } catch {
    return unauthorizedResponse(res, 'Invalid or expired verification token');
  }

  if (tokenPayload.purpose !== 'REGISTRATION') {
    return errorResponse(res, 'Invalid token purpose', HTTP_STATUS.BAD_REQUEST);
  }

  const phone = tokenPayload.phone;

  // Check if user already exists
  const existingUser = await User.findOne({ phone });
  if (existingUser) {
    return conflictResponse(res, 'An account with this phone number already exists');
  }

  // Check email uniqueness if provided
  if (value.email) {
    const emailExists = await User.findOne({ email: value.email.toLowerCase() });
    if (emailExists) {
      return conflictResponse(res, 'An account with this email already exists');
    }
  }

  // Create user
  const user = await User.create({
    phone,
    email: value.email?.toLowerCase(),
    password: value.password,
    role: 'CUSTOMER',
    isVerified: true, // Phone verified via OTP
  });

  // Create customer profile
  const customer = await Customer.create({
    user: user._id,
    firstName: value.firstName,
    lastName: value.lastName,
  });

  // Generate tokens
  const tokens = generateTokenPair(user._id.toString(), user.role);

  logger.info(`New customer registered: ${phone}`);

  return createdResponse(
    res,
    {
      user: {
        id: user._id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
      },
      profile: {
        firstName: customer.firstName,
        lastName: customer.lastName,
        fullName: customer.fullName,
      },
      ...tokens,
    },
    'Registration successful'
  );
});

/**
 * Register Worker
 * POST /api/auth/register/worker
 */
export const registerWorker = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{
    tempToken: string;
    firstName: string;
    lastName: string;
    email?: string;
    password: string;
    cnic: string;
    skills: Array<{ category: string; experience: number; hourlyRate: number }>;
  }>(registerWorkerSchema, req.body);

  if (error) {
    const errors = error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }));
    return validationErrorResponse(res, errors);
  }

  // Verify temp token
  let tokenPayload;
  try {
    tokenPayload = verifyTempToken(value.tempToken);
  } catch {
    return unauthorizedResponse(res, 'Invalid or expired verification token');
  }

  if (tokenPayload.purpose !== 'REGISTRATION') {
    return errorResponse(res, 'Invalid token purpose', HTTP_STATUS.BAD_REQUEST);
  }

  const phone = tokenPayload.phone;
  const cnic = normalizeCNIC(value.cnic);

  // Check if user already exists
  const existingUser = await User.findOne({ phone });
  if (existingUser) {
    return conflictResponse(res, 'An account with this phone number already exists');
  }

  // Check CNIC uniqueness
  const cnicExists = await Worker.findByCNIC(cnic);
  if (cnicExists) {
    return conflictResponse(res, 'An account with this CNIC already exists');
  }

  // Check email uniqueness if provided
  if (value.email) {
    const emailExists = await User.findOne({ email: value.email.toLowerCase() });
    if (emailExists) {
      return conflictResponse(res, 'An account with this email already exists');
    }
  }

  // Create user
  const user = await User.create({
    phone,
    email: value.email?.toLowerCase(),
    password: value.password,
    role: 'WORKER',
    isVerified: true, // Phone verified via OTP
  });

  // Create worker profile
  const worker = await Worker.create({
    user: user._id,
    firstName: value.firstName,
    lastName: value.lastName,
    cnic,
    skills: value.skills.map(skill => ({
      ...skill,
      isVerified: false,
    })),
    status: 'PENDING_VERIFICATION',
  });

  // Generate tokens
  const tokens = generateTokenPair(user._id.toString(), user.role);

  logger.info(`New worker registered: ${phone}, CNIC: ${cnic}`);

  return createdResponse(
    res,
    {
      user: {
        id: user._id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
      },
      profile: {
        firstName: worker.firstName,
        lastName: worker.lastName,
        fullName: worker.fullName,
        cnic: worker.cnic,
        status: worker.status,
        skills: worker.skills,
      },
      ...tokens,
    },
    'Registration successful. Your account is pending verification.'
  );
});

/**
 * Login
 * POST /api/auth/login
 */
export const login = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{ phone?: string; email?: string; password: string }>(
    loginSchema,
    req.body
  );

  if (error) {
    const errors = error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }));
    return validationErrorResponse(res, errors);
  }

  // Find user with password, by phone or email
  const user = value.phone
    ? await User.findByPhone(normalizePhoneNumber(value.phone))
    : await User.findOne({ email: value.email!.toLowerCase() }).select('+password');

  if (!user) {
    return unauthorizedResponse(res, 'Invalid phone number or password');
  }

  // Check if user is active
  if (!user.isActive) {
    return errorResponse(res, 'Your account has been deactivated', HTTP_STATUS.FORBIDDEN);
  }

  // Compare passwords
  const isPasswordValid = await user.comparePassword(value.password);

  if (!isPasswordValid) {
    return unauthorizedResponse(res, 'Invalid phone number or password');
  }

  // Update last login
  user.lastLogin = new Date();
  await user.save();

  // Get profile based on role
  let profile: any = null;
  if (user.role === 'CUSTOMER') {
    profile = await Customer.findByUserId(user._id);
  } else if (user.role === 'WORKER') {
    profile = await Worker.findByUserId(user._id);

    // Check if worker is active
    if (profile && profile.status === 'SUSPENDED') {
      return errorResponse(res, 'Your worker account has been suspended', HTTP_STATUS.FORBIDDEN);
    }
  }

  // Generate tokens
  const tokens = generateTokenPair(user._id.toString(), user.role);

  logger.info(`User logged in: ${user.phone}`);

  return successResponse(
    res,
    {
      user: {
        id: user._id,
        phone: user.phone,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
      },
      profile: profile
        ? {
            firstName: profile.firstName,
            lastName: profile.lastName,
            fullName: profile.fullName,
            ...(user.role === 'WORKER' && { status: profile.status }),
          }
        : null,
      ...tokens,
    },
    'Login successful'
  );
});

/**
 * Refresh Token
 * POST /api/auth/refresh-token
 */
export const refreshToken = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{ refreshToken: string }>(refreshTokenSchema, req.body);

  if (error) {
    return validationErrorResponse(
      res,
      error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }))
    );
  }

  // Verify refresh token
  let decoded;
  try {
    decoded = verifyRefreshToken(value.refreshToken);
  } catch {
    return unauthorizedResponse(res, 'Invalid or expired refresh token');
  }

  // Check if refresh token has been revoked
  const isRevoked = await TokenBlacklist.isRevoked(value.refreshToken);
  if (isRevoked) {
    return unauthorizedResponse(res, 'Token has been revoked');
  }

  // Get user
  const user = await User.findById(decoded.userId);

  if (!user || !user.isActive) {
    return unauthorizedResponse(res, 'User not found or inactive');
  }

  // Blacklist the old refresh token to prevent reuse
  await TokenBlacklist.revokeToken(
    value.refreshToken,
    user._id.toString(),
    'token_refresh',
    new Date((decoded.exp || 0) * 1000)
  );

  // Generate new tokens
  const tokens = generateTokenPair(user._id.toString(), user.role);

  return successResponse(res, tokens, 'Tokens refreshed successfully');
});

/**
 * Forgot Password - sends OTP
 * POST /api/auth/forgot-password
 */
export const forgotPassword = asyncHandler(async (req: Request, res: Response) => {
  const { phone } = req.body;

  if (!phone) {
    return validationErrorResponse(res, [{ field: 'phone', message: 'Phone number is required' }]);
  }

  const normalizedPhone = normalizePhoneNumber(phone);

  // Check if user exists
  const user = await User.findOne({ phone: normalizedPhone });
  if (!user) {
    // Don't reveal if user exists or not
    return successResponse(res, null, 'If an account exists, an OTP will be sent');
  }

  // Send OTP
  const result = await createAndSendOTP(normalizedPhone, 'PASSWORD_RESET');

  if (!result.success) {
    return errorResponse(res, 'Failed to send OTP', HTTP_STATUS.INTERNAL_SERVER_ERROR);
  }

  return successResponse(res, { otpId: result.otpId }, 'OTP sent for password reset');
});

/**
 * Reset Password
 * POST /api/auth/reset-password
 */
export const resetPassword = asyncHandler(async (req: Request, res: Response) => {
  // Validate input
  const { value, error } = validate<{ tempToken: string; newPassword: string }>(
    resetPasswordSchema,
    req.body
  );

  if (error) {
    return validationErrorResponse(
      res,
      error.details.map(d => ({ field: d.path[0]?.toString(), message: d.message }))
    );
  }

  // Verify temp token
  let tokenPayload;
  try {
    tokenPayload = verifyTempToken(value.tempToken);
  } catch {
    return unauthorizedResponse(res, 'Invalid or expired verification token');
  }

  if (tokenPayload.purpose !== 'PASSWORD_RESET') {
    return errorResponse(res, 'Invalid token purpose', HTTP_STATUS.BAD_REQUEST);
  }

  // Find user
  const user = await User.findOne({ phone: tokenPayload.phone }).select('+password');

  if (!user) {
    return errorResponse(res, 'User not found', HTTP_STATUS.NOT_FOUND);
  }

  // Check if new password is the same as old password
  const isSamePassword = await user.comparePassword(value.newPassword);
  if (isSamePassword) {
    return errorResponse(
      res,
      'New password cannot be the same as your current password',
      HTTP_STATUS.BAD_REQUEST
    );
  }

  // Update password
  user.password = value.newPassword;
  await user.save();

  // Revoke all existing sessions for security
  await TokenBlacklist.revokeAllForUser(user._id.toString(), 'password_reset');

  logger.info(`Password reset for user: ${user.phone}`);

  return successResponse(res, null, 'Password reset successful');
});

/**
 * Logout - revoke current tokens
 * POST /api/auth/logout
 */
export const logout = asyncHandler(async (req: Request, res: Response) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return successResponse(res, null, 'Logged out successfully');
  }

  const accessToken = authHeader.split(' ')[1];

  if (accessToken) {
    // Revoke the access token
    try {
      const decoded = verifyAccessToken(accessToken) as any;
      await TokenBlacklist.revokeToken(
        accessToken,
        decoded.userId,
        'logout',
        new Date((decoded.exp || 0) * 1000)
      );
    } catch {
      // Token may be invalid/expired already - still log out successfully
    }
  }

  // Also revoke refresh token if provided in body
  const { refreshToken: rt } = req.body || {};
  if (rt) {
    try {
      const decoded = verifyRefreshToken(rt);
      await TokenBlacklist.revokeToken(
        rt,
        decoded.userId,
        'logout',
        new Date((decoded.exp || 0) * 1000)
      );
    } catch {
      // Ignore invalid refresh tokens during logout
    }
  }

  return successResponse(res, null, 'Logged out successfully');
});
