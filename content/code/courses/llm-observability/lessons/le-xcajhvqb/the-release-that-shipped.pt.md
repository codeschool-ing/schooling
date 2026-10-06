---
title: A versão que foi ao ar
version: 1
---

O `regress.py` compara duas execuções do mesmo conjunto. Ele recusa execuções que não fizeram exatamente
as perguntas do conjunto, avalia cada resposta pelos fatos e verificações da aula 8, e relata os casos
que se mexeram, as verificações que passaram a falhar, e o que a mudança fez com os tokens, o dinheiro e
o tempo:

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
new_fails = [(i, sorted(grade(cand[i])[1] - grade(base[i])[1])) for i in cases]
print("checks newly failing:", ", ".join(f"{i} {n}" for i, ns in new_fails for n in ns) or "none")
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

A primeira comparação é história: a versão de 2 de outubro contra a anterior, que é o teste que ninguém
rodou naquela semana.

```
ana@lab:~/obs$ python regress.py 2026.09.4 2026.10.1
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.09.4 -> 2026.10.1
               both right  both wrong  fixed  broken
  dev                 10          15      0       3
  held-out             8           4      0       2
exact McNemar p = 0.0625 on 5 changed verdicts
  broken e07 dev      Above what order value is standard delivery free?
  broken e17 dev      When is the contract of sale formed?
  broken e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  broken e24 held-out Do you store my IP address?
  broken e42 held-out right of withdrawal days
checks newly failing: none
replies changed: 12 of 42
output tokens         956 ->        637   -33%
cost US$       0.01821592 -> 0.00944242   -48%
median ms             701 ->         92   -87%
```

**Cinco casos quebraram, e nenhum foi consertado.** Três de desenvolvimento, dois reservados. A aula 8
viu três deles só como um total caindo de 19 para 16; aqui os cinco estão pelo nome, com as perguntas,
antes de qualquer cliente encontrá-los: o mínimo da entrega grátis, o contrato de compra, um pacote
perdido perguntado com número de pedido, o endereço IP, e o direito de arrependimento perguntado em
palavras-chave.

**E todo o resto do relatório parece uma melhora.** 33% menos tokens de saída, 48% mais barato, uma
resposta mediana mais de sete vezes mais rápida. É por isso que uma versão assim vai ao ar. O piso faz o
assistente recusar mais, e uma recusa é curta, não custa chamada de modelo, e volta na hora; um painel de
custo e latência teria parabenizado a equipe. Só os casos dizem de que eram feitas as economias.

Essa é a primeira regra para ler um relatório de regressão: **custo e latência se leem ao lado dos casos
quebrados, nunca no lugar deles**. Uma candidata mais rápida e mais barata porque responde menos é um
assistente pior com uma conta menor.
