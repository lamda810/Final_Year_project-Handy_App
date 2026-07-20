import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as adminController from '../controllers/admin.controller.js';
import { validate } from '@handy-go/shared';
import { verifyWorkerSchema, updateUserStatusSchema, } from '../validators/user.validators.js';
const router = Router();
// All routes require authentication as ADMIN
router.use(authenticate);
router.use(authorize('ADMIN'));
/**
 * @route   GET /api/users/admin/customers
 * @desc    Get all customers (paginated)
 * @access  Private (Admin)
 */
router.get('/customers', adminController.getCustomers);
/**
 * @route   GET /api/users/admin/workers
 * @desc    Get all workers (paginated)
 * @access  Private (Admin)
 */
router.get('/workers', adminController.getWorkers);
/**
 * @route   GET /api/users/admin/workers/pending
 * @desc    Get workers pending verification
 * @access  Private (Admin)
 */
router.get('/workers/pending', adminController.getPendingWorkers);
/**
 * @route   PUT /api/users/admin/workers/:workerId/verify
 * @desc    Verify worker (approve/reject)
 * @access  Private (Admin)
 */
router.put('/workers/:workerId/verify', validate(verifyWorkerSchema), adminController.verifyWorker);
/**
 * @route   PUT /api/users/admin/users/:userId/status
 * @desc    Update user status (activate/deactivate)
 * @access  Private (Admin)
 */
router.put('/users/:userId/status', validate(updateUserStatusSchema), adminController.updateUserStatus);
/**
 * @route   GET /api/users/admin/users/:userId
 * @desc    Get user details
 * @access  Private (Admin)
 */
router.get('/users/:userId', adminController.getUserDetails);
export default router;
//# sourceMappingURL=admin.routes.js.map