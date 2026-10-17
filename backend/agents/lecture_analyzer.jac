# Lecture Analyzer Agent (Dev 2 Domain)
# Uses byllm via OpenRouter for text concept extraction. The configured vision
# model remains reserved for the upcoming image-input path.
# to analyze lecture content (text, slide OCR, notes) and extract atomic concepts.

import from backend.llm_config { lecture_llm }

# Structured concept definition extracted from lecture notes
obj RawExtractedConcept {
    has name: str;
    has summary: str;
    has formula_or_rule: str = "";
    has difficulty: float = 5.0;
    has prerequisites: list[str] = [];
}

# Live Meaning-Typed LLM function. The return type makes the model response
# structured and directly usable by the graph builder.
def extract_concepts_with_llm(lecture_title: str, notes_content: str) -> list[RawExtractedConcept] by lecture_llm();
sem extract_concepts_with_llm = "Extract 3 to 8 atomic learning concepts from the lecture. Return only concepts grounded in the supplied material. For each concept provide a concise summary, any formula or rule, difficulty from 1 to 10, and prerequisite concept names. Do not invent facts that are not supported by the notes.";

# Public analyzer entrypoint. If the model fails, the error propagates to the
# UI; never substitute unrelated seeded concepts for the user's lecture.
def extract_concepts_from_text(lecture_title: str, notes_content: str) -> list[RawExtractedConcept] {
    concepts = extract_concepts_with_llm(lecture_title, notes_content);
    if len(concepts) == 0 {
        raise Exception("The lecture model returned no concepts.");
    }
    return concepts;
}
