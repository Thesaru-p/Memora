// Client service for interacting with Jac backend walkers
// Configured to connect to Jac server (default localhost:8000 or JacHammer URL)

import {
  DashboardData,
  QuizPayload,
  StudentSubmissionItem,
  QuizEvaluationResult,
  KnowledgeGraphData,
  AnalyticsData,
  ReviewSchedule
} from '../types';

declare const process: { env: { EXPO_PUBLIC_API_URL?: string } };

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

    const envelope = await res.json();
    const data = envelope.data ?? envelope;
    if (data.reports && data.reports.length > 0) {
      return data.reports[data.reports.length - 1] as T;
    }
    return data as T;
  } catch (err) {
    console.warn(`[API Client] Walker ${walkerName} unavailable.`, err);
    throw err;
  }
}

export const api = {
  // 1. Fetch Home Dashboard overview
  async getDashboard(subjectName: string = 'Computer Networks'): Promise<DashboardData> {
    return callWalker<DashboardData>('get_dashboard', { subject_name: subjectName });
  },

  // 2. Ingest lecture notes (Text or Slide transcription)
  async ingestLecture(
    subjectName: string,
    title: string,
    notesText: string,
    options?: {
      replaceExisting?: boolean;
      imageB64?: string;
      imagesB64?: string[];
    }
  ) {
    const result: any = await callWalker('ingest_lecture', {
        subject_name: subjectName,
        lecture_title: title,
        notes_text: notesText,
        replace_existing: options?.replaceExisting ?? false,
        image_b64: options?.imageB64 ?? '',
        images_b64: options?.imagesB64 ?? [],
      });
    if (result?.status !== 'success') {
      throw new Error(result?.error || 'Lecture ingestion failed.');
    }
    return result;
  },

  // 3. Get 3-4 minute micro-quiz
  async getQuiz(subjectName: string = 'Computer Networks'): Promise<QuizPayload> {
    const result = await callWalker<QuizPayload>('get_quiz', { subject_name: subjectName });
    if (result.status !== 'success') throw new Error(result.error || 'Quiz unavailable');
    return result;
  },

  // 4. Submit student answers and recalibrate
  async submitQuiz(quizId: string, submissions: StudentSubmissionItem[], durationSeconds = 0): Promise<QuizEvaluationResult> {
    const result = await callWalker<QuizEvaluationResult>('submit_quiz', {
      quiz_id: quizId,
      submissions,
      duration_seconds: durationSeconds,
    });
    if (result.status !== 'success') throw new Error(result.error || 'Quiz submission failed');
    return result;
  },

  // 5. Get Knowledge Graph Visualizer Data
  async getGraphData(subjectName: string = 'Computer Networks'): Promise<KnowledgeGraphData> {
    return callWalker<KnowledgeGraphData>('get_graph_data', { subject_name: subjectName });
  },

  // 6. Get Analytics & Retention Trends
  async getAnalytics(subjectName: string = 'Computer Networks'): Promise<AnalyticsData> {
    try {
      return await callWalker<AnalyticsData>('get_analytics', { subject_name: subjectName });
    } catch {
      return {
        subject: subjectName,
        retention_curve: [
          { day: 0.0, retention_pct: 100.0, event: 'Lecture: Subnetting & CIDR' },
          { day: 0.5, retention_pct: 68.0, event: '' },
          { day: 1.0, retention_pct: 42.0, event: 'Day 1 Forgetting Cliff' },
          { day: 1.05, retention_pct: 94.0, event: 'Completed 3-min Micro-Quiz 1' },
          { day: 2.0, retention_pct: 82.0, event: '' },
          { day: 3.0, retention_pct: 65.0, event: 'Review Window' },
          { day: 3.05, retention_pct: 96.0, event: 'Completed 3-min Micro-Quiz 2' },
          { day: 5.0, retention_pct: 89.0, event: 'Flattened Retention Curve' },
        ],
        quiz_history: [
          { date: 'Day 1', score: 3, total: 4, accuracy_pct: 75.0, duration: '3m 12s' },
          { date: 'Day 3', score: 4, total: 4, accuracy_pct: 100.0, duration: '2m 45s' },
        ],
        mastery_distribution: {
          mastered_count: 3,
          fading_count: 1,
          critical_count: 0,
          total_concepts: 4,
          overall_subject_retention_pct: 84.5,
        },
        study_streak_days: 3,
        hours_saved_vs_cramming: 4.5,
      };
    }
  },

  // 7. Get Notifications & Day-1 Alerts
  async getNotifications(subjectName: string = 'Computer Networks'): Promise<ReviewSchedule> {
    const data = await callWalker<ReviewSchedule & { status: string; error?: string }>('get_notifications', { subject_name: subjectName });
    if (data.status !== 'success') throw new Error(data.error || 'Notifications unavailable');
    return { notifications: data.notifications || [], next_review: data.next_review || null };
  },
};
