import { Booking } from '@handy-go/shared';
import { config } from '../config/index.js';
import priceBaselines from '../data/price-baselines.json' with { type: 'json' };

interface PriceBaselineData {
  laborMin: number;
  laborMax: number;
  durationMin: number;
  durationMax: number;
  examples: string[];
}

interface CategoryPricing {
  basic: PriceBaselineData;
  medium: PriceBaselineData;
  complex: PriceBaselineData;
}

type PriceBaselinesType = {
  [key: string]: CategoryPricing;
};

const typedPriceBaselines = priceBaselines as PriceBaselinesType;

export interface PriceEstimate {
  estimatedPrice: { min: number; max: number; average: number };
  breakdown: {
    laborCost: { min: number; max: number };
    estimatedMaterials: { min: number; max: number };
    platformFee: number;
  };
  priceFactors: string[];
}

export interface DurationEstimate {
  estimatedMinutes: number;
  range: { min: number; max: number };
  confidence: number;
}

/**
 * Estimate price for a service
 */
export const estimatePrice = async (data: {
  serviceCategory: string;
  problemDescription: string;
  city: string;
  area?: string;
  scheduledDateTime?: string;
}): Promise<PriceEstimate> => {
  const { serviceCategory, problemDescription, city, area, scheduledDateTime } = data;
  const priceFactors: string[] = [];

  // Get baseline pricing for category
  const categoryPricing = typedPriceBaselines[serviceCategory];
  if (!categoryPricing) {
    // Return default estimate if category not found
    return getDefaultEstimate();
  }

  // Determine complexity from problem description
  const complexity = determineComplexity(problemDescription, serviceCategory);
  const baseline = categoryPricing[complexity];
  priceFactors.push(`${complexity.charAt(0).toUpperCase() + complexity.slice(1)} complexity job`);

  // Apply basic city location multiplier
  let locationMultiplier = getLocationMultiplier(city);
  if (locationMultiplier !== 1) {
    priceFactors.push(`${city} base area rate adjustment`);
  }

  // AI Area-Based Intelligence
  if (area) {
    const areaMultiplier = getAreaMultiplier(city, area);
    locationMultiplier *= areaMultiplier;
    if (areaMultiplier > 1) priceFactors.push(`High demand area logic applied (${area})`);
    if (areaMultiplier < 1) priceFactors.push(`Low demand area adjustment (${area})`);
  }

  // Peak Hours / Dynamic Time Computation
  let timeMultiplier = 1.0;
  if (scheduledDateTime) {
    const targetDate = new Date(scheduledDateTime);
    const hour = targetDate.getHours();
    
    // Peak hours: 8am-10am and 6pm-10pm
    if ((hour >= 8 && hour <= 10) || (hour >= 18 && hour <= 22)) {
      timeMultiplier = 1.25; // 25% surge for peak slots
      priceFactors.push('Peak hour demand surge pricing (+25%)');
    }
    // Late night surcharge: 11pm-6am
    else if (hour >= 23 || hour <= 6) {
      timeMultiplier = 1.60; // 60% surge for late night
      priceFactors.push('Late night availability explicitly priced (+60%)');
    }
  }

  // Calculate labor costs dynamically combining base + area + time surge
  let laborMin = Math.round(baseline.laborMin * locationMultiplier * timeMultiplier);
  let laborMax = Math.round(baseline.laborMax * locationMultiplier * timeMultiplier);

  // Get historical data for similar jobs
  const historicalData = await getHistoricalPricing(serviceCategory, city);
  if (historicalData.count > 5) {
    // Adjust based on historical data
    laborMin = Math.round((laborMin + historicalData.avgPrice * 0.8) / 2);
    laborMax = Math.round((laborMax + historicalData.avgPrice * 1.2) / 2);
    priceFactors.push('Based on historical data');
  }

  // Estimate materials (20-40% of labor typically)
  const materialsMin = Math.round(laborMin * 0.1);
  const materialsMax = Math.round(laborMax * 0.4);

  // Calculate totals
  const totalMin = laborMin + materialsMin;
  const totalMax = laborMax + materialsMax;
  const average = Math.round((totalMin + totalMax) / 2);

  // Platform fee (15% of labor)
  const platformFee = Math.round(average * 0.15);

  // Add buffer
  const buffer = config.pricing.bufferPercent / 100;
  const bufferedMin = Math.round(totalMin * (1 - buffer / 2));
  const bufferedMax = Math.round(totalMax * (1 + buffer / 2));

  return {
    estimatedPrice: {
      min: bufferedMin,
      max: bufferedMax,
      average,
    },
    breakdown: {
      laborCost: { min: laborMin, max: laborMax },
      estimatedMaterials: { min: materialsMin, max: materialsMax },
      platformFee,
    },
    priceFactors,
  };
};

