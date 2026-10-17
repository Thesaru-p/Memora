# Quiz Evaluator & Calibration Agent (Dev 3 Domain)
# Evaluates student submissions, diagnoses misconceptions, and recalibrates memory curve parameters.

import time;
import from backend.graph { ConceptNode }
import from backend.ebbinghaus { update_stability, calc_next_review_days, classify_retention_status }

obj StudentAnswerSubmission {
    has question_id: str;
    has concept_id: str;
    has submitted_answer: str;
    has correct_answer: str;
    has explanation: str;
}

obj EvaluatedQuestionResult {
    has question_id: str;
    has concept_id: str;
    has is_correct: bool;
    has submitted_answer: str;
    has correct_answer: str;
    has explanation: str;
}

walker evaluate_quiz_submission {
    has quiz_id: str;
    has submissions: list[StudentAnswerSubmission];
    
    has total_items: int = 0;
    has correct_items: int = 0;
    has score: float = 0.0;
    has accuracy_pct: float = 0.0;
    has missed_explanations: list[dict] = [];
    has recalibrated_concepts: list[dict] = [];

    can evaluate_all with `root entry {
        now: float = time.time();

        for sub in self.submissions {
            self.total_items += 1;
            is_right: bool = (sub.submitted_answer.strip().lower() == sub.correct_answer.strip().lower());
            if is_right {
                self.correct_items += 1;
            } else {
                self.missed_explanations.append({
                    "question_id": sub.question_id,
                    "concept_id": sub.concept_id,
                    "your_answer": sub.submitted_answer,
                    "correct_answer": sub.correct_answer,
                    "pedagogical_explanation": sub.explanation
                });
            }
        }

        if self.total_items > 0 {
            self.score = float(self.correct_items) / float(self.total_items);
            self.accuracy_pct = self.score * 100.0;
        }

        # Traverse connected concept nodes to recalibrate stability S
        visit [-->];
    }

    can recalibrate with ConceptNode entry {
        now: float = time.time();
        
        # Check if this concept was tested in this quiz
        for sub in self.submissions {
            if sub.concept_id == here.id {
                let_grade: float = 0.0;
                if sub.submitted_answer.strip().lower() == sub.correct_answer.strip().lower() {
                    let_grade = 1.0;
                }
                
                # Recalibrate memory stability
                here.stability = update_stability(here.stability, let_grade, here.retrievability, here.difficulty);
                here.retrievability = 1.0; # Retention refreshed immediately following the quiz!
                here.last_reviewed = now;
                here.review_count += 1;
                here.status = classify_retention_status(here.retrievability);
                
                next_days = calc_next_review_days(here.stability, 0.75);
                here.next_review_due = now + (next_days * 86400.0);

                if let_grade >= 0.7 {
                    if here.mastery_score < 0.75 {
                        here.mastery_score += 0.25;
                    } else {
                        here.mastery_score = 1.0;
                    }
                }

                self.recalibrated_concepts.append({
                    "concept_id": here.id,
                    "name": here.name,
                    "new_stability_days": here.stability,
                    "next_review_in_days": next_days,
                    "mastery_score": here.mastery_score,
                    "status": here.status
                });
            }
        }
    }

    can summarize with `root exit {
        report {
            "quiz_id": self.quiz_id,
            "total_items": self.total_items,
            "correct_items": self.correct_items,
            "score": self.score,
            "accuracy_pct": self.accuracy_pct,
            "missed_explanations": self.missed_explanations,
            "recalibrated_concepts": self.recalibrated_concepts
        };
    }
}
