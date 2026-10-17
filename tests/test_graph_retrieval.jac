# Tests for dynamic get_graph_data and get_dashboard walkers (Dev 2 Domain)

import time;
import from backend.graph { SubjectNode, LectureNode, ConceptNode }
import from backend.agents.graph_builder { build_lecture_graph }
import from backend.agents.lecture_analyzer { RawExtractedConcept }
import from main { get_graph_data, get_dashboard }

test "get_graph_data traverses real spatial nodes and prerequisite edges" {
    concepts = [
        RawExtractedConcept(name="Mitochondria", summary="Powerhouse of the cell", formula_or_rule="Produces ATP", difficulty=3.0, prerequisites=[]),
        RawExtractedConcept(name="ATP Synthase", summary="Enzyme that synthesizes ATP", formula_or_rule="ADP + Pi -> ATP", difficulty=6.0, prerequisites=["Mitochondria"]),
        RawExtractedConcept(name="Proton Gradient", summary="Electrochemical gradient across inner membrane", formula_or_rule="H+ accumulation", difficulty=7.0, prerequisites=["ATP Synthase"])
    ];

    root spawn build_lecture_graph(
        subject_name="Cell Biology",
        lecture_title="Bioenergetics",
        raw_notes="Cell energy notes",
        concepts=concepts
    );

    walker_res = root spawn get_graph_data(subject_name="Cell Biology");
    data = walker_res.result;

    assert data["status"] == "success";
    assert data["subject"] == "Cell Biology";
    assert data["total_nodes"] == 3;
    assert len(data["nodes"]) == 3;
    assert len(data["edges"]) == 2;

    # Check node fields
    labels = [n["label"] for n in data["nodes"]];
    assert "Mitochondria" in labels;
    assert "ATP Synthase" in labels;
    assert "Proton Gradient" in labels;

    for n in data["nodes"] {
        assert n["retention_pct"] >= 95.0;
        assert n["status"] in ["STRONG", "NEW"];
        assert n["mastery_score"] == 0.1;
        assert n["id"].startswith("c_lec_");
    }

    # Check edges
    edge_types = [e["type"] for e in data["edges"]];
    assert edge_types == ["depends_on", "depends_on"];
}

test "get_dashboard computes dynamic retention and active concept count" {
    concepts = [
        RawExtractedConcept(name="Neurons", summary="Excitable nerve cells", formula_or_rule="", difficulty=4.0, prerequisites=[]),
        RawExtractedConcept(name="Synapses", summary="Junctions between neurons", formula_or_rule="", difficulty=5.0, prerequisites=["Neurons"]),
        RawExtractedConcept(name="Neurotransmitters", summary="Chemical messengers", formula_or_rule="", difficulty=5.0, prerequisites=["Synapses"]),
        RawExtractedConcept(name="Action Potential", summary="Rapid membrane depolarization", formula_or_rule="All-or-none electrical impulse", difficulty=8.0, prerequisites=["Neurons"])
    ];

    root spawn build_lecture_graph(
        subject_name="Neuroscience",
        lecture_title="Neural Signaling",
        raw_notes="Signal transmission in brain",
        concepts=concepts
    );

    dash_res = root spawn get_dashboard(subject_name="Neuroscience");
    dash = dash_res.result;

    assert dash["status"] == "success";
    assert dash["subject_name"] == "Neuroscience";
    assert dash["active_concepts_count"] == 4;
    assert dash["overall_retention_pct"] >= 95.0;
    assert dash["pending_quiz_available"] == True;
    assert dash["next_quiz_topic"] != "";
}

test "missing subject never returns another subject or demo nodes" {
    res = root spawn get_graph_data(subject_name="Missing Subject");
    data = res.result;
    assert data["status"] == "no_lecture_context";
    assert data["subject"] == "Missing Subject";
    assert len(data["nodes"]) == 0;
}
