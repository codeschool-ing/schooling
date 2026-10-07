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

O `lab/or_sort.py` classifica um dos casos da ana pelo substituto e imprime quem serviu. O único
argumento dele é JSON extra para o corpo da requisição:

```python
import json
import os
import sys

from openai import OpenAI, APIStatusError

client = OpenAI(base_url=os.environ["OPENROUTER_BASE_URL"], api_key=os.environ["OPENROUTER_API_KEY"])
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

# the request's extra fields, as JSON on the command line: {"provider": {...}} or {"models": [...]}
extra = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
try:
    r = client.chat.completions.create(
        model="standin/large", extra_body=extra,
        messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
except APIStatusError as e:
    sys.exit(f"{e.status_code}: {e.body['message']}")
print(f"{r.choices[0].message.content:6} model={r.model} provider={r.provider} cost=${r.usage.cost:.6f}")
```

O `standin/large` do substituto é servido por dois provedores, `standin-east` e `standin-west`, ao
mesmo preço. Ele não balanceia carga; tenta os dois em ordem, o que deixa visível o efeito de cada
ajuste:

```
ana@desk:~/desk$ python lab/or_sort.py
other  model=standin/large provider=standin-east cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"order": ["standin-west"]}}'
other  model=standin/large provider=standin-west cost=$0.000168
```

`provider.order` diz quem tentar primeiro. Agora o `standin-east` cai (o lab é avisado disso; no
mundo, um provedor simplesmente falha), e as mesmas duas requisições rodam de novo, a segunda com os
fallbacks desligados:

```
ana@desk:~/desk$ python lab/or_sort.py
other  model=standin/large provider=standin-west cost=$0.000168
```

```
ana@desk:~/desk$ python lab/or_sort.py '{"provider": {"order": ["standin-east"], "allow_fallbacks": false}}'
503: No allowed providers are available for the selected model. standin/large at standin-east: 503
```

Com fallbacks permitidos, a queda não custou à ana nada que ela pudesse ver: a requisição foi para o
outro provedor e a resposta voltou. Com `allow_fallbacks: false` a requisição **falha em vez de
mudar**. Qual das duas ela quer depende da decisão da seção 10 da aula 5: se a avaliação foi feita
contra o modelo servido por um provedor, outro provedor é outro candidato, e falhar pode ser o
resultado honesto.

**Registre o provedor junto de cada resposta.** A resposta diz qual foi, e uma avaliação ou um
incidente que não sabe que provedor respondeu não pode ser repetido.
