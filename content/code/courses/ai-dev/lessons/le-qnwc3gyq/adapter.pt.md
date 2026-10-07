---
title: Uma porta para todo provedor
version: 2
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
      "code": "def _anthropic(system, question, max_tokens):\n    try:\n        r = anthropic.Anthropic().messages.create(model=os.environ[\"LLM_MODEL_ANTHROPIC\"], max_tokens=max_tokens,\n                                                  system=system, messages=[{\"role\": \"user\", \"content\": question}])\n    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:\n        raise Unavailable(f\"anthropic: {type(e).__name__}\") from e\n    tokens_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # Ollama reports reuse apart\n    return Reply(r.content[0].text, tokens_in, r.usage.output_tokens, \"anthropic\")\n\n\n",
      "note": "**Cada provedor é uma função pequena** que traduz a pergunta na ida e a resposta na volta, e transforma as falhas que espera em `Unavailable`. Quais falhas ela espera é a parte que o fim desta seção mostra estar errada."
    },
    {
      "code": "def _openai(system, question, max_tokens):\n    try:\n        r = openai.OpenAI().chat.completions.create(\n            model=os.environ[\"LLM_MODEL_OPENAI\"], max_completion_tokens=max_tokens,\n            messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": question}])\n    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:\n        raise Unavailable(f\"openai: {type(e).__name__}\") from e\n    return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, \"openai\")\n\n\n",
      "note": "**O nome do modelo vem do ambiente**, nunca do código."
    },
    {
      "code": "def _google(system, question, max_tokens):\n    try:\n        r = genai.Client().models.generate_content(\n            model=os.environ[\"LLM_MODEL_GOOGLE\"], contents=question,\n            config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,\n                                               automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    except genai_errors.ServerError as e:\n        raise Unavailable(f\"google: {type(e).__name__}\") from e\n    u = r.usage_metadata\n    return Reply(r.text, u.prompt_token_count, u.candidates_token_count, \"google\")\n\n\n"
    },
    {
      "code": "PROVIDERS = {\"anthropic\": _anthropic, \"openai\": _openai, \"google\": _google}\n\n\n"
    },
    {
      "code": "def ask(system, question, max_tokens=300):\n    \"\"\"Ask the providers in LLM_PROVIDERS, in order, until one answers.\"\"\"\n    tried = []\n    for name in os.environ[\"LLM_PROVIDERS\"].split(\",\"):\n        try:\n            return PROVIDERS[name](system, question, max_tokens)\n        except Unavailable as e:\n            tried.append(str(e))\n    raise Unavailable(\"; \".join(tried))\n",
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
print(f"{r.provider}: {r.tokens_in} in, {r.tokens_out} out | {' '.join(r.text.split())[:48]}…")
```

Os modelos vêm do ambiente, e o `.env` os guarda, ao lado do `.gitignore` da seção 03 que o mantém
fora do git:

```
ana@dev:~/shop$ cat .env
LLM_MODEL_ANTHROPIC=llama3.2:3b
LLM_MODEL_OPENAI=llama3.2:3b
LLM_MODEL_GOOGLE=gemini-3.5-flash
ana@dev:~/shop$ set -a; . ./.env; for p in anthropic openai; do LLM_PROVIDERS=$p python ask.py "Explain in a paragraph why the cart stores prices in cents."; done
anthropic: 43 in, 136 out | The carton of eggs, milk, and many other product…
openai: 43 in, 119 out | The reason cart stores often display prices in c…
```

**Dois provedores, uma linha de saída cada, e o código da loja não mudou.** Só o `LLM_PROVIDERS`
mudou. Os dois são o Ollama aqui, com o mesmo modelo atrás de dois formatos, o que basta para provar o
adaptador; uma implantação de verdade aponta as duas variáveis de cada SDK para duas empresas.

## Testando o fallback

O sentido de uma lista de provedores é perguntar ao próximo quando o primeiro está fora. **Um
fallback que nunca rodou é um palpite**, então a ana quebra o primeiro provedor de propósito,
apontando o SDK da Anthropic para um endereço onde ninguém escuta:

```
ana@dev:~/shop$ set -a; . ./.env; ANTHROPIC_BASE_URL=http://127.0.0.1:11400 LLM_PROVIDERS=anthropic,openai python ask.py "Explain in a paragraph why the cart stores prices in cents."
openai: 43 in, 157 out | The practice of pricing items in cents in retail…
```

O SDK da Anthropic fez as suas tentativas, como na seção 05, lançou `APIConnectionError`, o adaptador o transformou em
`Unavailable`, e o lado da OpenAI respondeu. Isso funciona.

## O fallback que não teria caído para o próximo

Um erro de conexão é um jeito de um provedor estar fora. Outro é o provedor responder 529,
*sobrecarregado*, o que a API da Anthropic faz quando está ocupada e o que o SDK da Anthropic lança
como `OverloadedError`. O adaptador pega `InternalServerError`, o erro 5xx, e isso soa como se
cobrisse o 529. A árvore de classes do SDK diz outra coisa:

```
ana@dev:~/shop$ python -c 'import anthropic; print(anthropic.OverloadedError.__mro__[1].__name__, issubclass(anthropic.OverloadedError, anthropic.InternalServerError))'
APIStatusError False
```

**`OverloadedError` é irmão do `InternalServerError`, não um tipo dele**: os dois vêm direto do
`APIStatusError`. No primeiro dia em que a Anthropic estivesse sobrecarregada, o adaptador deixaria um
529 chegar à pessoa, sem a OpenAI ser consultada. O código parece certo, e a lista de exceções é um
palpite sobre a árvore de classes do SDK. Não foi preciso provedor nenhum para descobrir isso; bastou
uma linha de Python.

O conserto decide pelo código de status em vez de pelo nome da classe, numa função usada pelos três:

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

**O endereço inalcançável continua caindo para o próximo**: um erro de conexão não tem código de
status, e o `transient` o conta. **Um nome de modelo que não existe não cai**: o `llama3.3:3b` nunca foi
baixado, o Ollama responde 404, e o adaptador o lança em vez de perguntar à OpenAI. Isso é de
propósito. Um 400, um 401 ou um 404 é uma requisição errada, uma chave errada ou um nome errado, e
perguntar a outro provedor não consertaria; só esconderia, atrás de uma resposta de um modelo que
ninguém escolheu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Como ask() trata uma falha. Ele chama o primeiro provedor, cujo SDK repete sozinho, e uma resposta dele volta direto. Se o erro é transitório, uma conexão perdida, um 429 ou um 5xx, ele passa ao próximo provedor da lista. Qualquer outro erro, como um 400 ou um 401, vai direto para quem chamou.\"><defs><marker id=\"fb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask()</text><path d=\"M112 92 L148 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"150\" y=\"64\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">primeiro provedor</text><text x=\"235.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o SDK repete duas vezes</text><path d=\"M322 92 L368 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><rect x=\"370\" y=\"64\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">transitório?</text><text x=\"445.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem conexão, 429, 5xx</text><path d=\"M522 92 L568 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"545\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sim</text><rect x=\"570\" y=\"64\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">próximo provedor</text><path d=\"M635 122 L635 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"635\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma resposta</text><path d=\"M235 122 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"235\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma resposta</text><path d=\"M445 122 L445 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fb-ah)\"></path><text x=\"445\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">lançado para quem chamou</text><text x=\"452\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não: 400, 401…</text></svg>", "caption": "Só uma falha que o tempo ou outro provedor consertam desce a lista. Uma requisição errada falha igual em todo lugar."}
```

## Antes de contar com um fallback

- **Teste-o quebrando o primeiro provedor**, como aqui, de todo jeito que você conseguir quebrá-lo.
- **Avalie o segundo modelo também.** Um fallback responde aos seus usuários com outro modelo, então
  ele precisa passar na mesma avaliação que o primeiro.
- **Registre que provedor respondeu.** O `Reply.provider` está lá para que uma semana de fallbacks
  silenciosos apareça como um número, não como uma surpresa na conta.
