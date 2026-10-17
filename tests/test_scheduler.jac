"""Tests for due review and notification priority helpers."""

import from backend.agents.notification_core { is_review_due, notification_kind, notification_urgency }

test "future reviews are not due" {
    assert not is_review_due(2000.0, 1000.0);
}

test "past reviews are due" {
    assert is_review_due(900.0, 1000.0);
}

test "zero review timestamp is not due" {
    assert not is_review_due(0.0, 1000.0);
}

test "first review after one day is a day one alert" {
    kind = notification_kind(0, 1000.0, 0.0, 1000.0 + 86400.0);
    assert kind == "DAY_1_EBBINGHAUS_ALERT";
}

test "reviewed concepts use spaced review notification" {
    kind = notification_kind(2, 1000.0, 900.0, 1000.0);
    assert kind == "SPACED_REVIEW_DUE";
}

test "not-yet-due concepts have no notification" {
    kind = notification_kind(1, 1000.0, 2000.0, 1000.0);
    assert kind == "";
}

test "critical concepts receive high urgency" {
    assert notification_urgency("CRITICAL") == "HIGH";
}

test "fading and new concepts receive warning urgency" {
    assert notification_urgency("FADING") == "WARN";
    assert notification_urgency("NEW") == "WARN";
}
