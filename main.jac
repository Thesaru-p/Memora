# Memora - Main Entrypoint & Public Walker Endpoints
# Exposes clean REST APIs for the React Native Mobile App and JacHammer Cloud.

import time;
import from backend.graph { SubjectNode, LectureNode, ConceptNode, QuizNode, QuestionNode, depends_on }
import from backend.ebbinghaus { calc_retrievability, classify_retention_status }
import from backend.agents.lecture_analyzer { extract_concepts_from_text, RawExtractedConcept }
import from backend.agents.graph_builder { build_lecture_graph }
import from backend.agents.quiz_planner { plan_quiz }
import from backend.agents.quiz_generator { generate_live_micro_quiz_items, GeneratedQuestion }
import from backend.agents.evaluator { evaluate_quiz_submission, StudentAnswerSubmission }
import from backend.agents.scheduler { get_notifications }
import from backend.agents.analytics { get_analytics }

# Traverse the persistent graph to recover the concepts and summaries from the
# uploaded lecture before asking the quiz LLM to generate questions.
walker collect_subject_context {
    has subject_name: str;
    has contexts: list[dict] = [];
    has latest_lecture_id: str = "";
    has latest_timestamp: float = 0.0;

    can start with `Root entry {
        visit [-->];
    }

    can inspect_subject with SubjectNode entry {
        if here.name == self.subject_name {
            visit [-->];
        }
    }

    can inspect_lecture with LectureNode entry {
        # Only the newest lecture for this subject should drive the next quiz.
        # This prevents older seeded/demo concepts from leaking into a new quiz.
        if here.timestamp >= self.latest_timestamp {
            self.latest_timestamp = here.timestamp;
            self.latest_lecture_id = here.id;
            self.contexts = [];
            visit [-->];
        }
    }

    can collect_concept with ConceptNode entry {
        if here.lecture_id == self.latest_lecture_id {
            self.contexts.append({
                "id": here.id,
                "name": here.name,
                "summary": here.summary,
                "formula_or_rule": here.formula_or_rule,
                "status": here.status,
                "retrievability": here.retrievability,
                "mastery_score": here.mastery_score
            });
        }
    }
}

# -------------------------------------------------------------
# 1. Ingest Lecture Notes (Dev 2 Pipeline)
# -------------------------------------------------------------
walker:pub ingest_lecture {
    has subject_name: str = "Computer Networks";
    has lecture_title: str = "IP Subnetting & CIDR";
    has notes_text: str = "";

    can process with `Root entry {
        # Agent 1: Analyze lecture notes and extract atomic concepts
        extracted = extract_concepts_from_text(self.lecture_title, self.notes_text);

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
        context_walker = root spawn collect_subject_context(subject_name=self.subject_name);
        if len(context_walker.contexts) == 0 {
            report {
                "status": "no_lecture_context",
                "error": "Upload a lecture before opening the dashboard.",
                "subject_name": self.subject_name
            };
        } else {
            total_retention: float = 0.0;
            for item in context_walker.contexts {
                total_retention += item.get("retrievability", 0.0) as float;
            }
            overall_retention: float = (total_retention / len(context_walker.contexts)) * 100.0;

            report {
                "status": "success",
                "subject_name": self.subject_name,
                "code": "",
                "overall_retention_pct": overall_retention,
                "active_concepts_count": len(context_walker.contexts),
                "study_streak_days": 0,
                "next_quiz_due_in_hours": 24,
                "next_quiz_topic": context_walker.contexts[0].get("name", "") as str,
                "pending_quiz_available": True
            };
        }
    }
}

