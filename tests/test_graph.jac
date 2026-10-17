# Unit Tests for Jac Knowledge Graph Structures and Walkers (Dev 2 Domain)

import from backend.graph { SubjectNode, LectureNode, ConceptNode, depends_on }

test "concept node initializes with correct ebbinghaus defaults" {
    c = ConceptNode(
        id="c_test_subnetting",
        subject_id="subj_cs301",
        lecture_id="lec_1",
        name="Subnetting",
        summary="IP address partitioning",
        formula_or_rule="2^n - 2",
        stability=1.0,
        difficulty=5.0,
        retrievability=1.0,
        mastery_score=0.0,
        review_count=0,
        last_reviewed=0.0,
        next_review_due=86400.0,
        status="NEW"
    );

    assert c.stability == 1.0;
    assert c.retrievability == 1.0;
    assert c.status == "NEW";
}

test "prerequisite edge links between concepts" {
    c1 = ConceptNode(
        id="c1", subject_id="s1", lecture_id="l1", name="CIDR", summary="Slash notation",
        stability=1.0, difficulty=5.0, retrievability=1.0, mastery_score=0.0, review_count=0, last_reviewed=0.0, next_review_due=0.0, status="NEW"
    );
    c2 = ConceptNode(
        id="c2", subject_id="s1", lecture_id="l1", name="IP", summary="Internet protocol",
        stability=1.0, difficulty=5.0, retrievability=1.0, mastery_score=0.0, review_count=0, last_reviewed=0.0, next_review_due=0.0, status="NEW"
    );

    c1 +>:depends_on:+> c2;
    prerequisites = [c1->:depends_on:->];
    assert len(prerequisites) == 1;
    assert prerequisites[0].id == "c2";
}

test "subject lecture and concept form the required topology" {
    subject = SubjectNode(id="s2", name="Networks", code="CS-301");
    lecture = LectureNode(id="l2", subject_id="s2", title="Subnetting");
    concept = ConceptNode(
        id="c3", subject_id="s2", lecture_id="l2", name="CIDR", summary="Prefix notation"
    );

    subject ++> lecture ++> concept;
    lectures = [subject-->];
    concepts = [lecture-->];
    assert len(lectures) == 1;
    assert len(concepts) == 1;
    assert concepts[0].next_review_due == 0.0;
}
