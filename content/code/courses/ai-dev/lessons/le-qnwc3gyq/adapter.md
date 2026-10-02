---
title: One door to every provider
version: 1
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
      "code": "def _anthropic(system, question, max_tokens):\n    try:\n        r = anthropic.Anthropic().messages.create(model=os.environ[\"LLM_MODEL_ANTHROPIC\"], max_tokens=max_tokens,\n                                                  system=system, messages=[{\"role\": \"user\", \"content\": question}])\n    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:\n        raise Unavailable(f\"anthropic: {type(e).__name__}\") from e\n    return Reply(r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, \"anthropic\")\n\n\n",
      "note": "**Each provider is a small function** that translates the question in and the reply out, and turns the failures it expects into `Unavailable`. Which failures it expects is the part section 08 shows to be wrong."
    },
    {
      "code": "def _openai(system, question, max_tokens):\n    try:\n        r = openai.OpenAI().chat.completions.create(\n            model=os.environ[\"LLM_MODEL_OPENAI\"], max_completion_tokens=max_tokens,\n            messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": question}])\n    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:\n        raise Unavailable(f\"openai: {type(e).__name__}\") from e\n    return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, \"openai\")\n\n\n",
      "note": "**The model's name comes from the environment**, never from the code."
    },
    {
      "code": "def _google(system, question, max_tokens):\n    client = genai.Client(http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]))\n    try:\n        r = client.models.generate_content(\n            model=os.environ[\"LLM_MODEL_GOOGLE\"], contents=question,\n            config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,\n                                               automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    except genai_errors.ServerError as e:\n        raise Unavailable(f\"google: {type(e).__name__}\") from e\n    u = r.usage_metadata\n    return Reply(r.text, u.prompt_token_count, u.candidates_token_count, \"google\")\n\n\n"
    },
    {
      "code": "PROVIDERS = {\"anthropic\": _anthropic, \"openai\": _openai, \"google\": _google}\n\n\n"
    },
    {
      "code": "def ask(system, question, max_tokens=300):\n    \"\"\"Ask the providers in LLM_PROVIDERS, in order, until one answers.\"\"\"\n    tried = []\n    for name in os.environ[\"LLM_PROVIDERS\"].split(\",\"):\n        try:\n            return PROVIDERS[name](system, question, max_tokens)\n        except Unavailable as e:\n            tried.append(str(e))\n    raise Unavailable(\"; \".join(tried))",
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
print(f"{r.provider}: {r.tokens_in} in, {r.tokens_out} out | {r.text[:48]}…")
```

The models come from the environment, and `.env` holds them for the lab:

```
ana@dev:~/shop$ cat .env
LLM_MODEL_ANTHROPIC=scripted-1
LLM_MODEL_OPENAI=scripted-1
LLM_MODEL_GOOGLE=scripted-1
ana@dev:~/shop$ set -a; . ./.env; for p in anthropic openai google; do LLM_PROVIDERS=$p python ask.py "Explain in a paragraph why the cart stores prices in cents."; done
anthropic: 20 in, 82 out | The cart stores prices as integer cents because …
openai: 20 in, 82 out | The cart stores prices as integer cents because …
google: 20 in, 82 out | The cart stores prices as integer cents because …
```

**Three providers, one line of output each, and the shop's code did not change.** Only
`LLM_PROVIDERS` did.

## The fallback that did not fall back

The point of a list of providers is to ask the next one when the first is down. labllm is told to
answer 529 three times, which is one more than the Anthropic SDK retries:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 3}' >/dev/null; set -a; . ./.env; LLM_PROVIDERS=anthropic,openai python ask.py 'Explain in a paragraph why the cart stores prices in cents.' 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_lab_0026'}
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["path"], r["status"]) for r in map(json.loads, sys.stdin)]'
/v1/messages 529
/v1/messages 529
/v1/messages 529
```

**The fallback never ran.** Three 529s and an `OverloadedError` straight to the person, with
OpenAI never asked. The adapter catches `InternalServerError`, and in this SDK a 529 is an
`OverloadedError`, which is a sibling of `InternalServerError`, not a kind of it. The code read
correctly, and the list of exceptions was a guess about the SDK's class tree.

The fix decides by status code instead of by class name, in one function used by all three:

```
ana@dev:~/shop$ git diff llm.py
diff --git a/llm.py b/llm.py
index 7427dfa..acea00d 100644
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
     return Reply(r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, "anthropic")
 
@@ -35,7 +43,9 @@ def _openai(system, question, max_tokens):
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
```

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 3}' >/dev/null; set -a; . ./.env; LLM_PROVIDERS=anthropic,openai python ask.py 'Explain in a paragraph why the cart stores prices in cents.'
openai: 20 in, 82 out | The cart stores prices as integer cents because …
ana@dev:~/shop$ tail -n 4 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["path"], r["status"]) for r in map(json.loads, sys.stdin)]'
/v1/messages 529
/v1/messages 529
/v1/messages 529
/v1/chat/completions 200
```

**Three 529s, then OpenAI answered**, and the person got a reply. A 400 or a 401 still goes
straight through `raise`, because asking another provider would not fix a wrong request or a
wrong key; it would only hide them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"How ask() treats a failure. It calls the first provider, whose SDK retries on its own, and a reply from it goes straight back. If the error is transient, a lost connection, a 429 or a 5xx, it moves to the next provider in the list. Any other error, such as a 400 or a 401, goes straight to the caller.\"><defs><marker id=\"fb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask()</text><path d=\"M112 92 L148 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"150\" y=\"64\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">first provider</text><text x=\"235.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the SDK retries twice</text><path d=\"M322 92 L368 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"370\" y=\"64\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">transient?</text><text x=\"445.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no connection, 429, 5xx</text><path d=\"M522 92 L568 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"545\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">yes</text><rect x=\"570\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">next provider</text><path d=\"M635 122 L635 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"635\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a reply</text><path d=\"M235 122 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"235\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a reply</text><path d=\"M445 122 L445 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"445\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">raised to the caller</text><text x=\"452\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no: 400, 401…</text></svg>", "caption": "Only a failure that time or another provider can fix moves down the list. A wrong request fails the same way everywhere."}
```

## Before you rely on a fallback

- **Test it by breaking the first provider**, as here. A fallback that has never run is a guess.
- **Evaluate the second model too.** A fallback answers your users with a different model, so it
  must pass the same evaluation as the first.
- **Log which provider answered.** `Reply.provider` is there so that a week of quiet fallbacks
  shows up as a number, not as a surprise on the bill.
