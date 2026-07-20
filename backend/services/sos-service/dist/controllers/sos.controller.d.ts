import { Request, Response } from 'express';
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
 * Trigger SOS emergency
 * POST /api/sos/trigger
 */
export declare const triggerSOS: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get SOS details
 * GET /api/sos/:sosId
 */
export declare const getSOSDetails: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update SOS with additional information
 * PUT /api/sos/:sosId/update
 */
export declare const updateSOS: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get all active SOS sorted by priority
 * GET /api/sos/admin/active
 */
export declare const getActiveSOSList: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Assign SOS to admin
 * POST /api/sos/admin/:sosId/assign
 */
export declare const assignSOS: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Resolve SOS
 * POST /api/sos/admin/:sosId/resolve
 */
export declare const resolveSOS: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Escalate SOS
 * POST /api/sos/admin/:sosId/escalate
 */
export declare const escalateSOS: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Mark SOS as false alarm
 * POST /api/sos/admin/:sosId/false-alarm
 */
export declare const markFalseAlarm: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get SOS statistics
 * GET /api/sos/admin/stats
 */
export declare const getSOSStats: (req: Request, res: Response, next: import("express").NextFunction) => void;
//# sourceMappingURL=sos.controller.d.ts.map