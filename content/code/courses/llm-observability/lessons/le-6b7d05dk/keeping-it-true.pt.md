---
title: Mantê-lo verdadeiro
version: 1
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

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
p = argparse.ArgumentParser()
p.add_argument("set")
p.add_argument("--docs", default="data/docs")
a = p.parse_args()
body = open(a.set, "rb").read()
cases = [json.loads(line) for line in body.decode().splitlines()]
manifest = json.load(open("data/eval-v2.manifest.json"))
shop = docs.load(a.docs)
squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
analyzer = AnalyzerEngine()
problems = {"ids": [], "gold sections": [], "facts": [], "personal data": [], "documents": []}
ids = [c["id"] for c in cases]
problems["ids"] = sorted({i for i in ids if ids.count(i) > 1})
for c in cases:
    missing = [g for g in c["gold"] if g[0] not in shop or g[1] not in shop[g[0]][1]]
    if missing:
        problems["gold sections"].append(f"{c['id']} {missing}")
    elif c["facts"]:
        text = " ".join(shop[d][1][h] for d, h in c["gold"])
        if not any(squash(f) in squash(text) for f in c["facts"]):
            problems["facts"].append(f"{c['id']} {c['facts']}")
    allowed = set(c.get("synthetic", []))
    found = [c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                     entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])]
    found += [m.group() for _, pattern in redact.PATTERNS for m in pattern.finditer(c["question"])]
    if set(found) - allowed:
        problems["personal data"].append(f"{c['id']} {sorted(set(found) - allowed)}")
for d, version in manifest["documents"].items():
    if shop[d][0]["version"] != version:
        problems["documents"].append(f"{d} is version {shop[d][0]['version']}, the set was checked against {version}")
pinned = hashlib.sha256(body).hexdigest() == manifest["sha256"]
print(f"{a.set}: {len(cases)} cases, {'the version the manifest pins' if pinned else 'NOT the version the manifest pins'}")
for name, found in problems.items():
    print(f"  {name:14} {'ok' if not found else ''}".rstrip())
    for line in found:
        print(f"    {line}")
```

Cinco verificações, cada uma uma linha do relatório:

- **ids**: nenhum id aparece duas vezes.
- **gold sections**: toda seção para onde um caso aponta ainda existe, por documento e título.
- **facts**: pelo menos um dos fatos de um caso está no texto das suas seções gold.
- **personal data**: nada numa pergunta parece um nome, um e-mail, um telefone ou um número de pedido,
  pelo Presidio e pelos padrões da aula 2, a não ser os valores que o caso declara sintéticos.
- **documents**: todo documento ainda está na versão que o manifesto fixou.

Na versão 2 como foi construída:

```
ana@lab:~/obs$ python check_set.py data/eval-v2.jsonl
data/eval-v2.jsonl: 42 cases, the version the manifest pins
  ids            ok
  gold sections  ok
  facts          ok
  personal data  ok
  documents      ok
```

## Dois jeitos de dar errado

**Um caso colado direto da coleta.** Alguém copia a terceira linha do harvest num rascunho do conjunto,
mantendo o nome:

```
ana@lab:~/obs$ cp data/eval-v2.jsonl draft.jsonl && echo '{"id": "e43", "question": "Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"]}' >> draft.jsonl
ana@lab:~/obs$ python check_set.py draft.jsonl
draft.jsonl: 43 cases, NOT the version the manifest pins
  ids            ok
  gold sections  ok
  facts          ok
  personal data
    e43 ['Tiago Moura']
  documents      ok
```

O Presidio acha o nome. O número do pedido e o telefone já tinham sido trocados pela remoção do harvest,
então os padrões não têm mais o que achar; o nome teria ido para o repositório, para a saída de toda
execução, e para todo pull request que mostrasse um caso reprovado. A primeira linha do relatório também
diz algo: o rascunho não é a versão que o manifesto fixa, o que vale para qualquer conjunto editado até
ele ser construído e lançado como versão nova.

**Um documento que muda.** A loja sobe o mínimo da entrega grátis de 40 para 50, e o documento de entrega
passa da versão 6 para a 7. Aqui a mudança é feita numa cópia:

```
ana@lab:~/obs$ cp -r data/docs docs-next && sed -i -e 's/free on orders over 40/free on orders over 50/' -e 's/^version: 6$/version: 7/' docs-next/shipping-and-delivery.md
ana@lab:~/obs$ python check_set.py data/eval-v2.jsonl --docs docs-next
data/eval-v2.jsonl: 42 cases, the version the manifest pins
  ids            ok
  gold sections  ok
  facts
    e07 ['free on orders over 40']
    e33 ['free on orders over 40']
  personal data  ok
  documents
    shipping-and-delivery is version 7, the set was checked against 6
```

**Dois casos ficaram falsos**, o e07 da versão 1 e o e33 dos acréscimos desta aula, e o manifesto diz por
que vale olhar: o documento em que eles se apoiam não está na versão contra a qual o conjunto foi
conferido. Sem a verificação, os dois começariam a reprovar toda versão do assistente a partir do dia em
que o documento mudou, e as reprovações seriam culpa do conjunto, não do assistente: um modelo que
respondesse "free on orders over 50" seria marcado errado por estar certo.

A correção é a manutenção que o título desta aula promete: aposentar os dois casos, escrever casos novos
com o fato novo, e lançar a versão 3. A aula 15 roda esta verificação no build, para que o dia em que os
documentos mudam seja o dia em que alguém fica sabendo.
