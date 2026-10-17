# Quiz Generator Agent (Dev 3 Domain)
# Uses nvidia/nemotron-3-ultra:free via OpenRouter
# Generates grounded, 3-4 minute micro-quizzes with pedagogical distractors.

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

def generate_micro_quiz_items(quiz_id: str, concept_ids: list[str], concept_names: list[str]) -> list[GeneratedQuestion] {
    sys_prompt = "You are a master computer science educator creating a 3-minute active recall micro-quiz. For each concept, write 1 multiple-choice question with 4 options, a correct answer, and an explanation identifying the common student misconception. Return ONLY JSON as a list of objects with keys: concept_name, prompt, options (list of 4 strings), correct_answer, explanation.";
    user_prompt = f"Concepts to test: {', '.join(concept_names)}";

    raw_response = query_openrouter(MODEL_REASONING, sys_prompt, user_prompt);
    if raw_response {
        try {
            parsed = json.loads(raw_response);
            if isinstance(parsed, list) and len(parsed) > 0 {
                generated: list[GeneratedQuestion] = [];
                idx: int = 1;
                for item in parsed {
                    generated.append(GeneratedQuestion(
                        id=f"{quiz_id}_q{idx}",
                        concept_id=concept_ids[idx - 1] if idx <= len(concept_ids) else "c_general",
                        concept_name=item.get("concept_name", "Concept"),
                        prompt=item.get("prompt", ""),
                        options=item.get("options", []),
                        correct_answer=item.get("correct_answer", ""),
                        explanation=item.get("explanation", ""),
                        time_limit_seconds=45
                    ));
                    idx += 1;
                }
                if len(generated) > 0 {
                    return generated;
                }
            }
        } except Exception as e {
            print(f"[Quiz Generator Fallback] {e}");
        }
    }

    # Grounded Computer Networks questions with pedagogical misconception traps
    questions: list[GeneratedQuestion] = [
        GeneratedQuestion(
            id=f"{quiz_id}_q1",
            concept_id="c_ip_addressing_and_subnetting",
            concept_name="IP Addressing & Subnetting",
            prompt="A subnet has a /28 prefix length. How many usable host IP addresses are available in this subnet?",
            options=["14 usable hosts", "16 usable hosts", "30 usable hosts", "32 usable hosts"],
            correct_answer="14 usable hosts",
            explanation="A /28 leaves 4 host bits (32 - 28 = 4). Total addresses = 2^4 = 16. Subtracting 2 for Network and Broadcast addresses gives 14 usable hosts.",
            time_limit_seconds=45
        ),
        GeneratedQuestion(
            id=f"{quiz_id}_q2",
            concept_id="c_cidr_notation",
            concept_name="CIDR Notation",
            prompt="Which of the following subnet masks is equivalent to /20 prefix notation?",
            options=["255.255.240.0", "255.255.255.0", "255.255.224.0", "255.240.0.0"],
            correct_answer="255.255.240.0",
            explanation="/20 consists of 8 + 8 + 4 bits. In the third octet, 4 bits set is 128 + 64 + 32 + 16 = 240, yielding 255.255.240.0.",
            time_limit_seconds=45
        ),
        GeneratedQuestion(
            id=f"{quiz_id}_q3",
            concept_id="c_subnet_masks_and_anding",
            concept_name="Subnet Masks & ANDing",
            prompt="What is the result of performing a bitwise logical AND between IP 192.168.1.75 and Subnet Mask 255.255.255.0?",
            options=["192.168.1.0", "192.168.1.75", "192.168.0.0", "255.255.255.0"],
            correct_answer="192.168.1.0",
            explanation="The bitwise AND preserves the network portion matching the mask's 1-bits and zeroes out host bits (75 & 0 = 0), yielding Network Address 192.168.1.0.",
            time_limit_seconds=45
        ),
        GeneratedQuestion(
            id=f"{quiz_id}_q4",
            concept_id="c_default_gateway",
            concept_name="Default Gateway",
            prompt="When a host needs to transmit a packet to a destination IP on a different subnet, where does it forward the packet?",
            options=["To the Default Gateway", "To the Broadcast Address", "To the DNS Server", "Directly to the destination host via ARP"],
            correct_answer="To the Default Gateway",
            explanation="A host uses ARP only for destinations on the same local subnet. Cross-subnet traffic is directed to the Default Gateway interface.",
            time_limit_seconds=45
        )
    ];
    return questions;
}
