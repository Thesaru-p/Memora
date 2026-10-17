"""Read review alerts from persisted concept due times."""
import time;
import json;
import from backend.graph { SubjectNode, LectureNode, ConceptNode }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }
import from backend.config { query_openrouter, MODEL_FAST }

def notification_copy(subject: str, topic: str) -> dict {
    fallback = {"title": "Time to review", "message": f"{topic} in {subject} is ready for a 3-minute review."};
    raw = query_openrouter(MODEL_FAST,
        "Write a brief, truthful study reminder. Return only JSON with title and message.",
        f"Subject: {subject}\nDue concept: {topic}");
    if raw {
        try {
            parsed = json.loads(raw);
            if isinstance(parsed, dict) and isinstance(parsed.get("title"), str) and isinstance(parsed.get("message"), str) and parsed["title"].strip() and parsed["message"].strip() {
                return {"title": parsed["title"], "message": parsed["message"]};
            }
        } except Exception {
            raw = "";
        }
    }
    return fallback;
}

walker:pub get_notifications {
    has subject_name: str = "Computer Networks";
    has alerts: list[dict] = [];

    can check_schedule with Root entry {
        subject = None;
        for child in [root-->] {
            if isinstance(child, SubjectNode) and child.name.strip().lower() == self.subject_name.strip().lower() {
                subject = child;
                break;
            }
        }
        if subject is None {
            report {"status": "error", "error": "Subject not found.", "notifications": [], "total_pending": 0};
            return;
        }
        now = time.time();
        due: list[dict] = [];
        for lecture in [subject-->] {
            if isinstance(lecture, LectureNode) {
                for concept in [lecture-->] {
                    if isinstance(concept, ConceptNode) and concept.subject_id == subject.id {
                        concept.retrievability = calc_retrievability(concept.stability, (now - concept.last_reviewed) / 86400.0);
                        concept.status = "NEW" if concept.review_count == 0 else classify_retention_status(concept.retrievability);
                        if (concept.next_review_due > 0.0 and concept.next_review_due <= now) or concept.retrievability < 0.6 {
                            due.append({"id": concept.id, "name": concept.name, "due_time": concept.next_review_due,
                                "retention": concept.retrievability});
                        }
                    }
                }
            }
        }
        for item in due {
            copy = notification_copy(subject.name, str(item["name"]));
            self.alerts.append({
                "id": f"review_{subject.id}_{item['id']}_{int(item['due_time'])}",
                "type": "REVIEW_DUE", "subject": subject.name,
                "concept_ids": [item["id"]], "title": copy["title"], "message": copy["message"],
                "urgency": "HIGH" if item["retention"] < 0.6 else "WARN",
                "estimated_minutes": 3, "due_time": item["due_time"]
            });
        }
        report {"status": "success", "notifications": self.alerts, "total_pending": len(self.alerts)};
    }
}
