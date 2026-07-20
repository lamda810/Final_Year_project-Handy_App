import { Router } from 'express';
import * as notificationController from '../controllers/notification.controller.js';
import { authenticate, authenticateService } from '@handy-go/shared';
import { sendNotificationSchema, sendTemplatedNotificationSchema, sendBulkNotificationSchema, registerDeviceSchema, unregisterDeviceSchema, getNotificationsSchema, } from '../validators/notification.validators.js';
const router = Router();
// Validation middleware helper
const validate = (schema) => {
    return (req, res, next) => {
        const { error } = schema.validate(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: 'Validation error',
                errors: error.details.map((d) => d.message),
            });
        }
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
// ==================== Internal Service Endpoints ====================
// These are called by other microservices, not directly by clients
/**
 * @route POST /api/notifications/send
 * @desc Send notification to a user (internal service use)
 * @access Internal (Service Key)
 */
router.post('/send', authenticateService, validate(sendNotificationSchema), notificationController.sendNotification);
/**
 * @route POST /api/notifications/send-templated
 * @desc Send templated notification (internal service use)
 * @access Internal (Service Key)
 */
router.post('/send-templated', authenticateService, validate(sendTemplatedNotificationSchema), notificationController.sendTemplatedNotification);
/**
 * @route POST /api/notifications/send-bulk
 * @desc Send bulk notification to multiple users (internal service use)
 * @access Internal (Service Key)
 */
router.post('/send-bulk', authenticateService, validate(sendBulkNotificationSchema), notificationController.sendBulkNotification);
// ==================== User-facing Endpoints ====================
/**
 * @route GET /api/notifications
 * @desc Get user's notifications
 * @access Private
 */
router.get('/', authenticate, validateQuery(getNotificationsSchema), notificationController.getNotifications);
/**
 * @route GET /api/notifications/unread-count
 * @desc Get unread notification count
 * @access Private
 */
router.get('/unread-count', authenticate, notificationController.getUnreadCount);
/**
 * @route PUT /api/notifications/:notificationId/read
 * @desc Mark a notification as read
 * @access Private
 */
router.put('/:notificationId/read', authenticate, notificationController.markAsRead);
/**
 * @route PUT /api/notifications/read-all
 * @desc Mark all notifications as read
 * @access Private
 */
router.put('/read-all', authenticate, notificationController.markAllAsRead);
/**
 * @route POST /api/notifications/register-device
 * @desc Register device token for push notifications
 * @access Private
 */
router.post('/register-device', authenticate, validate(registerDeviceSchema), notificationController.registerDevice);
/**
 * @route DELETE /api/notifications/unregister-device
 * @desc Unregister device token
 * @access Private
 */
router.delete('/unregister-device', authenticate, validate(unregisterDeviceSchema), notificationController.unregisterDevice);
/**
 * @route DELETE /api/notifications/:notificationId
 * @desc Delete a notification
 * @access Private
 */
router.delete('/:notificationId', authenticate, notificationController.deleteNotification);
export default router;
//# sourceMappingURL=notification.routes.js.map