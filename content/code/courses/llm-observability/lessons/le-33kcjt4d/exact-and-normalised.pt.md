---
title: Comparando com uma resposta esperada
version: 1
---

A aula 8 do `rag` construiu o `data/eval.jsonl`: trinta perguntas, cada uma com os **fatos** que uma
resposta certa contém, e quatro sem fatos, cuja resposta certa é a recusa. Isso é um gabarito, e este
curso corrige contra ele.

Corrigir exige respostas para corrigir. O `evalrun.py` manda cada pergunta do conjunto pelo assistente e
guarda o que voltou como uma **execução** (run), com as fontes que cada resposta recebeu:

```python
"""evalrun.py: every question of an evaluation set through the assistant, kept as a run.

    python evalrun.py NAME [--set data/eval.jsonl] [--at 2026-10-05T12:00:00] [--release R]

A run is runs/NAME.jsonl: one line per question with its id, the question, the
reply, the release that answered, the sources the model was shown (their ids
and their text) and the trace id. Later lessons grade runs and compare them;
they never call the assistant themselves, so a run can be graded again, by
another method, without asking the model twice.
"""
import argparse
import json
import os

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("name")
p.add_argument("--set", default="data/eval.jsonl")
p.add_argument("--at", default="2026-10-05T12:00:00", help="the moment whose release answers")
p.add_argument("--release", help="answer with this release, whatever the moment")
a = p.parse_args()

if a.release:   # a release not yet in force: answer as if it were
    assistant.RELEASES = {a.release: dict(assistant.RELEASES[a.release], **{"from": "0000"})}
telemetry.setup("eval-spans.jsonl", service="evalrun")
os.makedirs("runs", exist_ok=True)
text = dict(assistant.db.execute("SELECT id, text FROM chunks").fetchall())
n = 0
with open(f"runs/{a.name}.jsonl", "w") as out:
    for case in map(json.loads, open(a.set)):
        reply, sources, trace = assistant.ask(case["question"], user="evalrun", feature="help", at=a.at)
        release, _ = assistant.release_at(a.at)
        out.write(json.dumps({"id": case["id"], "question": case["question"], "reply": reply, "release": release,
                              "sources": [{"id": s[0], "text": text[s[0]]} for s in sources],
                              "trace": trace}, ensure_ascii=False) + "\n")
        n += 1
print(f"runs/{a.name}.jsonl: {n} questions, release {release}")
```

Uma execução é guardada para poder ser corrigida de novo, por outro método, sem perguntar ao modelo
duas vezes; as aulas 9 a 12 corrigem este mesmo arquivo. O `--at` escolhe qual versão responde, pelo
momento em que ela estaria em vigor, e o padrão é a segunda-feira, 5 de outubro, sob a versão que subiu
o piso:

```
ana@lab:~/obs$ python evalrun.py current
runs/current.jsonl: 30 questions, release 2026.10.1
ana@lab:~/obs$ head -c 600 runs/current.jsonl; echo
{"id": "e01", "question": "How many days do I have to return a printed book?", "reply": "You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]", "release": "2026.10.1", "sources": [{"id": "returns-policy:fbe325d9ffef", "text": "You have 30 days from delivery to return a printed book in the condi
```

## A comparação, e quão frouxa ela é

O `facts.py` corrige uma execução de dois jeitos: **exato**, em que um fato precisa aparecer na resposta
como foi escrito, e **normalizado**, em que maiúsculas, pontuação e sequências de espaços são ignoradas
dos dois lados antes.

```python
"""facts.py: a run graded against the facts of the evaluation set, two ways."""
import json
import re
import sys

REFUSAL = "I could not find that in our documents."
cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def exact(reply, facts):
    return reply == REFUSAL if not facts else any(f in reply for f in facts)


def normalised(reply, facts):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    return reply == REFUSAL if not facts else any(squash(f) in squash(reply) for f in facts)


if __name__ == "__main__":
    run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
    for name, grade in (("exact", exact), ("normalised", normalised)):
        right = [r["id"] for r in run if grade(r["reply"], cases[r["id"]]["facts"])]
        print(f"{name:10} {len(right)}/{len(run)} right")
    wrong = [r for r in run if not normalised(r["reply"], cases[r["id"]]["facts"])]
    for r in wrong:
        print(f"  {r['id']}  {r['question'][:52]:52}  {r['reply'][:60]}")
```

```
ana@lab:~/obs$ python facts.py current
exact      16/30 right
normalised 16/30 right
  e02  Who pays for the return postage?                      I could not find that in our documents.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  My e-book was downloaded yesterday, can I still get   An e-book can be refunded within 14 days of purchase if you 
  e06  How much is express delivery?                         Express delivery is not free at any order value. [1]
  e07  Above what order value is standard delivery free?     Express delivery is not free at any order value. [1]
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e17  When is the contract of sale formed?                  I could not find that in our documents.
  e19  What commission does Marginalia take from a marketpl  Marginalia is an online bookshop operated at marginalia.exam
  e20  How often are sellers paid?                           I could not find that in our documents.
  e21  What does error E-4102 mean in the affiliate API?     I could not find that in our documents.
  e22  What commission do affiliates earn on e-books?        I could not find that in our documents.
  e24  Do you store my IP address?                           I could not find that in our documents.
  e25  What is the most a support agent can refund without   I could not find that in our documents.
  e26  What must I check before changing a customer's order  I could not find that in our documents.
```

**Dezesseis de trinta**, dos dois jeitos. Sob esta versão, dez das catorze respostas erradas são a recusa
a uma pergunta que os documentos respondem, o que a aula 5 teria previsto, e duas são a frase da entrega
expressa da aula 1, agora respondendo também a pergunta sobre o preço da entrega expressa.

As duas comparações concordam aqui porque o extract-1 copia frases, então uma resposta certa contém o
fato como o documento o escreveu. A diferença aparece em respostas com outra redação. O `normalise.py`
pega três, **escritas pelo curso para isso**, contra o fato *30 days from delivery*:

```python
"""normalise.py: three replies the course wrote, against one fact, compared two ways."""
from facts import exact, normalised

fact = ["30 days from delivery"]
for reply in ["You have 30 days from delivery to return a printed book. [1]",
              "You have 30 days  from Delivery to return it. [1]",
              "You have thirty days after delivery to return it. [1]"]:
    print(f"exact {exact(reply, fact)!s:5}  normalised {normalised(reply, fact)!s:5}  {reply}")
```

```
ana@lab:~/obs$ python normalise.py
exact True   normalised True   You have 30 days from delivery to return a printed book. [1]
exact False  normalised True   You have 30 days  from Delivery to return it. [1]
exact False  normalised False  You have thirty days after delivery to return it. [1]
```

A segunda resposta, com um espaço duplo e uma maiúscula, falha na comparação exata e passa na
normalizada. A terceira diz a mesma coisa com outras palavras e falha nas duas. **Nenhuma normalização
alcança uma paráfrase.** Uma comparação só pode ser afrouxada por coisas que não mudam o sentido:
maiúsculas, espaços, pontuação, talvez números por extenso. Cada afrouxamento é uma decisão, tomada
para este conjunto e escrita no código onde um revisor possa vê-la, exatamente como uma lacuna declara
`ignore_case`.

Isso torna a comparação determinística certa para os fatos que têm uma forma só: um preço, um número de
dias, um código de erro, um status de pedido, uma palavra de uma lista fixa. E errada para tudo o que
uma pessoa diria com as próprias palavras, que é a maior parte do que um assistente diz. A aula 9 é
sobre o resto.
