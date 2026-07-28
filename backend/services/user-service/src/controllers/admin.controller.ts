import { Request, Response } from 'express';
import {
  Customer,
  Worker,
  User,
  Notification,
  Withdrawal,
  asyncHandler,
  successResponse,
  createdResponse,
  errorResponse,
  notFoundResponse,
  conflictResponse,
  paginatedResponse,
  normalizePhoneNumber,
  normalizeCNIC,
  HTTP_STATUS,
  DEFAULTS,
} from '@handy-go/shared';

/**
 * Get all customers (paginated)
 * GET /api/users/admin/customers
 */
export const getCustomers = asyncHandler(async (req: Request, res: Response) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = Math.min(parseInt(req.query.limit as string) || DEFAULTS.PAGINATION_LIMIT, DEFAULTS.MAX_PAGINATION_LIMIT);
  const search = req.query.search as string;
  const status = req.query.status as string;

  const skip = (page - 1) * limit;

  // Build filter
  const filter: any = {};

  if (search) {
    filter.$or = [
      { firstName: { $regex: search, $options: 'i' } },
      { lastName: { $regex: search, $options: 'i' } },
    ];
  }

  // Get total count
  const total = await Customer.countDocuments(filter);

  // Get customers
  const customers = await Customer.find(filter)
    .populate('user', 'phone email isVerified isActive createdAt')
    .skip(skip)
    .limit(limit)
    .sort({ createdAt: -1 });

  // Filter by user status if provided
  let filteredCustomers = customers;
  if (status === 'active') {
    filteredCustomers = customers.filter((c: any) => c.user?.isActive);
  } else if (status === 'inactive') {
    filteredCustomers = customers.filter((c: any) => !c.user?.isActive);
  }

  return paginatedResponse(res, filteredCustomers, page, limit, total, 'Customers retrieved');
});

/**
 * Create a worker directly (admin-added, bypasses phone-OTP registration)
 * POST /api/users/admin/workers
 */
export const createWorker = asyncHandler(async (req: Request, res: Response) => {
  const { firstName, lastName, email, password, skills, status } = req.body;

  const phone = normalizePhoneNumber(req.body.phone);
  const cnic = normalizeCNIC(req.body.cnic);

  const existingUser = await User.findOne({ phone });
  if (existingUser) {
    return conflictResponse(res, 'An account with this phone number already exists');
  }

  const cnicExists = await Worker.findByCNIC(cnic);
  if (cnicExists) {
    return conflictResponse(res, 'An account with this CNIC already exists');
  }

  if (email) {
    const emailExists = await User.findOne({ email: email.toLowerCase() });
    if (emailExists) {
      return conflictResponse(res, 'An account with this email already exists');
    }
  }

  const user = await User.create({
    phone,
    email: email?.toLowerCase(),
    password,
    role: 'WORKER',
    isVerified: true,
  });

  const workerStatus = status || 'PENDING_VERIFICATION';
  const worker = await Worker.create({
    user: user._id,
    firstName,
    lastName,
    cnic,
    skills: skills.map((skill: any) => ({
      ...skill,
      isVerified: workerStatus === 'ACTIVE',
    })),
    cnicVerified: workerStatus === 'ACTIVE',
    status: workerStatus,
  });

  return createdResponse(res, worker, 'Worker created successfully');
});

/**
 * Get all workers (paginated)
 * GET /api/users/admin/workers
 */
export const getWorkers = asyncHandler(async (req: Request, res: Response) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = Math.min(parseInt(req.query.limit as string) || DEFAULTS.PAGINATION_LIMIT, DEFAULTS.MAX_PAGINATION_LIMIT);
  const search = req.query.search as string;
  const status = req.query.status as string;
  const verificationStatus = req.query.verificationStatus as string;

  const skip = (page - 1) * limit;

  // Build filter
  const filter: any = {};

  if (search) {
    filter.$or = [
      { firstName: { $regex: search, $options: 'i' } },
      { lastName: { $regex: search, $options: 'i' } },
      { cnic: { $regex: search, $options: 'i' } },
    ];
  }

  if (verificationStatus) {
    filter.status = verificationStatus;
  }

  // Get total count
  const total = await Worker.countDocuments(filter);

  // Get workers
  const workers = await Worker.find(filter)
    .populate('user', 'phone email isVerified isActive createdAt')
    .skip(skip)
    .limit(limit)
    .sort({ createdAt: -1 });

  return paginatedResponse(res, workers, page, limit, total, 'Workers retrieved');
});

