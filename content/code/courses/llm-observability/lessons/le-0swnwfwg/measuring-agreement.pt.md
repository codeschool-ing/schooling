---
title: Concordância, e concordância por acaso
version: 2
---

A medida óbvia de dois avaliadores é com que frequência concordam. Sozinha ela engana, e o motivo é
aritmético. Se os dois aprovassem nove respostas em dez sem lê-las, ainda concordariam na maioria,
porque na maior parte das vezes os dois teriam escrito aprovado. **Parte da concordância é de graça**,
e quanto depende só de com que frequência cada um dá cada veredicto.

O **kappa de Cohen** tira a parte de graça. Ele compara a concordância observada com a que dois
avaliadores alcançariam por acaso, escrevendo os veredictos nas próprias proporções sem ligação
nenhuma entre eles:

```
kappa = (observed − by chance) / (1 − by chance)
```

O kappa é 1 quando concordam em tudo, 0 quando concordam exatamente tanto quanto o acaso os faria
concordar, e abaixo de 0 quando concordam menos que isso, o que quer dizer que estão lendo a rubrica
sistematicamente de jeitos opostos. O `agree.py` o calcula para dois conjuntos de rótulos quaisquer, e
lista as respostas em que os dois discordam, separadas por ser ou não a recusa combinada:

```python
"""agree.py: how far two sets of relevance labels agree, beyond what chance alone would give.

    python agree.py relevance-v1/ana relevance-v1/bruno
    python agree.py relevance-v2/agreed judge

A set is RUBRIC/RATER from data/labels.jsonl, or `judge`, the verdicts
judge_runs.py wrote. A reply is named by its question's id and the release
that wrote it, never by its position in a file.
"""
import json
import sys
from collections import Counter

import checks

def kappa(a, b):
    """Cohen's kappa: the agreement observed, the agreement chance would give, and how far beyond it."""
    n = len(a)
    observed = sum(x == y for x, y in zip(a, b)) / n
    ca, cb = Counter(a), Counter(b)
    expected = sum(ca[k] * cb[k] for k in ca) / n / n
    return observed, expected, (observed - expected) / (1 - expected)

def load(name):
    if name == "judge":
        return {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("runs/judged.jsonl"))}
    rubric, rater = name.split("/")
    return {(r["case"], r["release"]): r[rubric][rater] for r in map(json.loads, open("data/labels.jsonl"))}

replies = {(r["id"], r["release"]): r["reply"] for run in ("old", "new") for r in map(json.loads, open(f"runs/{run}.jsonl"))}
left, right = load(sys.argv[1]), load(sys.argv[2])
keys = sorted(left)
assert keys == sorted(right) == sorted(replies), "the two sets do not label the same replies"
a, b = [left[k] for k in keys], [right[k] for k in keys]
observed, expected, k = kappa(a, b)
cells = Counter(zip(a, b))
print(f"{len(keys)} replies; rows {sys.argv[1]}, columns {sys.argv[2]}")
print("          pass  fail")
for x in ("pass", "fail"):
    print(f"  {x}  {cells[x, 'pass']:6}{cells[x, 'fail']:6}")
print(f"agreement {observed:.1%}   by chance {expected:.1%}   kappa {k:.2f}")
apart = [key for key in keys if left[key] != right[key]]
refusals = [key for key in apart if checks.is_refusal(replies[key])]
print(f"apart on {len(apart)}: {len(refusals)} refusals, {len(apart) - len(refusals)} other replies")
for key in apart:
    print(f"  {key[0]} {key[1]}  {left[key]} / {right[key]}  {replies[key][:58]}")
```

## Versão 1

```
ana@dev:~/obs$ python agree.py relevance-v1/ana relevance-v1/bruno
48 replies; rows relevance-v1/ana, columns relevance-v1/bruno
          pass  fail
  pass      31    17
  fail       0     0
agreement 64.6%   by chance 64.6%   kappa 0.00
apart on 17: 17 refusals, 0 other replies
  e04 2026.10.1  pass / fail  I could not find that in our documents.
  e05 2026.09.4  pass / fail  I could not find that in our documents.
  e05 2026.10.1  pass / fail  I could not find that in our documents.
  e12 2026.09.4  pass / fail  I could not find that in our documents.
  e12 2026.10.1  pass / fail  I could not find that in our documents.
  e14 2026.10.1  pass / fail  I could not find that in our documents.
  e19 2026.10.1  pass / fail  I could not find that in our documents.
  e20 2026.09.4  pass / fail  I could not find that in our documents.
  e20 2026.10.1  pass / fail  I could not find that in our documents.
  e21 2026.09.4  pass / fail  I could not find that in our documents.
  e21 2026.10.1  pass / fail  I could not find that in our documents.
  e22 2026.09.4  pass / fail  I could not find that in our documents.
  e22 2026.10.1  pass / fail  I could not find that in our documents.
  e23 2026.09.4  pass / fail  I could not find that in our documents.
  e23 2026.10.1  pass / fail  I could not find that in our documents.
  e24 2026.09.4  pass / fail  I could not find that in our documents.
  e24 2026.10.1  pass / fail  I could not find that in our documents.
```

**Eles concordam em 31 das 48 respostas, 64,6%, e o acaso sozinho daria exatamente isso.** O kappa é
0,00: duas pessoas lendo as mesmas respostas contra a mesma frase concordaram em dois terços delas, e
nem uma concordância a mais do que se uma delas tivesse escrito veredictos sem olhar. Nenhuma foi
descuidada. A tabela diz por quê: a Ana aprovou todas as respostas, e quando um avaliador nunca
reprova, toda concordância é do tipo de graça.

**As dezessete discordâncias são todas a recusa.** A Ana leu "a resposta trata da pergunta" como "é
sobre a pergunta", e uma resposta dizendo que os documentos não têm a resposta é sobre a pergunta. O
Bruno leu como "responde", e uma recusa não responde nada. As duas leituras são razoáveis, e a versão 1
não escolhe entre elas. Repare que os dois aprovaram toda resposta que respondeu, inclusive a e02 na
versão nova, que diz ao cliente que ele paga o frete da devolução quando não paga. Nenhuma leitura da
versão 1 pergunta se uma resposta é verdadeira, e nenhuma deveria: isso é fidelidade.

## Para que serve o número

Um kappa zero não diz nada sobre as respostas e diz tudo sobre a rubrica: **os rótulos não podem ser
usados como referência**, porque uma terceira pessoa concordaria com a Ana ou com o Bruno conforme
lesse uma frase. Medir o juiz contra qualquer um dos conjuntos seria medi-lo contra uma moeda.

Existem tabelas que dão nome a faixas de kappa, "leve", "moderada", "substancial", e elas são
convenções, não resultados. O que importa na prática é a comparação: o kappa entre pessoas é o teto
prático do kappa entre o juiz e as pessoas. Quando duas pessoas concordam pela metade, um juiz que bate
com uma delas está batendo com uma leitura da rubrica, não com a rubrica.