/**
 * Estimate duration for a service
 */
export const estimateDuration = async (data: {
  serviceCategory: string;
  problemDescription: string;
}): Promise<DurationEstimate> => {
  const { serviceCategory, problemDescription } = data;

  // Get baseline duration for category
  const categoryPricing = typedPriceBaselines[serviceCategory];
  if (!categoryPricing) {
    return {
      estimatedMinutes: 60,
      range: { min: 30, max: 120 },
      confidence: 0.5,
    };
  }

  // Determine complexity
  const complexity = determineComplexity(problemDescription, serviceCategory);
  const baseline = categoryPricing[complexity];

  const average = Math.round((baseline.durationMin + baseline.durationMax) / 2);
  const confidence = complexity === 'basic' ? 0.8 : complexity === 'medium' ? 0.7 : 0.6;

  return {
    estimatedMinutes: average,
    range: {
      min: baseline.durationMin,
      max: baseline.durationMax,
    },
    confidence,
  };
};

/**
 * Determine job complexity from description
 */
const determineComplexity = (
  description: string,
  category: string
): 'basic' | 'medium' | 'complex' => {
  const text = description.toLowerCase();

  // Complex indicators
  const complexIndicators = [
    'complete', 'full', 'entire', 'whole house', 'installation',
    'replacement', 'rewiring', 'renovation', 'major', 'rebuild',
    'new', 'custom', 'multiple'
  ];

  // Basic indicators
  const basicIndicators = [
    'small', 'minor', 'simple', 'quick', 'just', 'only one',
    'single', 'touch up', 'check', 'inspect', 'service'
  ];

  let complexScore = 0;
  let basicScore = 0;

  complexIndicators.forEach(indicator => {
    if (text.includes(indicator)) complexScore++;
  });

  basicIndicators.forEach(indicator => {
    if (text.includes(indicator)) basicScore++;
  });

  // Check examples from pricing data
  const categoryPricing = typedPriceBaselines[category];
  if (categoryPricing) {
    categoryPricing.complex.examples.forEach(example => {
      if (text.includes(example.toLowerCase())) complexScore += 2;
    });
    categoryPricing.basic.examples.forEach(example => {
      if (text.includes(example.toLowerCase())) basicScore += 2;
    });
  }

  if (complexScore > basicScore && complexScore >= 2) return 'complex';
  if (basicScore > complexScore && basicScore >= 1) return 'basic';
  return 'medium';
};

/**
 * Get location-based price multiplier
 */
const getLocationMultiplier = (city: string): number => {
  const normalizedCity = city.toLowerCase().trim();
  const multipliers = config.pricing.locationMultipliers as Record<string, number>;

  return multipliers[normalizedCity] || multipliers.default || 1;
};

/**
 * Get dynamic area-based (neighborhood) price intelligence
 * Currently mocks high/medium/low traffic sectors
 */
const getAreaMultiplier = (city: string, area: string): number => {
  const normalizedArea = area.toLowerCase().trim();
  
  // Example busy tech hubs or commercial zones logic
  const busyAreas = ['dha', 'clifton', 'bahria', 'blue area', 'saddar', 'gulberg', 'commercial'];
  const isBusy = busyAreas.some(b => normalizedArea.includes(b));
  
  if (isBusy) return 1.2; // 20% premium for busy commercial/upper-class areas
  return 1.0;
};

/**
 * Get historical pricing data for similar jobs
 */
const getHistoricalPricing = async (
  category: string,
  city: string
): Promise<{ avgPrice: number; count: number }> => {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

  const result = await Booking.aggregate([
    {
      $match: {
        serviceCategory: category,
        'address.city': { $regex: new RegExp(city, 'i') },
        status: 'COMPLETED',
        'pricing.finalPrice': { $exists: true, $gt: 0 },
        createdAt: { $gte: thirtyDaysAgo },
      },
    },
    {
      $group: {
        _id: null,
        avgPrice: { $avg: '$pricing.finalPrice' },
        count: { $sum: 1 },
      },
    },
  ]);

  if (result.length > 0) {
    return {
      avgPrice: Math.round(result[0].avgPrice),
      count: result[0].count,
    };
  }

  return { avgPrice: 0, count: 0 };
};

/**
 * Get default estimate when category not found
 */
const getDefaultEstimate = (): PriceEstimate => {
  return {
    estimatedPrice: { min: 500, max: 2000, average: 1000 },
    breakdown: {
      laborCost: { min: 400, max: 1500 },
      estimatedMaterials: { min: 100, max: 500 },
      platformFee: 150,
    },
    priceFactors: ['Standard estimate applied'],
  };
};

export default {
  estimatePrice,
  estimateDuration,
};
