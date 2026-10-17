# Memora - Main Entrypoint & Public Walker Endpoints
# Exposes clean REST APIs for the React Native Mobile App and JacHammer Cloud.

import base64;
import time;
import uuid;
import from backend.config { openrouter_status }
import from backend.graph { SubjectNode, LectureNode, ConceptNode, QuizNode, QuestionNode, depends_on }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }
import from backend.agents.lecture_analyzer {
    extract_concepts_from_text,
    RawExtractedConcept
}
import from backend.agents.graph_builder { build_lecture_graph }
import from backend.agents.quiz_planner { plan_quiz }
import from backend.agents.quiz_generator { generate_micro_quiz_items, GeneratedQuestion }
import from backend.agents.evaluator { evaluate_quiz_submission, StudentAnswerSubmission }
import from backend.agents.scheduler { get_notifications }
import from backend.agents.analytics { get_analytics }
walker:pub get_openrouter_status {
    has verify: bool = False;

    can check with `Root entry {
        report openrouter_status(self.verify);
    }
}

# -------------------------------------------------------------
# 1. Ingest Lecture Notes (Dev 2 Pipeline)
# -------------------------------------------------------------
walker:pub ingest_lecture {
    has subject_name: str = "Computer Networks";
    has subject_code: str = "";
    has lecture_title: str = "IP Subnetting & CIDR";
    has notes_text: str = "";
    has image_b64: str = "";
    has images_b64: list[str] = [];
    has replace_existing: bool = False;
    has result: dict = {};

    can process with `Root entry {
        clean_subject: str = self.subject_name.strip();
        clean_title: str = self.lecture_title.strip();
        if not clean_subject or not clean_title or len(clean_subject) > 200 or len(clean_title) > 300 {
            self.result = {"status": "error", "error": "subject_name and lecture_title are required and must be at most 200 and 300 characters.", "concepts_extracted": [], "total_concepts": 0};
            report self.result;
            return;
        }
        if len(self.notes_text) > 100000 {
            self.result = {"status": "error", "error": "notes_text exceeds the 100,000 character limit.", "concepts_extracted": [], "total_concepts": 0};
            report self.result;
            return;
        }

        all_images: list[str] = [];
        if self.images_b64 and len(self.images_b64) > 0 {
            for img in self.images_b64 {
                if img {
                    all_images.append(img);
                }
            }
        } elif self.image_b64 {
            all_images.append(self.image_b64);
        }
        if len(all_images) > 10 {
            self.result = {"status": "error", "error": "A maximum of 10 lecture images can be ingested at once.", "concepts_extracted": [], "total_concepts": 0};
            report self.result;
            return;
        }
        for img in all_images {
            valid_type: bool = img.startswith("data:image/jpeg;base64,") or img.startswith("data:image/png;base64,") or img.startswith("data:image/webp;base64,");
            valid_image: bool = valid_type and len(img) <= 7000000;
            if valid_image {
                try {
                    decoded_image = base64.b64decode(img.split(",", 1)[1], validate=True);
                    valid_image = len(decoded_image) > 0 and len(decoded_image) <= 5242880;
                } except Exception {
                    valid_image = False;
                }
            }
            if not valid_image {
                self.result = {"status": "error", "error": "Each image must be a JPG, PNG, or WebP data URL no larger than 5 MB.", "concepts_extracted": [], "total_concepts": 0};
                report self.result;
                return;
            }
        }
        if len(all_images) == 0 and not self.notes_text.strip() {
            self.result = {"status": "error", "error": "Provide notes_text or at least one lecture image.", "concepts_extracted": [], "total_concepts": 0};
            report self.result;
            return;
        }

        # Agent 1: Analyze lecture notes (text or image) and extract atomic concepts
        extracted_all: list[RawExtractedConcept] = [];
        failed_slide: int = 0;
        if len(all_images) > 0 {
            img_idx = 0;
            for img in all_images {
                slide_notes = self.notes_text if img_idx == 0 else "";
                extracted = extract_concepts_from_text(self.lecture_title, slide_notes, img);
                if len(extracted) == 0 {
                    failed_slide = img_idx + 1;
                    break;
                }
                for c in extracted {
                    # deduplicate by name within the batch
                    exists_in_batch = False;
                    for prev in extracted_all {
                        if prev.name.strip().lower() == c.name.strip().lower() {
                            exists_in_batch = True;
                            break;
                        }
                    }
                    if not exists_in_batch {
                        extracted_all.append(c);
                    }
                }
                img_idx += 1;
            }
        } else {
            extracted_all = extract_concepts_from_text(self.lecture_title, self.notes_text, "");
        }

        if failed_slide > 0 or len(extracted_all) == 0 {
            self.result = {
                "status": "error",
                "error": f"AI concept extraction failed for slide {failed_slide}. No graph nodes were created." if failed_slide > 0 else "AI concept extraction failed. No graph nodes were created. Check the OpenRouter status and server output, then retry.",
                "subject": self.subject_name,
                "lecture_title": self.lecture_title,
                "concepts_extracted": [],
                "total_concepts": 0
            };
            report self.result;
            return;
        }

        # Agent 2: Build and stitch knowledge graph from root
        builder = root spawn build_lecture_graph(
            subject_name=self.subject_name,
            subject_code=self.subject_code,
            lecture_title=self.lecture_title,
            raw_notes=self.notes_text,
            concepts=extracted_all,
            replace_existing=self.replace_existing
        );

        concept_summaries: list[dict] = [];
        for c in extracted_all {
            concept_summaries.append({
                "name": c.name,
                "summary": c.summary,
                "formula_or_rule": c.formula_or_rule,
                "difficulty": c.difficulty,
                "prerequisites": c.prerequisites
            });
        }

        total_in_lecture = builder.total_lecture_concepts if builder.total_lecture_concepts > 0 else len(concept_summaries);

        self.result = {
            "status": "success",
            "subject": self.subject_name,
            "lecture_title": self.lecture_title,
            "extraction_source": "openrouter",
            "mode": "replace" if self.replace_existing else "append",
            "slides_processed": max(1, len(all_images)),
            "new_concepts_extracted": len(concept_summaries),
            "concepts_extracted": concept_summaries,
            "total_concepts": total_in_lecture,
            "total_lecture_concepts": total_in_lecture,
            "day_1_quiz_scheduled_in_hours": 24
        };
        report self.result;
    }
}

