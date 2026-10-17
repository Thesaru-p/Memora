# Quiz Evaluator & Calibration Agent (Dev 3 Domain)
# Evaluates student submissions, diagnoses misconceptions, and recalibrates memory curve parameters.

import from backend.llm_config { evaluator_llm }

import time;
import from backend.graph { ConceptNode }
import from backend.ebbinghaus { update_stability, calc_next_review_days, classify_retention_status }
import from backend.agents.evaluator_core { answers_match, calculate_score, update_mastery }

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

# Uses the reasoning model to turn a wrong answer into a short, useful
# misconception debrief. The stored question explanation remains the fallback.
def explain_misconception_with_llm(submitted_answer: str, correct_answer: str, context: str) -> str by evaluator_llm();
sem explain_misconception_with_llm = "Explain the misconception in one or two friendly sentences. Compare the student's answer with the correct answer, use only the supplied context, and end with one practical memory cue.";

walker evaluate_quiz_submission {
    has quiz_id: str;
    has submissions: list[StudentAnswerSubmission];
    
    has total_items: int = 0;
    has correct_items: int = 0;
    has score: float = 0.0;
    has accuracy_pct: float = 0.0;
    has missed_explanations: list[dict] = [];
    has recalibrated_concepts: list[dict] = [];

    can evaluate_all with `Root entry {
        now: float = time.time();

        for sub in self.submissions {
            self.total_items += 1;
            is_right: bool = answers_match(sub.submitted_answer, sub.correct_answer);
            if is_right {
                self.correct_items += 1;
            } else {
                explanation_text: str = sub.explanation;
                try {
                    explanation_text = explain_misconception_with_llm(
                        sub.submitted_answer,
                        sub.correct_answer,
                        sub.explanation
                    );
                } except Exception {
                    explanation_text = sub.explanation;
                }
                self.missed_explanations.append({
                    "question_id": sub.question_id,
                    "concept_id": sub.concept_id,
                    "your_answer": sub.submitted_answer,
                    "correct_answer": sub.correct_answer,
                    "pedagogical_explanation": explanation_text
                });
            }
        }

        if self.total_items > 0 {
            self.score = calculate_score(self.correct_items, self.total_items);
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
                is_right: bool = answers_match(sub.submitted_answer, sub.correct_answer);
                if is_right {
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
                    here.mastery_score = update_mastery(here.mastery_score, is_right);
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

    can summarize with Root exit {
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
