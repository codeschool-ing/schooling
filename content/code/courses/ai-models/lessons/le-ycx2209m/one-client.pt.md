---
title: Três coisas mudam, e nada mais
version: 1
---

A seção 05 da aula 8 chamou a Chat Completions de formato que a maior parte da indústria copiou, e
as aulas 9, 14, 15 e 19 continuaram encontrando-o: Mistral, Ollama, LM Studio, OpenRouter e o
roteador do Hugging Face aceitam uma requisição escrita para a biblioteca da OpenAI. A Anthropic
oferece o mesmo, como um endpoint separado ao lado da própria API. O `lab/compat.py` manda os dez
casos de fora da aula 13 a sete provedores por um cliente só, e muda três coisas por provedor:

```python
import json
import os

from openai import OpenAI

env = os.environ
# name: (base URL, key, model) -- the only three things that change
PROVIDERS = {
    "OpenAI":       (env["OPENAI_BASE_URL"], env["OPENAI_API_KEY"], "standin-small"),
    "Anthropic":    (env["ANTHROPIC_BASE_URL"] + "/v1/", env["ANTHROPIC_API_KEY"], "standin-large"),
    "Mistral":      (env["MISTRAL_SERVER_URL"] + "/v1", env["MISTRAL_API_KEY"], "standin-small"),
    "OpenRouter":   (env["OPENROUTER_BASE_URL"], env["OPENROUTER_API_KEY"], "standin/small"),
    "Hugging Face": (env["HF_BASE_URL"] + "/v1", env["HF_TOKEN"], "standin/small:cheapest"),
    "Ollama":       ("http://127.0.0.1:11434/v1", "ollama", "standin-local"),
    "LM Studio":    ("http://127.0.0.1:1234/v1", "lm-studio", "standin-local"),
}
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][30:]

for name, (url, key, model) in PROVIDERS.items():
    client = OpenAI(base_url=url, api_key=key)
    right, limits = 0, set()
    for c in cases:
        raw = client.chat.completions.with_raw_response.create(
            model=model, temperature=0, max_tokens=16,
            messages=[{"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
        right += raw.parse().choices[0].message.content.strip() == c["label"]
        limits |= {h for h in raw.headers if "ratelimit" in h and "requests" in h and "remaining" in h}
    print(f"{name:12} {model:22} {right}/{len(cases)}  {', '.join(sorted(limits)) or '(no rate-limit header)'}")
```

```
ana@desk:~/desk$ python lab/compat.py
OpenAI       standin-small          7/10  x-ratelimit-remaining-requests
Anthropic    standin-large          9/10  anthropic-ratelimit-requests-remaining
Mistral      standin-small          7/10  x-ratelimit-remaining-requests
OpenRouter   standin/small          7/10  x-ratelimit-remaining-requests
Hugging Face standin/small:cheapest 7/10  x-ratelimit-remaining-requests
Ollama       standin-local          7/10  (no rate-limit header)
LM Studio    standin-local          7/10  (no rate-limit header)
```

```
ana@desk:~/desk$ wire --count 70 | cut -d" " -f1,2,5 | sort | uniq -c
     10 POST /hf/v1/chat/completions hf
     10 POST /openrouter/api/v1/chat/completions openrouter
     10 POST /v1/chat/completions anthropic
     10 POST /v1/chat/completions lmstudio
     10 POST /v1/chat/completions mistral
     10 POST /v1/chat/completions ollama
     10 POST /v1/chat/completions openai
```

Setenta requisições, uma biblioteca, e o substituto atrás de todas, então as notas são as tabelas
dele e não sete modelos. O que a execução mostra é a parte real: **um laço alcançou sete
provedores**, cinco deles no mesmíssimo caminho, e o harness de avaliação da aula 5 rodaria sem
mudança contra cada um. Esse é todo o valor do formato, e é grande: comparar candidatos de
provedores diferentes vira um dicionário de três colunas em vez de sete integrações.

A última coluna é o primeiro sinal do que o formato não cobre. A requisição era a mesma; os
**cabeçalhos que voltaram não eram**. Dois esquemas de nome para o mesmo fato, e nenhum dos dois
servidores na máquina da própria ana. A aula 21 lê esses cabeçalhos, e um programa que os lê
precisa, no fim das contas, saber com que provedor está falando.
