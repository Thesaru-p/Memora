# Knowledge Graph Data Archetypes for Memora
# Owned primarily by Dev 2 (Ingestion & Knowledge Graph Lead)

# -------------------------------------------------------------
# Nodes
# -------------------------------------------------------------

node SubjectNode {
    has id: str;
    has name: str;
    has code: str;
    has description: str = "";
    has created_at: float = 0.0;
}

node LectureNode {
    has id: str;
    has subject_id: str;
    has title: str;
    has raw_notes: str = "";
    has summary: str = "";
    has timestamp: float = 0.0;
    has concept_count: int = 0;
}

node ConceptNode {
    has id: str;
    has subject_id: str;
    has lecture_id: str;
    has name: str;
    has summary: str;
    has formula_or_rule: str = "";
    
    # Ebbinghaus Cognitive State Parameters
    has stability: float = 1.0;          # S: Memory stability in days (half-life)
    has difficulty: float = 5.0;         # D: 1.0 (easy) to 10.0 (hard)
    has retrievability: float = 1.0;     # R: 0.0 to 1.0 (calculated decay)
    has mastery_score: float = 0.0;      # 0.0 (new) to 1.0 (mastered)
    has review_count: int = 0;
    has last_reviewed: float = 0.0;      # Timestamp of last review / creation
    has next_review_due: float = 0.0;    # Projected timestamp for next review
    has status: str = "NEW";             # NEW | LEARNING | DUE | MASTERED
}

node QuizNode {
    has id: str;
    has subject_id: str;
    has created_at: float = 0.0;
    has completed_at: float = 0.0;
    has duration_seconds: int = 0;
    has score: float = 0.0;
    has accuracy_pct: float = 0.0;
    has status: str = "PENDING";          # PENDING | COMPLETED
}

node QuestionNode {
    has id: str;
    has quiz_id: str;
    has concept_id: str;
    has concept_name: str;
    has prompt: str;
    has correct_answer: str;
    has question_type: str = "MCQ";      # MCQ | ACTIVE_RECALL
    has explanation: str = "";           # Pedagogical misconception explanation
    has student_answer: str = "";
    has is_correct: bool = False;
}

# -------------------------------------------------------------
# Edges
# -------------------------------------------------------------

edge depends_on {
    has relationship: str = "requires_knowledge_of";
}

edge subconcept_of {
    has relationship: str = "child_of";
}

edge relates_to {
    has relationship: str = "semantic_association";
}

edge tested_by {
    has quiz_id: str = "";
}
