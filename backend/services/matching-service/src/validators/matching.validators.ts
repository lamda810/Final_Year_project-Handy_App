import Joi from 'joi';
import { SERVICE_CATEGORIES } from '@handy-go/shared';

export const analyzeProblemSchema = Joi.object({
  problemDescription: Joi.string().min(5).max(1000).required().trim(),
  serviceCategory: Joi.string().valid(...SERVICE_CATEGORIES),
});

export const findWorkersSchema = Joi.object({
  serviceCategory: Joi.string()
    .valid(...SERVICE_CATEGORIES)
    .required(),
  location: Joi.object({
    lat: Joi.number().min(-90).max(90).required(),
    lng: Joi.number().min(-180).max(180).required(),
  }).required(),
  scheduledDateTime: Joi.date().iso().required(),
  isUrgent: Joi.boolean().default(false),
  problemComplexity: Joi.string().valid('LOW', 'MEDIUM', 'HIGH'),
  urgencyLevel: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL_SOS').optional(),
});

export const estimatePriceSchema = Joi.object({
  serviceCategory: Joi.string()
    .valid(...SERVICE_CATEGORIES)
    .required(),
  problemDescription: Joi.string().min(5).max(1000).required().trim(),
  location: Joi.object({
    city: Joi.string().min(2).max(50).required().trim(),
    area: Joi.string().min(2).max(100).optional().trim(),
  }).required(),
  scheduledDateTime: Joi.date().iso().optional(),
});

export const estimateDurationSchema = Joi.object({
  serviceCategory: Joi.string()
    .valid(...SERVICE_CATEGORIES)
    .required(),
  problemDescription: Joi.string().min(5).max(1000).required().trim(),
});

export const calculateTrustScoreSchema = Joi.object({
  workerId: Joi.string().hex().length(24).required(),
});

export const autoReplaceWorkerSchema = Joi.object({
  bookingId: Joi.string().hex().length(24).required(),
  excludeWorkerIds: Joi.array().items(Joi.string().hex().length(24)).default([]),
});

export const chatAssistantSchema = Joi.object({
  message: Joi.string().min(1).max(500).required().trim(),
  contextData: Joi.object({
    city: Joi.string().optional(),
    area: Joi.string().optional(),
  }).optional(),
});
