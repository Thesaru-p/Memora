// Shared Data Contracts matching Jac Graph and Walker Payloads
// Used by Dev 1 (Frontend Lead)

export type RetentionStatus = 'STRONG' | 'FADING' | 'CRITICAL' | 'NEW';

export interface Concept {
  id: string;
  name: string;
  summary: string;
  formula_or_rule?: string;
  difficulty: number;
  prerequisites: string[];
  stability?: number;
  retrievability?: number;
  mastery_score?: number;
  status?: RetentionStatus;
}

export interface DashboardData {
  subject_name: string;
  code: string;
  overall_retention_pct: number;
  active_concepts_count: number;
  study_streak_days: number;
  next_quiz_due_in_hours: number;
  next_quiz_topic: string;
  pending_quiz_available: boolean;
}

export interface QuizQuestion {
  id: string;
  concept_id: string;
  concept_name: string;
  prompt: string;
  options: string[];
  time_limit_seconds: number;
}

export interface PlannedConcept {
  concept_id: string;
  concept_name: string;
  summary: string;
  retrievability: number;
  status: RetentionStatus;
  selection_reason: string;
}

export interface QuizPayload {
  status: string;
  error?: string;
  quiz_id: string;
  subject: string;
  duration_minutes: number;
  total_questions: number;
  plan: PlannedConcept[];
  questions: QuizQuestion[];
}

export interface StudentSubmissionItem {
  question_id: string;
  submitted_answer: string;
}

export interface MissedExplanation {
  question_id: string;
  concept_id: string;
  your_answer: string;
  correct_answer: string;
  pedagogical_explanation: string;
}

export interface RecalibratedConcept {
  concept_id: string;
  name: string;
  new_stability_days: number;
  next_review_in_days: number;
  mastery_score: number;
  status: RetentionStatus;
}

export interface QuizEvaluationResult {
  status: string;
  error?: string;
  quiz_id: string;
  total_items: number;
  correct_items: number;
  score: number;
  accuracy_pct: number;
  missed_explanations: MissedExplanation[];
  recalibrated_concepts: RecalibratedConcept[];
}

export interface RetentionCurvePoint {
  day: number;
  retention_pct: number;
  event: string;
}

export interface AnalyticsData {
  subject: string;
  retention_curve: RetentionCurvePoint[];
  quiz_history: Array<{
    date: string;
    score: number;
    total: number;
    accuracy_pct: number;
    duration: string;
  }>;
  mastery_distribution: {
    mastered_count: number;
    fading_count: number;
    critical_count: number;
    total_concepts: number;
    overall_subject_retention_pct: number;
  };
  study_streak_days: number;
  hours_saved_vs_cramming: number;
}

export interface GraphNode {
  id: string;
  label: string;
  status: RetentionStatus;
  retention_pct: number;
  mastery_score: number;
  summary: string;
}

export interface GraphEdge {
  source: string;
  target: string;
  type: string;
}

export interface KnowledgeGraphData {
  subject: string;
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface AppNotification {
  id: string;
  type: string;
  subject?: string;
  concept_ids?: string[];
  title: string;
  message: string;
  urgency: 'HIGH' | 'INFO' | 'WARN';
  estimated_minutes?: number;
  due_time: number;
}
