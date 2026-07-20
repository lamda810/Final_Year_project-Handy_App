export interface PriceEstimate {
    estimatedPrice: {
        min: number;
        max: number;
        average: number;
    };
    breakdown: {
        laborCost: {
            min: number;
            max: number;
        };
        estimatedMaterials: {
            min: number;
            max: number;
        };
        platformFee: number;
    };
    priceFactors: string[];
}
export interface DurationEstimate {
    estimatedMinutes: number;
    range: {
        min: number;
        max: number;
    };
    confidence: number;
}
/**
 * Estimate price for a service
 */
export declare const estimatePrice: (data: {
    serviceCategory: string;
    problemDescription: string;
    city: string;
    area?: string;
    scheduledDateTime?: string;
}) => Promise<PriceEstimate>;
/**
 * Estimate duration for a service
 */
export declare const estimateDuration: (data: {
    serviceCategory: string;
    problemDescription: string;
}) => Promise<DurationEstimate>;
declare const _default: {
    estimatePrice: (data: {
        serviceCategory: string;
        problemDescription: string;
        city: string;
        area?: string;
        scheduledDateTime?: string;
    }) => Promise<PriceEstimate>;
    estimateDuration: (data: {
        serviceCategory: string;
        problemDescription: string;
    }) => Promise<DurationEstimate>;
};
export default _default;
//# sourceMappingURL=price-predictor.d.ts.map