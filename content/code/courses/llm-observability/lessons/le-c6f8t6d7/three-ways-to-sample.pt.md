---
title: Três maneiras de escolher
version: 1
---

O `sample.py` guarda três regras para escolher quais respostas avaliar:

```python
"""sample.py: which replies of the week to grade, by three different rules."""
import hashlib
import random


def keep(trace, share):
    """Random but repeatable: the same trace is in or out on every run, decided by its id."""
    return int(hashlib.sha256(trace.encode()).hexdigest()[:8], 16) / 0xFFFFFFFF < share


def uniform(replies, share):
    return [r for r in replies if keep(r["trace"], share)]


def stratified(replies, per_group, key=lambda r: (r["release"], r["feature"])):
    """The same number from every group, so a small group is not drowned by a large one."""
    groups = {}
    for r in replies:
        groups.setdefault(key(r), []).append(r)
    rng = random.Random(7)
    return [r for g in sorted(groups) for r in rng.sample(groups[g], min(per_group, len(groups[g])))]


def targeted(replies):
    """Every reply somebody already doubted: a thumb down, or a refusal."""
    return [r for r in replies if r["thumb"] == "down" or r["outcome"] == "refused"]
```

A **uniforme** pega uma fração fixa de tudo. A escolha sai de um hash do id do trace e não de um número
aleatório, então uma nova execução escolhe as mesmas respostas, e duas pessoas que avaliam "a amostra de
10%" avaliam a mesma coisa. A **estratificada** pega o mesmo número de cada grupo, aqui cada combinação
de versão e funcionalidade. A **dirigida** pega toda resposta de que alguém já duvidou: um polegar para
baixo, ou uma recusa.

O `grade_sample.py` avalia a que foi escolhida e relata uma taxa de aprovação por versão, com o seu
intervalo de 95%:

```python
"""grade_sample.py: judge-1 on a sample of the week, pass rates per release with how sure they are."""
import argparse
import json
import math
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

import judge
import sample
import telemetry
import traffic

p = argparse.ArgumentParser()
p.add_argument("how", choices=["uniform", "stratified", "targeted"])
p.add_argument("--share", type=float, default=0.1)
p.add_argument("--per-group", type=int, default=30)
a = p.parse_args()


def wilson(passed, n, z=1.96):
    """The 95% interval for a pass rate measured on n replies."""
    if n == 0:
        return 0.0, 1.0
    p = passed / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return centre - half, centre + half


replies = list(traffic.replies())
chosen = {"uniform": lambda: sample.uniform(replies, a.share),
          "stratified": lambda: sample.stratified(replies, a.per_group),
          "targeted": lambda: sample.targeted(replies)}[a.how]()
telemetry.setup("judge-spans.jsonl", service="judge")
with ThreadPoolExecutor(8) as pool:   # eight at a time, as replay.py does
    verdicts = list(pool.map(lambda r: judge.grade("relevance", r["question"], r["reply"], r["sources"]), chosen))
passed, seen = defaultdict(int), defaultdict(int)
with open("verdicts.jsonl", "a") as out:
    for r, v in zip(chosen, verdicts):
        out.write(json.dumps({"trace": r["trace"], "criterion": "relevance", "sample": a.how, **v}) + "\n")
        seen[r["release"]] += 1
        passed[r["release"]] += v["verdict"] == "pass"
print(f"{a.how}: {len(chosen)} of {len(replies)} replies graded for relevance")
for rel in sorted(seen):
    lo, hi = wilson(passed[rel], seen[rel])
    print(f"  {rel}  {passed[rel]:4}/{seen[rel]:<4} pass  {passed[rel] / seen[rel]:5.1%}   95% between {lo:5.1%} and {hi:5.1%}")
```

```
ana@lab:~/obs$ python grade_sample.py uniform --share 0.1
uniform: 118 of 1221 replies graded for relevance
  2026.09.4    55/71   pass  77.5%   95% between 66.5% and 85.6%
  2026.10.1    31/47   pass  66.0%   95% between 51.7% and 77.8%
```

```
ana@lab:~/obs$ python grade_sample.py stratified --per-group 30
stratified: 120 of 1221 replies graded for relevance
  2026.09.4    40/60   pass  66.7%   95% between 54.1% and 77.3%
  2026.10.1    37/60   pass  61.7%   95% between 49.0% and 72.9%
```

