---
title: A loja, os documentos e o índice
version: 1
---

Quem está no teclado neste curso é a ana, desenvolvedora na **Marginalia**, uma livraria online que
não existe. A loja tem um assistente de ajuda: o cliente digita uma pergunta, e ele responde a
partir dos próprios documentos da loja, citando-os. Neste curso **ele está em produção**: clientes
digitam nele, a equipe de suporte o usa para resumir conversas, e ninguém sabe dizer se ele vai bem.
Essa última parte é o assunto do curso.

O `rag` construiu um assistente como este, sobre um conjunto maior de documentos. Este curso
constrói um menor, só dele, nesta seção e nas próximas aulas, para não precisar de nada de outro
curso: sete documentos curtos, um índice, e o próprio assistente na seção 07. Tudo fica em `~/obs`.

## Os documentos

O `make-obs.sh` escreve os documentos e um arquivo de configuração no diretório que você indicar.
Salve-o como `~/make-obs.sh`, num editor ou colando-o entre `cat > ~/make-obs.sh <<'SCRIPT'` e uma
linha só com `SCRIPT`:

```sh
# make-obs.sh: Marginalia's documents and the assistant's releases, in the directory named
set -euo pipefail
mkdir -p "$1/data/docs"
cd "$1"
cat > data/docs/returns-policy.md <<'DOC'
---
title: Returns and refunds
updated: 2026-03-02
status: current
audience: public
---

## The return window

You can return a printed book within 30 days from delivery, for any reason. The book has to come
back in the condition it left: no writing in it and no broken spine.

## How to start a return

Open the order in your account and choose "Return an item". Returns are free: we e-mail you a
prepaid label, and you drop the parcel at any post office.

## Refunds

We refund within three working days of the return arriving at our warehouse, to the card or
account you paid with. A gift card is refunded as a new gift card.

## Items that cannot be returned

Signed copies, books printed on demand, and e-books or audiobooks once they have been downloaded.

## The right of withdrawal

Under Brazil's Consumer Protection Code you may cancel any purchase made online within seven days
of delivery, with no reason given, and we refund the whole amount, delivery included.
DOC
cat > data/docs/returns-policy-2025.md <<'DOC'
---
title: Returns and refunds (2025)
updated: 2025-01-15
status: superseded
audience: public
---

## The return window

You can return a printed book within 14 days from delivery.

## How to start a return

Write to the support team with your order number. The return postage is paid by the customer.
DOC
cat > data/docs/shipping-and-delivery.md <<'DOC'
---
title: Shipping and delivery
updated: 2026-05-20
status: current
audience: public
---

## Standard delivery

Standard delivery takes three to six working days. It costs R$ 12.90, and it is free on orders
over R$ 40.

## Express delivery

Express delivery arrives on the next working day if you order before 2 pm. It costs R$ 29.90, and
it is not free at any order value.

## Lost parcels

A standard parcel is considered lost when its tracking has not changed for 10 working days. Tell
us, and we send a new copy or refund you, whichever you prefer.

## Pickup points

You can collect a parcel at one of our pickup points instead. It waits there for ten days, and
then it comes back to us and we refund you.
DOC
cat > data/docs/ebooks-and-audiobooks.md <<'DOC'
---
title: E-books and audiobooks
updated: 2026-02-11
status: current
audience: public
---

## Devices

An e-book you buy from us can be read on up to six devices at the same time, signed in to the
same account.

## Formats

Our e-books are EPUB files protected with Adobe DRM. They open in any reading app that supports
Adobe DRM; Kindle readers cannot open them.

## Audiobooks

Audiobooks play in our app, on a phone or in the browser, and you can download them to listen
offline.
DOC
cat > data/docs/gift-cards.md <<'DOC'
---
title: Gift cards
updated: 2026-01-08
status: current
audience: public
---

## Validity

A gift card is valid for two years from the day it was bought. It cannot be exchanged for cash.

## Using a gift card

Type the card's code at checkout. If the order costs more than the card holds, you pay the rest
with any other method; if it costs less, the balance stays on the card.
DOC
cat > data/docs/payments-and-invoices.md <<'DOC'
---
title: Payments and invoices
updated: 2026-04-30
status: current
audience: public
---

## How you can pay

We accept credit and debit cards, Pix and bank slips. A bank slip takes up to two working days to
clear, and the order ships after that.

## Instalments

On a credit card you can pay in up to three instalments with no interest, on orders over R$ 100.

## Invoices

Every order comes with an electronic invoice, sent to your e-mail address when the order ships.
DOC
cat > data/docs/finance-refund-controls.md <<'DOC'
---
title: Refund controls (finance team)
updated: 2026-06-03
status: current
audience: internal
---

## Approvals

A refund above R$ 500 needs the approval of two people from the finance team before it is paid.
A refund to a different card from the one used to pay is never made.
DOC
cat > releases.json <<'JSON'
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.1": {"from": "2026-10-01T10:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.55}
}
JSON
```

Depois rode-o:

```
ana@dev:~$ bash make-obs.sh ~/obs
ana@dev:~/obs$ ls -R
.:
data
releases.json

./data:
docs

./data/docs:
ebooks-and-audiobooks.md
finance-refund-controls.md
gift-cards.md
payments-and-invoices.md
returns-policy-2025.md
returns-policy.md
shipping-and-delivery.md
```

