export declare const config: {
    nodeEnv: string;
    port: number;
    mongodbUri: string;
    corsOrigin: string;
    jwt: {
        secret: string;
    };
    serviceKey: string;
    matching: {
        weights: {
            distance: number;
            rating: number;
            trustScore: number;
            experience: number;
            workload: number;
        };
        maxDistance: number;
        minTrustScore: number;
        resultsLimit: number;
    };
    pricing: {
        bufferPercent: number;
        locationMultipliers: {
            karachi: number;
            lahore: number;
            islamabad: number;
            rawalpindi: number;
            faisalabad: number;
            multan: number;
            peshawar: number;
            quetta: number;
            default: number;
        };
    };
    trustScore: {
        weights: {
            rating: number;
            completionRate: number;
            onTimeRate: number;
            complaints: number;
            accountAge: number;
        };
    };
};
//# sourceMappingURL=index.d.ts.map