```
ana@lab:~/obs$ python grade_sample.py targeted
targeted: 393 of 1221 replies graded for relevance
  2026.09.4    27/212  pass  12.7%   95% between  8.9% and 17.9%
  2026.10.1    18/181  pass   9.9%   95% between  6.4% and 15.2%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Taxas de aprovação em relevância por versão, como pontos com intervalos de 95%, num eixo de 0 a 100%. Toda resposta: 76,6% antes da versão e 62,3% depois, com intervalos estreitos. Uma amostra uniforme de 10%: 77,5% e 66,0%, com intervalos que se sobrepõem. Trinta por grupo: 66,7% e 61,7%, as duas baixas demais para a primeira versão. Dirigida: 12,7% e 9,9%, longe da verdade.\"><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">toda resposta</text><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 1221</text><path d=\"M552.2 40 L582.88 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"568.32\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M469.52 56 L516.84 56\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"493.96\" cy=\"56\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uniforme 10%</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 118</text><path d=\"M515.8 84 L615.12 84\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"573\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M438.84 100 L574.56 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"513.2\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">30 por grupo</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 120</text><path d=\"M451.32 128 L571.96 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"516.84\" cy=\"128\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M424.8 144 L549.08 144\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"490.84\" cy=\"144\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dirigida</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 393</text><path d=\"M216.28 172 L263.08 172\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"236.04\" cy=\"172\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M203.28 188 L249.04 188\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"221.48\" cy=\"188\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><path d=\"M170 218 L690 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 218 L170 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M274 218 L274 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"274\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M378 218 L378 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"378\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M482 218 L482 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"482\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M586 218 L586 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"586\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M690 218 L690 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"430\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parcela de respostas que o judge-1 aprova em relevância</text><circle cx=\"190.8\" cy=\"14\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"200.8\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2026.09.4</text><circle cx=\"305.2\" cy=\"14\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"315.2\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1</text></svg>", "caption": "Só a primeira linha é a semana. As outras são o que três jeitos de amostrar teriam relatado, e quão certo cada um podia estar."}
```

**A uniforme acerta a semana, com folga.** 77,5% e 66,0%, contra os verdadeiros 76,6% e 62,3%. Os dois
valores verdadeiros estão dentro dos intervalos, que é o que uma amostra não enviesada promete. Mas os
intervalos são largos, e se sobrepõem: só com esta amostra, uma equipe não poderia ter confiança de que
a versão piorou a relevância. Um décimo de semana não basta para ver com certeza uma queda de catorze
pontos, e a próxima seção diz quanto bastaria.

**A estratificada erra a primeira versão**, 66,7% contra 76,6% de verdade, e a razão é o desenho. Trinta
respostas de cada funcionalidade quer dizer que as perguntas de pedido, um quinto do tráfego, são metade
da amostra, e perguntas de pedido falham em relevância muito mais vezes. Um número igual por grupo é a
maneira certa de aprender sobre cada grupo, e a maneira errada de estimar o todo, a não ser que o
resultado de cada grupo volte a ser pesado pela sua parte do tráfego. Estratificar e esquecer de
repesar é um jeito comum de relatar um número que ninguém mediu.

**A dirigida não estima nada**: 12,7% e 9,9%. Ela escolheu as respostas com mais chance de serem ruins,
e eram. Esse é o seu propósito. Ela acha falhas para ler, depurar e transformar em casos de teste,
assunto da aula 13, por uma fração do custo de achá-las ao acaso. A sua taxa de aprovação nunca deve ir
para um painel como "qualidade", porque mede a regra de amostragem.

## Qual usar

As três, para perguntas diferentes. Uma amostra **uniforme** para o número que vai para o painel. Uma
**estratificada**, repesada, quando um grupo pequeno importa por si, como uma funcionalidade com pouco
tráfego que receberia três respostas num décimo uniforme. Uma **dirigida** para a lista de leitura, com
os resultados guardados à parte dos outros. E a regra que decidiu cada amostra guardada com os seus
veredictos, como o `grade_sample.py` faz em `verdicts.jsonl`, para que ninguém depois tire a média de
tudo junto.
