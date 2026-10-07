---
title: Três coisas mudam, e nada mais
version: 1
---

A seção 05 da aula 8 chamou a Chat Completions de formato que a maior parte do setor copiou, e as
aulas 9, 14, 15 e 19 continuaram a encontrá-lo: Mistral, Ollama, LM Studio, OpenRouter e o
roteador do Hugging Face aceitam todos uma requisição escrita para a biblioteca da OpenAI. A
Anthropic e o Google oferecem o mesmo, num endpoint separado ao lado das APIs próprias. O
`compat.py` manda dez casos da ana a oito provedores por um único cliente, e muda três coisas por
provedor:

```python
import json
import os

import openai
from openai import OpenAI


def key(name):  # your key for each provider, where you have one
    return os.environ.get(name, "none")


# name: (base URL, key, model) -- the only three things that change
PROVIDERS = {
    "OpenAI":       ("https://api.openai.com/v1", key("OPENAI_API_KEY"), "gpt-5.4-mini"),
    "Anthropic":    ("https://api.anthropic.com/v1/", key("ANTHROPIC_API_KEY"), "claude-haiku-4-5"),
    "Google":       ("https://generativelanguage.googleapis.com/v1beta/openai/", key("GOOGLE_API_KEY"),
                     "gemini-3.5-flash"),
    "Mistral":      ("https://api.mistral.ai/v1", key("MISTRAL_API_KEY"), "mistral-small-latest"),
    "OpenRouter":   ("https://openrouter.ai/api/v1", key("OPENROUTER_API_KEY"), "meta-llama/llama-3.3-70b-instruct"),
    "Hugging Face": ("https://router.huggingface.co/v1", key("HF_TOKEN"), "meta-llama/Llama-3.3-70B-Instruct"),
    "Ollama":       ("http://127.0.0.1:11434/v1", "ollama", "llama3.2:3b"),
    "LM Studio":    ("http://127.0.0.1:1234/v1", "lm-studio", "llama-3.2-3b-instruct"),
}
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][30:]

for name, (url, api_key, model) in PROVIDERS.items():
    client = OpenAI(base_url=url, api_key=api_key, max_retries=0)
    right = 0
    try:
        for c in cases:
            r = client.chat.completions.create(model=model, temperature=0, max_tokens=16, messages=[
                {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
            right += r.choices[0].message.content.strip() == c["label"]
        print(f"{name:12} {right}/{len(cases)}")
    except openai.APIStatusError as e:
        print(f"{name:12} {e.status_code} {type(e).__name__}, its body a {type(e.body).__name__}")
    except openai.APIConnectionError as e:
        print(f"{name:12} no connection: {e.__cause__}")
```

Cada chave vem da variável que a biblioteca do próprio provedor lê, então uma chave que você já tem
é usada e as outras vão como `none`. Na máquina em que este curso foi gravado, sem chave nenhuma:

```
ana@desk:~/desk$ python compat.py
OpenAI       403 PermissionDeniedError, its body a str
Anthropic    401 AuthenticationError, its body a dict
Google       400 BadRequestError, its body a list
Mistral      403 PermissionDeniedError, its body a str
OpenRouter   403 PermissionDeniedError, its body a str
Hugging Face 403 PermissionDeniedError, its body a str
Ollama       4/10
LM Studio    no connection: [Errno 111] Connection refused
```

Oito provedores, um laço, e oito resultados diferentes, todos reais:

- **O Ollama respondeu os dez**, e acertou o que o llama3.2:3b acerta nesses casos com temperatura
  0.
- **A Anthropic e o Google leram a requisição e recusaram a chave.** É o máximo que esta máquina
  conseguia deles, e basta para mostrar que a requisição foi entendida.
- **Os quatro 403 não são dos provedores.** Esses endereços foram recusados pela rede em que o curso
  foi gravado, e o proxy dela respondeu no lugar deles. Em casa, cada um vai recusar a chave de
  mentira ele mesmo, e com uma chave sua, responder.
- **O LM Studio não estava rodando**, que é o estado da máquina que a seção 05 da aula 14 encontrou.

O que a execução mostra é a parte do formato que se sustenta: **um laço alcançou todos os
provedores**, e o harness da aula 5 poderia rodar sem mudança contra cada um que tenha chave. Esse é
o valor inteiro do formato, e ele é grande: comparar candidatos de provedores diferentes é um
dicionário de três colunas em vez de oito integrações.

Os erros são o primeiro sinal do que o formato não cobre. O mesmo engano, uma chave errada, voltou
como um 401 `AuthenticationError` da Anthropic e um 400 `BadRequestError` do Google, então um
programa que captura o primeiro para dizer "confira sua chave" não diz nada para o Google. E o
corpo do erro é um dicionário num e **uma lista** no outro: `e.body["message"]` funciona no da
Anthropic e levanta um `TypeError` no do Google, dentro do código que devia tratar o erro. Um
programa que lê um erro precisa saber com que provedor está falando, afinal.
