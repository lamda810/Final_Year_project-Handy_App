import { Request, Response, NextFunction } from 'express';
import { UserRole } from '@handy-go/shared';
declare global {
    namespace Express {
        interface Request {
            user?: {
                id: string;
                role: UserRole;
            };
        }
    }
}
/**
 * Send notification to a single user
 * POST /api/notifications/send
 */
export declare const sendNotification: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Send templated notification
 * POST /api/notifications/send-templated
 */
export declare const sendTemplatedNotification: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Send bulk notification to multiple users
 * POST /api/notifications/send-bulk
 */
export declare const sendBulkNotification: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Get user's notifications
 * GET /api/notifications
 */
export declare const getNotifications: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Get unread notification count
 * GET /api/notifications/unread-count
 */
export declare const getUnreadCount: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Mark notification as read
 * PUT /api/notifications/:notificationId/read
 */
export declare const markAsRead: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Mark all notifications as read
 * PUT /api/notifications/read-all
 */
export declare const markAllAsRead: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Register device token for push notifications
 * POST /api/notifications/register-device
 */
export declare const registerDevice: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Unregister device token
 * DELETE /api/notifications/unregister-device
 */
export declare const unregisterDevice: (req: Request, res: Response, next: NextFunction) => void;
/**
 * Delete a notification
 * DELETE /api/notifications/:notificationId
 */
export declare const deleteNotification: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=notification.controller.d.ts.map