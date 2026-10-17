"""Choose review concepts from the persistent subject graph."""
import time;
import from backend.graph { SubjectNode, LectureNode, ConceptNode }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }

walker plan_quiz {
    has subject_name: str = "Computer Networks";
    has subject_id: str = "";
    has status: str = "error";
    has error: str = "";
    has selected_concepts: list[dict] = [];

    can plan with Root entry {
        now = time.time();
        subject = None;
        for child in [root-->] {
            if isinstance(child, SubjectNode) and child.name.strip().lower() == self.subject_name.strip().lower() {
                subject = child;
                break;
            }
        }
        if subject is None {
            self.error = "Subject not found. Upload lecture notes first.";
            return;
        }
        self.subject_id = subject.id;
        candidates: list[dict] = [];
        for lecture in [subject-->] {
            if isinstance(lecture, LectureNode) {
                for concept in [lecture-->] {
                    if isinstance(concept, ConceptNode) and concept.subject_id == subject.id {
                        elapsed = (now - concept.last_reviewed) / 86400.0;
                        concept.retrievability = calc_retrievability(concept.stability, elapsed);
                        concept.status = "NEW" if concept.review_count == 0 else classify_retention_status(concept.retrievability);
                        overdue = concept.next_review_due > 0.0 and concept.next_review_due <= now;
                        due = overdue or concept.status == "NEW" or concept.retrievability < 0.85;
                        priority = (100 if overdue else 0) + (20 if concept.status == "NEW" else 0) + (1.0 - concept.retrievability) * 10.0 + concept.difficulty / 100.0;
                        candidates.append({
                            "concept_id": concept.id, "concept_name": concept.name,
                            "summary": concept.summary, "formula_or_rule": concept.formula_or_rule,
                            "difficulty": concept.difficulty, "retrievability": concept.retrievability,
                            "status": concept.status,
                            "selection_reason": "Review overdue" if overdue else ("New concept" if concept.status == "NEW" else "Retention fading" if due else "Weakest available concept"),
                            "due": due, "priority": priority
                        });
                    }
                }
            }
        }
        if len(candidates) == 0 {
            self.error = "This subject has no concepts yet. Upload lecture notes first.";
            return;
        }
        any_due = False;
        for candidate in candidates {
            if candidate["due"] { any_due = True; }
        }
        while len(self.selected_concepts) < 4 {
            best: dict = {};
            found_best = False;
            for candidate in candidates {
                already_selected = False;
                for chosen in self.selected_concepts {
                    if chosen["concept_id"] == candidate["concept_id"] { already_selected = True; }
                }
                if not already_selected and (candidate["due"] or not any_due) {
                    if not found_best or candidate["priority"] > best["priority"] or (candidate["priority"] == best["priority"] and candidate["concept_id"] < best["concept_id"]) {
                        best = candidate;
                        found_best = True;
                    }
                }
            }
            if not found_best { break; }
            self.selected_concepts.append(best);
        }
        self.status = "success";
    }
}
