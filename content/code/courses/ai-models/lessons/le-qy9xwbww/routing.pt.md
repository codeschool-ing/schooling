---
title: Qual provedor respondeu
version: 1
---

A seção 05 da aula 10 achou o Llama 4 Maverick em dez entradas da tabela, com o preço de entrada
variando mais de catorze vezes.
No OpenRouter, um nome de modelo pode representar vários deles, e **o OpenRouter escolhe um por
requisição**. A documentação diz como, por padrão:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
  65: 2. For the stable providers, look at the lowest-cost candidates and select one weighted
      by inverse square of the price (example below).
  73: - Your request is routed to Provider A. Provider A is 9x more likely to be first routed
      to Provider A than Provider C because $(1 / 3^2 = 1/9)$ (inverse square of the price).
```

Com peso pelo inverso do quadrado do preço, três provedores a US$ 1, US$ 2 e US$ 3 dividem o
tráfego assim, em porcentagem:

```
ana@desk:~/desk$ python -c "p = [1, 2, 3]; w = [1 / x**2 for x in p]; print([round(x / sum(w) * 100, 1) for x in w])"
[73.5, 18.4, 8.2]
```

Três requisições em quatro vão para o mais barato, mas não todas, então **duas requisições
idênticas podem ser servidas por dois provedores diferentes**. A seção 05 da aula 10 disse que a
precisão que um host serve é escolha dele; aqui o host é escolhido a cada requisição, por outra
pessoa.

O `or_sort.py` classifica um dos casos da ana pelo OpenRouter e imprime qual modelo e qual provedor
responderam. O único argumento dele é um JSON extra para o corpo da requisição, que é onde o
roteamento é pedido. Duas configurações o apontam para outro lugar: `OPENROUTER_BASE_URL` para o
relay, e `MODEL` para um modelo que o Ollama tem:

```python
import json
import os
import sys

from openai import OpenAI

# OpenRouter's address and your key; without them, the relay passes the request to Ollama
client = OpenAI(base_url=os.environ.get("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
                api_key=os.environ.get("OPENROUTER_API_KEY", "none"))
model = os.environ.get("MODEL", "meta-llama/llama-3.3-70b-instruct")
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

# the request's extra fields, as JSON on the command line: {"provider": {...}} or {"models": [...]}
extra = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
r = client.chat.completions.create(model=model, extra_body=extra, messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(r.choices[0].message.content, f"model={r.model}", f"provider={getattr(r, 'provider', None)}")
```

Aqui ele pede a DeepInfra primeiro, depois a Together, e **nenhum recurso a mais ninguém**:

```
ana@desk:~/desk$ export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
ana@desk:~/desk$ python or_sort.py '{"provider": {"order": ["deepinfra", "together"], "allow_fallbacks": false}}'
other. model=llama3.2:3b provider=None
ana@desk:~/desk$ python relay.py show --body | grep -A6 '"provider"'
  "provider": {
    "order": [
      "deepinfra",
      "together"
    ],
    "allow_fallbacks": false
  }
```

A resposta voltou, e **`provider=None` é a descoberta**. O Ollama não tem campo `provider` na API
dele, então ignorou o objeto e respondeu com o modelo que foi pedido, sem dizer nada; o relay mostra
que o objeto foi mandado. O OpenRouter o lê, e a documentação dele diz o que faz com ele:

```
# OpenRouterTeam/docs@3e840a21 guides/routing/provider-selection.mdx
  30: | `allow_fallbacks` | boolean | `true` | Whether to allow backup providers when the
      primary is unavailable. [Learn more](#disabling-fallbacks) |
 944: Here's an example with `allow_fallbacks` set to `false` that skips over OpenAI (which
      doesn't host Mixtral), tries Together, and then fails if Together fails:
```

Então, no OpenRouter, a mesma requisição vai para a DeepInfra, ou para a Together se a DeepInfra não
puder atendê-la, e **falha em vez de seguir adiante** com `allow_fallbacks: false`. Qual dos dois a
ana quer depende da decisão da seção 10 da aula 5: se a avaliação rodou contra o serviço de um
provedor para o modelo, um provedor diferente é um candidato diferente, e falhar pode ser o
resultado honesto.

**Registre o provedor com cada resposta.** A resposta do OpenRouter o nomeia, e uma avaliação ou um
incidente que não sabe qual provedor respondeu não pode ser repetido. Um servidor que não conhece o
campo, como o Ollama aqui, responde sem ele, e é por isso que o `or_sort.py` imprime `None` em vez
de supor.
