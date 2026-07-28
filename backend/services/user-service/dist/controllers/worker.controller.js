import { Worker, User, Booking, Withdrawal, asyncHandler, successResponse, errorResponse, notFoundResponse, HTTP_STATUS, MIN_WITHDRAWAL_AMOUNT, } from '@handy-go/shared';
/**
 * Get worker profile
 * GET /api/users/worker/profile
 */
export const getProfile = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const worker = await Worker.findByUserId(userId);
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    return successResponse(res, worker, 'Profile retrieved successfully');
});
/**
 * Update worker profile
 * PUT /api/users/worker/profile
 */
export const updateProfile = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { firstName, lastName, email, profileImage, contactPhone, skills, serviceRadius, availability, bankDetails } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    // Update worker fields
    if (firstName)
        worker.firstName = firstName;
    if (lastName)
        worker.lastName = lastName;
    if (profileImage)
        worker.profileImage = profileImage;
    if (contactPhone !== undefined)
        worker.contactPhone = contactPhone || undefined;
    if (skills) {
        worker.skills = skills.map((skill) => ({
            ...skill,
            isVerified: worker.skills.find(s => s.category === skill.category)?.isVerified || false,
        }));
    }
    if (serviceRadius)
        worker.serviceRadius = serviceRadius;
    if (availability)
        worker.availability = availability;
    if (bankDetails)
        worker.bankDetails = bankDetails;
    // Update email in User model if provided
    if (email) {
        const existingEmail = await User.findOne({ email: email.toLowerCase(), _id: { $ne: userId } });
        if (existingEmail) {
            return errorResponse(res, 'Email already in use', HTTP_STATUS.CONFLICT);
        }
        await User.findByIdAndUpdate(userId, { email: email.toLowerCase() });
    }
    await worker.save();
    const updatedWorker = await Worker.findByUserId(userId);
    return successResponse(res, updatedWorker, 'Profile updated successfully');
});
/**
 * Update worker location
 * PUT /api/users/worker/location
 */
export const updateLocation = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { coordinates } = req.body;
    if (!coordinates || typeof coordinates.lat !== 'number' || typeof coordinates.lng !== 'number') {
        return errorResponse(res, 'Valid coordinates are required', HTTP_STATUS.BAD_REQUEST);
    }
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    await worker.updateLocation(coordinates.lat, coordinates.lng);
    return successResponse(res, { success: true }, 'Location updated');
});
/**
 * Update worker availability
 * PUT /api/users/worker/availability
 */
export const updateAvailability = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { isAvailable } = req.body;
    if (typeof isAvailable !== 'boolean') {
        return errorResponse(res, 'isAvailable must be a boolean', HTTP_STATUS.BAD_REQUEST);
    }
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    worker.availability.isAvailable = isAvailable;
    await worker.save();
    return successResponse(res, { isAvailable: worker.availability.isAvailable }, 'Availability updated');
});
/**
 * Add document
 * POST /api/users/worker/documents
 *
 * `type` is one of the fixed onboarding document ids the worker-app's
 * documents screen uses ('cnic_front' | 'cnic_back' | 'profile_photo').
 * Each maps to its own flat image + status field (rather than only the
 * generic `documents[]` log) so admin review can approve/reject them
 * independently. Re-uploading resets that one document back to 'pending'
 * so a previously-rejected document re-enters review.
 */
export const addDocument = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { type, url } = req.body;
    if (!type || !url) {
        return errorResponse(res, 'Document type and URL are required', HTTP_STATUS.BAD_REQUEST);
    }
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    switch (type) {
        case 'cnic_front':
            worker.cnicFrontImage = url;
            worker.cnicFrontStatus = 'pending';
            break;
        case 'cnic_back':
            worker.cnicBackImage = url;
            worker.cnicBackStatus = 'pending';
            break;
        case 'profile_photo':
            worker.profileImage = url;
            worker.profilePhotoStatus = 'pending';
            break;
        default:
            return errorResponse(res, 'Unknown document type', HTTP_STATUS.BAD_REQUEST);
    }
    worker.documents.push({
        type,
        url,
        verified: false,
        uploadedAt: new Date(),
    });
    await worker.save();
    return successResponse(res, worker, 'Document uploaded successfully');
});
/**
 * Get earnings
 * GET /api/users/worker/earnings
 */
