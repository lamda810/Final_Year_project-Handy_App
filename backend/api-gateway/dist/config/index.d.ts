export declare const config: {
    port: number;
    nodeEnv: string;
    localDevMode: boolean;
    jwt: {
        secret: string;
    };
    corsOrigins: string[];
    redis: {
        url: string;
    };
    services: {
        auth: string;
        user: string;
        booking: string;
        matching: string;
        notification: string;
        sos: string;
    };
    rateLimiting: {
        general: {
            windowMs: number;
            max: number;
        };
        auth: {
            windowMs: number;
            max: number;
        };
        authenticated: {
            windowMs: number;
            max: number;
        };
        sos: {
            windowMs: number;
            max: number;
        };
    };
    logging: {
        format: string;
    };
    serviceKey: string;
};
//# sourceMappingURL=index.d.ts.map