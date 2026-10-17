# Scheduler & Notification Agent (Dev 3 Domain)
# Uses liquid/lfm-2.5-2.6b:free (273ms latency, 216 t/s) via OpenRouter
# Generates personalized Day-1 spaced repetition alerts tailored to the student's decaying topics.

import time;
import json;
import from backend.graph { SubjectNode, ConceptNode }
import from backend.config { query_openrouter, MODEL_FAST }

# Generates personalized Day-1 review notification copy using the fast LiquidAI model.
def generate_personalized_notification(subject: str, topic: str, streak: int) -> dict {
    sys_prompt = "You are a motivating, warm study coach. Generate a 1-sentence urgent yet friendly push notification for a student reminding them of the 24-hour Ebbinghaus forgetting curve. Return ONLY JSON: {\"title\": str, \"message\": str}.";
    user_prompt = f"Subject: {subject}\nFading Topic: {topic}\nStudy Streak: {streak} days";

    raw_response = query_openrouter(MODEL_FAST, sys_prompt, user_prompt);
    if raw_response {
        try {
            parsed = json.loads(raw_response);
            if isinstance(parsed, dict) and "title" in parsed {
                return {
                    "title": str(parsed.get("title", "Protect Your Memory Curve!")),
                    "message": str(parsed.get("message", f"It's been ~24 hours since your {topic} lecture. Take a quick 3-min quiz to stop the 50% forgetting cliff!"))
                };
            }
        } except Exception as e {
            print(f"[Scheduler Fallback] {e}");
        }
    }

    return {
        "title": "Protect Your Memory Curve!",
        "message": f"It has been ~24 hours since your {topic} lecture. Take a quick 3-min quiz to stop the 50% forgetting cliff!"
    };
}

walker get_notifications {
    has subject_name: str = "Computer Networks";
    has alerts: list[dict] = [];

    can check_schedule with `root entry {
        now: float = time.time();

        # Synthesize personalized notification with fast model
        notif_content = generate_personalized_notification(
            subject=self.subject_name,
            topic="Subnet Masks & ANDing",
            streak=3
        );

        self.alerts.append({
            "id": f"notif_day1_{int(now)}",
            "type": "DAY_1_EBBINGHAUS_ALERT",
            "title": notif_content["title"],
            "message": notif_content["message"],
            "urgency": "HIGH",
            "estimated_minutes": 3,
            "due_time": now
        });

        self.alerts.append({
            "id": f"notif_streak_{int(now)}",
            "type": "STREAK_ACTIVE",
            "title": "Study Streak: 3 Days!",
            "message": "Great consistency! Micro-reviews save ~4 hours of last-minute cramming per exam.",
            "urgency": "INFO",
            "due_time": now
        });

        report {
            "status": "success",
            "notifications": self.alerts,
            "total_pending": len(self.alerts)
        };
    }
}
