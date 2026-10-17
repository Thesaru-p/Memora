"""Tests for quiz grading and mastery helpers."""

import from backend.agents.evaluator_core { normalize_answer, answers_match, calculate_score, update_mastery }

test "answers are normalized before comparison" {
    assert normalize_answer("  Correct Answer ") == "correct answer";
    assert answers_match("  Correct Answer ", "correct answer");
}

test "different answers are rejected" {
    assert not answers_match("wrong", "correct");
    assert not answers_match("", "correct");
}

test "score is zero for an empty submission" {
    assert calculate_score(0, 0) == 0.0;
}

test "score is calculated as a fraction" {
    score = calculate_score(3, 4);
    assert score > 0.74 and score < 0.76;
}

test "correct answers increase mastery by a quarter" {
    assert update_mastery(0.0, True) == 0.25;
    assert update_mastery(0.5, True) == 0.75;
}

test "mastery caps at one" {
    assert update_mastery(0.75, True) == 1.0;
    assert update_mastery(1.5, True) == 1.0;
}

test "incorrect answers preserve mastery" {
    assert update_mastery(0.6, False) == 0.6;
}
