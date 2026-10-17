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
    has replace_existing: bool = False;
    has created_nodes_count: int = 0;
    has total_lecture_concepts: int = 0;
    has result: dict = {};

    can construct with Root entry {
        now: float = time.time();
        clean_subject: str = self.subject_name.strip();
        clean_title: str = self.lecture_title.strip();
        subject_id: str = f"subj_{clean_subject.lower().replace(' ', '_')}";

        # 1. Find and reuse existing Subject Node by subject_id, or create if not present
        subject = SubjectNode(
            id=subject_id,
            name=clean_subject,
            code="CS-301",
            description=f"Course module for {clean_subject}",
            created_at=now
        );
        found_subject = False;
        for child in [root-->] {
            if isinstance(child, SubjectNode) and child.id == subject_id {
                subject = child;
                found_subject = True;
                break;
            }
        }
        if not found_subject {
            root ++> subject;
        }

        # 2. Find and reuse existing Lecture Node under subject, or create new
        lecture = LectureNode(
            id=f"lec_{int(now)}",
            subject_id=subject.id,
            title=clean_title,
            raw_notes=self.raw_notes,
            summary=f"Lecture notes on {clean_title}",
            timestamp=now,
            concept_count=len(self.concepts)
        );
        found_lecture = False;
        for child in [subject-->] {
            if isinstance(child, LectureNode) and child.title.strip().lower() == clean_title.lower() {
                lecture = child;
                found_lecture = True;
                break;
            }
        }

        if found_lecture and self.replace_existing {
            # Clear previous concept nodes under this lecture for a fresh replace
            old_concepts: list[ConceptNode] = [];
            for child in [lecture-->] {
                if isinstance(child, ConceptNode) {
                    old_concepts.append(child);
                }
            }
            for old_c in old_concepts {
                del old_c;
            }
        }

        if not found_lecture {
            lecture_id = f"lec_{int(now)}";
            existing_lecture_ids: list[str] = [];
            for child in [subject-->] {
                if isinstance(child, LectureNode) {
                    existing_lecture_ids.append(child.id);
                }
            }
            if lecture_id in existing_lecture_ids {
                counter = 1;
                while f"{lecture_id}_{counter}" in existing_lecture_ids {
                    counter += 1;
                }
                lecture_id = f"{lecture_id}_{counter}";
            }
            lecture.id = lecture_id;
            subject ++> lecture;
        } else {
            if self.raw_notes {
                lecture.raw_notes = self.raw_notes;
            }
            lecture.timestamp = now;
        }

        lecture_id = lecture.id;

        # 3. Create or update Concept Nodes under the lecture with lecture-scoped IDs
        existing_concept_map: dict[str, ConceptNode] = {};
        for child in [lecture-->] {
            if isinstance(child, ConceptNode) {
                existing_concept_map[child.name.strip().lower()] = child;
            }
        }

        created_concepts: list[ConceptNode] = [];
        for raw in self.concepts {
            raw_key: str = raw.name.strip().lower();
            if raw_key in existing_concept_map {
                c_node = existing_concept_map[raw_key];
                c_node.summary = raw.summary;
                c_node.formula_or_rule = raw.formula_or_rule;
                c_node.difficulty = raw.difficulty;
                created_concepts.append(c_node);
            } else {
                slug_raw: str = raw.name.lower().strip().replace(" ", "_").replace("&", "and").replace("-", "_");
                cleaned_slug: str = "";
                for ch in slug_raw {
                    if ch.isalnum() or ch == "_" {
                        cleaned_slug = f"{cleaned_slug}{ch}";
                    } else {
                        cleaned_slug = f"{cleaned_slug}_";
                    }
                }
                while "__" in cleaned_slug {
                    cleaned_slug = cleaned_slug.replace("__", "_");
                }
                cleaned_slug = cleaned_slug.strip("_");

                concept_id: str = f"c_{lecture_id}_{cleaned_slug}";
                c_node = ConceptNode(
                    id=concept_id,
                    subject_id=subject.id,
                    lecture_id=lecture_id,
                    name=raw.name.strip(),
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
                existing_concept_map[raw_key] = c_node;
                self.created_nodes_count += 1;
            }
        }

        # Collect all concepts across this subject for prerequisite resolution
        all_subject_concepts: list[ConceptNode] = [];
        for lec_node in [subject-->] {
            if isinstance(lec_node, LectureNode) {
                for cn in [lec_node-->] {
                    if isinstance(cn, ConceptNode) {
                        all_subject_concepts.append(cn);
                    }
                }
            }
        }

        # 4. Link prerequisite edges between concepts (+>:depends_on:+>) idempotently
        for c in created_concepts {
            for raw in self.concepts {
                if raw.name.strip().lower() == c.name.strip().lower() {
                    for prereq_name in raw.prerequisites {
                        clean_prereq: str = prereq_name.strip().lower();
                        linked = False;
                        for other in created_concepts {
                            if other.name.strip().lower() == clean_prereq {
                                existing_prereqs = [c->:depends_on:->];
                                already_linked = False;
                                for p in existing_prereqs {
                                    if p.id == other.id {
                                        already_linked = True;
                                        break;
                                    }
                                }
                                if not already_linked {
                                    c +>:depends_on:+> other;
                                }
                                linked = True;
                                break;
                            }
                        }
                        if not linked {
                            for other in all_subject_concepts {
                                if other.name.strip().lower() == clean_prereq {
                                    existing_prereqs = [c->:depends_on:->];
                                    already_linked = False;
                                    for p in existing_prereqs {
                                        if p.id == other.id {
                                            already_linked = True;
                                            break;
                                        }
                                    }
                                    if not already_linked {
                                        c +>:depends_on:+> other;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        # Update total concept count on lecture node
        total_concepts: int = 0;
        for child in [lecture-->] {
            if isinstance(child, ConceptNode) {
                total_concepts += 1;
            }
        }
        lecture.concept_count = total_concepts;
        self.total_lecture_concepts = total_concepts;

        self.result = {
            "status": "success",
            "subject_id": subject.id,
            "lecture_id": lecture_id,
            "nodes_created": self.created_nodes_count,
            "total_lecture_concepts": total_concepts,
            "mode": "replace" if self.replace_existing else "append"
        };
        report self.result;
    }
}
