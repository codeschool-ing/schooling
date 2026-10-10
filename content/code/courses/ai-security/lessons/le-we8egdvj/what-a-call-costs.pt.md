---
title: Quanto custa uma chamada, medido
version: 1
---

Um modelo com conta a pagar é um recurso que qualquer pessoa capaz de mandar texto a ele pode gastar.
A lista da OWASP na aula 4 chama essa falha de **consumo sem limite** (*unbounded consumption*),
`LLM10`: requisições que ninguém limitou, respostas que ninguém cortou, laços que ninguém parou, e uma
conta que chega no fim do mês com o incidente já terminado. A aula 7 limitou quantas requisições uma
pessoa manda por minuto. Esta aula é sobre **quanto cada requisição custa e quanto uma pessoa, e o
assistente inteiro, podem gastar num dia.**

A unidade é o token. Um fornecedor cobra pelos tokens que lê, o prompt, e pelos tokens que escreve, a
resposta, normalmente a preços diferentes, com a resposta mais cara. Os preços desta aula são do curso,
em reais, e um fornecedor de verdade publica os seus. Cole:

```sh
cat > ~/guard/data/prices.json <<'EOF'
{
 "currency": "BRL",
 "cents_per_million_input": 1500,
 "cents_per_million_output": 6000
}
EOF
```

O programa faz uma pergunta e lê de volta o que o servidor contou, que todo servidor de chat
completions devolve ao lado da resposta. **Dinheiro é centavo inteiro aqui, como em todo lugar onde se
lida com dinheiro**: a soma fica em milionésimos de centavo até ser impressa, e nunca passa por um
float. Ele importa o `ask.py` da aula 1 para saber o endereço do modelo. Salve-o como
`~/guard/tools/cost.py`:

```python
# cost.py: what one question to the model costs, in tokens and in cents.
#
#   guard cost QUESTION [--max-tokens N]
#
# It asks the model once and prints what the server counted: the tokens of the
# prompt, the tokens of the reply, and why the reply stopped ("stop" when the
# model finished, "length" when it hit --max-tokens). The cost uses the prices
# in data/prices.json, which the course invented; a provider publishes its own.
# Money is integer cents, rounded half up, never a float.
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

import ask

p = argparse.ArgumentParser(prog="guard cost")
p.add_argument("question")
p.add_argument("--max-tokens", type=int)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prices.json"), encoding="utf-8") as f:
    prices = json.load(f)

body = {"model": ask.MODEL, "temperature": 0, "seed": 1,
        "messages": [{"role": "user", "content": a.question}]}
if a.max_tokens:
    body["max_tokens"] = a.max_tokens
req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
if ask.KEY:
    req.add_header("Authorization", "Bearer " + ask.KEY)
try:
    with urllib.request.urlopen(req, timeout=600) as r:
        reply = json.load(r)
except urllib.error.HTTPError as e:
    sys.exit("cost: %s answered %d: %s" % (ask.URL, e.code, e.read().decode().strip()))
except urllib.error.URLError as e:
    sys.exit("cost: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))

used = reply["usage"]
millionths = (used["prompt_tokens"] * prices["cents_per_million_input"]
              + used["completion_tokens"] * prices["cents_per_million_output"])
cents, rest = divmod(millionths, 1_000_000)
cents += rest >= 500_000
text = reply["choices"][0]["message"]["content"]
print("prompt %d tokens, reply %d tokens, stopped: %s" % (
    used["prompt_tokens"], used["completion_tokens"], reply["choices"][0]["finish_reason"]))
print("cost %d cent(s) at the course's prices (%d millionths of a cent)" % (cents, millionths))
print("reply ends: ..." + text.replace("\n", " ")[-70:])
```

A mesma pergunta duas vezes, uma sem limite para a resposta e outra com `--max-tokens 60`. O modelo
local não custa nada para rodar; os centavos são o que os mesmos tokens custariam nos preços do curso:

```
ana@lab:~/guard$ guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered."
prompt 48 tokens, reply 526 tokens, stopped: stop
cost 3 cent(s) at the course's prices (3228000 millionths of a cent)
reply ends: ...here to support you throughout your freelance journey on our platform.
ana@lab:~/guard$ guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered." --max-tokens 60
prompt 48 tokens, reply 60 tokens, stopped: length
cost 0 cent(s) at the course's prices (432000 millionths of a cent)
reply ends: ...or you.  Here's how it works:  1. **Client Places an Order**: A client
```

**É na resposta que o dinheiro vai.** O prompt teve 48 tokens nas duas vezes. Sem limite, o modelo
escreveu 526 tokens, onze vezes a pergunta, e a esses preços a resposta foi quase todo o custo. Com o
limite de 60, ela parou com `length`, que é o servidor dizendo que cortou a resposta, e não que o
modelo terminou, e as últimas palavras mostram isso: uma lista numerada que para no primeiro item.

Então o `max_tokens` é duas coisas ao mesmo tempo, e as duas importam. É **um teto para o custo de uma
chamada**, o único que não depende de o modelo escolher ser breve. E é **um jeito de quebrar uma
resposta**: uma resposta cortada é uma resposta pior, e um objeto JSON cortado nem é JSON. A aula 9 o
pôs perto do que o esquema da resposta permite, para que uma resposta que se alonga falhe rápido e o
laço de nova tentativa cuide dela. Aqui a lição é a mesma vista do outro lado: **uma resposta que para
com `length` é uma falha a tratar**, nunca uma resposta para mostrar como está.
