# Pure quiz-priority calculation shared by the planner and its tests.

# Returns a comparable urgency score. Higher scores are selected first.
# Critical concepts outrank fading concepts, and overdue concepts receive
# an additional score based on how long they have been due.
def concept_priority(status: str, retrievability: float, next_review_due: float, now: float) -> float {
    base_score: float = 0.0;

    if status == "CRITICAL" {
        base_score = 300.0;
    } elif status == "NEW" {
        base_score = 250.0;
    } elif status == "FADING" {
        base_score = 200.0;
    } else {
        base_score = 100.0;
    }

    retention_score: float = (1.0 - retrievability) * 100.0;
    overdue_score: float = 0.0;
    if next_review_due > 0.0 and now > next_review_due {
        overdue_score = (now - next_review_due) / 3600.0;
        if overdue_score > 100.0 {
            overdue_score = 100.0;
        }
    }

    return base_score + retention_score + overdue_score;
}
