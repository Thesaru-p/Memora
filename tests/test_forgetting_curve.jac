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

test "retention status classification tags correctly" {
    assert classify_retention_status(0.90) == "STRONG";
    assert classify_retention_status(0.70) == "FADING";
    assert classify_retention_status(0.40) == "CRITICAL";
}