# -------------------------------------------------------------
# 3. Get / Plan 3-4 Minute Micro-Quiz (Dev 3 Pipeline)
# -------------------------------------------------------------
walker:pub get_quiz {
    has subject_name: str = "Computer Networks";

    can prepare_quiz with `Root entry {
        now: float = time.time();
        quiz_id: str = f"quiz_{int(now)}";

        # Agent 3: Select concepts only from the latest uploaded lecture.
        # There is no seeded quiz here: quiz content must come from a lecture.
        concept_ids: list[str] = [];
        concept_names: list[str] = [];
        concept_contexts: list[str] = [];
        context_walker = root spawn collect_subject_context(subject_name=self.subject_name);

        if len(context_walker.contexts) > 0 {
            for item in context_walker.contexts {
                concept_name: str = item.get("name", "") as str;
                if concept_name != "" {
                    concept_ids.append(f"c_{concept_name.lower().replace(' ', '_').replace('&', 'and')}");
                    concept_names.append(concept_name);
                    concept_contexts.append(
                        f"Concept: {concept_name}. Summary: {item.get('summary', '') as str}. Rule: {item.get('formula_or_rule', '') as str}."
                    );
                }
            }
        }

        # Agent 4: Generate grounded micro-quiz questions
        generated_questions: list[GeneratedQuestion] = [];
        if len(concept_ids) > 0 {
            generated_questions = generate_live_micro_quiz_items(quiz_id, concept_ids, concept_names, concept_contexts);
        }

        q_list: list[dict] = [];
        llm_question_count: int = 0;
        for q in generated_questions {
            if q.generation_source == "llm" {
                llm_question_count += 1;
            }
            q_list.append({
                "id": q.id,
                "concept_id": q.concept_id,
                "concept_name": q.concept_name,
                "prompt": q.prompt,
                "options": q.options,
                "correct_answer": q.correct_answer,
                "explanation": q.explanation,
                "time_limit_seconds": q.time_limit_seconds,
                "generation_source": q.generation_source
            });
        }

        status_text: str = "success";
        if len(concept_ids) == 0 {
            status_text = "no_lecture_context";
        } elif len(q_list) == 0 {
            status_text = "llm_unavailable";
        }

        report {
            "status": status_text,
            "quiz_id": quiz_id,
            "subject": self.subject_name,
            "duration_minutes": 3,
            "total_questions": len(q_list),
            "llm_generated_questions": llm_question_count,
            "generation_mode": f"{llm_question_count}/{len(q_list)} generated by LLM",
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

    can evaluate with `Root entry {
        typed_subs: list[StudentAnswerSubmission] = [];
        for item in self.submissions {
            typed_subs.append(StudentAnswerSubmission(
                question_id=(item.get("question_id", "") as str),
                concept_id=(item.get("concept_id", "") as str),
                submitted_answer=(item.get("submitted_answer", "") as str),
                correct_answer=(item.get("correct_answer", "") as str),
                explanation=(item.get("explanation", "") as str)
            ));
        }

        eval_walker = root spawn evaluate_quiz_submission(
            quiz_id=self.quiz_id,
            submissions=typed_subs
        );
    }
}

# -------------------------------------------------------------
# 5. Get Knowledge Graph Data for Mobile Visualizer
# -------------------------------------------------------------
walker:pub get_graph_data {
    has subject_name: str = "Computer Networks";

    can gather with `Root entry {
        context_walker = root spawn collect_subject_context(subject_name=self.subject_name);
        nodes: list[dict] = [];
        for item in context_walker.contexts {
            nodes.append({
                "id": item.get("id", "") as str,
                "label": item.get("name", "") as str,
                "status": item.get("status", "NEW") as str,
                "retention_pct": (item.get("retrievability", 0.0) as float) * 100.0,
                "mastery_score": item.get("mastery_score", 0.0) as float,
                "summary": item.get("summary", "") as str
            });
        }

        report {
            "status": ("success" if len(nodes) > 0 else "no_lecture_context"),
            "error": ("" if len(nodes) > 0 else "Upload a lecture before opening the knowledge graph."),
            "subject": self.subject_name,
            "nodes": nodes,
            "edges": []
        };
    }
}

with entry {
    print("==================================================");
    print("Memora - Ebbinghaus Spaced Repetition Multi-Agent System");
    print("Jac Platform Backend initialized and ready!");
    print("Public Walkers: ingest_lecture, get_dashboard, get_quiz, submit_quiz, get_graph_data, get_analytics, get_notifications");
    print("==================================================");
}
