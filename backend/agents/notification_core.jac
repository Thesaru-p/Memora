# Pure scheduling helpers shared by the notification walker and tests.

def is_review_due(next_review_due: float, now: float) -> bool {
    return next_review_due > 0.0 and next_review_due <= now;
}

def notification_kind(review_count: int, last_reviewed: float, next_review_due: float, now: float) -> str {
    if review_count == 0 and last_reviewed > 0.0 and (now - last_reviewed) >= 86400.0 {
        return "DAY_1_EBBINGHAUS_ALERT";
    }
    if is_review_due(next_review_due, now) {
        return "SPACED_REVIEW_DUE";
    }
    return "";
}

def notification_urgency(status: str) -> str {
    if status == "CRITICAL" {
        return "HIGH";
    }
    if status == "FADING" or status == "NEW" {
        return "WARN";
    }
    return "INFO";
}
