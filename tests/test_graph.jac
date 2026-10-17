# Unit Tests for Jac Knowledge Graph Structures and Walkers (Dev 2 Domain)

import time;
import from backend.graph { SubjectNode, LectureNode, ConceptNode, depends_on }
import from backend.agents.graph_builder { build_lecture_graph }
import from backend.agents.lecture_analyzer { RawExtractedConcept }

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

test "two lectures for science produce 1 subject, 2 lectures, and lecture-scoped concepts" {
    c_set_photosynthesis = [
        RawExtractedConcept(name="Photosynthesis", summary="Energy conversion in plants", formula_or_rule="6CO2 + 6H2O -> C6H12O6 + 6O2", difficulty=4.0, prerequisites=[]),
        RawExtractedConcept(name="Chlorophyll", summary="Pigment absorbing light", formula_or_rule="", difficulty=3.0, prerequisites=["Photosynthesis"]),
        RawExtractedConcept(name="Light Reactions", summary="Produces ATP and NADPH", formula_or_rule="", difficulty=6.0, prerequisites=["Chlorophyll"]),
        RawExtractedConcept(name="Calvin Cycle", summary="Fixes carbon into sugar", formula_or_rule="", difficulty=7.0, prerequisites=["Light Reactions"])
    ];
    c_set_respiration = [
        RawExtractedConcept(name="Cellular Respiration", summary="Breakdown of glucose for ATP", formula_or_rule="C6H12O6 + 6O2 -> 6CO2 + 6H2O + ATP", difficulty=5.0, prerequisites=[]),
        RawExtractedConcept(name="Glycolysis", summary="Anaerobic glucose splitting", formula_or_rule="", difficulty=6.0, prerequisites=["Cellular Respiration"]),
        RawExtractedConcept(name="Krebs Cycle", summary="Mitochondrial oxidation cycle", formula_or_rule="", difficulty=7.0, prerequisites=["Glycolysis"]),
        RawExtractedConcept(name="Electron Transport", summary="Chemiosmotic ATP synthesis", formula_or_rule="", difficulty=8.0, prerequisites=["Krebs Cycle"])
    ];

    root spawn build_lecture_graph(
        subject_name="Science",
        lecture_title="Photosynthesis",
        raw_notes="Photosynthesis lecture notes",
        concepts=c_set_photosynthesis
    );
    root spawn build_lecture_graph(
        subject_name="Science",
        lecture_title="Cellular Respiration",
        raw_notes="Cellular respiration lecture notes",
        concepts=c_set_respiration
    );

    # 1. Exactly 1 SubjectNode for Science
    science_subjects = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_science"];
    assert len(science_subjects) == 1;
    subj = science_subjects[0];
    assert subj.name == "Science";

    # 2. Exactly 2 LectureNodes under the reused subject
    lectures = [l for l in [subj-->] if isinstance(l, LectureNode)];
    assert len(lectures) == 2;
    titles = [l.title for l in lectures];
    assert "Photosynthesis" in titles;
    assert "Cellular Respiration" in titles;

    # 3. Lecture-scoped ConceptNodes
    all_concepts: list[ConceptNode] = [];
    for lec in lectures {
        lec_concepts = [c for c in [lec-->] if isinstance(c, ConceptNode)];
        assert len(lec_concepts) == 4;
        for c in lec_concepts {
            all_concepts.append(c);
            # Concept IDs must be lecture-scoped
            assert c.id.startswith(f"c_{lec.id}_");
            assert c.subject_id == "subj_science";
            assert c.lecture_id == lec.id;
            # Ebbinghaus initial values
            assert c.stability == 1.0;
            assert c.retrievability == 1.0;
            assert c.status == "NEW";
            assert c.mastery_score == 0.1;
            assert c.review_count == 0;
            assert c.next_review_due > 0.0;
        }
    }
    assert len(all_concepts) == 8;
}

test "repeated ingestion of same lecture is idempotent without duplicate nodes or edges" {
    c_set = [
        RawExtractedConcept(name="Photosynthesis", summary="Energy conversion", formula_or_rule="", difficulty=4.0, prerequisites=[]),
        RawExtractedConcept(name="Chlorophyll", summary="Light absorbing pigment", formula_or_rule="", difficulty=3.0, prerequisites=["Photosynthesis"])
    ];

    # First ingestion
    root spawn build_lecture_graph(
        subject_name="Botany",
        lecture_title="Plant Physiology",
        raw_notes="First version notes",
        concepts=c_set
    );

    # Second repeated ingestion of the exact same lecture
    root spawn build_lecture_graph(
        subject_name="Botany",
        lecture_title="Plant Physiology",
        raw_notes="Second updated notes",
        concepts=c_set
    );

    botany_subjects = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_botany"];
    assert len(botany_subjects) == 1;
    subj = botany_subjects[0];

    lectures = [l for l in [subj-->] if isinstance(l, LectureNode)];
    assert len(lectures) == 1;
    assert lectures[0].raw_notes == "Second updated notes";

    concepts = [c for c in [lectures[0]-->] if isinstance(c, ConceptNode)];
    assert len(concepts) == 2;

    chloro = [c for c in concepts if c.name == "Chlorophyll"][0];
    prereqs = [chloro->:depends_on:->];
    assert len(prereqs) == 1;
    assert prereqs[0].name == "Photosynthesis";
}

test "cross-lecture prerequisite edge linking within same subject" {
    c_set_bio1 = [
        RawExtractedConcept(name="Macromolecules", summary="Carbohydrates, lipids, proteins", formula_or_rule="", difficulty=3.0, prerequisites=[])
    ];
    c_set_bio2 = [
        RawExtractedConcept(name="Enzyme Kinetics", summary="Catalytic action on macromolecules", formula_or_rule="v = Vmax[S]/(Km+[S])", difficulty=7.0, prerequisites=["Macromolecules"])
    ];

    root spawn build_lecture_graph(
        subject_name="Biochemistry",
        lecture_title="Foundations",
        raw_notes="",
        concepts=c_set_bio1
    );
    root spawn build_lecture_graph(
        subject_name="Biochemistry",
        lecture_title="Enzymes",
        raw_notes="",
        concepts=c_set_bio2
    );

    bio_subj = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_biochemistry"][0];
    enzyme_lec = [l for l in [bio_subj-->] if isinstance(l, LectureNode) and l.title == "Enzymes"][0];
    enzyme_concept = [c for c in [enzyme_lec-->] if isinstance(c, ConceptNode) and c.name == "Enzyme Kinetics"][0];

    prereqs = [enzyme_concept->:depends_on:->];
    assert len(prereqs) == 1;
    assert prereqs[0].name == "Macromolecules";
    assert prereqs[0].subject_id == "subj_biochemistry";
}
