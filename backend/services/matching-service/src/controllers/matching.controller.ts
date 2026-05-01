import { Request, Response } from 'express';
import {
  asyncHandler,
  successResponse,
  errorResponse,
  HTTP_STATUS,
} from '@handy-go/shared';
import problemAnalyzer from '../algorithms/problem-analyzer.js';
import workerMatcher from '../algorithms/worker-matcher.js';
import pricePredictor from '../algorithms/price-predictor.js';
import trustCalculator from '../algorithms/trust-calculator.js';
import * as chatbot from '../algorithms/chatbot.js';

/**
 * Analyze problem description
 * POST /api/matching/analyze-problem
 */
export const analyzeProblem = asyncHandler(async (req: Request, res: Response) => {
  const { problemDescription, serviceCategory } = req.body;

  const analysis = await problemAnalyzer.analyzeProblem(problemDescription, serviceCategory);

  return successResponse(res, analysis, 'Problem analyzed successfully');
});

/**
 * Find matching workers
 * POST /api/matching/find-workers
 */
export const findWorkers = asyncHandler(async (req: Request, res: Response) => {
  const { serviceCategory, location, scheduledDateTime, isUrgent, problemComplexity, urgencyLevel } = req.body;

  const result = await workerMatcher.findMatchingWorkers({
    serviceCategory,
    location,
    scheduledDateTime: new Date(scheduledDateTime),
    isUrgent: isUrgent || false,
    problemComplexity,
    urgencyLevel
  });

  return successResponse(res, result, 'Workers found');
});

/**
 * Estimate price
 * POST /api/matching/estimate-price
 */
export const estimatePrice = asyncHandler(async (req: Request, res: Response) => {
  const { serviceCategory, problemDescription, location, scheduledDateTime } = req.body;

  const estimate = await pricePredictor.estimatePrice({
    serviceCategory,
    problemDescription,
    city: location.city,
    area: location.area,
    scheduledDateTime,
  });

  return successResponse(res, estimate, 'Price estimated');
});

/**
 * Estimate duration
 * POST /api/matching/estimate-duration
 */
export const estimateDuration = asyncHandler(async (req: Request, res: Response) => {
  const { serviceCategory, problemDescription } = req.body;

  const estimate = await pricePredictor.estimateDuration({
    serviceCategory,
    problemDescription,
  });

  return successResponse(res, estimate, 'Duration estimated');
});

/**
 * Calculate trust score for a worker
 * POST /api/matching/calculate-trust-score (internal)
 */
export const calculateTrustScore = asyncHandler(async (req: Request, res: Response) => {
  const { workerId } = req.body;

  const result = await trustCalculator.calculateTrustScore(workerId);

  return successResponse(res, result, 'Trust score calculated');
});

/**
 * Update trust score for a specific worker (Webhook/Internal)
 * POST /api/matching/update-trust-score
 */
export const updateTrustScore = asyncHandler(async (req: Request, res: Response) => {
  const { workerId } = req.body;

  const updatedScore = await trustCalculator.updateWorkerTrustScore(workerId);

  return successResponse(res, { trustScore: updatedScore }, 'Worker trust score dynamically adjusted based on new feedback');
});

/**
 * Auto-replace worker for a booking
 * POST /api/matching/auto-replace-worker (internal)
 */
export const autoReplaceWorker = asyncHandler(async (req: Request, res: Response) => {
  const { bookingId, excludeWorkerIds } = req.body;

  const result = await workerMatcher.findReplacementWorker(bookingId, excludeWorkerIds || []);

  return successResponse(res, result, result.success ? 'Worker replaced' : 'No replacement found');
});

/**
 * Update trust scores for all workers (admin/cron)
 * POST /api/matching/admin/update-trust-scores
 */
export const batchUpdateTrustScores = asyncHandler(async (req: Request, res: Response) => {
  const updatedCount = await trustCalculator.batchUpdateTrustScores();

  return successResponse(res, { updatedCount }, `Updated trust scores for ${updatedCount} workers`);
});

/**
 * Handle user Chatbot interactions
 * POST /api/matching/chatbot/ask
 */
export const askChatbot = asyncHandler(async (req: Request, res: Response) => {
  const { message, contextData } = req.body;

  const result = await chatbot.processChatMessage({ message, contextData });

  return successResponse(res, result, 'Chatbot replied');
});