export const getEarnings = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { startDate, endDate } = req.query;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    // Build date filter
    const dateFilter = { worker: worker._id, status: 'COMPLETED' };
    if (startDate) {
        dateFilter.createdAt = { $gte: new Date(startDate) };
    }
    if (endDate) {
        dateFilter.createdAt = { ...dateFilter.createdAt, $lte: new Date(endDate) };
    }
    // Get completed bookings
    const bookings = await Booking.find(dateFilter).select('pricing createdAt');
    // Calculate earnings
    const total = bookings.reduce((sum, booking) => sum + (booking.pricing.finalPrice || 0), 0);
    const platformFees = bookings.reduce((sum, booking) => sum + (booking.pricing.platformFee || 0), 0);
    const netEarnings = total - platformFees;
    // Group by date for breakdown
    const breakdown = {};
    bookings.forEach(booking => {
        const date = booking.createdAt?.toISOString().split('T')[0];
        if (date) {
            breakdown[date] = (breakdown[date] || 0) + (booking.pricing.finalPrice || 0) - (booking.pricing.platformFee || 0);
        }
    });
    return successResponse(res, {
        totalEarnings: total,
        platformFees,
        netEarnings,
        bookingsCount: bookings.length,
        breakdown,
    }, 'Earnings retrieved successfully');
});
/**
 * Compute a worker's withdrawable balance: net earnings from completed
 * bookings, minus anything already paid out or currently tied up in a
 * pending/approved (not yet paid) withdrawal request.
 */
const calculateAvailableBalance = async (workerId) => {
    const bookings = await Booking.find({ worker: workerId, status: 'COMPLETED' }).select('pricing');
    const netEarnings = bookings.reduce((sum, booking) => sum + (booking.pricing.finalPrice || 0) - (booking.pricing.platformFee || 0), 0);
    const reserved = await Withdrawal.aggregate([
        { $match: { worker: workerId, status: { $in: ['PENDING', 'APPROVED', 'PAID'] } } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
    ]);
    const alreadyWithdrawnOrReserved = reserved[0]?.total ?? 0;
    return Math.max(0, netEarnings - alreadyWithdrawnOrReserved);
};
/**
 * Request a withdrawal
 * POST /api/users/worker/withdrawals
 */
export const requestWithdrawal = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { amount } = req.body;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    if (!worker.bankDetails?.accountNumber) {
        return errorResponse(res, 'Please add your bank details to your profile before requesting a withdrawal', HTTP_STATUS.BAD_REQUEST);
    }
    if (amount < MIN_WITHDRAWAL_AMOUNT) {
        return errorResponse(res, `Minimum withdrawal amount is Rs. ${MIN_WITHDRAWAL_AMOUNT}`, HTTP_STATUS.BAD_REQUEST);
    }
    const availableBalance = await calculateAvailableBalance(worker._id);
    if (amount > availableBalance) {
        return errorResponse(res, `Withdrawal amount exceeds available balance (Rs. ${availableBalance})`, HTTP_STATUS.BAD_REQUEST);
    }
    const withdrawal = await Withdrawal.create({
        worker: worker._id,
        amount,
        bankDetails: worker.bankDetails,
        status: 'PENDING',
    });
    return successResponse(res, withdrawal, 'Withdrawal request submitted successfully', HTTP_STATUS.CREATED);
});
/**
 * Get the authenticated worker's withdrawal history + current balance
 * GET /api/users/worker/withdrawals
 */
export const getWithdrawals = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const worker = await Worker.findOne({ user: userId });
    if (!worker) {
        return notFoundResponse(res, 'Worker profile not found');
    }
    const [withdrawals, availableBalance] = await Promise.all([
        Withdrawal.find({ worker: worker._id }).sort({ createdAt: -1 }),
        calculateAvailableBalance(worker._id),
    ]);
    return successResponse(res, { withdrawals, availableBalance }, 'Withdrawals retrieved successfully');
});
//# sourceMappingURL=worker.controller.js.map