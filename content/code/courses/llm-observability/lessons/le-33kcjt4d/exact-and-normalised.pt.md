---
title: Comparando com uma resposta esperada
version: 2
---

Uma avaliação precisa de um **gabarito**: perguntas, e para cada uma o que uma resposta certa contém.
O curso escreve um para o assistente aqui, vinte e quatro perguntas. Dezenove têm **fatos**, as
palavras que uma resposta certa precisa conter, pelo menos uma delas, e trechos **gold**, os ids dos
trechos que guardam a resposta, que a aula 11 usa. Cinco não têm nenhum dos dois, e a resposta certa
delas é a recusa: quatro perguntam sobre coisas que os documentos nunca mencionam, e a `e20` pergunta
sobre algo que só um documento interno responde, que o assistente não pode mostrar a um cliente. Salve
como `data/eval.jsonl`:

```json
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}
{"id": "e02", "question": "Who pays for the return postage?", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"]}
{"id": "e03", "question": "How long after my return arrives will I get the refund?", "gold": ["returns-policy:refunds"], "facts": ["three working days", "3 working days"]}
{"id": "e04", "question": "Can I return a signed copy?", "gold": ["returns-policy:items-that-cannot-be-returned"], "facts": ["signed copies cannot", "cannot be returned", "can't be returned", "not be returned"]}
{"id": "e05", "question": "I downloaded an e-book yesterday. Can I still return it?", "gold": ["returns-policy:items-that-cannot-be-returned"], "facts": ["cannot be returned", "can't be returned", "not be returned", "cannot return"]}
{"id": "e06", "question": "How long does standard delivery take?", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["three to six working days", "3 to 6 working days"]}
{"id": "e07", "question": "Above what order value is standard delivery free?", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["R$ 40"]}
{"id": "e08", "question": "How much is express delivery?", "gold": ["shipping-and-delivery:express-delivery"], "facts": ["29.90"]}
{"id": "e09", "question": "When is a standard parcel considered lost?", "gold": ["shipping-and-delivery:lost-parcels"], "facts": ["10 working days", "ten working days"]}
{"id": "e10", "question": "How long does a pickup point keep my parcel?", "gold": ["shipping-and-delivery:pickup-points"], "facts": ["ten days", "10 days"]}
{"id": "e11", "question": "On how many devices can I read my e-books?", "gold": ["ebooks-and-audiobooks:devices"], "facts": ["six devices", "6 devices"]}
{"id": "e12", "question": "Will my e-books open on a Kindle?", "gold": ["ebooks-and-audiobooks:formats"], "facts": ["cannot open", "cannot be opened", "can't open"]}
{"id": "e13", "question": "Can I listen to an audiobook without an internet connection?", "gold": ["ebooks-and-audiobooks:audiobooks"], "facts": ["offline"]}
{"id": "e14", "question": "Can I pay in instalments?", "gold": ["payments-and-invoices:instalments"], "facts": ["three instalments", "3 instalments"]}
{"id": "e15", "question": "When does an order paid by bank slip ship?", "gold": ["payments-and-invoices:how-you-can-pay"], "facts": ["two working days", "2 working days"]}
{"id": "e16", "question": "When do I get the invoice for my order?", "gold": ["payments-and-invoices:invoices"], "facts": ["when the order ships", "when your order ships", "when it ships"]}
{"id": "e17", "question": "How long is a gift card valid?", "gold": ["gift-cards:validity"], "facts": ["two years", "2 years"]}
{"id": "e18", "question": "What happens if my order costs more than my gift card holds?", "gold": ["gift-cards:using-a-gift-card"], "facts": ["the rest"]}
{"id": "e19", "question": "How long is the statutory right of withdrawal?", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"]}
{"id": "e20", "question": "What is the largest refund that can be paid without anybody approving it?", "gold": [], "facts": []}
{"id": "e21", "question": "Do you have a shop in Porto Alegre where I can pick up books?", "gold": [], "facts": []}
{"id": "e22", "question": "Can I place an order by phone?", "gold": [], "facts": []}
{"id": "e23", "question": "Which carrier do you use in Portugal?", "gold": [], "facts": []}
{"id": "e24", "question": "Is there a student discount?", "gold": [], "facts": []}
```

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
release, _ = assistant.release_at(a.at)
n = 0
with open(f"runs/{a.name}.jsonl", "w") as out:
    for case in map(json.loads, open(a.set)):
        reply, sources, trace = assistant.ask(case["question"], user="evalrun", feature="help", at=a.at)
        out.write(json.dumps({"id": case["id"], "question": case["question"], "reply": reply, "release": release,
                              "sources": [{"id": c["id"], "text": c["text"]} for c, _ in sources],
                              "trace": trace}, ensure_ascii=False) + "\n")
        n += 1
