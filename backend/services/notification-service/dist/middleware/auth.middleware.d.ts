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
 * Verify JWT token and attach user to request
 */
export declare const authenticate: (req: Request, res: Response, next: NextFunction) => Promise<void>;
/**
 * Check if user has required role(s)
 */
export declare const authorize: (...roles: UserRole[]) => (req: Request, res: Response, next: NextFunction) => void;
/**
 * Internal service authentication (for service-to-service calls)
 */
export declare const authenticateService: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.middleware.d.ts.map