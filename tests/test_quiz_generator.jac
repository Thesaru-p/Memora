"""Tests for deterministic grounded quiz generation."""

import from backend.agents.quiz_generator { generate_grounded_question, generate_micro_quiz_items }

test "seeded concept generates a grounded question" {
    question = generate_grounded_question(
        "quiz_1",
        "c_cidr_notation",
        "CIDR Notation"
    );
    assert question.id == "quiz_1_c_cidr_notation";
    assert question.correct_answer == "255.255.240.0";
    assert question.options[0] == question.correct_answer;
    assert question.time_limit_seconds == 45;
}

test "unknown concept uses stored summary as the answer" {
    question = generate_grounded_question(
        "quiz_2",
        "c_custom",
        "Custom Concept",
        "A concept summary from lecture notes."
    );
    assert question.correct_answer == "A concept summary from lecture notes.";
    assert question.options[0] == question.correct_answer;
}

test "formula is used when summary is unavailable" {
    question = generate_grounded_question(
        "quiz_3",
        "c_formula",
        "Formula Concept",
        "",
        "R = exp(-t / S)"
    );
    assert question.correct_answer == "R = exp(-t / S)";
}

test "micro quiz creates one question per concept" {
    questions = generate_micro_quiz_items(
        "quiz_4",
        ["c1", "c2", "c3"],
        ["Concept 1", "Concept 2", "Concept 3"]
    );
    assert len(questions) == 3;
    assert questions[0].concept_id == "c1";
    assert questions[2].concept_id == "c3";
}

test "micro quiz is capped at five questions" {
    questions = generate_micro_quiz_items(
        "quiz_5",
        ["c1", "c2", "c3", "c4", "c5", "c6"],
        ["1", "2", "3", "4", "5", "6"]
    );
    assert len(questions) == 5;
}
