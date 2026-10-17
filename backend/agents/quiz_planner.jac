# Quiz Planner Agent (Dev 3 Domain)
# Traverses persistent ConceptNodes, computes retrievability decay,
# and selects high-priority fading concepts for the 3-4 minute quiz.

import time;
import from backend.graph { SubjectNode, ConceptNode, QuizNode }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }

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
        days_elapsed: float = (now - here.last_reviewed) / 86400.0;
        
        # Calculate real-time decay
        here.retrievability = calc_retrievability(here.stability, days_elapsed);
        here.status = classify_retention_status(here.retrievability);

        # Prioritize concepts that have dropped below 85% or are NEW
        if here.retrievability < 0.85 or here.status == "NEW" or here.status == "CRITICAL" {
            self.target_concepts.append(here);
        }
    }

    can finalize with `root exit {
        now: float = time.time();
        self.quiz_id = f"quiz_{int(now)}";

        # Cap selection at 4 concepts for a 3-4 minute micro-quiz
        selected_ids: list[str] = [];
        selected_names: list[str] = [];
        count: int = 0;
        for c in self.target_concepts {
            if count < 4 {
                selected_ids.append(c.id);
                selected_names.append(c.name);
                count += 1;
            }
        }

        report {
            "quiz_id": self.quiz_id,
            "target_concept_ids": selected_ids,
            "target_concept_names": selected_names,
            "estimated_duration_minutes": 3,
            "scheduled_time": now
        };
    }
}
