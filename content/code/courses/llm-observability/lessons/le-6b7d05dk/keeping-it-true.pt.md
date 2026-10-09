---
title: Mantê-lo verdadeiro
version: 2
---

Um conjunto se degrada de dois jeitos que ninguém nota: os documentos mudam e os seus fatos deixam de
ser verdade, e alguém acrescenta um caso sem o cuidado que os primeiros tiveram. O `check_set.py`
confere os dois, em todo caso, em segundos:

```python
"""check_set.py: whether an evaluation set is still true of the documents, and holds nobody's data.

    python check_set.py SET [--docs FOLDER]
"""
import argparse
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact

logging.disable(logging.WARNING)   # Presidio warns about every recogniser it loads; none of it is news here
p = argparse.ArgumentParser()
p.add_argument("set")
p.add_argument("--docs", default="data/docs")
a = p.parse_args()
body = open(a.set, "rb").read()
cases = [json.loads(line) for line in body.decode().splitlines()]
manifest = json.load(open("data/eval-v2.manifest.json"))
shop = docs.load(a.docs)
chunks = {cid: text for _, found in shop.values() for cid, text in found.items()}
squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.$]", " ", t.lower())).strip()
analyzer = AnalyzerEngine()
problems = {"ids": [], "gold chunks": [], "facts": [], "personal data": [], "documents": []}
ids = [c["id"] for c in cases]
problems["ids"] = sorted({i for i in ids if ids.count(i) > 1})
for c in cases:
    missing = [g for g in c["gold"] if g not in chunks]
    if missing:
        problems["gold chunks"].append(f"{c['id']} {missing}")
    elif c["facts"]:
        text = " ".join(chunks[g] for g in c["gold"])
        if not any(squash(f) in squash(text) for f in c["facts"]):
            problems["facts"].append(f"{c['id']} {c['facts']}")
    allowed = set(c.get("synthetic", []))
    found = [c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                     entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])]
    found += [m.group() for _, pattern in redact.PATTERNS for m in pattern.finditer(c["question"])]
    if set(found) - allowed:
        problems["personal data"].append(f"{c['id']} {sorted(set(found) - allowed)}")
for d, updated in manifest["documents"].items():
    if shop[d][0]["updated"] != updated:
        problems["documents"].append(f"{d} was updated {shop[d][0]['updated']}, the set was checked against {updated}")
pinned = hashlib.sha256(body).hexdigest() == manifest["sha256"]
print(f"{a.set}: {len(cases)} cases, {'the version the manifest pins' if pinned else 'NOT the version the manifest pins'}")
for name, found in problems.items():
    print(f"  {name:14} {'ok' if not found else ''}".rstrip())
    for line in found:
        print(f"    {line}")
```

Cinco verificações, cada uma uma linha do relatório:

- **ids**: nenhum id aparece duas vezes.
- **gold chunks**: todo trecho para onde um caso aponta ainda existe, pelo seu id.
- **facts**: pelo menos um dos fatos de um caso está no texto dos seus trechos gold.
- **personal data**: nada numa pergunta parece um nome, um e-mail, um telefone ou um número de pedido,
  pelo Presidio e pelos padrões da aula 2, a não ser os valores que o caso declara sintéticos.
- **documents**: todo documento foi atualizado pela última vez na data que o manifesto fixou.

Na versão 2 como foi construída:

```
ana@dev:~/obs$ python check_set.py data/eval-v2.jsonl
data/eval-v2.jsonl: 32 cases, the version the manifest pins
  ids            ok
  gold chunks    ok
  facts          ok
  personal data  ok
  documents      ok
```

## Dois jeitos de dar errado

**Um caso colado direto da coleta.** Alguém copia a quinta linha do harvest num rascunho do conjunto,
mantendo o nome:

```
ana@dev:~/obs$ cp data/eval-v2.jsonl draft.jsonl && echo '{"id": "e33", "question": "This is Marta Seixas, order [order]: can I still return a book I got 3 weeks ago? My email is [email].", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' >> draft.jsonl
ana@dev:~/obs$ python check_set.py draft.jsonl
draft.jsonl: 33 cases, NOT the version the manifest pins
  ids            ok
  gold chunks    ok
  facts          ok
  personal data
    e33 ['Marta Seixas']
  documents      ok
```

O Presidio acha o nome. O número do pedido e o e-mail já tinham sido trocados pela remoção do harvest,
então os padrões não têm mais nada a achar. O nome teria ido para o repositório, para a saída de toda
execução e para todo pull request que mostra um caso falhando. A primeira linha do relatório também diz
algo: o rascunho não é a versão que o manifesto fixa, o que vale para qualquer conjunto editado até ser
montado e lançado como versão nova.

**Um documento que muda.** A loja sobe o limite do frete grátis de R$ 40 para R$ 50, e a data
`updated` do documento de entrega muda. Aqui a mudança é feita numa cópia:

```
ana@dev:~/obs$ cp -r data/docs docs-next && sed -i -e 's/over R\$ 40/over R$ 50/' -e 's/^updated: .*/updated: 2026-10-08/' docs-next/shipping-and-delivery.md
ana@dev:~/obs$ python check_set.py data/eval-v2.jsonl --docs docs-next
data/eval-v2.jsonl: 32 cases, the version the manifest pins
  ids            ok
  gold chunks    ok
  facts
    e07 ['R$ 40']
    e32 ['R$ 40']
  personal data  ok
  documents
    shipping-and-delivery was updated 2026-10-08, the set was checked against 2026-05-20
```

**Dois casos ficaram falsos**, o e07 da versão 1 e o e32 dos acréscimos desta aula, e o manifesto diz
por que vale olhar: o documento em que se apoiam foi atualizado depois de o conjunto ter sido conferido
contra ele. Sem a verificação, os dois casos começariam a falhar em toda versão a partir do dia em que o
documento mudou, e as falhas seriam culpa do conjunto, não do assistente: um modelo que respondesse
"free on orders over R$ 50" seria marcado errado por estar certo.

A correção é a manutenção que o título desta aula promete: aposentar os dois casos, escrever casos novos
com o fato novo, e lançar a versão 3. A aula 15 roda esta verificação no build, para que o dia em que os
documentos mudam seja o dia em que alguém fica sabendo.
