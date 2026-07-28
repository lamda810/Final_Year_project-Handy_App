import { Request, Response } from 'express';
/**
 * Get worker profile
 * GET /api/users/worker/profile
 */
export declare const getProfile: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update worker profile
 * PUT /api/users/worker/profile
 */
export declare const updateProfile: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update worker location
 * PUT /api/users/worker/location
 */
export declare const updateLocation: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update worker availability
 * PUT /api/users/worker/availability
 */
export declare const updateAvailability: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Add document
 * POST /api/users/worker/documents
 *
 * `type` is one of the fixed onboarding document ids the worker-app's
 * documents screen uses ('cnic_front' | 'cnic_back' | 'profile_photo').
 * Each maps to its own flat image + status field (rather than only the
 * generic `documents[]` log) so admin review can approve/reject them
 * independently. Re-uploading resets that one document back to 'pending'
 * so a previously-rejected document re-enters review.
 */
export declare const addDocument: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Get earnings
 * GET /api/users/worker/earnings
 */
export declare const getEarnings: (req: Request, res: Response, next: import("express").NextFunction) => void;
//# sourceMappingURL=worker.controller.d.ts.map