# -------------------------------------------------------------
# 2. Get Dashboard Overview
# -------------------------------------------------------------
walker:pub get_dashboard {
    has subject_name: str = "Computer Networks";
    has result: dict = {};

    can fetch with `Root entry {
        now: float = time.time();
        clean_subject: str = self.subject_name.strip();
        target_subject_id: str = f"subj_{clean_subject.lower().replace(' ', '_')}";

        subject: SubjectNode | None = None;
        resolved_subject_name: str = clean_subject;
        resolved_subject_code: str = "";
        for child in [root-->] {
            if isinstance(child, SubjectNode) {
                if child.id == target_subject_id or child.name.strip().lower() == clean_subject.lower() {
                    subject = child;
                    break;
                }
            }
        }
        concepts: list[ConceptNode] = [];
        if subject {
            resolved_subject_name = subject.name;
            resolved_subject_code = subject.code;
            for lec in [subject-->] {
                if isinstance(lec, LectureNode) {
                    for c in [lec-->] {
                        if isinstance(c, ConceptNode) {
                            days_elapsed: float = (now - c.last_reviewed) / 86400.0 if c.last_reviewed > 0.0 else 0.0;
                            if days_elapsed > 0.0 {
                                c.retrievability = calc_retrievability(stability=c.stability, days_elapsed=days_elapsed);
                                c.status = classify_retention_status(c.retrievability);
                            }
                            concepts.append(c);
                        }
                    }
                }
            }
        }

        if len(concepts) > 0 {
            total_retention: float = 0.0;
            lowest_retention_concept: ConceptNode = concepts[0];
            nearest_due_seconds: float = concepts[0].next_review_due - now;

            for c in concepts {
                total_retention += c.retrievability;
                if c.retrievability < lowest_retention_concept.retrievability {
                    lowest_retention_concept = c;
                }
                time_until_due: float = c.next_review_due - now;
                if time_until_due < nearest_due_seconds {
                    nearest_due_seconds = time_until_due;
                }
            }

            avg_ret: float = (total_retention / len(concepts)) * 100.0;
            overall_retention: float = float(int(avg_ret * 10.0)) / 10.0;
            due_in_hours: int = int(nearest_due_seconds / 3600.0) if nearest_due_seconds > 0.0 else 0;
            if due_in_hours < 1 and nearest_due_seconds > 0.0 {
                due_in_hours = 1;
            }

            self.result = {
                "status": "success",
                "subject_name": resolved_subject_name,
                "code": resolved_subject_code,
                "overall_retention_pct": overall_retention,
                "active_concepts_count": len(concepts),
                "study_streak_days": 3,
                "next_quiz_due_in_hours": due_in_hours,
                "next_quiz_topic": lowest_retention_concept.name,
                "pending_quiz_available": True
            };
            report self.result;
        } else {
            self.result = {
                "status": "no_lecture_context",
                "subject_name": resolved_subject_name,
                "code": resolved_subject_code,
                "overall_retention_pct": 0.0,
                "active_concepts_count": 0,
                "study_streak_days": 0,
                "next_quiz_due_in_hours": 0,
                "next_quiz_topic": "",
                "pending_quiz_available": False
            };
            report self.result;
        }
    }
}

# -------------------------------------------------------------
# 3. Get / Plan 3-4 Minute Micro-Quiz (Dev 3 Pipeline)
# -------------------------------------------------------------
walker:pub get_quiz {
    has subject_name: str = "Computer Networks";

    can prepare_quiz with `Root entry {
        planner = root spawn plan_quiz(subject_name=self.subject_name);
        if planner.status != "success" or len(planner.selected_concepts) == 0 {
            report {"status": "error", "error": planner.error, "questions": []};
            return;
        }
        quiz_id = f"quiz_{uuid.uuid4().hex}";
        generated_questions = generate_micro_quiz_items(quiz_id, planner.selected_concepts);
        if len(generated_questions) != len(planner.selected_concepts) {
            report {"status": "error", "error": "Unable to generate a complete quiz.", "questions": []};
            return;
        }
        subject = None;
        for child in [root-->] {
            if isinstance(child, SubjectNode) and child.id == planner.subject_id {
                subject = child;
                break;
            }
        }
        if subject is None {
            report {"status": "error", "error": "Subject not found.", "questions": []};
            return;
        }
        quiz = QuizNode(id=quiz_id, subject_id=subject.id, created_at=time.time());
        subject ++> quiz;

        q_list: list[dict] = [];
        for q in generated_questions {
            question = QuestionNode(id=q.id, quiz_id=quiz_id, concept_id=q.concept_id,
                concept_name=q.concept_name, prompt=q.prompt, options=q.options,
                correct_answer=q.correct_answer, explanation=q.explanation);
            quiz ++> question;
            q_list.append({
                "id": q.id,
                "concept_id": q.concept_id,
                "concept_name": q.concept_name,
                "prompt": q.prompt,
                "options": q.options,
                "time_limit_seconds": q.time_limit_seconds
            });
        }

        report {
            "status": "success",
            "quiz_id": quiz_id,
            "subject": self.subject_name,
            "duration_minutes": 3,
            "total_questions": len(q_list),
            "plan": planner.selected_concepts,
            "questions": q_list
        };
    }
}

