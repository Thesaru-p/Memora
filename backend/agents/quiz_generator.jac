"""Generate MCQs grounded in selected concept descriptions."""
import json;
import from backend.config { query_openrouter, MODEL_REASONING }

obj GeneratedQuestion {
    has id: str;
    has concept_id: str;
    has concept_name: str;
    has prompt: str;
    has options: list[str];
    has correct_answer: str;
    has explanation: str;
    has time_limit_seconds: int = 45;
}

def generate_micro_quiz_items(quiz_id: str, concepts: list[dict]) -> list[GeneratedQuestion] {
    if len(concepts) == 0 { return []; }
    context: list[dict] = [];
    for concept in concepts {
        context.append({"concept_id": concept["concept_id"], "name": concept["concept_name"],
            "summary": concept["summary"], "formula_or_rule": concept["formula_or_rule"],
            "difficulty": concept["difficulty"]});
    }
    system_prompt = "Write exactly one multiple choice question per supplied concept. Use only its description and rule. Return ONLY a JSON list, in input order, with concept_id, prompt, options (four distinct strings), correct_answer (exact option text), explanation. Never invent facts.";
    raw = query_openrouter(MODEL_REASONING, system_prompt, json.dumps(context));
    if raw {
        try {
            parsed = json.loads(raw);
            if isinstance(parsed, list) and len(parsed) == len(concepts) {
                valid: list[GeneratedQuestion] = [];
                for idx in range(len(concepts)) {
                    item = parsed[idx];
                    concept = concepts[idx];
                    if not isinstance(item, dict) or item.get("concept_id") != concept["concept_id"] { break; }
                    options = item.get("options", []);
                    prompt = item.get("prompt", "");
                    answer = item.get("correct_answer", "");
                    explanation = item.get("explanation", "");
                    if not isinstance(options, list) or len(options) != 4 or not all(isinstance(o, str) and o.strip() for o in options) or len(set(options)) != 4 or not isinstance(prompt, str) or not prompt.strip() or answer not in options or not isinstance(explanation, str) or not explanation.strip() { break; }
                    clean_options: list[str] = [];
                    for option in options { clean_options.append(str(option)); }
                    valid.append(GeneratedQuestion(id=f"{quiz_id}_q{idx + 1}", concept_id=str(concept["concept_id"]), concept_name=str(concept["concept_name"]), prompt=str(prompt), options=clean_options, correct_answer=str(answer), explanation=str(explanation)));
                }
                if len(valid) == len(concepts) { return valid; }
            }
        } except Exception {
            raw = "";
        }
    }
    generated: list[GeneratedQuestion] = [];
    for idx in range(len(concepts)) {
        concept = concepts[idx];
        correct: str = str(concept["summary"]).strip();
        if not correct { correct = f"The core idea described by {concept['concept_name']}"; }
        fallback_options: list[str] = [correct,
            f"{concept['concept_name']} has no relationship to this subject",
            f"{concept['concept_name']} is only a memorization schedule",
            f"{concept['concept_name']} means every related concept is identical"];
        generated.append(GeneratedQuestion(id=f"{quiz_id}_q{idx + 1}", concept_id=str(concept["concept_id"]), concept_name=str(concept["concept_name"]), prompt=f"Which description best matches {concept['concept_name']}?", options=fallback_options, correct_answer=correct, explanation=f"The lecture describes {concept['concept_name']} as: {correct}"));
    }
    return generated;
}
