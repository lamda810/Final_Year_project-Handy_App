import { Router } from 'express';
import * as sosController from '../controllers/sos.controller.js';
import { authenticate, authorize } from '@handy-go/shared';
import { USER_ROLES_OBJ } from '@handy-go/shared';
import { triggerSOSSchema, updateSOSSchema, resolveSOSSchema, escalateSOSSchema, getActiveSOSSchema, markFalseAlarmSchema, } from '../validators/sos.validators.js';
const router = Router();
// Validation middleware helper
const validate = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: 'Validation error',
                errors: error.details.map((d) => d.message),
            });
        }
        req.body = value;
        next();
    };
};
const validateQuery = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.query);
        if (error) {
            return res.status(400).json({
                success: false,
                message: 'Validation error',
                errors: error.details.map((d) => d.message),
            });
        }
        req.query = value;
        next();
    };
};
// ==================== User Endpoints ====================
/**
 * @route POST /api/sos/trigger
 * @desc Trigger SOS emergency
 * @access Private (CUSTOMER, WORKER)
 */
router.post('/trigger', authenticate, authorize(USER_ROLES_OBJ.CUSTOMER, USER_ROLES_OBJ.WORKER), validate(triggerSOSSchema), sosController.triggerSOS);
// ==================== Admin Endpoints ====================
// IMPORTANT: Admin routes MUST be defined BEFORE the /:sosId param route
// to prevent Express from matching "admin" as a sosId parameter.
/**
 * @route GET /api/sos/admin/active
 * @desc Get all active SOS sorted by priority
 * @access Private (ADMIN)
 */
router.get('/admin/active', authenticate, authorize(USER_ROLES_OBJ.ADMIN), validateQuery(getActiveSOSSchema), sosController.getActiveSOSList);
/**
 * @route GET /api/sos/admin/stats
 * @desc Get SOS statistics
 * @access Private (ADMIN)
 */
router.get('/admin/stats', authenticate, authorize(USER_ROLES_OBJ.ADMIN), sosController.getSOSStats);
/**
 * @route POST /api/sos/admin/:sosId/assign
 * @desc Assign SOS to admin
 * @access Private (ADMIN)
 */
router.post('/admin/:sosId/assign', authenticate, authorize(USER_ROLES_OBJ.ADMIN), sosController.assignSOS);
/**
 * @route POST /api/sos/admin/:sosId/resolve
 * @desc Resolve SOS
 * @access Private (ADMIN)
 */
router.post('/admin/:sosId/resolve', authenticate, authorize(USER_ROLES_OBJ.ADMIN), validate(resolveSOSSchema), sosController.resolveSOS);
/**
 * @route POST /api/sos/admin/:sosId/escalate
 * @desc Escalate SOS
 * @access Private (ADMIN)
 */
router.post('/admin/:sosId/escalate', authenticate, authorize(USER_ROLES_OBJ.ADMIN), validate(escalateSOSSchema), sosController.escalateSOS);
/**
 * @route POST /api/sos/admin/:sosId/false-alarm
 * @desc Mark SOS as false alarm
 * @access Private (ADMIN)
 */
router.post('/admin/:sosId/false-alarm', authenticate, authorize(USER_ROLES_OBJ.ADMIN), validate(markFalseAlarmSchema), sosController.markFalseAlarm);
// ==================== Parameterized User Endpoints ====================
// These MUST come AFTER /admin/* routes to avoid catching "admin" as :sosId
/**
 * @route GET /api/sos/:sosId
 * @desc Get SOS details
 * @access Private
 */
router.get('/:sosId', authenticate, sosController.getSOSDetails);
/**
 * @route PUT /api/sos/:sosId/update
 * @desc Update SOS with additional information
 * @access Private (CUSTOMER, WORKER)
 */
router.put('/:sosId/update', authenticate, authorize(USER_ROLES_OBJ.CUSTOMER, USER_ROLES_OBJ.WORKER), validate(updateSOSSchema), sosController.updateSOS);
export default router;
//# sourceMappingURL=sos.routes.js.map