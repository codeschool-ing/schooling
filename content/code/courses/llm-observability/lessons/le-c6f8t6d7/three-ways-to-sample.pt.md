---
title: Três maneiras de escolher
version: 2
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
"""grade_sample.py: the judge on a sample of the week, pass rates per release with how sure they are."""
import argparse
import json
import math
import time
from collections import Counter

import judge
import sample
import telemetry
import week

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


replies = list(week.replies())
chosen = {"uniform": lambda: sample.uniform(replies, a.share),
          "stratified": lambda: sample.stratified(replies, a.per_group),
          "targeted": lambda: sample.targeted(replies)}[a.how]()
telemetry.setup("judge-spans.jsonl", service="judge")
started = time.monotonic()
passed, seen, unreadable = Counter(), Counter(), Counter()
with open("verdicts.jsonl", "a") as out:
    for r in chosen:   # one at a time: a judge on the same machine as the assistant competes with it
        v = judge.grade("relevance", r["question"], r["reply"], r["sources"])
        out.write(json.dumps({"trace": r["trace"], "sample": a.how, **v}) + "\n")
        if v["verdict"] == "unreadable":
            unreadable[r["release"]] += 1
            continue
        seen[r["release"]] += 1
        passed[r["release"]] += v["verdict"] == "pass"
print(f"{a.how}: {len(chosen)} of {len(replies)} replies graded for relevance in "
      f"{(time.monotonic() - started) / 60:.1f} min, {sum(unreadable.values())} verdicts unreadable")
for rel in sorted(seen):
    lo, hi = wilson(passed[rel], seen[rel])
    print(f"  {rel}  {passed[rel]:4}/{seen[rel]:<4} pass  {passed[rel] / seen[rel]:5.1%}   95% between {lo:5.1%} and {hi:5.1%}")
```

```
ana@dev:~/obs$ python grade_sample.py uniform --share 0.1
uniform: 23 of 275 replies graded for relevance in 2.1 min, 0 verdicts unreadable
  2026.09.4     3/10   pass  30.0%   95% between 10.8% and 60.3%
  2026.10.1     2/13   pass  15.4%   95% between  4.3% and 42.2%
```

```
ana@dev:~/obs$ python grade_sample.py stratified --per-group 30
stratified: 120 of 275 replies graded for relevance in 10.6 min, 0 verdicts unreadable
  2026.09.4    28/60   pass  46.7%   95% between 34.6% and 59.1%
  2026.10.1    20/60   pass  33.3%   95% between 22.7% and 45.9%
```

```
ana@dev:~/obs$ python grade_sample.py targeted
targeted: 90 of 275 replies graded for relevance in 7.7 min, 0 verdicts unreadable
  2026.09.4     1/32   pass   3.1%   95% between  0.6% and 15.7%
  2026.10.1     0/58   pass   0.0%   95% between  0.0% and  6.2%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Taxas de aprovação em relevância por versão, como pontos com intervalos de 95%, num eixo de 0 a 100%. Todas as respostas: 43,3% antes da versão e 34,0% depois, com intervalos que se sobrepõem. Uma amostra uniforme de 10%: 30,0% e 15,4%, com intervalos tão largos que cobrem quase todo o eixo. Trinta por grupo: 46,7% e 33,3%, um pouco alto para a primeira versão. Dirigida: 3,1% e 0,0%, longe da semana.\"><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todas as respostas</text><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 275</text><path d=\"M353.04 40 L438.84 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"395.16\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M308.84 56 L389.44 56\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"346.8\" cy=\"56\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uniforme 10%</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 23</text><path d=\"M226.16 84 L483.56 84\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"326.0\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M192.36 100 L389.44 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"250.08\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">30 por grupo</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 120</text><path d=\"M349.92 128 L477.32 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"412.84\" cy=\"128\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M288.04 144 L408.68 144\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"343.16\" cy=\"144\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dirigida</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 90</text><path d=\"M173.12 172 L251.64 172\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"186.12\" cy=\"172\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M170.0 188 L202.24 188\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"188\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><path d=\"M170 218 L690 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 218 L170 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M274 218 L274 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"274\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M378 218 L378 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"378\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M482 218 L482 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"482\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M586 218 L586 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"586\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M690 218 L690 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"430\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parcela de respostas que o juiz aprova em relevância</text><circle cx=\"190.8\" cy=\"14\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"200.8\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2026.09.4</text><circle cx=\"305.2\" cy=\"14\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"315.2\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1</text></svg>", "caption": "Só a primeira linha é a semana. As outras são o que três jeitos de amostrar teriam informado, e com que segurança."}
```

**A uniforme é não enviesada e quase inútil neste tamanho.** Um décimo de 275 são 23 respostas, e
30,0% e 15,4% vêm com intervalos de 10,8% a 60,3% e de 4,3% a 42,2%. Os dois valores da semana estão
dentro deles, que é tudo o que uma amostra não enviesada promete. Nenhum dos intervalos consegue
separar as versões, ou distinguir um juiz que aprova um terço das respostas de um que aprova metade.

**A estratificada chega perto, e enviesada para cima.** 46,7% e 33,3%, contra 43,3% e 34,0% da semana.
Trinta respostas de cada funcionalidade em cada versão faz dos pedidos de `order`, um quarto da semana,
metade da amostra, e este juiz aprova respostas de `order` com mais frequência que as de `help`: 43%
contra 37%, na semana inteira. Um número igual por grupo é o jeito certo de aprender sobre cada grupo, e
o errado de estimar o todo, a menos que o resultado de cada grupo seja repesado pela sua parte do
tráfego. Estratificar e esquecer de repesar é um jeito comum de informar um número que ninguém mediu.

**A dirigida não estima nada**: 3,1% e 0,0%. Ela escolheu cada resposta de que alguém já tinha
duvidado, um polegar para baixo ou uma recusa, e o juiz reprovou todas menos uma. A maioria delas são as
recusas que ele reprova por hábito, então aqui a amostra dirigida mede o juiz tanto quanto o
assistente. É o outro uso dela: acha falhas para ler, depurar e transformar em casos de teste, o assunto
da aula 13, e acha onde o juiz erra. A taxa de aprovação dela nunca pode ir para um painel como
"qualidade", porque mede a regra de amostragem.

## Qual usar

As três, para perguntas diferentes. Uma amostra **uniforme** para o número que vai para o painel. Uma
**estratificada**, repesada, quando um grupo pequeno importa por si, como uma funcionalidade com pouco
tráfego que receberia três respostas num décimo uniforme. Uma **dirigida** para a lista de leitura, com
os resultados guardados à parte dos outros. E a regra que decidiu cada amostra guardada com os seus
veredictos, como o `grade_sample.py` faz em `verdicts.jsonl`, para que ninguém depois tire a média de
tudo junto.