# -------------------------------------------------------------
# 4. Submit Quiz & Recalibrate (Dev 3 Pipeline)
# -------------------------------------------------------------
walker:pub submit_quiz {
    has quiz_id: str;
    has submissions: list[dict] = [];
    has duration_seconds: int = 0;

    can evaluate with `Root entry {
        if not self.quiz_id.strip() or len(self.submissions) == 0 {
            report {"status": "error", "error": "quiz_id and submissions are required."};
            return;
        }
        typed_subs: list[StudentAnswerSubmission] = [];
        for item in self.submissions {
            if not isinstance(item, dict) or not isinstance(item.get("question_id"), str) or not isinstance(item.get("submitted_answer"), str) or not item.get("question_id", "").strip() {
                report {"status": "error", "error": "Each submission needs a question_id and a text answer."};
                return;
            }
            typed_subs.append(StudentAnswerSubmission(
                question_id=str(item["question_id"]),
                submitted_answer=str(item["submitted_answer"])
            ));
        }

        eval_walker = root spawn evaluate_quiz_submission(
            quiz_id=self.quiz_id,
            submissions=typed_subs,
            duration_seconds=self.duration_seconds
        );
        report eval_walker.result;
    }
}

# -------------------------------------------------------------
# 5. Get Knowledge Graph Data for Mobile Visualizer
# -------------------------------------------------------------
walker:pub get_graph_data {
    has subject_name: str = "Computer Networks";
    has result: dict = {};

    can gather with `Root entry {
        now: float = time.time();
        clean_subject: str = self.subject_name.strip();
        target_subject_id: str = f"subj_{clean_subject.lower().replace(' ', '_')}";

        subject: SubjectNode | None = None;
        resolved_subject_name: str = clean_subject;
        resolved_subject_id: str = target_subject_id;
        for child in [root-->] {
            if isinstance(child, SubjectNode) {
                if child.id == target_subject_id or child.name.strip().lower() == clean_subject.lower() {
                    subject = child;
                    break;
                }
            }
        }
        nodes: list[dict] = [];
        edges: list[dict] = [];
        collected_concepts: list[ConceptNode] = [];

        if subject {
            resolved_subject_name = subject.name;
            resolved_subject_id = subject.id;
            for lec in [subject-->] {
                if isinstance(lec, LectureNode) {
                    for c in [lec-->] {
                        if isinstance(c, ConceptNode) {
                            days_elapsed: float = (now - c.last_reviewed) / 86400.0 if c.last_reviewed > 0.0 else 0.0;
                            if days_elapsed > 0.0 {
                                c.retrievability = calc_retrievability(stability=c.stability, days_elapsed=days_elapsed);
                                c.status = classify_retention_status(c.retrievability);
                            }
                            collected_concepts.append(c);
                            ret_val: float = float(int(c.retrievability * 1000.0)) / 10.0;
                            nodes.append({
                                "id": c.id,
                                "label": c.name,
                                "status": c.status,
                                "retention_pct": ret_val,
                                "mastery_score": c.mastery_score,
                                "summary": c.summary,
                                "formula_or_rule": c.formula_or_rule,
                                "lecture_id": c.lecture_id,
                                "difficulty": c.difficulty
                            });
                        }
                    }
                }
            }

            for c in collected_concepts {
                for target in [c->:depends_on:->] {
                    edges.append({
                        "source": c.id,
                        "target": target.id,
                        "type": "depends_on"
                    });
                }
            }
        }

        status_str: str = "success" if len(nodes) > 0 else "no_lecture_context";
        self.result = {
            "status": status_str,
            "subject": resolved_subject_name,
            "subject_id": resolved_subject_id,
            "total_nodes": len(nodes),
            "total_edges": len(edges),
            "nodes": nodes,
            "edges": edges
        };
        report self.result;
    }
}

cl import from components.MemoraDashboard { MemoraDashboard }

cl def:pub app() -> JsxElement {
    return <MemoraDashboard />;
}

with entry {
    print("==================================================");
    print("Memora - Ebbinghaus Spaced Repetition Multi-Agent System");
    print("Jac Platform Backend initialized and ready!");
    print("Public Walkers: ingest_lecture, get_dashboard, get_openrouter_status, get_quiz, submit_quiz, get_graph_data, get_analytics, get_notifications");
    print("==================================================");
}
