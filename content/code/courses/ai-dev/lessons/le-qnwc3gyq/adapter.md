---
title: One door to every provider
version: 2
---

The shop should not care which provider answered. **An adapter is a single function the rest of
the code calls**, with one shape for the question and one for the reply, and one implementation
per provider behind it. It is also the one place to decide what to do when a provider is down.

## The adapter

```schooling-example
{
  "language": "python",
  "file": "llm.py",
  "parts": [
    {
      "code": "\"\"\"One way for the shop to ask a model, whichever provider is behind it.\"\"\"\nimport os\nfrom dataclasses import dataclass\n\nimport anthropic\nimport openai\nfrom google import genai\nfrom google.genai import errors as genai_errors\nfrom google.genai import types\n\n\n"
    },
    {
      "code": "@dataclass\nclass Reply:\n    text: str\n    tokens_in: int\n    tokens_out: int\n    provider: str\n\n\n",
      "note": "**One shape for every reply**, whichever provider wrote it, with the provider's name kept for the log."
    },
    {
      "code": "class Unavailable(Exception):\n    \"\"\"The provider could not answer after its SDK's own retries.\"\"\"\n\n\n",
      "note": "**One exception for \"this provider cannot answer now\"**, which is what the fallback looks for."
    },
    {
      "code": "def _anthropic(system, question, max_tokens):\n    try:\n        r = anthropic.Anthropic().messages.create(model=os.environ[\"LLM_MODEL_ANTHROPIC\"], max_tokens=max_tokens,\n                                                  system=system, messages=[{\"role\": \"user\", \"content\": question}])\n    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:\n        raise Unavailable(f\"anthropic: {type(e).__name__}\") from e\n    tokens_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # Ollama reports reuse apart\n    return Reply(r.content[0].text, tokens_in, r.usage.output_tokens, \"anthropic\")\n\n\n",
      "note": "**Each provider is a small function** that translates the question in and the reply out, and turns the failures it expects into `Unavailable`. Which failures it expects is the part section 08 shows to be wrong."
    },
    {
      "code": "def _openai(system, question, max_tokens):\n    try:\n        r = openai.OpenAI().chat.completions.create(\n            model=os.environ[\"LLM_MODEL_OPENAI\"], max_completion_tokens=max_tokens,\n            messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": question}])\n    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:\n        raise Unavailable(f\"openai: {type(e).__name__}\") from e\n    return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, \"openai\")\n\n\n",
      "note": "**The model's name comes from the environment**, never from the code."
    },
    {
      "code": "def _google(system, question, max_tokens):\n    try:\n        r = genai.Client().models.generate_content(\n            model=os.environ[\"LLM_MODEL_GOOGLE\"], contents=question,\n            config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,\n                                               automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    except genai_errors.ServerError as e:\n        raise Unavailable(f\"google: {type(e).__name__}\") from e\n    u = r.usage_metadata\n    return Reply(r.text, u.prompt_token_count, u.candidates_token_count, \"google\")\n\n\n"
    },
    {
      "code": "PROVIDERS = {\"anthropic\": _anthropic, \"openai\": _openai, \"google\": _google}\n\n\n"
    },
    {
      "code": "def ask(system, question, max_tokens=300):\n    \"\"\"Ask the providers in LLM_PROVIDERS, in order, until one answers.\"\"\"\n    tried = []\n    for name in os.environ[\"LLM_PROVIDERS\"].split(\",\"):\n        try:\n            return PROVIDERS[name](system, question, max_tokens)\n        except Unavailable as e:\n            tried.append(str(e))\n    raise Unavailable(\"; \".join(tried))\n",
      "note": "**The fallback**: try each provider in `LLM_PROVIDERS`, in order, and say which ones failed if none answered."
    }
  ]
}
```

`ask.py` is all the shop sees:

```python
import sys

from llm import ask

r = ask("Answer in one paragraph.", sys.argv[1])
print(f"{r.provider}: {r.tokens_in} in, {r.tokens_out} out | {' '.join(r.text.split())[:48]}…")
```

The models come from the environment, and `.env` holds them, beside the `.gitignore` of section 03
that keeps it out of git:

```
ana@dev:~/shop$ cat .env
LLM_MODEL_ANTHROPIC=llama3.2:3b
LLM_MODEL_OPENAI=llama3.2:3b
LLM_MODEL_GOOGLE=gemini-3.5-flash
ana@dev:~/shop$ set -a; . ./.env; for p in anthropic openai; do LLM_PROVIDERS=$p python ask.py "Explain in a paragraph why the cart stores prices in cents."; done
anthropic: 43 in, 136 out | The carton of eggs, milk, and many other product…
openai: 43 in, 119 out | The reason cart stores often display prices in c…
```

**Two providers, one line of output each, and the shop's code did not change.** Only
`LLM_PROVIDERS` did. Both are Ollama here, with the same model behind two formats, which is enough to
prove the adapter; a real deployment points the two variables of each SDK at two companies.

## Testing the fallback

The point of a list of providers is to ask the next one when the first is down. **A fallback that has
never run is a guess**, so ana breaks the first provider on purpose, by pointing the Anthropic SDK at
an address where nothing listens:

```
ana@dev:~/shop$ set -a; . ./.env; ANTHROPIC_BASE_URL=http://127.0.0.1:11400 LLM_PROVIDERS=anthropic,openai python ask.py "Explain in a paragraph why the cart stores prices in cents."
openai: 43 in, 157 out | The practice of pricing items in cents in retail…
```

The Anthropic SDK tried three times, raised `APIConnectionError`, the adapter turned it into
`Unavailable`, and OpenAI's side answered. That works.

## The fallback that would not have fallen back