/**
 * Get workers pending verification
 * GET /api/users/admin/workers/pending
 */
export const getPendingWorkers = asyncHandler(async (req: Request, res: Response) => {
  const workers = await Worker.find({ status: 'PENDING_VERIFICATION' })
    .populate('user', 'phone email createdAt')
    .sort({ createdAt: 1 }); // Oldest first

  return successResponse(res, workers, 'Pending workers retrieved');
});

/**
 * Verify worker
 * PUT /api/users/admin/workers/:workerId/verify
 */
export const verifyWorker = asyncHandler(async (req: Request, res: Response) => {
  const { workerId } = req.params;
  const { status, notes, documentDecisions } = req.body;

  if (!['ACTIVE', 'REJECTED'].includes(status)) {
    return errorResponse(res, 'Status must be ACTIVE or REJECTED', HTTP_STATUS.BAD_REQUEST);
  }

  const worker = await Worker.findById(workerId);

  if (!worker) {
    return notFoundResponse(res, 'Worker not found');
  }

  worker.status = status;
  worker.verificationNotes = notes || undefined;

  if (documentDecisions?.cnicFront) worker.cnicFrontStatus = documentDecisions.cnicFront;
  if (documentDecisions?.cnicBack) worker.cnicBackStatus = documentDecisions.cnicBack;
  if (documentDecisions?.profilePhoto) worker.profilePhotoStatus = documentDecisions.profilePhoto;

  if (status === 'ACTIVE') {
    worker.cnicVerified = true;
    // Verify all skills, and any document not explicitly rejected above,
    // on overall approval.
    worker.skills = worker.skills.map(skill => ({ ...skill, isVerified: true }));
    if (worker.cnicFrontStatus !== 'rejected') worker.cnicFrontStatus = 'verified';
    if (worker.cnicBackStatus !== 'rejected') worker.cnicBackStatus = 'verified';
    if (worker.profilePhotoStatus !== 'rejected') worker.profilePhotoStatus = 'verified';
  }

  await worker.save();

  await Notification.create({
    recipient: worker.user,
    type: 'SYSTEM',
    title: status === 'ACTIVE' ? 'Verification approved' : 'Verification update',
    body:
      status === 'ACTIVE'
        ? 'Your account has been verified. You can now receive bookings.'
        : notes
          ? `Your verification was rejected: ${notes}`
          : 'Your verification was rejected. Please check your documents and re-upload.',
    data: { action: 'WORKER_VERIFICATION', status },
  });

  return successResponse(res, worker, `Worker ${status === 'ACTIVE' ? 'approved' : 'rejected'} successfully`);
});

/**
 * Update user status (activate/deactivate)
 * PUT /api/users/admin/users/:userId/status
 */
export const updateUserStatus = asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;
  const { isActive, reason } = req.body;

  if (typeof isActive !== 'boolean') {
    return errorResponse(res, 'isActive must be a boolean', HTTP_STATUS.BAD_REQUEST);
  }

  const user = await User.findById(userId);

  if (!user) {
    return notFoundResponse(res, 'User not found');
  }

  // Don't allow deactivating admin users
  if (user.role === 'ADMIN' && !isActive) {
    return errorResponse(res, 'Cannot deactivate admin users', HTTP_STATUS.FORBIDDEN);
  }

  user.isActive = isActive;
  await user.save();

  // If deactivating a worker, also update worker status
  if (!isActive && user.role === 'WORKER') {
    await Worker.findOneAndUpdate({ user: userId }, { status: 'SUSPENDED' });
  } else if (isActive && user.role === 'WORKER') {
    const worker = await Worker.findOne({ user: userId });
    if (worker && worker.status === 'SUSPENDED') {
      worker.status = worker.cnicVerified ? 'ACTIVE' : 'PENDING_VERIFICATION';
      await worker.save();
    }
  }

  // TODO: Send notification to user about account status change

  return successResponse(res, { isActive: user.isActive }, `User ${isActive ? 'activated' : 'deactivated'} successfully`);
});

/**
 * Get user details
 * GET /api/users/admin/users/:userId
 */
export const getUserDetails = asyncHandler(async (req: Request, res: Response) => {
  const { userId } = req.params;

  const user = await User.findById(userId);

  if (!user) {
    return notFoundResponse(res, 'User not found');
  }

  let profile = null;
  if (user.role === 'CUSTOMER') {
    profile = await Customer.findOne({ user: userId });
  } else if (user.role === 'WORKER') {
    profile = await Worker.findOne({ user: userId });
  }

  return successResponse(res, { user, profile }, 'User details retrieved');
});

