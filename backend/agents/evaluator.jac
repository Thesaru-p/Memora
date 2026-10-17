"""Grade persisted quiz questions and update memory state once."""
import time;
import json;
import from backend.graph { SubjectNode, LectureNode, ConceptNode, QuizNode, QuestionNode }
import from backend.ebbinghaus { update_stability, calc_next_review_days, classify_retention_status, calc_retrievability }
import from backend.config { query_openrouter, MODEL_EVALUATOR }

obj StudentAnswerSubmission {
    has question_id: str;
    has submitted_answer: str;
}

def semantically_evaluate_answer(question_prompt: str, student_answer: str, correct_answer: str, default_explanation: str) -> dict {
    if not student_answer.strip() {
        return {"is_correct": False, "explanation": default_explanation};
    }
    raw = query_openrouter(MODEL_EVALUATOR,
        "Grade a short answer. Return ONLY JSON with is_correct (boolean) and explanation (one sentence).",
        f"Question: {question_prompt}\nExpected answer: {correct_answer}\nStudent answer: {student_answer}");
    if raw {
        try {
            parsed = json.loads(raw);
            if isinstance(parsed, dict) and isinstance(parsed.get("is_correct"), bool) and isinstance(parsed.get("explanation"), str) {
                return {"is_correct": parsed["is_correct"], "explanation": parsed["explanation"]};
            }
        } except Exception {
            raw = "";
        }
    }
    return {"is_correct": student_answer.strip().lower() == correct_answer.strip().lower(), "explanation": default_explanation};
}

walker evaluate_quiz_submission {
    has quiz_id: str;
    has submissions: list[StudentAnswerSubmission];
    has duration_seconds: int = 0;
    has result: dict = {};

    can evaluate with Root entry {
        quiz = QuizNode(id="", subject_id="");
        subject = SubjectNode(id="", name="", code="");
        for child in [root-->] {
            if isinstance(child, SubjectNode) {
                for candidate in [child-->] {
                    if isinstance(candidate, QuizNode) and candidate.id == self.quiz_id {
                        quiz = candidate;
                        subject = child;
                        break;
                    }
                }
            }
            if quiz.id { break; }
        }
        if not quiz.id {
            self.result = {"status": "error", "error": "Quiz not found."};
            return;
        }
        if quiz.status != "PENDING" {
            self.result = {"status": "error", "error": "Quiz has already been submitted."};
            return;
        }
        questions: list[QuestionNode] = [];
        for child in [quiz-->] {
            if isinstance(child, QuestionNode) { questions.append(child); }
        }
        if len(questions) == 0 or len(self.submissions) != len(questions) {
            self.result = {"status": "error", "error": "Answer every quiz question once."};
            return;
        }
        seen: list[str] = [];
        for sub in self.submissions {
            matched = False;
            for question in questions {
                if question.id == sub.question_id { matched = True; }
            }
            if not matched or sub.question_id in seen {
                self.result = {"status": "error", "error": "Invalid or duplicate question ID."};
                return;
            }
            seen.append(sub.question_id);
        }
        now = time.time();
        correct_count = 0;
        missed: list[dict] = [];
        grades: dict[str, float] = {};
        for question in questions {
            answer = "";
            for sub in self.submissions {
                if sub.question_id == question.id { answer = sub.submitted_answer; }
            }
            if question.question_type == "ACTIVE_RECALL" {
                grade = semantically_evaluate_answer(question.prompt, answer, question.correct_answer, question.explanation);
                correct = bool(grade["is_correct"]);
                explanation = grade["explanation"];
            } else {
                correct = answer.strip().lower() == question.correct_answer.strip().lower() and bool(answer.strip());
                explanation = question.explanation;
            }
            question.student_answer = answer;
            question.is_correct = correct;
            if correct { correct_count += 1; }
            else {
                missed.append({"question_id": question.id, "concept_id": question.concept_id,
                    "your_answer": answer, "correct_answer": question.correct_answer,
                    "pedagogical_explanation": explanation});
            }
            grades[question.concept_id] = 1.0 if correct else 0.0;
        }
        updated: list[dict] = [];
        for lecture in [subject-->] {
            if isinstance(lecture, LectureNode) {
                for concept in [lecture-->] {
                    if isinstance(concept, ConceptNode) and concept.id in grades {
                        elapsed = (now - concept.last_reviewed) / 86400.0;
                        before = calc_retrievability(concept.stability, elapsed);
                        grade_value = grades[concept.id];
                        concept.stability = update_stability(concept.stability, grade_value, before, concept.difficulty);
                        concept.retrievability = 1.0;
                        concept.last_reviewed = now;
                        concept.review_count += 1;
                        concept.mastery_score = min(1.0, max(0.0, concept.mastery_score + (0.25 if grade_value >= 0.7 else -0.1)));
                        concept.status = classify_retention_status(concept.retrievability);
                        next_days = calc_next_review_days(concept.stability, 0.75);
                        concept.next_review_due = now + next_days * 86400.0;
                        updated.append({"concept_id": concept.id, "name": concept.name,
                            "new_stability_days": concept.stability, "next_review_in_days": next_days,
                            "mastery_score": concept.mastery_score, "status": concept.status});
                    }
                }
            }
        }
        quiz.status = "COMPLETED";
        quiz.completed_at = now;
        quiz.duration_seconds = max(0, self.duration_seconds);
        quiz.score = float(correct_count) / float(len(questions));
        quiz.accuracy_pct = quiz.score * 100.0;
        self.result = {"status": "success", "quiz_id": quiz.id, "total_items": len(questions),
            "correct_items": correct_count, "score": quiz.score, "accuracy_pct": quiz.accuracy_pct,
            "missed_explanations": missed, "recalibrated_concepts": updated};
    }
}
