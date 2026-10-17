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
    try {
      return await callWalker<QuizPayload>('get_quiz', { subject_name: subjectName });
    } catch {
      return {
        quiz_id: 'quiz_demo',
        subject: subjectName,
        duration_minutes: 3,
        total_questions: 4,
        questions: [
          {
            id: 'q1',
            concept_id: 'c_ip_addressing_and_subnetting',
            concept_name: 'IP Addressing & Subnetting',
            prompt: 'A subnet has a /28 prefix length. How many usable host IP addresses are available in this subnet?',
            options: ['14 usable hosts', '16 usable hosts', '30 usable hosts', '32 usable hosts'],
            correct_answer: '14 usable hosts',
            explanation: 'A /28 leaves 4 host bits (32 - 28 = 4). Total addresses = 2^4 = 16. Subtracting 2 gives 14 usable hosts.',
            time_limit_seconds: 45,
          },
          {
            id: 'q2',
            concept_id: 'c_cidr_notation',
            concept_name: 'CIDR Notation',
            prompt: 'Which of the following subnet masks is equivalent to /20 prefix notation?',
            options: ['255.255.240.0', '255.255.255.0', '255.255.224.0', '255.240.0.0'],
            correct_answer: '255.255.240.0',
            explanation: '/20 has 4 bits in 3rd octet (128+64+32+16 = 240), yielding 255.255.240.0.',
            time_limit_seconds: 45,
          },
          {
            id: 'q3',
            concept_id: 'c_subnet_masks_and_anding',
            concept_name: 'Subnet Masks & ANDing',
            prompt: 'What is the result of performing a bitwise logical AND between IP 192.168.1.75 and Subnet Mask 255.255.255.0?',
            options: ['192.168.1.0', '192.168.1.75', '192.168.0.0', '255.255.255.0'],
            correct_answer: '192.168.1.0',
            explanation: 'Bitwise AND preserves the network portion matching the mask\'s 1-bits and zeroes out host bits (75 & 0 = 0).',
            time_limit_seconds: 45,
          },
          {
            id: 'q4',
            concept_id: 'c_default_gateway',
            concept_name: 'Default Gateway',
            prompt: 'When a host needs to transmit a packet to a destination IP on a different subnet, where does it forward the packet?',
            options: ['To the Default Gateway', 'To the Broadcast Address', 'To the DNS Server', 'Directly to the destination host via ARP'],
            correct_answer: 'To the Default Gateway',
            explanation: 'Cross-subnet traffic cannot be resolved locally via ARP and must be forwarded to the Default Gateway interface.',
            time_limit_seconds: 45,
          },
        ],
      };
    }
  },

  // 4. Submit student answers and recalibrate
  async submitQuiz(quizId: string, submissions: StudentSubmissionItem[]): Promise<QuizEvaluationResult> {
    try {
      return await callWalker<QuizEvaluationResult>('submit_quiz', {
        quiz_id: quizId,
        submissions: submissions,
      });
    } catch {
      let correctCount = 0;
      const missed: any[] = [];
      submissions.forEach((s) => {
        if (s.submitted_answer.trim().toLowerCase() === s.correct_answer.trim().toLowerCase()) {
          correctCount += 1;
        } else {
          missed.push({
            question_id: s.question_id,
            concept_id: s.concept_id,
            your_answer: s.submitted_answer,
            correct_answer: s.correct_answer,
            pedagogical_explanation: s.explanation,
          });
        }
      });

      return {
        quiz_id: quizId,
        total_items: submissions.length,
        correct_items: correctCount,
        score: correctCount / (submissions.length || 1),
        accuracy_pct: (correctCount / (submissions.length || 1)) * 100,
        missed_explanations: missed,
        recalibrated_concepts: [
          {
            concept_id: 'c_ip_addressing_and_subnetting',
            name: 'IP Addressing & Subnetting',
            new_stability_days: 2.8,
            next_review_in_days: 3.2,
            mastery_score: 0.85,
            status: 'STRONG',
          },
        ],
      };
    }
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
  async getNotifications(subjectName: string = 'Computer Networks'): Promise<AppNotification[]> {
    try {
      const data = await callWalker<{ notifications: AppNotification[] }>('get_notifications', { subject_name: subjectName });
      return data.notifications || [];
    } catch {
      return [
        {
          id: 'n1',
          type: 'DAY_1_EBBINGHAUS_ALERT',
          title: 'Protect Your Memory Curve!',
          message: 'It has been ~24 hours since your Subnetting lecture. Take a quick 3-min quiz to stop the 50% forgetting cliff!',
          urgency: 'HIGH',
          estimated_minutes: 3,
          due_time: Date.now(),
        },
        {
          id: 'n2',
          type: 'STREAK_ACTIVE',
          title: 'Study Streak: 3 Days!',
          message: 'Great consistency! Micro-reviews save ~4 hours of last-minute cramming per exam.',
          urgency: 'INFO',
          due_time: Date.now(),
        },
      ];
    }
  },
};
