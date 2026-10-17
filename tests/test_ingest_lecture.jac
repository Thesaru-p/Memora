# Unit tests for main.jac ingest_lecture walker (multi-upload and replace mode)

import json;
import from unittest.mock { patch }
import from main { ingest_lecture }
import from backend.graph { SubjectNode, LectureNode, ConceptNode }
import from backend.agents.lecture_analyzer { RawExtractedConcept }

test "ingest_lecture in append mode accumulates concepts across uploads" {
    c1 = [
        RawExtractedConcept(name="Mitochondria", summary="Cell powerhouse", formula_or_rule="", difficulty=3.0, prerequisites=[]),
        RawExtractedConcept(name="ATP Synthase", summary="Enzyme producing ATP", formula_or_rule="", difficulty=5.0, prerequisites=["Mitochondria"])
    ];
    c2 = [
        RawExtractedConcept(name="Krebs Cycle", summary="Matrix reaction", formula_or_rule="", difficulty=6.0, prerequisites=["ATP Synthase"]),
        RawExtractedConcept(name="Electron Transport", summary="Membrane gradient", formula_or_rule="", difficulty=7.0, prerequisites=["Krebs Cycle"])
    ];

    with patch("main.extract_concepts_from_text", side_effect=[c1, c2]) {
        # Upload 1
        res1 = root spawn ingest_lecture(
            subject_name="Cellular Bio",
            lecture_title="Energy Production",
            notes_text="Part 1 notes",
            replace_existing=False
        );
        data1 = res1.result;
        assert data1["status"] == "success";
        assert data1["mode"] == "append";
        assert data1["total_lecture_concepts"] == 2;
        subject = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_cellular_bio"][0];
        assert subject.code == "CB-001";

        # Upload 2 (append mode)
        res2 = root spawn ingest_lecture(
            subject_name="Cellular Bio",
            lecture_title="Energy Production",
            notes_text="Part 2 notes",
            replace_existing=False
        );
        data2 = res2.result;
        assert data2["status"] == "success";
        assert data2["mode"] == "append";
        assert data2["total_lecture_concepts"] == 4;
    }
}

test "ingest_lecture in replace mode resets lecture concepts fresh" {
    c_old = [
        RawExtractedConcept(name="Old A", summary="Old summary", formula_or_rule="", difficulty=2.0, prerequisites=[]),
        RawExtractedConcept(name="Old B", summary="Old summary", formula_or_rule="", difficulty=3.0, prerequisites=[])
    ];
    c_new = [
        RawExtractedConcept(name="Fresh Concept 1", summary="Fresh summary", formula_or_rule="", difficulty=4.0, prerequisites=[]),
        RawExtractedConcept(name="Fresh Concept 2", summary="Fresh summary", formula_or_rule="", difficulty=5.0, prerequisites=[]),
        RawExtractedConcept(name="Fresh Concept 3", summary="Fresh summary", formula_or_rule="", difficulty=6.0, prerequisites=[])
    ];

    with patch("main.extract_concepts_from_text", side_effect=[c_old, c_new]) {
        # First ingest
        root spawn ingest_lecture(
            subject_name="Chemistry",
            lecture_title="Thermodynamics",
            notes_text="Old chemistry notes",
            replace_existing=False
        );

        # Second ingest with replace_existing=True
        res_replace = root spawn ingest_lecture(
            subject_name="Chemistry",
            lecture_title="Thermodynamics",
            notes_text="Fresh chemistry notes",
            replace_existing=True
        );
        data = res_replace.result;
        assert data["status"] == "success";
        assert data["mode"] == "replace";
        assert data["total_lecture_concepts"] == 3;

        # Verify old concepts were removed from graph
        subj = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_chemistry"][0];
        lec = [l for l in [subj-->] if isinstance(l, LectureNode) and l.title == "Thermodynamics"][0];
        concepts = [c for c in [lec-->] if isinstance(c, ConceptNode)];
        assert len(concepts) == 3;
        names = [c.name for c in concepts];
        assert "Fresh Concept 1" in names;
        assert "Old A" not in names;
    }
}

test "ingest_lecture with images_b64 batch processes multiple slides in one call" {
    c_slide1 = [
        RawExtractedConcept(name="Slide 1 Concept A", summary="S1 A", formula_or_rule="", difficulty=3.0, prerequisites=[]),
        RawExtractedConcept(name="Slide 1 Concept B", summary="S1 B", formula_or_rule="", difficulty=4.0, prerequisites=[])
    ];
    c_slide2 = [
        RawExtractedConcept(name="Slide 2 Concept C", summary="S2 C", formula_or_rule="", difficulty=5.0, prerequisites=["Slide 1 Concept A"]),
        RawExtractedConcept(name="Slide 2 Concept D", summary="S2 D", formula_or_rule="", difficulty=6.0, prerequisites=[])
    ];

    with patch("main.extract_concepts_from_text", side_effect=[c_slide1, c_slide2]) {
        res = root spawn ingest_lecture(
            subject_name="Physics",
            lecture_title="Kinematics",
            images_b64=["data:image/png;base64,c2xpZGUx", "data:image/png;base64,c2xpZGUy"],
            replace_existing=False
        );
        data = res.result;
        assert data["status"] == "success";
        assert data["slides_processed"] == 2;
        assert data["total_lecture_concepts"] == 4;
        assert len(data["concepts_extracted"]) == 4;
    }
}

test "ingest_lecture rejects the whole image batch when one slide fails" {
    valid = [
        RawExtractedConcept(name="Valid A", summary="A", formula_or_rule="", difficulty=3.0, prerequisites=[]),
        RawExtractedConcept(name="Valid B", summary="B", formula_or_rule="", difficulty=4.0, prerequisites=[]),
        RawExtractedConcept(name="Valid C", summary="C", formula_or_rule="", difficulty=5.0, prerequisites=[]),
        RawExtractedConcept(name="Valid D", summary="D", formula_or_rule="", difficulty=6.0, prerequisites=[])
    ];

    with patch("main.extract_concepts_from_text", side_effect=[valid, []]) {
        res = root spawn ingest_lecture(
            subject_name="Atomic Batch",
            lecture_title="Two Slides",
            images_b64=["data:image/png;base64,c2xpZGUx", "data:image/png;base64,c2xpZGUy"]
        );
        assert res.result["status"] == "error";
        subjects = [s for s in [root-->] if isinstance(s, SubjectNode) and s.id == "subj_atomic_batch"];
        assert len(subjects) == 0;
    }
}

test "ingest_lecture validates required content before extraction" {
    res = root spawn ingest_lecture(subject_name="", lecture_title="", notes_text="");
    assert res.result["status"] == "error";
    assert res.result["total_concepts"] == 0;
}
