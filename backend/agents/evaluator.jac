# Quiz Evaluator & Calibration Agent (Dev 3 Domain)
# Uses nvidia/nemotron-3-super:free via OpenRouter for fast, intelligent semantic grading.
# Replaces rigid string comparisons with pedagogical error diagnosis.

import time;
import json;
import from backend.graph { ConceptNode }
import from backend.ebbinghaus { update_stability, calc_next_review_days, classify_retention_status }
import from backend.config { query_openrouter, MODEL_EVALUATOR }

obj StudentAnswerSubmission {
    has question_id: str;
    has concept_id: str;
    has submitted_answer: str;
    has correct_answer: str;
    has explanation: str;
}

# Uses Nemotron 3 Super to semantically evaluate student response, accept synonyms,
# and generate custom diagnostic feedback on mistakes.
def semantically_evaluate_answer(question_prompt: str, student_answer: str, correct_answer: str, default_explanation: str) -> dict {
    sys_prompt = "You are a friendly, encouraging computer science professor grading a student quiz. Accept conceptual equivalents, synonyms, and acronyms (e.g., 'CIDR' equals 'Classless Inter-Domain Routing'). Return ONLY a JSON object with keys: is_correct (bool), score (float between 0.0 and 1.0), and explanation (1-2 sentences explaining why it is correct or diagnosing the student's exact misconception).";
    user_prompt = f"Correct Answer: {correct_answer}\nStudent Answer: {student_answer}\nStandard Explanation: {default_explanation}";

    raw_response = query_openrouter(MODEL_EVALUATOR, sys_prompt, user_prompt);
    if raw_response {
        try {
            parsed = json.loads(raw_response);
            if isinstance(parsed, dict) and "is_correct" in parsed {
                return {
                    "is_correct": bool(parsed.get("is_correct", false)),
                    "score": float(parsed.get("score", 0.0)),
                    "explanation": str(parsed.get("explanation", default_explanation))
                };
            }
        } except Exception as e {
            print(f"[Semantic Evaluator Fallback] {e}");
        }
    }

    # High-accuracy fallback
    is_right: bool = (student_answer.strip().lower() == correct_answer.strip().lower());
    score_val: float = 1.0 if is_right else 0.0;
    return {
        "is_correct": is_right,
        "score": score_val,
        "explanation": default_explanation
    };
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
            
            # Intelligent Semantic Grading with Nemotron 3 Super
            eval_res = semantically_evaluate_answer(
                question_prompt="",
                student_answer=sub.submitted_answer,
                correct_answer=sub.correct_answer,
                default_explanation=sub.explanation
            );

            if eval_res["is_correct"] {
                self.correct_items += 1;
            } else {
                self.missed_explanations.append({
                    "question_id": sub.question_id,
                    "concept_id": sub.concept_id,
                    "your_answer": sub.submitted_answer,
                    "correct_answer": sub.correct_answer,
                    "pedagogical_explanation": eval_res["explanation"]
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