Cada documento começa com algumas linhas de **front matter**, entre os dois `---`: o título, quando
foi atualizado pela última vez, se ainda está `current` (em vigor), e quem pode lê-lo. Cinco são
públicos e estão em vigor. O `returns-policy-2025.md` é a política do ano passado, `superseded`
(substituída), e diz o contrário da deste ano sobre quem paga uma devolução. O
`finance-refund-controls.md` é da equipe financeira, `internal`. Nenhum cliente pode ser respondido a
partir de nenhum dos dois, e o assistente garante isso antes que o modelo veja qualquer coisa.

## Versões

O `releases.json` é a configuração do assistente, e toda mudança nela é uma **versão** (*release*)
com o momento em que entrou em vigor. Uma versão diz o modelo, quantos trechos buscar para uma
pergunta (`k`), e a similaridade abaixo da qual um trecho encontrado nem é mostrado ao modelo
(`floor`, o piso). Em 1º de outubro alguém subiu o piso de 0.4 para 0.55, e essa ainda é a
versão em vigor. Guarde isso; a aula 5 descobre o que ela fez.

## O índice

O assistente encontra os documentos mais próximos de uma pergunta comparando números, não palavras.
O `index.py` corta cada documento em **trechos** (*chunks*), um para cada seção `## `, pede ao
`all-minilm` os 384 números de cada trecho, e grava todos em `data/index.json`, com o front matter de
cada trecho ao lado:

```python
"""index.py: the shop's documents, cut into chunks and embedded, written to data/index.json.

    python index.py

A chunk is one `## ` section of a document, with the document's title in front of it.
Each keeps the document's front matter (when it was updated, whether it is current,
who may read it), because the assistant searches only what is current and public.
"""
import glob
import json
import os

from openai import OpenAI

EMBEDDER = "all-minilm"
client = OpenAI()


def chunks(path):
    head, body = open(path).read().split("---\n")[1:3]
    meta = dict(line.split(": ", 1) for line in head.strip().splitlines())
    doc = os.path.basename(path)[:-3]
    for part in body.split("\n## ")[1:]:
        heading, text = part.split("\n", 1)
        yield {"id": f"{doc}:{heading.lower().replace(' ', '-')}", "doc": doc,
               "text": f"{meta['title']}: {heading}\n{' '.join(text.split())}",
               "updated": meta["updated"], "status": meta["status"], "audience": meta["audience"]}


rows = [c for path in sorted(glob.glob("data/docs/*.md")) for c in chunks(path)]
vectors = client.embeddings.create(model=EMBEDDER, input=[r["text"] for r in rows]).data
for r, v in zip(rows, vectors):
    r["embedding"] = [round(x, 6) for x in v.embedding]
json.dump({"embedder": EMBEDDER, "chunks": rows}, open("data/index.json", "w"))
print(f"{len(rows)} chunks from {len({r['doc'] for r in rows})} documents, "
      f"{len(rows[0]['embedding'])} numbers each, in data/index.json")
```

```
ana@dev:~/obs$ python index.py
20 chunks from 7 documents, 384 numbers each, in data/index.json
```

Vinte trechos, um pedido. O assistente lê este arquivo toda vez que começa; quando um documento
muda, rode o `index.py` de novo.

## Redação, antes de qualquer registro

Mais um arquivo, que o assistente importa e a aula 2 desmonta. O `redact.py` troca endereços de
e-mail, números de telefone, números de cartão e números de pedido por uma palavra entre colchetes
antes que um texto seja gravado em qualquer lugar, e transforma um id de usuário num hash com chave,
usando a `PSEUDONYM_KEY` que você definiu na seção anterior:

```python
"""redact.py: what is taken out of a text before it is recorded, and how a person is named instead.

    redact("write to joana.prado@example.com")  -> "write to [email]"
    pseudonym("u021")                            -> 16 hex characters, the same every time
"""
import hashlib
import hmac
import os
import re

PATTERNS = [
    ("email", re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")),
    ("phone", re.compile(r"\+\d{1,3}(?:[\s-]?\d){8,12}")),
    ("card", re.compile(r"\b(?:\d[ -]?){13,19}\b")),
    ("order", re.compile(r"\bMG-\d{8}\b")),
]


def redact(text):
    """TEXT with every match of PATTERNS replaced by its name in brackets."""
    for name, pattern in PATTERNS:
        text = pattern.sub(f"[{name}]", text)
    return text


def found(text):
    """{name: count} of what redact() would take out of TEXT."""
    return {name: len(p.findall(text)) for name, p in PATTERNS if p.search(text)}


KEY = os.environ.get("PSEUDONYM_KEY", "").encode()


def pseudonym(user):
    """A keyed hash of USER: the same person gets the same value, and without the key nobody can
    go from the value back to the person by trying every user id."""
    if not KEY:
        raise RuntimeError("PSEUDONYM_KEY is not set: refusing to record a user id unkeyed")
    return hmac.new(KEY, user.encode(), hashlib.sha256).hexdigest()[:16]
```

Com estes arquivos, o `~/obs` está pronto para a seção 06.
