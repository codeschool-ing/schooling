---
title: Concordância, e concordância por acaso
version: 1
---

A medida óbvia de duas pessoas avaliando é com que frequência concordam. Sozinha ela engana, e a razão
é aritmética. Se as duas aprovassem nove respostas em dez sem ler, ainda concordariam na maioria,
porque na maior parte das vezes as duas teriam escrito "passa". **Uma parte da concordância vem de
graça**, e quanto depende só de com que frequência cada uma diz cada veredicto.

O **kappa de Cohen** tira a parte de graça. Ele compara a concordância observada com a que duas pessoas
alcançariam por acaso, escrevendo veredictos nas suas próprias proporções, sem nenhuma ligação entre
elas:

```
kappa = (observed − by chance) / (1 − by chance)
```

O kappa é 1 quando concordam em tudo, 0 quando concordam exatamente tanto quanto o acaso faria, e
abaixo de 0 quando concordam menos do que isso, o que quer dizer que leem a rubrica de jeitos opostos
de forma sistemática. O `agree.py` calcula o kappa para quaisquer dois conjuntos de rótulos, e lista as
respostas em que os dois discordam, separadas por serem ou não a recusa combinada:

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
    return {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("data/labels.jsonl"))
            if r["rubric"] == rubric and r["rater"] == rater}


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
    if key not in refusals:
        print(f"  {key[0]} {key[1]}  {left[key]} / {right[key]}  {replies[key][:58]}")
```

## Versão 1

```
ana@lab:~/obs$ python agree.py relevance-v1/ana relevance-v1/bruno
60 replies; rows relevance-v1/ana, columns relevance-v1/bruno
          pass  fail
  pass      27    29
  fail       0     4
agreement 51.7%   by chance 45.7%   kappa 0.11
apart on 29: 24 refusals, 5 other replies
  e02 2026.09.4  pass / fail  Keep the receipt the post office gives you until the refun
  e05 2026.09.4  pass / fail  An e-book can be refunded within 14 days of purchase if yo
  e05 2026.10.1  pass / fail  An e-book can be refunded within 14 days of purchase if yo
  e06 2026.09.4  pass / fail  Express delivery is not free at any order value. [1]
  e06 2026.10.1  pass / fail  Express delivery is not free at any order value. [1]
```

**Eles concordam em 31 das 60 respostas, 51,7%, e o acaso sozinho daria 45,7%.** O kappa é 0,11: duas
pessoas lendo as mesmas respostas pela mesma frase concordaram pouco mais do que se uma delas tivesse
escrito veredictos sem olhar. Nenhuma das duas foi descuidada. A tabela diz onde deu errado: a Ana
aprovou quase tudo, 56 de 60, e o Bruno aprovou menos da metade.

**Vinte e quatro das vinte e nove discordâncias são a recusa.** A Ana leu "a resposta trata da
pergunta" como "é sobre a pergunta", e uma resposta dizendo que os documentos não têm a resposta é
sobre a pergunta. O Bruno leu como "responde à pergunta", e uma recusa não responde nada. As duas
leituras são razoáveis, e a versão 1 não escolhe entre elas.

As outras cinco são dois tipos de resposta que ficam na fronteira da mesma frase:

- **e02 na versão antiga**: à pergunta de quem paga a postagem da devolução, a resposta fala de
  guardar o comprovante dos correios. É sobre a postagem da devolução, e não diz quem paga.
- **e06 nas duas versões**: à pergunta de quanto custa a entrega expressa, a resposta diz que ela não
  é grátis em nenhum valor de pedido. No assunto; não o preço.
- **e05 nas duas versões**: à pergunta de se um e-book baixado ontem pode ser reembolsado, a resposta
  diz que um e-book pode ser reembolsado se não tiver sido baixado. A resposta está nela, mas o cliente
  tem de deduzi-la.

## Para que serve o número

Um kappa tão baixo não diz nada das respostas e tudo da rubrica: **os rótulos não podem servir de
referência**, porque uma terceira pessoa concordaria com a Ana ou com o Bruno conforme lesse uma frase.
Medir o juiz contra qualquer um dos dois conjuntos seria medir o juiz contra uma moeda.

Há tabelas que dão nome a faixas de kappa, "leve", "moderada", "substancial", e elas são convenções,
não resultados. O que importa na prática é a comparação: o kappa entre pessoas é o teto prático do
kappa entre o juiz e as pessoas. Quando duas pessoas concordam só pela metade, um juiz que bate com uma
delas está batendo com uma leitura da rubrica, não com a rubrica.
