"""Unit Tests for Ebbinghaus Memory Decay Engine."""

import from backend.ebbinghaus {
    calc_retrievability,
    update_stability,
    calc_next_review_days,
    classify_retention_status
}

test "initial retention is 100 percent" {
    r = calc_retrievability(stability=1.0, days_elapsed=0.0);
    assert r == 1.0;
}

test "day 1 forgetting cliff decays to ~37 percent" {
    r = calc_retrievability(stability=1.0, days_elapsed=1.0);
    assert r > 0.35 and r < 0.40;
}

test "future elapsed time never produces more than full retention" {
    r = calc_retrievability(stability=10.0, days_elapsed=-2.0);
    assert r == 1.0;
}

test "invalid stability returns safe minimum retention" {
    r = calc_retrievability(stability=0.0, days_elapsed=1.0);
    assert r == 0.0;
}

test "very old memories are clamped to the minimum tracked retention" {
    r = calc_retrievability(stability=1.0, days_elapsed=100.0);
    assert r == 0.01;
}

test "successful recall increases stability" {
    initial_s = 1.0;
    new_s = update_stability(curr_stability=initial_s, grade=1.0, curr_retrievability=0.5);
    assert new_s > initial_s * 1.5;
}

test "failed recall reduces stability" {
    initial_s = 4.0;
    new_s = update_stability(curr_stability=initial_s, grade=0.2, curr_retrievability=0.3);
    assert new_s < initial_s;
}

test "out of range grades are safely clamped" {
    high_grade_s = update_stability(curr_stability=2.0, grade=2.0, curr_retrievability=0.5);
    perfect_s = update_stability(curr_stability=2.0, grade=1.0, curr_retrievability=0.5);
    low_grade_s = update_stability(curr_stability=2.0, grade=-1.0, curr_retrievability=0.5);
    failed_s = update_stability(curr_stability=2.0, grade=0.0, curr_retrievability=0.5);
    assert high_grade_s == perfect_s;
    assert low_grade_s == failed_s;
}

test "failed recall never reduces stability below one day" {
    new_s = update_stability(curr_stability=0.6, grade=0.0, curr_retrievability=0.1);
    assert new_s == 1.0;
}

test "next review interval respects target retention" {
    days = calc_next_review_days(stability=1.0, target_retention=0.75);
    assert days == 0.5;
}

test "invalid target retention uses the default target" {
    default_days = calc_next_review_days(stability=2.0, target_retention=0.75);
    invalid_days = calc_next_review_days(stability=2.0, target_retention=1.0);
    assert default_days == invalid_days;
}

test "retention status classification tags correctly" {
    assert classify_retention_status(0.90) == "STRONG";
    assert classify_retention_status(0.70) == "FADING";
    assert classify_retention_status(0.40) == "CRITICAL";
}
