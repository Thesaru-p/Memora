"""Tests for retention-based quiz concept prioritization."""

import from backend.agents.quiz_priority { concept_priority }

test "critical concepts outrank fading concepts" {
    critical = concept_priority("CRITICAL", 0.40, 0.0, 1000.0);
    fading = concept_priority("FADING", 0.60, 0.0, 1000.0);
    assert critical > fading;
}

test "new concepts outrank healthy concepts" {
    new_concept = concept_priority("NEW", 1.0, 0.0, 1000.0);
    strong = concept_priority("STRONG", 0.90, 0.0, 1000.0);
    assert new_concept > strong;
}

test "lower retrievability increases urgency within a status" {
    fading_low = concept_priority("FADING", 0.61, 0.0, 1000.0);
    fading_high = concept_priority("FADING", 0.80, 0.0, 1000.0);
    assert fading_low > fading_high;
}

test "overdue concepts receive additional urgency" {
    due = concept_priority("FADING", 0.70, 900.0, 1000.0);
    not_due = concept_priority("FADING", 0.70, 1100.0, 1000.0);
    assert due > not_due;
}

test "overdue urgency is capped" {
    very_overdue = concept_priority("FADING", 0.70, 1.0, 1000000.0);
    capped_overdue = concept_priority("FADING", 0.70, 640000.0, 1000000.0);
    assert very_overdue == capped_overdue;
}
