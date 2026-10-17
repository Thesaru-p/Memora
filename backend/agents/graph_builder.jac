# Graph Builder Agent (Dev 2 Domain)
# Stitches extracted concepts into the persistent Jac Object-Spatial graph.

import time;
import from backend.graph { SubjectNode, LectureNode, ConceptNode, depends_on, subconcept_of }
import from backend.agents.lecture_analyzer { RawExtractedConcept }

walker build_lecture_graph {
    has subject_name: str;
    has lecture_title: str;
    has raw_notes: str;
    has concepts: list[RawExtractedConcept];
    has created_nodes_count: int = 0;

    can construct with `Root entry {
        now: float = time.time();
        
        # 1. Create or link Subject Node from root
        subject_id: str = f"subj_{self.subject_name.lower().replace(' ', '_')}";
        subject = SubjectNode(
            id=subject_id,
            name=self.subject_name,
            code="CS-301",
            description=f"Course module for {self.subject_name}",
            created_at=now
        );
        root ++> subject;

        # 2. Create Lecture Node
        lecture_id: str = f"lec_{int(now)}";
        num_concepts: int = 0;
        for _ in self.concepts {
            num_concepts += 1;
        }

        lecture = LectureNode(
            id=lecture_id,
            subject_id=subject_id,
            title=self.lecture_title,
            raw_notes=self.raw_notes,
            summary=f"Lecture notes on {self.lecture_title}",
            timestamp=now,
            concept_count=num_concepts
        );
        subject ++> lecture;

        # 3. Create Concept Nodes and link from lecture
        created_concepts: list[ConceptNode] = [];
        for raw in self.concepts {
            concept_id: str = f"c_{raw.name.lower().replace(' ', '_').replace('&', 'and')}";
            c_node = ConceptNode(
                id=concept_id,
                subject_id=subject_id,
                lecture_id=lecture_id,
                name=raw.name,
                summary=raw.summary,
                formula_or_rule=raw.formula_or_rule,
                stability=1.0,          # S0 = 1 day
                difficulty=raw.difficulty,
                retrievability=1.0,     # 100% upon initial learning
                mastery_score=0.1,
                review_count=0,
                last_reviewed=now,
                next_review_due=now + 86400.0, # 24h notification trigger
                status="NEW"
            );
            lecture ++> c_node;
            created_concepts.append(c_node);
            self.created_nodes_count += 1;
        }

        # 4. Link prerequisite edges between concepts (+>:depends_on:+>)
        for c in created_concepts {
            for raw in self.concepts {
                if raw.name == c.name {
                    for prereq_name in raw.prerequisites {
                        for other in created_concepts {
                            if other.name == prereq_name {
                                c +>:depends_on:+> other;
                            }
                        }
                    }
                }
            }
        }

        report {
            "status": "success",
            "subject_id": subject_id,
            "lecture_id": lecture_id,
            "nodes_created": self.created_nodes_count
        };
    }
}