/**
 * Get withdrawal requests (paginated, filterable by status)
 * GET /api/users/admin/withdrawals
 */
export const getWithdrawals = asyncHandler(async (req: Request, res: Response) => {
  const page = parseInt(req.query.page as string) || 1;
  const limit = Math.min(parseInt(req.query.limit as string) || DEFAULTS.PAGINATION_LIMIT, DEFAULTS.MAX_PAGINATION_LIMIT);
  const status = req.query.status as string;

  const query: Record<string, unknown> = {};
  if (status) query.status = status;

  const skip = (page - 1) * limit;

  const [withdrawals, total] = await Promise.all([
    Withdrawal.find(query)
      .populate({
        path: 'worker',
        select: 'firstName lastName contactPhone user',
        populate: { path: 'user', select: 'phone email' },
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Withdrawal.countDocuments(query),
  ]);

  return paginatedResponse(res, withdrawals, page, limit, total, 'Withdrawals retrieved');
});

/**
 * Get withdrawal stats for the admin dashboard cards
 * GET /api/users/admin/withdrawals/stats
 */
export const getWithdrawalStats = asyncHandler(async (_req: Request, res: Response) => {
  const [pending, approved, rejected, paid] = await Promise.all([
    Withdrawal.countDocuments({ status: 'PENDING' }),
    Withdrawal.countDocuments({ status: 'APPROVED' }),
    Withdrawal.countDocuments({ status: 'REJECTED' }),
    Withdrawal.countDocuments({ status: 'PAID' }),
  ]);

  const pendingAmountResult = await Withdrawal.aggregate([
    { $match: { status: { $in: ['PENDING', 'APPROVED'] } } },
    { $group: { _id: null, total: { $sum: '$amount' } } },
  ]);
  const paidAmountResult = await Withdrawal.aggregate([
    { $match: { status: 'PAID' } },
    { $group: { _id: null, total: { $sum: '$amount' } } },
  ]);

  return successResponse(
    res,
    {
      pending,
      approved,
      rejected,
      paid,
      pendingAmount: pendingAmountResult[0]?.total ?? 0,
      paidAmount: paidAmountResult[0]?.total ?? 0,
    },
    'Withdrawal stats retrieved'
  );
});

/**
 * Review a withdrawal request (approve/reject/mark paid)
 * PUT /api/users/admin/withdrawals/:withdrawalId/review
 */
export const reviewWithdrawal = asyncHandler(async (req: Request, res: Response) => {
  const adminId = req.user!.id;
  const { withdrawalId } = req.params;
  const { status, notes } = req.body;

  const withdrawal = await Withdrawal.findById(withdrawalId);
  if (!withdrawal) {
    return notFoundResponse(res, 'Withdrawal request not found');
  }

  const validTransitions: Record<string, string[]> = {
    PENDING: ['APPROVED', 'REJECTED'],
    APPROVED: ['PAID', 'REJECTED'],
  };
  const allowedNext = validTransitions[withdrawal.status] ?? [];
  if (!allowedNext.includes(status)) {
    return errorResponse(
      res,
      `Cannot move a ${withdrawal.status} withdrawal to ${status}`,
      HTTP_STATUS.BAD_REQUEST
    );
  }

  withdrawal.status = status;
  withdrawal.adminNotes = notes || undefined;
  withdrawal.processedBy = adminId as any;
  withdrawal.processedAt = new Date();
  withdrawal.timeline.push({
    status,
    timestamp: new Date(),
    note: notes,
    performedBy: adminId as any,
  });

  await withdrawal.save();

  const worker = await Worker.findById(withdrawal.worker);
  if (worker) {
    const statusText =
      status === 'APPROVED' ? 'approved and is being processed'
      : status === 'PAID' ? 'has been paid out'
      : 'was rejected';
    await Notification.create({
      recipient: worker.user,
      type: 'PAYMENT',
      title: 'Withdrawal update',
      body: notes
        ? `Your withdrawal request of Rs. ${withdrawal.amount} ${statusText}. Note: ${notes}`
        : `Your withdrawal request of Rs. ${withdrawal.amount} ${statusText}.`,
      data: { action: 'WITHDRAWAL_STATUS', withdrawalId: withdrawal._id.toString(), status },
    });
  }

  return successResponse(res, withdrawal, `Withdrawal ${status.toLowerCase()} successfully`);
});
