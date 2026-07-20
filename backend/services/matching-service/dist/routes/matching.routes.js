import { Router } from 'express';
import * as matchingController from '../controllers/matching.controller.js';
import { validate } from '@handy-go/shared';
import { authenticate, authorize, authenticateService } from '@handy-go/shared';
import { analyzeProblemSchema, findWorkersSchema, estimatePriceSchema, estimateDurationSchema, calculateTrustScoreSchema, autoReplaceWorkerSchema, chatAssistantSchema, } from '../validators/matching.validators.js';
const router = Router();
/**
 * @route   POST /api/matching/analyze-problem
 * @desc    Analyze problem description using NLP
 * @access  Authenticated users
 */
router.post('/analyze-problem', authenticate, validate(analyzeProblemSchema), matchingController.analyzeProblem);
/**
 * @route   POST /api/matching/find-workers
 * @desc    Find matching workers based on criteria
 * @access  Authenticated users
 */
router.post('/find-workers', authenticate, validate(findWorkersSchema), matchingController.findWorkers);
/**
 * @route   POST /api/matching/estimate-price
 * @desc    Estimate price for a service
 * @access  Authenticated users
 */
router.post('/estimate-price', authenticate, validate(estimatePriceSchema), matchingController.estimatePrice);
/**
 * @route   POST /api/matching/estimate-duration
 * @desc    Estimate duration for a service
 * @access  Authenticated users
 */
router.post('/estimate-duration', authenticate, validate(estimateDurationSchema), matchingController.estimateDuration);
/**
 * @route   POST /api/matching/calculate-trust-score
 * @desc    Calculate trust score for a worker (internal service-to-service)
 * @access  Internal (service key required)
 */
router.post('/calculate-trust-score', authenticateService, validate(calculateTrustScoreSchema), matchingController.calculateTrustScore);
/**
 * @route   POST /api/matching/update-trust-score
 * @desc    Update and save trust score dynamically for a worker
 * @access  Internal (service key required)
 */
router.post('/update-trust-score', authenticateService, validate(calculateTrustScoreSchema), matchingController.updateTrustScore);
/**
 * @route   POST /api/matching/auto-replace-worker
 * @desc    Auto-replace worker for a booking (internal service-to-service)
 * @access  Internal (service key required)
 */
router.post('/auto-replace-worker', authenticateService, validate(autoReplaceWorkerSchema), matchingController.autoReplaceWorker);
/**
 * @route   POST /api/matching/admin/update-trust-scores
 * @desc    Batch update trust scores for all workers
 * @access  Admin only
 */
router.post('/admin/update-trust-scores', authenticate, authorize('ADMIN'), matchingController.batchUpdateTrustScores);
/**
 * @route   POST /api/matching/chatbot/ask
 * @desc    Submit user message to OpenAI chatbot
 * @access  Authenticated users
 */
router.post('/chatbot/ask', authenticate, validate(chatAssistantSchema), matchingController.askChatbot);
export default router;
//# sourceMappingURL=matching.routes.js.map