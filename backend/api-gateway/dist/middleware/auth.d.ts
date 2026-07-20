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
 * Authentication middleware for the API Gateway
 * Validates JWT tokens and attaches user info to request
 */
export declare const authenticate: (req: Request, res: Response, next: NextFunction) => Promise<void | Response<any, Record<string, any>>>;
/**
 * Optional authentication - doesn't fail if no token
 * Just extracts user info if token is present
 */
export declare const optionalAuth: (req: Request, res: Response, next: NextFunction) => Promise<void>;
//# sourceMappingURL=auth.d.ts.map