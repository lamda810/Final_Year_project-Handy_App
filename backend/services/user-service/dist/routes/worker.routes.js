import { Router } from 'express';
import { authenticate, authorize } from '@handy-go/shared';
import * as workerController from '../controllers/worker.controller.js';
import { validate } from '@handy-go/shared';
import { updateWorkerProfileSchema, updateLocationSchema, updateAvailabilitySchema, addDocumentSchema, } from '../validators/user.validators.js';
const router = Router();
// All routes require authentication as WORKER
router.use(authenticate);
router.use(authorize('WORKER'));
/**
 * @route   GET /api/users/worker/profile
 * @desc    Get worker profile
 * @access  Private (Worker)
 */
router.get('/profile', workerController.getProfile);
/**
 * @route   PUT /api/users/worker/profile
 * @desc    Update worker profile
 * @access  Private (Worker)
 */
router.put('/profile', validate(updateWorkerProfileSchema), workerController.updateProfile);
/**
 * @route   PUT /api/users/worker/location
 * @desc    Update worker current location
 * @access  Private (Worker)
 */
router.put('/location', validate(updateLocationSchema), workerController.updateLocation);
/**
 * @route   PUT /api/users/worker/availability
 * @desc    Update worker availability status
 * @access  Private (Worker)
 */
router.put('/availability', validate(updateAvailabilitySchema), workerController.updateAvailability);
/**
 * @route   POST /api/users/worker/documents
 * @desc    Add worker document
 * @access  Private (Worker)
 */
router.post('/documents', validate(addDocumentSchema), workerController.addDocument);
/**
 * @route   GET /api/users/worker/earnings
 * @desc    Get worker earnings
 * @access  Private (Worker)
 */
router.get('/earnings', workerController.getEarnings);
export default router;
//# sourceMappingURL=worker.routes.js.map