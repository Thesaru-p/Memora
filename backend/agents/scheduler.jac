# Scheduler & Notification Agent (Dev 3 Domain)
# Dispatches Day-1 (24h) alerts and spaced repetition reminders.

import time;
import from backend.graph { SubjectNode, ConceptNode }
import from backend.ebbinghaus { calc_retrievability }
import from backend.agents.notification_core { notification_kind, notification_urgency }

walker get_notifications {
    has subject_name: str = "Computer Networks";
    has alerts: list[dict] = [];

    can check_schedule with Root entry {
        now: float = time.time();
        visit [-->];
        report {
            "status": "success",
            "notifications": self.alerts,
            "total_pending": len(self.alerts)
        };
    }

    can inspect_concept with ConceptNode entry {
        now: float = time.time();
        kind = notification_kind(here.review_count, here.last_reviewed, here.next_review_due, now);

        if kind != "" {
            title: str = "Review your memory";
            message: str = "A concept is ready for a focused 3-minute recall quiz.";
            if kind == "DAY_1_EBBINGHAUS_ALERT" {
                title = "Protect Your Memory Curve!";
                message = "It has been about 24 hours since this lecture. Take a quick quiz before the forgetting cliff.";
            }

            self.alerts.append({
                "id": f"notif_{here.id}_{kind}",
                "type": kind,
                "title": title,
                "message": message,
                "urgency": notification_urgency(here.status),
                "estimated_minutes": 3,
                "due_time": here.next_review_due
            });
        }
    }

}
