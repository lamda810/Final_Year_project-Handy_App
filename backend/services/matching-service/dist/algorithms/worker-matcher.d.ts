export interface WorkerMatchCriteria {
    serviceCategory: string;
    location: {
        lat: number;
        lng: number;
    };
    scheduledDateTime: Date;
    isUrgent: boolean;
    problemComplexity?: 'LOW' | 'MEDIUM' | 'HIGH';
    urgencyLevel?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL_SOS';
}
export interface MatchedWorker {
    workerId: string;
    name: string;
    profileImage?: string;
    rating: {
        average: number;
        count: number;
    };
    trustScore: number;
    distance: number;
    estimatedArrival: number;
    matchScore: number;
    hourlyRate: number;
    experience: number;
}
/**
 * Find and rank workers based on matching criteria
 */
export declare const findMatchingWorkers: (criteria: WorkerMatchCriteria) => Promise<{
    workers: MatchedWorker[];
    totalAvailable: number;
}>;
/**
 * Auto-replace worker for a booking
 */
export declare const findReplacementWorker: (bookingId: string, excludeWorkerIds: string[]) => Promise<{
    newWorkerId: string | null;
    success: boolean;
}>;
declare const _default: {
    findMatchingWorkers: (criteria: WorkerMatchCriteria) => Promise<{
        workers: MatchedWorker[];
        totalAvailable: number;
    }>;
    findReplacementWorker: (bookingId: string, excludeWorkerIds: string[]) => Promise<{
        newWorkerId: string | null;
        success: boolean;
    }>;
};
export default _default;
//# sourceMappingURL=worker-matcher.d.ts.map