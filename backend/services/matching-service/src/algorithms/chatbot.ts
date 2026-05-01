import OpenAI from 'openai';
import problemAnalyzer from './problem-analyzer.js';
import pricePredictor from './price-predictor.js';
import { SERVICE_CATEGORIES } from '@handy-go/shared';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || ''
});

export interface ChatbotRequest {
  message: string;
  contextData?: {
    city?: string;
    area?: string;
  };
}

export interface ChatbotResponse {
  message: string;
  detectedService?: string;
  estimatedPrice?: { min: number; max: number };
}

export const processChatMessage = async (data: ChatbotRequest): Promise<ChatbotResponse> => {
  const { message, contextData } = data;

  try {
    // 1. Ask Problem Analyzer to quietly extract service matching
    const problemAnalysis = await problemAnalyzer.analyzeProblem(message);
    const primaryService = problemAnalysis.detectedServices[0] || undefined;

    // 2. Determine base context via AI prompt
    const prompt = `You are a highly helpful, professional Smart Assistant for "Handy-Go", a home services app.
The user sent you a message: "${message}"

Your backend system parsed this and quietly predicts they need the service: ${primaryService || "UNKNOWN"}.
${primaryService ? 'Since we know the category, inform the user you can help them book a ' + primaryService + ' professional immediately.' : 'Politely ask clarifying questions to figure out what service heavily relates to ' + SERVICE_CATEGORIES.join(', ')}

Respond briefly (max 2-3 sentences). Be conversational. You can speak English, Urdu, or Roman Urdu depending on how the user spoke.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }]
    });

    const aiMessage = response.choices[0]?.message?.content || 'I am having trouble connecting. How can I help you?';

    // 3. Optional: Provide Price Estimate natively if actionable
    let estimatedPrice;
    if (primaryService && contextData?.city) {
      const estimate = await pricePredictor.estimatePrice({
        serviceCategory: primaryService,
        problemDescription: message,
        city: contextData.city,
        area: contextData.area
      });
      estimatedPrice = estimate.estimatedPrice;
    }

    return {
      message: aiMessage,
      detectedService: primaryService,
      estimatedPrice
    };
  } catch (error) {
    console.error('Chatbot processing error:', error);
    return {
      message: "Sorry, I am facing technical difficulties right now. Please select a service manually."
    };
  }
};
