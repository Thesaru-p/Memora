# OpenRouter Model Configurations for Memora Multi-Agent System
# Each agent uses the specialized model best suited for its cognitive role.

import os;
import json;
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError, URLError }
import from http.client { HTTPResponse }
import dotenv;

# -------------------------------------------------------------
# 1. Specialized Free Model Mapping (Tested & Active Free Models)
# -------------------------------------------------------------

# Agent 1 (Perception): 1M Context, Vision-Language for slide images & handwritten notes
glob MODEL_VISION = "nvidia/nemotron-3.5-super-vl:free";

# Agent 2 & 3 (Deep Pedagogical Reasoning & Question Synthesis): 120B MoE frontier reasoning
glob MODEL_REASONING = "nvidia/nemotron-3-super-120b-a12b:free";

# Agent 4 (Semantic Evaluator): Fast reasoning for real-time answer grading
glob MODEL_EVALUATOR = "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free";

# Agent 5 (Coaching & Scheduler): Ultra-fast 273ms latency, 216 t/s for instant notifications
glob MODEL_FAST = "liquid/lfm-2.5-2.6b:free";

glob OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1/chat/completions";

obj OpenRouterResponse {
    has status: str;
    has message: str;
    has model: str;
    has content: str = "";
    has key_configured: bool = False;
    has request_attempted: bool = False;
    has http_status: int = 0;
}

def resolve_openrouter_model(model: str) -> str {
    selected_model: str = model;
    if model == MODEL_VISION and os.environ.get("VISION_MODEL") {
        selected_model = os.environ.get("VISION_MODEL", model);
    } elif model == MODEL_REASONING and os.environ.get("REASONING_MODEL") {
        selected_model = os.environ.get("REASONING_MODEL", model);
    } elif model == MODEL_EVALUATOR and os.environ.get("EVALUATOR_MODEL") {
        selected_model = os.environ.get("EVALUATOR_MODEL", model);
    } elif model == MODEL_FAST and os.environ.get("FAST_MODEL") {
        selected_model = os.environ.get("FAST_MODEL", model);
    }

    return selected_model;
}

# The diagnostic and every agent use this exact credential/request path.
def request_openrouter(
    model: str,
    system_prompt: str,
    user_prompt: str,
    image_b64: str = "",
    json_mode: bool = False,
    max_tokens: int = 2048
) -> OpenRouterResponse {
    dotenv.load_dotenv();
    api_key: str = os.environ.get("OPENROUTER_API_KEY", "").strip();
    selected_model = resolve_openrouter_model(model);
    result = OpenRouterResponse(
        status="missing_key",
        message="OPENROUTER_API_KEY is not loaded in the running backend. Restart the preview after setting it.",
        model=selected_model,
        key_configured=bool(api_key)
    );
    if not api_key {
        return result;
    }

    try {
        messages: list[dict] = [
            {"role": "system", "content": system_prompt}
        ];

        if image_b64 {
            image_url = image_b64 if image_b64.startswith("data:image/") else f"data:image/jpeg;base64,{image_b64}";
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": user_prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": image_url}
                    }
                ]
            });
        } else {
            messages.append({"role": "user", "content": user_prompt});
        }

        request_data: dict[str, any] = {
            "model": selected_model,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": max_tokens,
            "reasoning": {"enabled": False, "exclude": True}
        };
        if json_mode {
            request_data["response_format"] = {"type": "json_object"};
        }
        req_body = json.dumps(request_data).encode("utf-8");

        headers: dict[str, str] = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "HTTP-Referer": "https://jachammer.ai",
            "X-Title": "Memora-Jac"
        };

        req = Request(
            OPENROUTER_BASE_URL,
            data=req_body,
            headers=headers,
            method="POST"
        );

        result.request_attempted = True;
        with (urlopen(req, timeout=25) as HTTPResponse) as response {
            result.http_status = int(response.status);
            res_data = json.loads(response.read().decode("utf-8"));
            result.status = "invalid_response";
            result.message = "OpenRouter returned no usable model answer.";
            choices: list[dict[str, any]] = res_data.get("choices", []) as list[dict[str, any]];
            if choices and len(choices) > 0 {
                msg = choices[0].get("message", {});
                content = msg.get("content", "");
                if content {
                    result.status = "connected";
                    result.message = "The backend sent its configured key and received a model answer. Lecture extraction is checked separately.";
                    result.content = str(content);
                    return result;
                }
                reasoning = msg.get("reasoning", "");
                if reasoning {
                    result.status = "reasoning_only";
                    result.message = "OpenRouter accepted the request but returned reasoning without a final answer. Lecture extraction will stop without writing graph nodes.";
                    return result;
                }
            }
        }
    } except HTTPError as e {
        result.http_status = e.code;
        result.status = "provider_error";
        result.message = f"OpenRouter returned HTTP {e.code}. Check the provider request in OpenRouter activity.";
        if e.code == 401 {
            result.status = "unauthorized";
            result.message = "OpenRouter rejected the backend API key (HTTP 401).";
        } elif e.code == 403 {
            result.status = "forbidden";
            result.message = "OpenRouter denied access (HTTP 403). Check account and model access settings.";
        } elif e.code == 429 {
            result.status = "rate_limited";
            result.message = "OpenRouter rate limit reached (HTTP 429). Wait before testing again.";
        }
    } except TimeoutError {
        result.status = "timeout";
        result.message = "OpenRouter did not respond within the 25-second request timeout.";
    } except URLError as e {
        result.status = "network_error";
        result.message = "The backend could not reach OpenRouter. Check backend networking or retry.";
        if isinstance(e.reason, TimeoutError) {
            result.status = "timeout";
            result.message = "OpenRouter did not respond within the 25-second request timeout.";
        }
    } except Exception {
        # Never publish exception bodies: providers may echo request credentials.
        result.status = "invalid_response";
        result.message = "The OpenRouter response could not be processed.";
    }
    return result;
}

# Agents receive only final model content. Failed or reasoning-only requests are empty.
def query_openrouter(
    model: str,
    system_prompt: str,
    user_prompt: str,
    image_b64: str = "",
    json_mode: bool = False,
    max_tokens: int = 2048
) -> str {
    result = request_openrouter(model, system_prompt, user_prompt, image_b64, json_mode, max_tokens);
    if result.status in ["provider_error", "timeout", "network_error"] {
        print(f"[OpenRouter Query Retry] {result.status}");
        result = request_openrouter(model, system_prompt, user_prompt, image_b64, json_mode, max_tokens);
    }
    if result.status != "connected" {
        print(f"[OpenRouter Query Warning] {result.status}: {result.message}");
    }
    return result.content;
}

def openrouter_status(verify: bool = False) -> dict[str, any] {
    dotenv.load_dotenv();
    key_configured = bool(os.environ.get("OPENROUTER_API_KEY", "").strip());
    result = OpenRouterResponse(
        status="configured" if key_configured else "missing_key",
        message="Key loaded in the backend. Use Test OpenRouter to verify it." if key_configured else "OPENROUTER_API_KEY is not loaded in the running backend. Restart the preview after setting it.",
        model=resolve_openrouter_model(MODEL_VISION),
        key_configured=key_configured
    );
    if verify {
        result = request_openrouter(
            MODEL_VISION,
            "You are a connection check. Reply with READY only.",
            "Reply with READY."
        );
    }
    # Only explicit diagnostic fields cross the API boundary, never the key/content.
    return {
        "status": result.status,
        "message": result.message,
        "model": result.model,
        "key_configured": result.key_configured,
        "request_attempted": result.request_attempted,
        "http_status": result.http_status
    };
}
