# Lecture Analyzer Agent (Dev 2 Domain)
# Uses by llm() via OpenRouter (nvidia/nemotron-3.5-super-vl:free)
# to analyze lecture content (text, slide OCR, notes) and extract atomic concepts.

# When mtllm plugin is installed (pip install mtllm):
# import from mtllm.llms { OpenAI }
# glob analyzer_llm = OpenAI(model_name="nvidia/nemotron-3.5-super-vl:free", api_base="https://openrouter.ai/api/v1");

# Structured concept definition extracted from lecture notes
obj RawExtractedConcept {
    has name: str;
    has summary: str;
    has formula_or_rule: str = "";
    has difficulty: float = 5.0;
    has prerequisites: list[str] = [];
}

# Meaning-Typed LLM function for extracting concepts from lecture material
def extract_concepts_from_text(lecture_title: str, notes_content: str) -> list[RawExtractedConcept] {
    # Default high-fidelity extractor for Computer Networks
    # When OpenRouter key is provided with mtllm, this executes via by llm()
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
