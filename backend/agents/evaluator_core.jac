# Pure quiz evaluation helpers. Kept separate so grading can be tested without
# requiring the shared persistent graph module.

def normalize_answer(answer: str) -> str {
    return answer.strip().lower();
}

def answers_match(submitted_answer: str, correct_answer: str) -> bool {
    return normalize_answer(submitted_answer) == normalize_answer(correct_answer);
}

def calculate_score(correct_items: int, total_items: int) -> float {
    if total_items <= 0 {
        return 0.0;
    }
    return float(correct_items) / float(total_items);
}

def update_mastery(current_mastery: float, is_correct: bool) -> float {
    safe_mastery: float = current_mastery;
    if safe_mastery < 0.0 {
        safe_mastery = 0.0;
    }
    if safe_mastery > 1.0 {
        safe_mastery = 1.0;
    }

    if not is_correct {
        return safe_mastery;
    }
    if safe_mastery >= 0.75 {
        return 1.0;
    }
    return safe_mastery + 0.25;
}