print(f"runs/{a.name}.jsonl: {n} questions, release {release}")
```

Uma execução é guardada para poder ser corrigida de novo, por outro método, sem perguntar ao modelo
duas vezes; as aulas 9 a 12 corrigem execuções como esta. O `--at` escolhe qual versão responde, pelo
momento em que ela estaria em vigor, e o padrão é segunda, 5 de outubro, sob a versão que subiu o piso:

```
ana@dev:~/obs$ python evalrun.py current
runs/current.jsonl: 24 questions, release 2026.10.1
ana@dev:~/obs$ head -c 700 runs/current.jsonl; echo
{"id": "e01", "question": "How many days do I have to return a printed book?", "reply": "You have 30 days from the date of delivery to return a printed book. [1]", "release": "2026.10.1", "sources": [{"id": "returns-policy:the-return-window", "text": "Returns and refunds: The return window\nYou can return a printed book within 30 days from delivery, for any reason. The book has to come back in the condition it left: no writing in it and no broken spine."}, {"id": "returns-policy:items-that-cannot-be-returned", "text": "Returns and refunds: Items that cannot be returned\nSigned copies, books printed on demand, and e-books or audiobooks once they have been downloaded."}], "trace": "37af0bbea40
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
ana@dev:~/obs$ python facts.py current
exact      16/24 right
normalised 16/24 right
  e02  Who pays for the return postage?                      According to [1], the customer pays for the return postage.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  I downloaded an e-book yesterday. Can I still return  I could not find that in our documents.
  e12  Will my e-books open on a Kindle?                     I could not find that in our documents.
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e16  When do I get the invoice for my order?               You will receive the electronic invoice for your order as so
  e18  What happens if my order costs more than my gift car  If your order costs more than your gift card holds, you pay 
  e19  How long is the statutory right of withdrawal?        I could not find that in our documents.
```

**Dezesseis de vinte e quatro**, dos dois jeitos, e as oito abaixo não estão todas erradas. Leia-as
contra os documentos:

- **Cinco são a recusa a uma pergunta que os documentos respondem**: o exemplar autografado, o e-book
  baixado, o Kindle, o parcelamento e o direito de arrependimento. A versão em vigor subiu o piso, e a
  aula 5 mostrou o que isso faz com perguntas cujo melhor trecho pontua logo abaixo dele.
- **A e02 contradiz a fonte.** O trecho que ela cita diz que a devolução é grátis e a etiqueta
  pré-paga, e a resposta diz que o cliente paga. É a mesma resposta que a aula 1 leu num trace.
- **A e16 e a e18 estão certas.** "As soon as it ships" diz o que o "when the order ships" do documento
  diz, e "the remaining amount" é "the rest" com outras palavras. A comparação as reprovou porque o
  modelo não copiou as palavras do documento.

Então a nota verdadeira é dezoito, e o programa diz dezesseis.

O `normalise.py` pega três respostas, **escritas pelo curso para isso**, contra o fato *30 days from
delivery*, para mostrar o que a normalização alcança e o que não alcança:

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
ana@dev:~/obs$ python normalise.py
exact True   normalised True   You have 30 days from delivery to return a printed book. [1]
exact False  normalised True   You have 30 days  from Delivery to return it. [1]
exact False  normalised False  You have thirty days after delivery to return it. [1]
```

A segunda resposta, com um espaço duplo e uma maiúscula, falha na comparação exata e passa na
normalizada. A terceira diz a mesma coisa com outras palavras e falha nas duas, exatamente como a e16 e
a e18. **Nenhuma normalização alcança uma paráfrase.** Uma comparação só pode ser afrouxada por coisas
que não mudam o sentido: maiúsculas, espaços, pontuação, talvez números por extenso. Cada afrouxamento
é uma decisão, tomada para este conjunto e escrita no código onde quem revisa a vê, exatamente como uma
lacuna declara `ignore_case`.

Isso torna a comparação determinística certa para os fatos que têm uma forma só: um preço, um número de
dias, um código de erro, um status de pedido, uma palavra de uma lista fixa. E errada para tudo o que
uma pessoa diria com as próprias palavras, que é a maior parte do que um assistente diz. A aula 9 trata
do resto.
