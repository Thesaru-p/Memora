# Live verification test for OpenRouter API integration in Jac
include backend.config;

with entry {
    print("Testing OpenRouter fast model via query_openrouter in Jac...");
    reply: str = query_openrouter(
        model=MODEL_FAST,
        system_prompt="You are an AI assistant. Be concise.",
        user_prompt="Say READY in one word."
    );
    print(f"OpenRouter Live Response: '{reply.strip()}'");
    assert len(reply) > 0, "Expected non-empty response from OpenRouter";
    print("OpenRouter Live Integration Test: SUCCESS!");
}
