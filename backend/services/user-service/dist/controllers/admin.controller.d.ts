import { Request, Response } from 'express';
/**
 * Get all customers (paginated)
 * GET /api/users/admin/customers
 */
export declare const getCustomers: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Create a worker directly (admin-added, bypasses phone-OTP registration)
 * POST /api/users/admin/workers
 */
export declare const createWorker: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get all workers (paginated)
 * GET /api/users/admin/workers
 */
export declare const getWorkers: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get workers pending verification
 * GET /api/users/admin/workers/pending
 */
export declare const getPendingWorkers: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Verify worker
 * PUT /api/users/admin/workers/:workerId/verify
 */
export declare const verifyWorker: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update user status (activate/deactivate)
 * PUT /api/users/admin/users/:userId/status
 */
export declare const updateUserStatus: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get user details
 * GET /api/users/admin/users/:userId
 */
export declare const getUserDetails: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get withdrawal requests (paginated, filterable by status)
 * GET /api/users/admin/withdrawals
 */
export declare const getWithdrawals: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get withdrawal stats for the admin dashboard cards
 * GET /api/users/admin/withdrawals/stats
 */
export declare const getWithdrawalStats: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Review a withdrawal request (approve/reject/mark paid)
 * PUT /api/users/admin/withdrawals/:withdrawalId/review
 */
export declare const reviewWithdrawal: (req: Request, res: Response, next: import("express").NextFunction) => void;
//# sourceMappingURL=admin.controller.d.ts.map