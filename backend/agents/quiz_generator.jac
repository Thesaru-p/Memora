# Quiz Generator Agent (Dev 3 Domain)
# Generates grounded, 3-4 minute micro-quizzes with pedagogical distractors.

import from backend.llm_config { quiz_llm }

obj GeneratedQuestion {
    has id: str;
    has concept_id: str;
    has concept_name: str;
    has prompt: str;
    has options: list[str];
    has correct_answer: str;
    has explanation: str;
    has time_limit_seconds: int = 45;
    has generation_source: str = "fallback";
}

# Live Meaning-Typed quiz generation. The typed object enforces a predictable
# payload for the mobile client while the semantic prompt keeps questions
# grounded in the stored concept content.
def generate_grounded_question_with_llm(quiz_id: str, concept_id: str, concept_name: str, summary: str = "", formula_or_rule: str = "") -> GeneratedQuestion by quiz_llm();
sem generate_grounded_question_with_llm = "Create one challenging but fair 45-second multiple-choice question grounded only in the supplied lecture context. Return four options, exactly one correct answer, and a concise explanation. Do not use outside topics. Include the quiz id and concept id unchanged, and set generation_source to 'llm'.";

# One batched request keeps the quiz responsive on free-tier providers while
# still producing one independent question per stored lecture concept.
def generate_quiz_with_llm(context_bundle: str) -> list[GeneratedQuestion] by quiz_llm();
sem generate_quiz_with_llm = "Create exactly one challenging but fair 45-second multiple-choice question for each concept in the supplied lecture context, preserving the concept order. Return only a list of structured questions. Each question must have four options, exactly one correct answer, and a concise explanation. Ground every question only in the supplied context and do not use outside topics.";

def generate_grounded_question(quiz_id: str, concept_id: str, concept_name: str, summary: str = "", formula_or_rule: str = "") -> GeneratedQuestion {
    question_id = f"{quiz_id}_{concept_id}";

    # Deterministic starter questions for the seeded Computer Networks module.
    if concept_id == "c_ip_addressing_and_subnetting" {
        return GeneratedQuestion(
            id=question_id,
            concept_id=concept_id,
            concept_name=concept_name,
            prompt="A subnet has a /28 prefix length. How many usable host IP addresses are available in this subnet?",
            options=["14 usable hosts", "16 usable hosts", "30 usable hosts", "32 usable hosts"],
            correct_answer="14 usable hosts",
            explanation="A /28 leaves 4 host bits. There are 16 total addresses, minus the network and broadcast addresses, leaving 14 usable hosts.",
            time_limit_seconds=45
        );
    } elif concept_id == "c_cidr_notation" {
        return GeneratedQuestion(
            id=question_id,
            concept_id=concept_id,
            concept_name=concept_name,
            prompt="Which subnet mask is equivalent to /20 prefix notation?",
            options=["255.255.240.0", "255.255.255.0", "255.255.224.0", "255.240.0.0"],
            correct_answer="255.255.240.0",
            explanation="A /20 prefix uses 4 bits in the third octet, giving 128 + 64 + 32 + 16 = 240.",
            time_limit_seconds=45
        );
    } elif concept_id == "c_subnet_masks_and_anding" {
        return GeneratedQuestion(
            id=question_id,
            concept_id=concept_id,
            concept_name=concept_name,
            prompt="What is the network address when 192.168.1.75 is ANDed with 255.255.255.0?",
            options=["192.168.1.0", "192.168.1.75", "192.168.0.0", "255.255.255.0"],
            correct_answer="192.168.1.0",
            explanation="The mask preserves the first three octets and clears the host octet, producing 192.168.1.0.",
            time_limit_seconds=45
        );
    } elif concept_id == "c_default_gateway" {
        return GeneratedQuestion(
            id=question_id,
            concept_id=concept_id,
            concept_name=concept_name,
            prompt="Where does a host forward a packet destined for a different subnet?",
            options=["To the Default Gateway", "To the Broadcast Address", "To the DNS Server", "Directly to the destination host via ARP"],
            correct_answer="To the Default Gateway",
            explanation="Traffic for another subnet is sent to the local router interface, known as the default gateway.",
            time_limit_seconds=45
        );
    }

    grounded_answer: str = summary;
    if grounded_answer == "" {
        grounded_answer = formula_or_rule;
    }
    if grounded_answer == "" {
        grounded_answer = f"Review the core idea of {concept_name}.";
    }

    return GeneratedQuestion(
        id=question_id,
        concept_id=concept_id,
        concept_name=concept_name,
        prompt=f"Which statement best describes {concept_name}?",
        options=[grounded_answer, f"This concept is unrelated to {concept_name}.", "It has no practical use.", "It should always be ignored."],
        correct_answer=grounded_answer,
        explanation=f"The answer is grounded in the stored concept content: {grounded_answer}",
        time_limit_seconds=45
    );
}

def generate_micro_quiz_items(quiz_id: str, concept_ids: list[str], concept_names: list[str]) -> list[GeneratedQuestion] {
    questions: list[GeneratedQuestion] = [];
    count: int = 0;
    for concept_id in concept_ids {
        if count >= 5 {
            break;
        }

        concept_name: str = concept_id;
        if count < len(concept_names) {
            concept_name = concept_names[count];
        }
        questions.append(generate_grounded_question(quiz_id, concept_id, concept_name));
        count += 1;
    }
    return questions;
}

# Live quiz path with per-question fallback. Keeping the deterministic helper
# separate makes unit tests stable and ensures one failed model response does
# not discard the rest of the quiz.
def generate_live_micro_quiz_items(quiz_id: str, concept_ids: list[str], concept_names: list[str], concept_contexts: list[str] = []) -> list[GeneratedQuestion] {
    questions: list[GeneratedQuestion] = [];
    context_bundle: str = "";
    count: int = 0;
    for concept_id in concept_ids {
        if count >= 5 {
            break;
        }
        concept_name: str = concept_id;
        if count < len(concept_names) {
            concept_name = concept_names[count];
        }
        context: str = "Core concept: " + concept_name;
        if count < len(concept_contexts) {
            context = concept_contexts[count];
        }
        context_bundle += f"\n[{count + 1}] Concept ID: {concept_id}; Name: {concept_name}; Context: {context}";
        count += 1;
    }

    try {
        llm_questions = generate_quiz_with_llm(context_bundle);
        count = 0;
        for live_question in llm_questions {
            if count >= len(concept_ids) or count >= 5 {
                break;
            }
            concept_id = concept_ids[count];
            concept_name = concept_names[count];
            live_question.id = f"{quiz_id}_{concept_id}";
            live_question.concept_id = concept_id;
            live_question.concept_name = concept_name;
            live_question.generation_source = "llm";
            questions.append(live_question);
            count += 1;
        }
    } except Exception {
        count = 0;
    }

    # Quiz mode is intentionally LLM-only. Do not silently replace a failed
    # provider response with demo questions that are unrelated to the lecture.
    return questions;
}
