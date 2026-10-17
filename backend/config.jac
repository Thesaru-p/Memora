# OpenRouter Model Configurations for Memora Multi-Agent System
# Each agent uses the specialized model best suited for its cognitive role.

import os;
import json;
import urllib.request;

# -------------------------------------------------------------
# 1. Specialized Free Model Mapping (from OpenRouter Dashboard)
# -------------------------------------------------------------

# Agent 1 (Perception): 1M Context, Vision-Language for slide images & handwritten notes
glob MODEL_VISION = "nvidia/nemotron-3.5-super-vl:free";

# Agent 2 & 3 (Deep Pedagogical Reasoning & Question Synthesis): 550B MoE frontier reasoning
glob MODEL_REASONING = "nvidia/nemotron-3-ultra:free";

# Agent 4 (Semantic Evaluator): Fast 862ms latency for real-time answer grading
glob MODEL_EVALUATOR = "nvidia/nemotron-3-super:free";

# Agent 5 (Coaching & Scheduler): Ultra-fast 273ms latency, 216 t/s for instant notifications
glob MODEL_FAST = "liquid/lfm-2.5-2.6b:free";

glob OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1/chat/completions";

# Queries OpenRouter API with graceful fallback if key is missing or offline.
def query_openrouter(model: str, system_prompt: str, user_prompt: str, image_b64: str = "") -> str {
    api_key: str = os.environ.get("OPENROUTER_API_KEY", "");
    if not api_key {
        return "";
    }

    try {
        messages: list[dict] = [
            {"role": "system", "content": system_prompt}
        ];

        if image_b64 and len(image_b64) > 100 {
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": user_prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}
                    }
                ]
            });
        } else {
            messages.append({"role": "user", "content": user_prompt});
        }

        req_body = json.dumps({
            "model": model,
            "messages": messages,
            "temperature": 0.3
        }).encode("utf-8");

        headers: dict = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "HTTP-Referer": "https://jachammer.ai",
            "X-Title": "Memora-Jac"
        };

        req = urllib.request.Request(
            OPENROUTER_BASE_URL,
            data=req_body,
            headers=headers,
            method="POST"
        );

        with urllib.request.urlopen(req, timeout=15) as response {
            res_data = json.loads(response.read().decode("utf-8"));
            choices = res_data.get("choices", []);
            if choices and len(choices) > 0 {
                return choices[0].get("message", {}).get("content", "");
            }
        }
    } except Exception as e {
        print(f"[OpenRouter Query Warning] {e}");
        return "";
    }
    return "";
}
