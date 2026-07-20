export interface ProblemAnalysisResult {
    detectedServices: string[];
    confidence: number;
    suggestedQuestions: string[];
    urgencyLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL_SOS';
    matchedKeywords: string[];
    matchedPatterns: string[];
}
/**
 * Analyze problem description to detect services and urgency
 */
export declare const analyzeProblem: (problemDescription: string, providedCategory?: string) => Promise<ProblemAnalysisResult>;
declare const _default: {
    analyzeProblem: (problemDescription: string, providedCategory?: string) => Promise<ProblemAnalysisResult>;
};
export default _default;
//# sourceMappingURL=problem-analyzer.d.ts.map