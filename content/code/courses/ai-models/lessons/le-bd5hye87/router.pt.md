---
title: Um sufixo que escolhe o provedor
version: 1
---

A aula 12 leu o Hub como o lugar onde os modelos ficam guardados. O Hugging Face também **roteia
requisições** para provedores que os servem, com um token e um cliente, o `InferenceClient` da
biblioteca `huggingface_hub` que a aula 12 já usou. A documentação diz como um provedor é escolhido:

```
ana@desk:~/desk$ sources lines hf-providers 135 139
# huggingface/hub-docs@08175d0f docs/inference-providers/index.md
 135| By default, our system automatically selects the fastest available provider for the specified model (equivalent to the `:fastest` policy — highest throughput in tokens per second).
 136|
 137| You can change the provider selection policy by appending a policy suffix to the model id: `:cheapest` for the most cost-efficient provider (lowest price per output token), or `:preferred` to follow your preference order in [Inference Provider settings](https://hf.co/settings/inference-providers). For example, `openai/gpt-oss-120b:cheapest`.
 138|
 139| You can also select the provider of your choice by appending the provider name to the model id (e.g. `"openai/gpt-oss-120b:groq"`).
```

O huggingface.co estava fora de alcance na máquina em que este curso foi gravado. O substituto faz o
papel do roteador, com os dois provedores da aula 15 e uma velocidade e um preço para cada: o
`standin-east` a 40 tokens por segundo e US$ 15 por milhão de tokens de saída, o `standin-west` a 80
por segundo e US$ 18. O `lab/hf_route.py` manda a mesma requisição três vezes, mudando só o nome do
modelo:

```python
import json
import os

from huggingface_hub import InferenceClient

client = InferenceClient(base_url=os.environ["HF_BASE_URL"])   # the token comes from HF_TOKEN
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

for model in ("standin/large", "standin/large:cheapest", "standin/large:standin-east"):
    r = client.chat_completion(model=model, max_tokens=16, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{model:28} -> {r.model:14} {r.choices[0].message.content}")
```

```
ana@desk:~/desk$ python lab/hf_route.py
standin/large                -> standin/large  other
standin/large:cheapest       -> standin/large  other
standin/large:standin-east   -> standin/large  other
```

Três respostas idênticas, e nada nelas diz quem serviu cada uma. O log do lab diz:

```
ana@desk:~/desk$ wire --count 3
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-west', 'policy': 'fastest'}
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-east', 'policy': 'cheapest'}
POST /hf/v1/chat/completions -> 200 hf standin-large routed={'model': 'standin/large', 'provider': 'standin-east', 'policy': 'standin-east'}
```

- **Sem sufixo** quer dizer `:fastest`, e o provedor mais rápido é o mais caro: o `standin-west`, a
  US$ 18 em vez de US$ 15, **20% a mais por token de saída**, escolhido por um padrão que ninguém
  escreveu.
- **`:cheapest`** escolheu o `standin-east`.
- **`:standin-east`** nomeou o provedor, e é a única das três cujo provedor a ana conhece pelo
  próprio código.

Compare com a aula 15: o padrão do OpenRouter pende para o provedor mais barato e este para o mais
rápido. O mesmo modelo por dois roteadores, ambos no padrão, pode custar valores diferentes e chegar
em velocidades diferentes, e nenhuma das diferenças aparece na resposta. **Diga a política, ou o
provedor, na string do modelo**, para que a escolha fique no código, onde pode ser lida e avaliada,
que é a regra da seção 03 da aula 15 em outra sintaxe.

A requisição em si está no formato da OpenAI, e o token viaja como Bearer:

```
ana@desk:~/desk$ wire --headers authorization,user-agent | head -4
POST /hf/v1/chat/completions
user-agent: unknown/None; hf_hub/2.1.1; python/3.11.15
authorization: Bearer hf_la…
```
