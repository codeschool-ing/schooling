---
title: Uma porta para todo provedor
version: 1
---

A loja não deveria se importar com qual provedor respondeu. **Um adaptador é uma função única que o
resto do código chama**, com um formato para a pergunta e um para a resposta, e uma implementação
por provedor atrás dela. Ele também é o único lugar para decidir o que fazer quando um provedor está
fora.

## O adaptador

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
      "note": "**Um formato para toda resposta**, seja qual for o provedor que a escreveu, com o nome do provedor guardado para o log."
    },
    {
      "code": "class Unavailable(Exception):\n    \"\"\"The provider could not answer after its SDK's own retries.\"\"\"\n\n\n",
      "note": "**Uma exceção para \"este provedor não consegue responder agora\"**, que é o que o fallback procura."
    },
    {
      "code": "def _anthropic(system, question, max_tokens):\n    try:\n        r = anthropic.Anthropic().messages.create(model=os.environ[\"LLM_MODEL_ANTHROPIC\"], max_tokens=max_tokens,\n                                                  system=system, messages=[{\"role\": \"user\", \"content\": question}])\n    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:\n        raise Unavailable(f\"anthropic: {type(e).__name__}\") from e\n    return Reply(r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, \"anthropic\")\n\n\n",
      "note": "**Cada provedor é uma função pequena** que traduz a pergunta na ida e a resposta na volta, e transforma as falhas que espera em `Unavailable`. Quais falhas ela espera é a parte que a seção 08 mostra estar errada."
    },
    {
      "code": "def _openai(system, question, max_tokens):\n    try:\n        r = openai.OpenAI().chat.completions.create(\n            model=os.environ[\"LLM_MODEL_OPENAI\"], max_completion_tokens=max_tokens,\n            messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": question}])\n    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:\n        raise Unavailable(f\"openai: {type(e).__name__}\") from e\n    return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, \"openai\")\n\n\n",
      "note": "**O nome do modelo vem do ambiente**, nunca do código."
    },
    {
      "code": "def _google(system, question, max_tokens):\n    client = genai.Client(http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]))\n    try:\n        r = client.models.generate_content(\n            model=os.environ[\"LLM_MODEL_GOOGLE\"], contents=question,\n            config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,\n                                               automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    except genai_errors.ServerError as e:\n        raise Unavailable(f\"google: {type(e).__name__}\") from e\n    u = r.usage_metadata\n    return Reply(r.text, u.prompt_token_count, u.candidates_token_count, \"google\")\n\n\n"
    },
    {
      "code": "PROVIDERS = {\"anthropic\": _anthropic, \"openai\": _openai, \"google\": _google}\n\n\n"
    },
    {
      "code": "def ask(system, question, max_tokens=300):\n    \"\"\"Ask the providers in LLM_PROVIDERS, in order, until one answers.\"\"\"\n    tried = []\n    for name in os.environ[\"LLM_PROVIDERS\"].split(\",\"):\n        try:\n            return PROVIDERS[name](system, question, max_tokens)\n        except Unavailable as e:\n            tried.append(str(e))\n    raise Unavailable(\"; \".join(tried))",
      "note": "**O fallback**: tentar cada provedor de `LLM_PROVIDERS`, em ordem, e dizer quais falharam se nenhum respondeu."
    }
  ]
}
```

O `ask.py` é tudo o que a loja vê:

```python
import sys

from llm import ask

r = ask("Answer in one paragraph.", sys.argv[1])
print(f"{r.provider}: {r.tokens_in} in, {r.tokens_out} out | {r.text[:48]}…")
```

Os modelos vêm do ambiente, e o `.env` os guarda para o laboratório:

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

**Três provedores, uma linha de saída cada, e o código da loja não mudou.** Só o `LLM_PROVIDERS`
mudou.

## O fallback que não caiu para o próximo

O sentido de uma lista de provedores é perguntar ao próximo quando o primeiro está fora. O labllm é
mandado a responder 529 três vezes, que é uma a mais do que o SDK da Anthropic repete:

```
ana@dev:~/shop$ curl -s localhost:8400/lab/config -d '{"fail_next": 529, "fail_count": 3}' >/dev/null; set -a; . ./.env; LLM_PROVIDERS=anthropic,openai python ask.py 'Explain in a paragraph why the cart stores prices in cents.' 2>&1 | tail -n 1
anthropic.OverloadedError: Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error', 'message': 'Overloaded'}, 'request_id': 'req_lab_0026'}
ana@dev:~/shop$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["path"], r["status"]) for r in map(json.loads, sys.stdin)]'
/v1/messages 529
/v1/messages 529
/v1/messages 529
```

**O fallback nunca rodou.** Três 529 e um `OverloadedError` direto para a pessoa, sem a OpenAI ser
consultada. O adaptador pega `InternalServerError`, e neste SDK um 529 é um `OverloadedError`, que é
irmão do `InternalServerError`, não um tipo dele. O código parecia certo, e a lista de exceções era
um palpite sobre a árvore de classes do SDK.

O conserto decide pelo código de status em vez de pelo nome da classe, numa função usada pelos três:

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

**Três 529, depois a OpenAI respondeu**, e a pessoa recebeu uma resposta. Um 400 ou um 401 continuam
saindo direto pelo `raise`, porque perguntar a outro provedor não consertaria uma requisição errada
nem uma chave errada; só os esconderia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Como ask() trata uma falha. Ele chama o primeiro provedor, cujo SDK repete sozinho, e uma resposta dele volta direto. Se o erro é transitório, uma conexão perdida, um 429 ou um 5xx, ele passa ao próximo provedor da lista. Qualquer outro erro, como um 400 ou um 401, vai direto para quem chamou.\"><defs><marker id=\"fb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask()</text><path d=\"M112 92 L148 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"150\" y=\"64\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">primeiro provedor</text><text x=\"235.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o SDK repete duas vezes</text><path d=\"M322 92 L368 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"370\" y=\"64\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">transitório?</text><text x=\"445.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem conexão, 429, 5xx</text><path d=\"M522 92 L568 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"545\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"570\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">próximo provedor</text><path d=\"M635 122 L635 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"635\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma resposta</text><path d=\"M235 122 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"235\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma resposta</text><path d=\"M445 122 L445 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"445\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lançado para quem chamou</text><text x=\"452\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não: 400, 401…</text></svg>", "caption": "Só uma falha que o tempo ou outro provedor consertam desce a lista. Uma requisição errada falha igual em todo lugar."}
```

## Antes de contar com um fallback

- **Teste-o quebrando o primeiro provedor**, como aqui. Um fallback que nunca rodou é um palpite.
- **Avalie o segundo modelo também.** Um fallback responde aos seus usuários com outro modelo, então
  ele precisa passar na mesma avaliação que o primeiro.
- **Registre que provedor respondeu.** O `Reply.provider` está lá para que uma semana de fallbacks
  silenciosos apareça como um número, não como uma surpresa na conta.
