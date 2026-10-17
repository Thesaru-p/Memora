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
cl import from .components.MemoraDashboard { MemoraDashboard }

cl def:pub app() -> JsxElement {
    return <MemoraDashboard />;
}

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
    has lecture_title: str = "IP Subnetting & CIDR";
    has notes_text: str = "";
    has image_b64: str = "";

    can process with `Root entry {
        # Agent 1: Analyze lecture notes (text or image) and extract atomic concepts
        extracted = extract_concepts_from_text(self.lecture_title, self.notes_text, self.image_b64);
        if len(extracted) == 0 {
            report {
                "status": "error",
                "error": "AI concept extraction failed. No graph nodes were created. Check the OpenRouter status and server output, then retry.",
                "subject": self.subject_name,
                "lecture_title": self.lecture_title,
                "concepts_extracted": [],
                "total_concepts": 0
            };
            return;
        }

        # Agent 2: Build and stitch knowledge graph from root
        builder = root spawn build_lecture_graph(
            subject_name=self.subject_name,
            lecture_title=self.lecture_title,
            raw_notes=self.notes_text,
            concepts=extracted
        );

        concept_summaries: list[dict] = [];
        for c in extracted {
            concept_summaries.append({
                "name": c.name,
                "summary": c.summary,
                "formula_or_rule": c.formula_or_rule,
                "difficulty": c.difficulty,
                "prerequisites": c.prerequisites
            });
        }

        report {
            "status": "success",
            "subject": self.subject_name,
            "lecture_title": self.lecture_title,
            "extraction_source": "openrouter",
            "concepts_extracted": concept_summaries,
            "total_concepts": len(concept_summaries),
            "day_1_quiz_scheduled_in_hours": 24
        };
    }
}

# -------------------------------------------------------------
# 2. Get Dashboard Overview
# -------------------------------------------------------------
walker:pub get_dashboard {
    has subject_name: str = "Computer Networks";

    can fetch with `Root entry {
        now: float = time.time();

        report {
            "status": "success",
            "subject_name": self.subject_name,
            "code": "CS-301",
            "overall_retention_pct": 82.5,
            "active_concepts_count": 4,
            "study_streak_days": 3,
            "next_quiz_due_in_hours": 18,
            "next_quiz_topic": "Subnet Masks & ANDing",
            "pending_quiz_available": True
        };
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

    can gather with `Root entry {
        nodes: list[dict] = [
            {
                "id": "c_ip_addressing_and_subnetting",
                "label": "IP Addressing & Subnetting",
                "status": "STRONG",
                "retention_pct": 92.0,
                "mastery_score": 0.85,
                "summary": "Hierarchical addressing scheme using network prefix and host bits."
            },
            {
                "id": "c_cidr_notation",
                "label": "CIDR Notation",
                "status": "STRONG",
                "retention_pct": 88.0,
                "mastery_score": 0.80,
                "summary": "Slash prefix representation replacing legacy IP classes."
            },
            {
                "id": "c_subnet_masks_and_anding",
                "label": "Subnet Masks & ANDing",
                "status": "FADING",
                "retention_pct": 64.0,
                "mastery_score": 0.60,
                "summary": "Bitwise AND operation to isolate the network address."
            },
            {
                "id": "c_default_gateway",
                "label": "Default Gateway",
                "status": "CRITICAL",
                "retention_pct": 48.0,
                "mastery_score": 0.40,
                "summary": "Routing interface for external cross-subnet packet forwarding."
            }
        ];

        edges: list[dict] = [
            {"source": "c_cidr_notation", "target": "c_ip_addressing_and_subnetting", "type": "depends_on"},
            {"source": "c_subnet_masks_and_anding", "target": "c_ip_addressing_and_subnetting", "type": "depends_on"},
            {"source": "c_subnet_masks_and_anding", "target": "c_cidr_notation", "type": "depends_on"},
            {"source": "c_default_gateway", "target": "c_subnet_masks_and_anding", "type": "depends_on"}
        ];

        report {
            "status": "success",
            "subject": self.subject_name,
            "nodes": nodes,
            "edges": edges
        };
    }
}

with entry {
    print("==================================================");
    print("Memora - Ebbinghaus Spaced Repetition Multi-Agent System");
    print("Jac Platform Backend initialized and ready!");
    print("Public Walkers: ingest_lecture, get_dashboard, get_openrouter_status, get_quiz, submit_quiz, get_graph_data, get_analytics, get_notifications");
    print("==================================================");
}
