# Role-based OpenRouter model configuration for live byLLM agents.
# The API key is read only by the Jac backend and is never sent to mobile.
import os;
import from byllm.lib { Model }

glob openrouter_config = {
    "api_base": os.getenv("OPENROUTER_BASE_URL") or "https://openrouter.ai/api/v1",
    "http_client": False
};

glob lecture_llm = Model(
    model_name=f"openrouter/{os.getenv('VISION_MODEL') or 'nvidia/nemotron-3.5-super-vl:free'}",
    api_key=os.getenv("OPENROUTER_API_KEY") or "",
    config=openrouter_config
);

glob quiz_llm = Model(
    model_name=f"openrouter/{os.getenv('REASONING_MODEL') or 'nvidia/nemotron-3-super-120b-a12b:free'}",
    api_key=os.getenv("OPENROUTER_API_KEY") or "",
    config=openrouter_config
);

glob evaluator_llm = Model(
    model_name=f"openrouter/{os.getenv('EVALUATOR_MODEL') or 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free'}",
    api_key=os.getenv("OPENROUTER_API_KEY") or "",
    config=openrouter_config
);

glob fast_llm = Model(
    model_name=f"openrouter/{os.getenv('FAST_MODEL') or 'liquid/lfm-2.5-2.6b:free'}",
    api_key=os.getenv("OPENROUTER_API_KEY") or "",
    config=openrouter_config
);

# Compatibility alias for agents that have not yet selected a specialist.
glob llm = quiz_llm;
