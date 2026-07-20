import { Customer, User, asyncHandler, successResponse, errorResponse, notFoundResponse, HTTP_STATUS, } from '@handy-go/shared';
/**
 * Get customer profile
 * GET /api/users/customer/profile
 */
export const getProfile = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const customer = await Customer.findByUserId(userId);
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    return successResponse(res, customer, 'Profile retrieved successfully');
});
/**
 * Update customer profile
 * PUT /api/users/customer/profile
 */
export const updateProfile = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { firstName, lastName, email, profileImage, contactPhone, preferredLanguage } = req.body;
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    // Update customer fields
    if (firstName)
        customer.firstName = firstName;
    if (lastName)
        customer.lastName = lastName;
    if (profileImage)
        customer.profileImage = profileImage;
    if (contactPhone !== undefined)
        customer.contactPhone = contactPhone || undefined;
    if (preferredLanguage)
        customer.preferredLanguage = preferredLanguage;
    // Update email in User model if provided
    if (email) {
        const existingEmail = await User.findOne({ email: email.toLowerCase(), _id: { $ne: userId } });
        if (existingEmail) {
            return errorResponse(res, 'Email already in use', HTTP_STATUS.CONFLICT);
        }
        await User.findByIdAndUpdate(userId, { email: email.toLowerCase() });
    }
    await customer.save();
    const updatedCustomer = await Customer.findByUserId(userId);
    return successResponse(res, updatedCustomer, 'Profile updated successfully');
});
/**
 * Get all addresses
 * GET /api/users/customer/addresses
 */
export const getAddresses = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    return successResponse(res, customer.addresses, 'Addresses retrieved successfully');
});
/**
 * Add address
 * POST /api/users/customer/addresses
 */
export const addAddress = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { label, address, city, coordinates, isDefault } = req.body;
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    if (customer.addresses.length >= 5) {
        return errorResponse(res, 'Maximum 5 addresses allowed', HTTP_STATUS.BAD_REQUEST);
    }
    // If this is default, unset other defaults
    if (isDefault) {
        customer.addresses.forEach(addr => {
            addr.isDefault = false;
        });
    }
    customer.addresses.push({
        label: label || 'Home',
        address,
        city,
        coordinates,
        isDefault: isDefault || customer.addresses.length === 0,
    });
    await customer.save();
    return successResponse(res, customer.addresses, 'Address added successfully');
});
/**
 * Update address
 * PUT /api/users/customer/addresses/:addressId
 */
export const updateAddress = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { addressId } = req.params;
    const { label, address, city, coordinates, isDefault } = req.body;
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    const addressIndex = customer.addresses.findIndex(addr => addr._id?.toString() === addressId);
    if (addressIndex === -1) {
        return notFoundResponse(res, 'Address not found');
    }
    // If making this default, unset other defaults
    if (isDefault) {
        customer.addresses.forEach(addr => {
            addr.isDefault = false;
        });
    }
    // Update address fields
    const addressToUpdate = customer.addresses[addressIndex];
    if (!addressToUpdate) {
        return notFoundResponse(res, 'Address not found');
    }
    if (label)
        addressToUpdate.label = label;
    if (address)
        addressToUpdate.address = address;
    if (city)
        addressToUpdate.city = city;
    if (coordinates)
        addressToUpdate.coordinates = coordinates;
    if (typeof isDefault === 'boolean')
        addressToUpdate.isDefault = isDefault;
    await customer.save();
    return successResponse(res, customer.addresses, 'Address updated successfully');
});
/**
 * Delete address
 * DELETE /api/users/customer/addresses/:addressId
 */
export const deleteAddress = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const { addressId } = req.params;
    const customer = await Customer.findOne({ user: userId });
    if (!customer) {
        return notFoundResponse(res, 'Customer profile not found');
    }
    const addressIndex = customer.addresses.findIndex(addr => addr._id?.toString() === addressId);
    if (addressIndex === -1) {
        return notFoundResponse(res, 'Address not found');
    }
    const addressToDelete = customer.addresses[addressIndex];
    const wasDefault = addressToDelete?.isDefault ?? false;
    customer.addresses.splice(addressIndex, 1);
    // If deleted address was default, make first address default
    if (wasDefault && customer.addresses.length > 0) {
        const firstAddress = customer.addresses[0];
        if (firstAddress) {
            firstAddress.isDefault = true;
        }
    }
    await customer.save();
    return successResponse(res, customer.addresses, 'Address deleted successfully');
});
/**
 * Delete/deactivate customer account
 * DELETE /api/users/customer/account
 */
export const deleteAccount = asyncHandler(async (req, res) => {
    const userId = req.user.id;
    // Find and deactivate user
    const user = await User.findById(userId);
    if (!user) {
        return notFoundResponse(res, 'User not found');
    }
    // Deactivate the user account (soft delete)
    user.isActive = false;
    await user.save();
    return successResponse(res, null, 'Account deleted successfully');
});
//# sourceMappingURL=customer.controller.js.map