---
title: A versão que foi ao ar
version: 2
---

O `regress.py` compara duas execuções do mesmo conjunto. Ele recusa execuções que não fizeram
exatamente as perguntas do conjunto, e avalia cada resposta pelos fatos e pelas verificações da aula 8.
Depois relata os casos que se moveram, as verificações que passaram a falhar, e o que a mudança fez com
tokens, dinheiro e tempo. Salve-o em `~/obs`:

```python
"""regress.py: a candidate release against the current one, case by case, on the same evaluation set.

    python regress.py BASE CANDIDATE        # runs/BASE.jsonl and runs/CANDIDATE.jsonl
"""
import hashlib
import json
import math
import statistics
import sys

import checks
import costs
from facts import normalised

SET = "data/eval-v2.jsonl"
body = open(SET, "rb").read()
cases = {c["id"]: c for c in map(json.loads, body.decode().splitlines())}
spent = {r["trace"]: r for r in costs.requests("eval-spans.jsonl")}


def load(name):
    run = {r["id"]: r for r in map(json.loads, open(f"runs/{name}.jsonl"))}
    if {i: r["question"] for i, r in run.items()} != {i: c["question"] for i, c in cases.items()}:
        sys.exit(f"runs/{name}.jsonl did not ask the questions of {SET}: refusing to compare")
    return run


def grade(r):
    """Right by lesson 8's facts, and the set of lesson 8's checks the reply fails."""
    return normalised(r["reply"], cases[r["id"]]["facts"]), {n for n, ok, _ in checks.run(r["reply"], r["sources"]) if not ok}


def mcnemar(broken, fixed):
    """Exact two-sided p: how often chance alone would split this many changed verdicts at least this unevenly."""
    n = broken + fixed
    tail = sum(math.comb(n, k) for k in range(min(broken, fixed) + 1)) / 2 ** n
    return min(1.0, 2 * tail)


base_name, cand_name = sys.argv[1:3]
base, cand = load(base_name), load(cand_name)
release = lambda run: next(iter(run.values()))["release"]
print(f"{SET} sha256 {hashlib.sha256(body).hexdigest()[:12]}: {release(base)} -> {release(cand)}")
print("               both right  both wrong  fixed  broken")
moved = {"fixed": [], "broken": []}
for split in ("dev", "held-out"):
    count = dict.fromkeys(("both right", "both wrong", "fixed", "broken"), 0)
    for i, c in cases.items():
        if c["split"] != split:
            continue
        was, now = grade(base[i])[0], grade(cand[i])[0]
        key = "both right" if was and now else "both wrong" if not (was or now) else "fixed" if now else "broken"
        count[key] += 1
        if key in moved:
            moved[key].append(i)
    print(f"  {split:9} {count['both right']:12}{count['both wrong']:12}{count['fixed']:7}{count['broken']:8}")
print(f"exact McNemar p = {mcnemar(len(moved['broken']), len(moved['fixed'])):.4f}"
      f" on {len(moved['broken']) + len(moved['fixed'])} changed verdicts")
for key in ("broken", "fixed"):
    for i in moved[key]:
        print(f"  {key:6} {i} {cases[i]['split']:8} {cases[i]['question'][:56]}")
newly = {}
for i in cases:
    for n in sorted(grade(cand[i])[1] - grade(base[i])[1]):
        newly.setdefault(n, []).append(i)
print("checks newly failing:" + ("" if newly else " none"))
for n, ids in sorted(newly.items()):
    print(f"  {n:22}{len(ids):3}  {' '.join(ids)}")
print(f"replies changed: {sum(base[i]['reply'] != cand[i]['reply'] for i in cases)} of {len(cases)}")
for label, f in (("output tokens", lambda r: spent[r["trace"]]["output"]), ("cost US$", lambda r: spent[r["trace"]]["cost"]),
                 ("median ms", None)):
    if f is None:
        b, n = (statistics.median(spent[r["trace"]]["ms"] for r in run.values()) for run in (base, cand))
        print(f"{label:14} {b:10.0f} -> {n:10.0f}   {(n - b) / b:+.0%}")
    else:
        b, n = (sum(f(r) for r in run.values()) for run in (base, cand))
        print(f"{label:14} {b:10} -> {n:10}   {(n - b) / b:+.0%}")
```

A primeira comparação é história: a versão de 1º de outubro contra a anterior, que é o teste que
ninguém rodou naquela semana.

```
ana@dev:~/obs$ python regress.py 2026.09.4 2026.10.1
data/eval-v2.jsonl sha256 8763ed310b27: 2026.09.4 -> 2026.10.1
               both right  both wrong  fixed  broken
  dev                 11           4      1       6
  held-out             7           1      1       1
exact McNemar p = 0.1797 on 9 changed verdicts
  broken e02 dev      Who pays for the return postage?
  broken e04 dev      Can I return a signed copy?
  broken e14 dev      Can I pay in instalments?
  broken e16 dev      When do I get the invoice for my order?
  broken e19 dev      How long is the statutory right of withdrawal?
  broken e32 dev      when is shipping free
  broken e30 held-out Hi, I'm Ana Teste (ana.teste@example.com). My order MG-0
  fixed  e29 dev      This is Ana Teste, order MG-00000001: can I still return
  fixed  e12 held-out Will my e-books open on a Kindle?
checks newly failing:
  cites_every_sentence    1  e29
  numbers_in_sources      1  e29
replies changed: 15 of 32
output tokens         643 ->        471   -27%
cost US$       0.01323878 -> 0.00877328   -34%
median ms            3136 ->       2158   -31%
```

**Sete casos quebraram, e dois foram consertados.** Seis de desenvolvimento e um reservado: quem paga o
frete da devolução, o exemplar autografado, o parcelamento, a nota fiscal, o direito legal de
arrependimento, o frete grátis perguntado em palavras-chave, e uma encomenda perdida perguntada com um
nome e um número de pedido. Cada um é uma pergunta que a versão de setembro respondia e a de outubro
recusa, e aqui estão eles pelo nome, antes de algum cliente ter topado com qualquer um.

Os dois casos consertados também merecem um olhar. A e12, o Kindle, e a e29, uma devolução perguntada
dentro de uma mensagem de pedido, são respondidas agora e eram recusadas antes. Com o piso mais baixo o
modelo recebia três trechos para cada uma, o certo entre eles, e recusava; com o piso mais alto recebia
um ou dois, e respondia. É a descoberta da aula 11 vista do outro lado: mais contexto nem sempre ajuda
mais um modelo pequeno. E a nova resposta da e29 falha duas verificações que nunca tinha alcançado,
porque uma recusa não tem frase para deixar sem citação.

**Tudo abaixo dos casos parece uma melhora.** 27% menos tokens de saída, 34% mais barata, uma resposta
mediana 31% mais rápida. É por isso que uma versão assim vai ao ar. O piso faz o assistente recusar
mais, e uma recusa é curta, não custa chamada ao modelo e volta na hora; um painel de custo e latência
teria parabenizado a equipe. Só os casos dizem do que a economia foi feita.

Essa é a primeira regra para ler um relatório de regressão: **custo e latência se leem ao lado dos casos
quebrados, nunca no lugar deles**. Uma candidata que é mais rápida e mais barata porque responde menos é
um assistente pior com uma conta menor.
