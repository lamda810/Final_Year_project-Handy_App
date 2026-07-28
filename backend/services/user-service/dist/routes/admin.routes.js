import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as adminController from '../controllers/admin.controller.js';
import { validate } from '@handy-go/shared';
import { createWorkerSchema, verifyWorkerSchema, updateUserStatusSchema, reviewWithdrawalSchema, } from '../validators/user.validators.js';
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
 * @route   POST /api/users/admin/workers
 * @desc    Create a worker directly (admin-added)
 * @access  Private (Admin)
 */
router.post('/workers', validate(createWorkerSchema), adminController.createWorker);
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
/**
 * @route   GET /api/users/admin/withdrawals/stats
 * @desc    Get withdrawal stats for the dashboard cards
 * @access  Private (Admin)
 * @note    Must be registered before /withdrawals/:withdrawalId/review so
 *          Express doesn't try to match "stats" as a withdrawalId.
 */
router.get('/withdrawals/stats', adminController.getWithdrawalStats);
/**
 * @route   GET /api/users/admin/withdrawals
 * @desc    Get withdrawal requests (paginated, filterable by status)
 * @access  Private (Admin)
 */
router.get('/withdrawals', adminController.getWithdrawals);
/**
 * @route   PUT /api/users/admin/withdrawals/:withdrawalId/review
 * @desc    Approve/reject/mark a withdrawal request as paid
 * @access  Private (Admin)
 */
router.put('/withdrawals/:withdrawalId/review', validate(reviewWithdrawalSchema), adminController.reviewWithdrawal);
export default router;
//# sourceMappingURL=admin.routes.js.map