import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as customerController from '../controllers/customer.controller.js';
import { validate } from '@handy-go/shared';
import { updateCustomerProfileSchema, addAddressSchema, updateAddressSchema, } from '../validators/user.validators.js';
const router = Router();
// All routes require authentication as CUSTOMER
router.use(authenticate);
router.use(authorize('CUSTOMER'));
/**
 * @route   GET /api/users/customer/profile
 * @desc    Get customer profile
 * @access  Private (Customer)
 */
router.get('/profile', customerController.getProfile);
/**
 * @route   PUT /api/users/customer/profile
 * @desc    Update customer profile
 * @access  Private (Customer)
 */
router.put('/profile', validate(updateCustomerProfileSchema), customerController.updateProfile);
/**
 * @route   GET /api/users/customer/addresses
 * @desc    Get all customer addresses
 * @access  Private (Customer)
 */
router.get('/addresses', customerController.getAddresses);
/**
 * @route   POST /api/users/customer/addresses
 * @desc    Add new address
 * @access  Private (Customer)
 */
router.post('/addresses', validate(addAddressSchema), customerController.addAddress);
/**
 * @route   PUT /api/users/customer/addresses/:addressId
 * @desc    Update address
 * @access  Private (Customer)
 */
router.put('/addresses/:addressId', validate(updateAddressSchema), customerController.updateAddress);
/**
 * @route   DELETE /api/users/customer/addresses/:addressId
 * @desc    Delete address
 * @access  Private (Customer)
 */
router.delete('/addresses/:addressId', customerController.deleteAddress);
/**
 * @route   DELETE /api/users/customer/account
 * @desc    Delete/deactivate customer account
 * @access  Private (Customer)
 */
router.delete('/account', customerController.deleteAccount);
export default router;
//# sourceMappingURL=customer.routes.js.map