---
title: Um sufixo que escolhe o provedor
version: 1
---

A aula 12 leu o Hub como o lugar onde os modelos ficam guardados. O Hugging Face também **roteia
requisições** para provedores que os servem, com um token e um cliente, o `InferenceClient` da
biblioteca `huggingface_hub` que a aula 12 já usou. A documentação diz como um provedor é escolhido:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/index.md
 135| By default, our system automatically selects the fastest available provider for the specified model (equivalent to the `:fastest` policy — highest throughput in tokens per second).
 136|
 137| You can change the provider selection policy by appending a policy suffix to the model id: `:cheapest` for the most cost-efficient provider (lowest price per output token), or `:preferred` to follow your preference order in [Inference Provider settings](https://hf.co/settings/inference-providers). For example, `openai/gpt-oss-120b:cheapest`.
 138|
 139| You can also select the provider of your choice by appending the provider name to the model id (e.g. `"openai/gpt-oss-120b:groq"`).
```

O `router.huggingface.co` foi recusado pela rede da máquina em que este curso foi gravado, então
as escolhas do roteador não podem ser mostradas aqui, e nem uma velocidade ou um preço de provedor
algum. O que dá para mostrar é onde a escolha fica escrita. O `hf_route.py` manda a mesma requisição
três vezes, mudando só o fim do nome do modelo. Dois ajustes o apontam para outro lugar: o
`HF_BASE_URL` para o relay, e o `MODEL` para um modelo que o Ollama tem:

```python
import json
import os

from huggingface_hub import InferenceClient
from huggingface_hub.errors import HfHubHTTPError

# Hugging Face's router, and your token from HF_TOKEN; HF_BASE_URL at the relay sends it to Ollama
client = InferenceClient(base_url=os.environ.get("HF_BASE_URL", "https://router.huggingface.co/v1"))
model = os.environ.get("MODEL", "meta-llama/Llama-3.3-70B-Instruct")
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

for suffix in ("", ":cheapest", ":groq"):
    try:
        r = client.chat_completion(model=model + suffix, max_tokens=16, temperature=0, messages=[
            {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
        print(f"{model + suffix:24} -> {r.model} {r.choices[0].message.content}")
    except HfHubHTTPError as e:
        print(f"{model + suffix:24} -> {e.response.status_code} {e.response.text.strip()}")
```

```
ana@desk:~/desk$ export HF_BASE_URL=http://127.0.0.1:8500/v1 HF_TOKEN=ollama MODEL=llama3.2:3b
ana@desk:~/desk$ python hf_route.py
llama3.2:3b              -> llama3.2:3b order-status
llama3.2:3b:cheapest     -> 400 {"error":{"message":"invalid model name","type":"invalid_request_error","param":null,"code":null}}
llama3.2:3b:groq         -> 400 {"error":{"message":"invalid model name","type":"invalid_request_error","param":null,"code":null}}
ana@desk:~/desk$ python relay.py show --count 3
POST /v1/chat/completions -> 200 llama3.2:3b
POST /v1/chat/completions -> 400 llama3.2:3b:cheapest
POST /v1/chat/completions -> 400 llama3.2:3b:groq
```

**A política viaja dentro do nome do modelo**, e em nenhum outro lugar: as três requisições só
diferem nessa string. O roteador do Hugging Face lê o que vem depois dos últimos dois-pontos como
uma política ou um provedor. O Ollama lê `llama3.2:3b:cheapest` como nome de modelo, acha malformado
e diz isso com um 400. É o contrário da seção 03 da aula 15, em que o Ollama ignorou o objeto
`provider` do OpenRouter e respondeu: um ajuste num campo próprio pode ser descartado em silêncio
por um servidor que não o conhece, e um ajuste dentro do nome do modelo não pode. O preço são os
próprios dois-pontos, que o Ollama já usa para uma tag, então a mesma string quer dizer coisas
diferentes para os dois servidores.

Contra o roteador, com um token seu e sem `MODEL` e `HF_BASE_URL`, a documentação acima diz o que as
três linhas fazem. **Sem sufixo** quer dizer `:fastest`, escolhido pela vazão, cobre o que esse
provedor cobrar. **`:cheapest`** escolhe pelo preço por token de saída. **`:groq`** nomeia o
provedor, e é a única das três cujo provedor a ana conhece pelo código. A página do modelo no Hub
lista quais provedores o servem e a que preço; uma requisição não lista.

Compare com a aula 15: o padrão do OpenRouter puxa para o provedor mais barato e este para o mais
rápido. O mesmo modelo por dois roteadores, os dois com seus padrões, pode custar valores diferentes
e chegar em velocidades diferentes, e nenhuma das diferenças aparece na resposta. **Nomeie a
política, ou o provedor, na string do modelo**, para que a escolha fique no código, onde pode ser
lida e avaliada, que é a regra da seção 03 da aula 15 em outra sintaxe.

A requisição em si tem o formato da OpenAI, e o token vai como Bearer:

```
ana@desk:~/desk$ python relay.py show --headers authorization,user-agent | head -4
POST /v1/chat/completions
user-agent: unknown/None; hf_hub/2.1.1; python/3.13.16
authorization: Bearer ollam…
```
