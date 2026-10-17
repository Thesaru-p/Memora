# Quiz Planner Agent (Dev 3 Domain)
# Traverses persistent ConceptNodes, computes retrievability decay,
# and selects high-priority fading concepts for the 3-4 minute quiz.

import time;
import from backend.graph { SubjectNode, ConceptNode }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }
import from backend.agents.quiz_priority { concept_priority }

walker plan_quiz {
    has subject_name: str = "Computer Networks";
    has target_concepts: list[ConceptNode] = [];
    has quiz_id: str = "";

    can inspect_concepts with SubjectNode entry {
        now: float = time.time();
        
        # Traverse connected concept nodes
        visit [-->];
    }

    can filter_concept with ConceptNode entry {
        now: float = time.time();
        if here.last_reviewed <= 0.0 {
            here.retrievability = 1.0;
            here.status = "NEW";
        } else {
            days_elapsed: float = (now - here.last_reviewed) / 86400.0;

            # Calculate real-time decay.
            here.retrievability = calc_retrievability(here.stability, days_elapsed);
            here.status = classify_retention_status(here.retrievability);
        }

        # Prioritize concepts that have dropped below 85% or are NEW
        if here.retrievability < 0.85 or here.status == "NEW" or here.status == "CRITICAL" or (here.next_review_due > 0.0 and now >= here.next_review_due) {
            self.target_concepts.append(here);
        }
    }

    can finalize with Root exit {
        now: float = time.time();
        self.quiz_id = f"quiz_{int(now)}";

        # Select the most urgent concepts first, capped at five concepts.
        selected_ids: list[str] = [];
        selected_names: list[str] = [];
        selected_count: int = 0;
        while selected_count < 5 and selected_count < len(self.target_concepts) {
            best_index: int = -1;
            best_score: float = -1.0;
            candidate_index: int = 0;

            for c in self.target_concepts {
                selected_match: int = 0;
                for selected_id in selected_ids {
                    if selected_id == c.id {
                        selected_match = 1;
                    }
                }

                if selected_match == 0 {
                    score = concept_priority(c.status, c.retrievability, c.next_review_due, now);
                    if score > best_score {
                        best_score = score;
                        best_index = candidate_index;
                    }
                }
                candidate_index += 1;
            }

            if best_index < 0 {
                break;
            }

            best_concept = self.target_concepts[best_index];
            selected_ids.append(best_concept.id);
            selected_names.append(best_concept.name);
            selected_count += 1;
        }

        report {
            "quiz_id": self.quiz_id,
            "target_concept_ids": selected_ids,
            "target_concept_names": selected_names,
            "duration_seconds": selected_count * 45,
            "estimated_duration_minutes": 3,
            "scheduled_time": now
        };
    }
}
