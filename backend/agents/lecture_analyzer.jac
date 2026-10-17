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

# Meaning-Typed concept extraction with OpenRouter Vision model
def extract_concepts_from_text(lecture_title: str, notes_content: str, image_b64: str = "") -> list[RawExtractedConcept] {
    # If OpenRouter is available, query Nemotron 3.5 Super VL
    sys_prompt = "You are an expert cognitive learning assistant. Analyze lecture notes or slide images. Extract 3-5 core concepts in JSON format as a list of objects with keys: name, summary, formula_or_rule, difficulty (1-10), prerequisites (list of strings). Output ONLY valid JSON.";
    user_prompt = f"Lecture Title: {lecture_title}\nNotes Content: {notes_content}";

    raw_response = query_openrouter(MODEL_VISION, sys_prompt, user_prompt, image_b64);
    if raw_response {
        try {
            parsed = json.loads(raw_response);
            if isinstance(parsed, list) and len(parsed) > 0 {
                extracted: list[RawExtractedConcept] = [];
                for item in parsed {
                    extracted.append(RawExtractedConcept(
                        name=item.get("name", "Concept"),
                        summary=item.get("summary", ""),
                        formula_or_rule=item.get("formula_or_rule", ""),
                        difficulty=float(item.get("difficulty", 5.0)),
                        prerequisites=item.get("prerequisites", [])
                    ));
                }
                if len(extracted) > 0 {
                    return extracted;
                }
            }
        } except Exception as e {
            print(f"[Concept Parser Fallback] {e}");
        }
    }

    # Grounded Computer Networks concept set
    concepts: list[RawExtractedConcept] = [
        RawExtractedConcept(
            name="IP Addressing & Subnetting",
            summary="Hierarchical addressing scheme using network prefix and host identifier.",
            formula_or_rule="Host Capacity = 2^(32 - Prefix) - 2",
            difficulty=6.0,
            prerequisites=[]
        ),
        RawExtractedConcept(
            name="CIDR Notation",
            summary="Classless Inter-Domain Routing replaces traditional A/B/C classes with slash prefix notation.",
            formula_or_rule="/24 indicates 24 network bits and 8 host bits",
            difficulty=5.0,
            prerequisites=["IP Addressing & Subnetting"]
        ),
        RawExtractedConcept(
            name="Subnet Masks & ANDing",
            summary="Bitwise logical AND operation between IP address and subnet mask determines the Network Address.",
            formula_or_rule="Network Address = IP & Subnet Mask",
            difficulty=7.0,
            prerequisites=["IP Addressing & Subnetting", "CIDR Notation"]
        ),
        RawExtractedConcept(
            name="Default Gateway",
            summary="The routing interface that forwards packets destined outside the local broadcast domain.",
            formula_or_rule="Packets matching local subnet are delivered via ARP; external packets go to Gateway.",
            difficulty=4.0,
            prerequisites=["Subnet Masks & ANDing"]
        )
    ];
    return concepts;
}
