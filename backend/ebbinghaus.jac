# Ebbinghaus Forgetting Curve and Spaced Repetition Mathematical Engine
# Owned primarily by Dev 3 (Cognitive Engine & Quiz Lead)

import math;

# Calculates Retrievability R(t) = exp(-t / S).
# When t = 0, R = 1.0 (100% retention right after learning).
# When t = S, R = exp(-1) ~ 0.368 (~37%).
def calc_retrievability(stability: float, days_elapsed: float) -> float {
    if stability <= 0.0 {
        return 0.0;
    }
    if days_elapsed <= 0.0 {
        return 1.0;
    }
    decay = -1.0 * (days_elapsed / stability);
    retrieval = math.exp(decay);
    if retrieval > 1.0 {
        return 1.0;
    }
    if retrieval < 0.01 {
        return 0.01;
    }
    return retrieval;
}

# Recalibrates memory stability S after student completes a quiz item.
# - grade: Score from 0.0 (blank/missed) to 1.0 (perfect).
# - If grade >= 0.7: Stability multiplies (curve flattens).
# - If grade < 0.7: Stability drops, scheduling next quiz soon.
def update_stability(curr_stability: float, grade: float, curr_retrievability: float, difficulty: float = 5.0) -> float {
    safe_stability: float = 1.0;
    if curr_stability > 0.5 {
        safe_stability = curr_stability;
    }

    safe_diff: float = 5.0;
    if difficulty >= 1.0 and difficulty <= 10.0 {
        safe_diff = difficulty;
    }

    if grade >= 0.7 {
        difficulty_factor = (11.0 - safe_diff) / 10.0;
        bonus = 1.5 * (1.0 - curr_retrievability) * difficulty_factor;
        multiplier: float = 1.8 + bonus;
        if multiplier > 3.5 {
            multiplier = 3.5;
        }
        return safe_stability * multiplier;
    } else {
        new_s: float = safe_stability * 0.5;
        if new_s < 1.0 {
            return 1.0;
        }
        return new_s;
    }
}

# Calculates when the next review should occur (in days)
# to prevent retention from dropping below target_retention.
# t = -S * ln(target_retention)
def calc_next_review_days(stability: float, target_retention: float = 0.75) -> float {
    if stability <= 0.0 {
        return 1.0;
    }
    target: float = 0.75;
    if target_retention > 0.1 and target_retention < 0.99 {
        target = target_retention;
    }
    days = -1.0 * stability * math.log(target);
    if days < 0.5 {
        return 0.5;
    }
    return days;
}

# Categorizes retention into clear visual status tags for the UI.
def classify_retention_status(retrievability: float) -> str {
    if retrievability >= 0.85 {
        return "STRONG";
    } elif retrievability >= 0.60 {
        return "FADING";
    } else {
        return "CRITICAL";
    }
}
