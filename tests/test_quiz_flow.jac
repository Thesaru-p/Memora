"""Checks the planner, stored-answer grading, and due reminders."""
import time;
import uuid;
import from backend.graph { SubjectNode, LectureNode, ConceptNode, QuizNode, QuestionNode }
import from backend.agents.quiz_planner { plan_quiz }
import from backend.agents.evaluator { evaluate_quiz_submission, StudentAnswerSubmission }
import from backend.agents.scheduler { get_notifications }
import from main { get_quiz, submit_quiz }

test "planner selects the overdue concept from the requested subject" {
    now = time.time();
    suffix = uuid.uuid4().hex;
    subject = SubjectNode(id=f"s_plan_{suffix}", name=f"Planner Test {suffix}", code="TEST");
    lecture = LectureNode(id=f"l_plan_{suffix}", subject_id=subject.id, title="Review");
    due = ConceptNode(id=f"c_due_{suffix}", subject_id=subject.id, lecture_id=lecture.id,
        name="Due idea", summary="The stored summary", last_reviewed=now - 172800.0,
        next_review_due=now - 10.0, review_count=1);
    fresh = ConceptNode(id=f"c_fresh_{suffix}", subject_id=subject.id, lecture_id=lecture.id,
        name="Fresh idea", summary="Another summary", last_reviewed=now,
        next_review_due=now + 86400.0, review_count=1);
    root ++> subject ++> lecture;
    lecture ++> due;
    lecture ++> fresh;
    plan = root spawn plan_quiz(subject_name=subject.name);
    assert plan.status == "success";
    assert len(plan.selected_concepts) == 1;
    assert plan.selected_concepts[0]["concept_id"] == due.id;
    assert due.retrievability < 0.85;
    assert fresh.retrievability > 0.85;
}

test "stored answer grades once and recalibrates matching concept" {
    now = time.time();
    suffix = uuid.uuid4().hex;
    subject = SubjectNode(id=f"s_grade_{suffix}", name=f"Grading Test {suffix}", code="TEST");
    lecture = LectureNode(id=f"l_grade_{suffix}", subject_id=subject.id, title="Review");
    concept = ConceptNode(id=f"c_grade_{suffix}", subject_id=subject.id, lecture_id=lecture.id,
        name="Recall", summary="Correct fact", last_reviewed=now - 86400.0,
        next_review_due=now - 1.0);
    quiz = QuizNode(id=f"q_grade_{suffix}", subject_id=subject.id, created_at=now);
    question = QuestionNode(id=f"q_grade_{suffix}_1", quiz_id=quiz.id, concept_id=concept.id,
        concept_name=concept.name, prompt="Choose the fact", options=["Correct fact", "Wrong", "No", "Other"],
        correct_answer="Correct fact", explanation="The stored fact is correct.");
    root ++> subject;
    subject ++> lecture ++> concept;
    subject ++> quiz ++> question;
    answers = [StudentAnswerSubmission(question_id=question.id, submitted_answer="Correct fact")];
    first = root spawn evaluate_quiz_submission(quiz_id=quiz.id, submissions=answers);
    assert first.result["status"] == "success";
    assert first.result["correct_items"] == 1;
    assert concept.review_count == 1;
    assert quiz.status == "COMPLETED";
    second = root spawn evaluate_quiz_submission(quiz_id=quiz.id, submissions=answers);
    assert second.result["status"] == "error";
    assert concept.review_count == 1;
}

test "scheduler returns a real overdue concept" {
    now = time.time();
    suffix = uuid.uuid4().hex;
    subject = SubjectNode(id=f"s_alert_{suffix}", name=f"Reminder Test {suffix}", code="TEST");
    lecture = LectureNode(id=f"l_alert_{suffix}", subject_id=subject.id, title="Review");
    concept = ConceptNode(id=f"c_alert_{suffix}", subject_id=subject.id, lecture_id=lecture.id,
        name="Due review", summary="A real topic", last_reviewed=now - 172800.0,
        next_review_due=now - 1.0);
    root ++> subject ++> lecture ++> concept;
    alerts = root spawn get_notifications(subject_name=subject.name);
    assert len(alerts.alerts) == 1;
    assert alerts.alerts[0]["concept_ids"][0] == concept.id;
}

test "public walkers create and grade a persistent quiz" {
    suffix = uuid.uuid4().hex;
    now = time.time();
    subject = SubjectNode(id=f"s_public_{suffix}", name=f"Public Quiz {suffix}", code="TEST");
    lecture = LectureNode(id=f"l_public_{suffix}", subject_id=subject.id, title="Concept");
    concept = ConceptNode(id=f"c_public_{suffix}", subject_id=subject.id, lecture_id=lecture.id,
        name="Axiom", summary="A foundational statement", last_reviewed=now - 86400.0,
        next_review_due=now - 1.0);
    root ++> subject ++> lecture ++> concept;
    result = root spawn get_quiz(subject_name=subject.name);
    assert result.reports[0]["status"] == "success";
    assert "quiz_id" in (result.reports[0] as dict);
    quizzes = [child for child in [subject-->] if isinstance(child, QuizNode)];
    assert len(quizzes) == 1;
    questions = [child for child in [quizzes[0]-->] if isinstance(child, QuestionNode)];
    assert len(questions) == 1;
    assert questions[0].concept_id == concept.id;
    public_question = result.reports[len(result.reports) - 1]["questions"][0] as dict;
    assert "correct_answer" not in public_question;
    submission = root spawn submit_quiz(quiz_id=quizzes[0].id, submissions=[
        {"question_id": questions[0].id, "submitted_answer": questions[0].correct_answer,
         "correct_answer": "forged client answer"}]);
    assert submission.reports[0]["status"] == "success";
    assert quizzes[0].status == "COMPLETED";
    assert quizzes[0].score == 1.0;
}
