# AI Provider & API Key Setup (v1.13.0)

Contexta uses a provider-agnostic AI gateway for explanations and suggestions.

## Why This Change

Contexta is open source. To avoid using a shared maintainer key, each user provides their own API key.

Benefits:
- Your own usage and billing remain under your control
- No shared key abuse risk
- No accidental maintainer credit consumption

## Setup Steps

1. Open Contexta.
2. Go to Settings -> AI provider & key.
3. Enter your provider name (for example: Gemini, Perplexity, OpenAI, Anthropic).
4. Paste the API key for that provider.
5. Tap Save API key.

## Where The Key Is Stored

- The key is stored securely on-device using encrypted secure storage.
- It is not hardcoded in the repository.
- It is not shared across users.

## Popup Guidance For Key Issues

Contexta shows clear popups when AI calls fail due to credentials.

| Scenario | Popup Meaning | What To Do |
|---|---|---|
| Key missing | No key has been set for AI calls | Open AI Settings and add a key |
| Invalid key | The configured provider rejected the saved key | Replace the key in AI Settings |
| Expired key | Saved key is expired/revoked | Generate a new key and save it |
| Quota exceeded | Key has no remaining quota right now | Wait, increase quota, or switch key |

Each popup includes an Open AI Settings action for quick recovery.

## Optional Local Dev Fallback

If needed for local development only, you can define:

```env
LLM_PROVIDER_NAME=your_provider_name_here
LLM_API_KEY=your_api_key_here
```

The recommended production/open-source flow is still in-app user key management.
