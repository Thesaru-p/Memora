import json;
import from backend.agents.lecture_analyzer { parse_extracted_concepts }

test "parses structured concept object without changing subject" {
    payload = json.dumps({"concepts": [
        {"name": "Photosynthesis", "summary": "Plants convert light into chemical energy.", "formula_or_rule": "6CO2 + 6H2O -> C6H12O6 + 6O2", "difficulty": 4, "prerequisites": []},
        {"name": "Chlorophyll", "summary": "Pigment absorbs light energy.", "formula_or_rule": "Absorbs red and blue light", "difficulty": 3, "prerequisites": ["Photosynthesis"]},
        {"name": "Light Reactions", "summary": "Light reactions produce ATP and NADPH.", "formula_or_rule": "Light + H2O -> ATP + NADPH + O2", "difficulty": 6, "prerequisites": ["Chlorophyll"]},
        {"name": "Calvin Cycle", "summary": "Carbon fixation builds sugars.", "formula_or_rule": "CO2 + ATP + NADPH -> G3P", "difficulty": 7, "prerequisites": ["Light Reactions"]}
    ]});
    concepts = parse_extracted_concepts(payload);
    assert len(concepts) == 4;
    assert concepts[0].name == "Photosynthesis";
    assert concepts[3].prerequisites == ["Light Reactions"];
}

test "accepts fenced JSON and clamps difficulty" {
    payload = "```json\n{\"concepts\":[" + ",".join([
        "{\"name\":\"A\",\"summary\":\"One\",\"difficulty\":0,\"prerequisites\":[]}",
        "{\"name\":\"B\",\"summary\":\"Two\",\"difficulty\":11,\"prerequisites\":[\"A\"]}",
        "{\"name\":\"C\",\"summary\":\"Three\",\"difficulty\":5,\"prerequisites\":[\"B\"]}",
        "{\"name\":\"D\",\"summary\":\"Four\",\"difficulty\":5,\"prerequisites\":[\"C\"]}"
    ]) + "]}\n```";
    concepts = parse_extracted_concepts(payload);
    assert concepts[0].difficulty == 1.0;
    assert concepts[1].difficulty == 10.0;
}

test "rejects truncated malformed or undersized output" {
    assert len(parse_extracted_concepts("{\"concepts\":[")) == 0;
    assert len(parse_extracted_concepts("{\"concepts\":[{\"name\":\"Only\",\"summary\":\"One\",\"prerequisites\":[]}]}")) == 0;
    assert len(parse_extracted_concepts("")) == 0;
}
