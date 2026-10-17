# Lecture Analyzer Agent (Dev 2 Domain)
# Uses nvidia/nemotron-3.5-super-vl:free via OpenRouter
# Analyzes multimodal lecture material (slides, handwritten notes, text) and extracts atomic concepts.

import json;
import from backend.config { query_openrouter, MODEL_VISION }

# Structured concept definition extracted from lecture notes
obj RawExtractedConcept {
    has name: str;
    has summary: str;
    has formula_or_rule: str = "";
    has difficulty: float = 5.0;
    has prerequisites: list[str] = [];
}

def parse_extracted_concepts(raw_response: str) -> list[RawExtractedConcept] {
    if not raw_response {
        return [];
    }
    try {
        cleaned = raw_response.strip();
        if cleaned.startswith("```") {
            first_newline = cleaned.find("\n");
            if first_newline >= 0 {
                cleaned = cleaned[first_newline + 1:];
            }
            if cleaned.endswith("```") {
                cleaned = cleaned[:-3].strip();
            }
        }
        parsed = json.loads(cleaned);
        items = parsed.get("concepts", []) if isinstance(parsed, dict) else parsed;
        if not isinstance(items, list) or len(items) < 4 or len(items) > 8 {
            print("[Concept Parser Error] Expected 4-8 concepts.");
            return [];
        }
        extracted: list[RawExtractedConcept] = [];
        for item in items {
            name = str(item.get("name", "")).strip();
            summary = str(item.get("summary", "")).strip();
            prerequisites = item.get("prerequisites", []);
            if not name or not summary or not isinstance(prerequisites, list) {
                print("[Concept Parser Error] Concept fields are incomplete.");
                return [];
            }
            difficulty = float(item.get("difficulty", 5.0));
            if difficulty < 1.0 {
                difficulty = 1.0;
            } elif difficulty > 10.0 {
                difficulty = 10.0;
            }
            extracted.append(RawExtractedConcept(
                name=name,
                summary=summary,
                formula_or_rule=str(item.get("formula_or_rule", "")),
                difficulty=difficulty,
                prerequisites=[str(value) for value in prerequisites]
            ));
        }
        return extracted;
    } except Exception as e {
        print(f"[Concept Parser Error] {e}");
        return [];
    }
}

# Jac's current compiler disables `by llm()` calls, so this uses the shared Jac OpenRouter client directly.
def extract_concepts_from_text(lecture_title: str, notes_content: str, image_b64: str = "") -> list[RawExtractedConcept] {
    sys_prompt = "You are an expert cognitive learning assistant. Analyze only the supplied lecture notes or image. Return one JSON object with a concepts key containing 4-8 atomic concepts. Every concept must contain name, a one-sentence summary, formula_or_rule, difficulty from 1 to 10, and prerequisite concept names from the same response. Do not add unrelated subject matter.";
    user_prompt = f"Lecture Title: {lecture_title}\nNotes Content: {notes_content}";

    raw_response = query_openrouter(MODEL_VISION, sys_prompt, user_prompt, image_b64, True, 4096);
    return parse_extracted_concepts(raw_response);
}
