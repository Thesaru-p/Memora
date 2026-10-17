# Lecture Analyzer Agent (Dev 2 Domain)
# Meaning-typed extraction through OpenRouter and Nemotron Super VL.

import os;
import from byllm.lib { Image, Model }

glob analyzer_llm = Model(
    model_name="openrouter/nvidia/nemotron-3.5-super-vl:free",
    api_key=os.environ.get("OPENROUTER_API_KEY", ""),
    config={"api_base": "https://openrouter.ai/api/v1"}
);

obj RawExtractedConcept {
    has name: str;
    has summary: str;
    has formula_or_rule: str = "";
    has difficulty: float = 5.0;
    has prerequisites: list[str] = [];
}

sem RawExtractedConcept = "An atomic, independently testable concept from one lecture.";
sem RawExtractedConcept.name = "A concise concept name used as its graph label.";
sem RawExtractedConcept.summary = "One sentence grounded only in the supplied lecture material.";
sem RawExtractedConcept.formula_or_rule = "The key formula or rule, or an empty string when none is present.";
sem RawExtractedConcept.difficulty = "Estimated learning difficulty from 1.0 (easy) to 10.0 (hard).";
sem RawExtractedConcept.prerequisites = "Names of other extracted concepts required first; use exact names from this result.";

sem extract_concepts_from_text = "Extract 4 to 8 atomic concepts from the supplied lecture title and transcript. Stay grounded in the material, merge duplicates, and order concepts from foundational to advanced.";
sem extract_concepts_from_text.lecture_title = "The lecture title, used only to establish subject context.";
sem extract_concepts_from_text.notes_content = "The raw lecture transcript or pasted notes. This is the source of truth.";
def extract_concepts_from_text(
    lecture_title: str,
    notes_content: str
) -> list[RawExtractedConcept] by analyzer_llm(temperature=0.1);

sem extract_concepts_from_image = "Read the supplied slide, whiteboard, or handwritten-note image and extract 4 to 8 atomic concepts. Combine visible content with the optional transcript, stay grounded in those sources, merge duplicates, and order concepts from foundational to advanced.";
sem extract_concepts_from_image.lecture_title = "The lecture title, used only to establish subject context.";
sem extract_concepts_from_image.notes_content = "Optional accompanying transcript or notes; may be empty.";
sem extract_concepts_from_image.image = "A lecture slide, whiteboard photo, or handwritten-note image.";
def extract_concepts_from_image(
    lecture_title: str,
    notes_content: str,
    image: Image
) -> list[RawExtractedConcept] by analyzer_llm(temperature=0.1);