A connection error is one way for a provider to be down. Another is the provider answering 529,
*overloaded*, which Anthropic's API does when it is busy and which the Anthropic SDK raises as
`OverloadedError`. The adapter catches `InternalServerError`, the 5xx error, and that sounds as if it
covers 529. The SDK's class tree says otherwise:

```
ana@dev:~/shop$ python -c 'import anthropic; print(anthropic.OverloadedError.__mro__[1].__name__, issubclass(anthropic.OverloadedError, anthropic.InternalServerError))'
APIStatusError False
```

**`OverloadedError` is a sibling of `InternalServerError`, not a kind of it**: both come straight from
`APIStatusError`. On the first day Anthropic was overloaded, the adapter would have let a 529 through
to the person, with OpenAI never asked. The code reads correctly, and the list of exceptions is a
guess about the SDK's class tree. No provider was needed to find that; one line of Python was.

The fix decides by status code instead of by class name, in one function used by all three:

```
ana@dev:~/shop$ git diff llm.py
diff --git a/llm.py b/llm.py
index 6fee7eb..1bac79e 100644
--- a/llm.py
+++ b/llm.py
@@ -21,11 +21,19 @@ class Unavailable(Exception):
     """The provider could not answer after its SDK's own retries."""
 
 
+def transient(e):
+    """Worth asking another provider: no connection, a rate limit, or the provider's own failure."""
+    status = getattr(e, "status_code", None) or getattr(e, "code", None)
+    return status is None or status == 429 or status >= 500
+
+
 def _anthropic(system, question, max_tokens):
     try:
         r = anthropic.Anthropic().messages.create(model=os.environ["LLM_MODEL_ANTHROPIC"], max_tokens=max_tokens,
                                                   system=system, messages=[{"role": "user", "content": question}])
-    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:
+    except (anthropic.APIConnectionError, anthropic.APIStatusError) as e:
+        if not transient(e):
+            raise
         raise Unavailable(f"anthropic: {type(e).__name__}") from e
     tokens_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # Ollama reports reuse apart
     return Reply(r.content[0].text, tokens_in, r.usage.output_tokens, "anthropic")
@@ -36,7 +44,9 @@ def _openai(system, question, max_tokens):
         r = openai.OpenAI().chat.completions.create(
             model=os.environ["LLM_MODEL_OPENAI"], max_completion_tokens=max_tokens,
             messages=[{"role": "system", "content": system}, {"role": "user", "content": question}])
-    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:
+    except (openai.APIConnectionError, openai.APIStatusError) as e:
+        if not transient(e):
+            raise
         raise Unavailable(f"openai: {type(e).__name__}") from e
     return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, "openai")
 
@@ -47,7 +57,9 @@ def _google(system, question, max_tokens):
             model=os.environ["LLM_MODEL_GOOGLE"], contents=question,
             config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,
                                                automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))
-    except genai_errors.ServerError as e:
+    except genai_errors.APIError as e:
+        if not transient(e):
+            raise
         raise Unavailable(f"google: {type(e).__name__}") from e
     u = r.usage_metadata
     return Reply(r.text, u.prompt_token_count, u.candidates_token_count, "google")
ana@dev:~/shop$ set -a; . ./.env; ANTHROPIC_BASE_URL=http://127.0.0.1:11400 LLM_PROVIDERS=anthropic,openai python ask.py "Explain in a paragraph why the cart stores prices in cents."
openai: 43 in, 164 out | The tradition of pricing in cents in cart stores…
ana@dev:~/shop$ set -a; . ./.env; LLM_MODEL_ANTHROPIC=llama3.3:3b LLM_PROVIDERS=anthropic,openai python ask.py "Explain in a paragraph why the cart stores prices in cents." 2>&1 | tail -n 1
anthropic.NotFoundError: Error code: 404 - {'type': 'error', 'error': {'type': 'not_found_error', 'message': "model 'llama3.3:3b' not found"}, 'request_id': 'req_780af3135b5318250dc67acf'}
```

**The unreachable address still falls back**: a connection error has no status code, and `transient`
counts it. **A model name that does not exist does not**: `llama3.3:3b` was never pulled, Ollama
answers 404, and the adapter raises it instead of asking OpenAI. That is deliberate. A 400, a 401 or a
404 is a wrong request, a wrong key or a wrong name, and asking another provider would not fix it; it
would only hide it, behind a reply from a model nobody chose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"How ask() treats a failure. It calls the first provider, whose SDK retries on its own, and a reply from it goes straight back. If the error is transient, a lost connection, a 429 or a 5xx, it moves to the next provider in the list. Any other error, such as a 400 or a 401, goes straight to the caller.\"><defs><marker id=\"fb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask()</text><path d=\"M112 92 L148 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"150\" y=\"64\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first provider</text><text x=\"235.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the SDK retries twice</text><path d=\"M322 92 L368 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"370\" y=\"64\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">transient?</text><text x=\"445.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no connection, 429, 5xx</text><path d=\"M522 92 L568 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"545\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"570\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">next provider</text><path d=\"M635 122 L635 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"635\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a reply</text><path d=\"M235 122 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"235\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a reply</text><path d=\"M445 122 L445 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"445\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">raised to the caller</text><text x=\"452\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no: 400, 401…</text></svg>", "caption": "Only a failure that time or another provider can fix moves down the list. A wrong request fails the same way everywhere."}
```


## Before you rely on a fallback

- **Test it by breaking the first provider**, as here, in every way you can make it break.
- **Evaluate the second model too.** A fallback answers your users with a different model, so it
  must pass the same evaluation as the first.
- **Log which provider answered.** `Reply.provider` is there so that a week of quiet fallbacks
  shows up as a number, not as a surprise on the bill.
