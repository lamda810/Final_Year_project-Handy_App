import { Request, Response } from 'express';
/**
 * Analyze problem description
 * POST /api/matching/analyze-problem
 */
export declare const analyzeProblem: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Find matching workers
 * POST /api/matching/find-workers
 */
export declare const findWorkers: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Estimate price
 * POST /api/matching/estimate-price
 */
export declare const estimatePrice: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Estimate duration
 * POST /api/matching/estimate-duration
 */
export declare const estimateDuration: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Calculate trust score for a worker
 * POST /api/matching/calculate-trust-score (internal)
 */
export declare const calculateTrustScore: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update trust score for a specific worker (Webhook/Internal)
 * POST /api/matching/update-trust-score
 */
export declare const updateTrustScore: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Auto-replace worker for a booking
 * POST /api/matching/auto-replace-worker (internal)
 */
export declare const autoReplaceWorker: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Update trust scores for all workers (admin/cron)
 * POST /api/matching/admin/update-trust-scores
 */
export declare const batchUpdateTrustScores: (req: Request, res: Response, next: import("express").NextFunction) => void;
/**
 * Handle user Chatbot interactions
 * POST /api/matching/chatbot/ask
 */
export declare const askChatbot: (req: Request, res: Response, next: import("express").NextFunction) => void;
//# sourceMappingURL=matching.controller.d.ts.map