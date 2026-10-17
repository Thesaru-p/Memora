// Client service for interacting with Jac backend walkers
// Configured to connect to Jac server (default localhost:8000 or JacHammer URL)

import {
  DashboardData,
  QuizPayload,
  StudentSubmissionItem,
  QuizEvaluationResult,
  KnowledgeGraphData,
  AnalyticsData,
  AppNotification
} from '../types';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8000';

async function callWalker<T>(walkerName: string, payload: Record<string, any>): Promise<T> {
  try {
    const res = await fetch(`${API_BASE_URL}/walker/${walkerName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      throw new Error(`Walker ${walkerName} failed with status: ${res.status}`);
    }

    const data = await res.json();
    // Jac server responses may expose reports at the top level or under the
    // response envelope's data object.
    const reports = data.reports || data.data?.reports || data.data?.result?.reports;
    if (reports && reports.length > 0) {
      return reports[0] as T;
    }

    return (data.data?.result || data.data || data) as T;
  } catch (err) {
    console.warn(`[API Client] Walker ${walkerName} failed.`, err);
    throw err;
  }
}

export const api = {
  // 1. Fetch Home Dashboard overview
  async getDashboard(subjectName: string): Promise<DashboardData> {
    const result = await callWalker<DashboardData & { status?: string; error?: string }>('get_dashboard', { subject_name: subjectName });
    if (result.status !== 'success') throw new Error(result.error || 'Dashboard data is unavailable.');
    return result;
  },

  // 2. Ingest lecture notes (Text or Slide transcription)
  async ingestLecture(subjectName: string, title: string, notesText: string) {
    const request = callWalker('ingest_lecture', {
      subject_name: subjectName,
      lecture_title: title,
      notes_text: notesText,
    });
    const timeout = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error('Lecture analysis timed out')), 90000);
    });
    return await Promise.race([request, timeout]);
  },

  // 3. Get 3-4 minute micro-quiz
  async getQuiz(subjectName: string): Promise<QuizPayload> {
    const result = await callWalker<QuizPayload>('get_quiz', { subject_name: subjectName });
    if (!result.questions || result.questions.length === 0) {
      throw new Error('No lecture-based AI quiz is available. Upload a lecture first or retry when the model is available.');
    }
    if (result.questions.some((question) => question.generation_source !== 'llm')) {
      throw new Error('The server returned a non-LLM question. Quiz display was blocked.');
    }
    return result;
  },

  // 4. Submit student answers and recalibrate
  async submitQuiz(quizId: string, submissions: StudentSubmissionItem[]): Promise<QuizEvaluationResult> {
    return await callWalker<QuizEvaluationResult>('submit_quiz', {
      quiz_id: quizId,
      submissions: submissions,
    });
  },

  // 5. Get Knowledge Graph Visualizer Data
  async getGraphData(subjectName: string): Promise<KnowledgeGraphData> {
    const result = await callWalker<KnowledgeGraphData & { status?: string; error?: string }>('get_graph_data', { subject_name: subjectName });
    if (result.status !== 'success') throw new Error(result.error || 'Knowledge graph data is unavailable.');
    return result;
  },

  // 6. Get Analytics & Retention Trends
  async getAnalytics(subjectName: string): Promise<AnalyticsData> {
    const result = await callWalker<AnalyticsData & { status?: string; error?: string }>('get_analytics', { subject_name: subjectName });
    if (result.status !== 'success') throw new Error(result.error || 'Analytics are unavailable.');
    return result;
  },

  // 7. Get Notifications & Day-1 Alerts
  async getNotifications(subjectName: string): Promise<AppNotification[]> {
    const data = await callWalker<{ notifications: AppNotification[] }>('get_notifications', { subject_name: subjectName });
    return data.notifications;
  },
};
