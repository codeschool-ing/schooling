---
title: Quatro regras para um alerta
version: 2
---

Um alerta é uma regra avaliada numa agenda: a cada hora, digamos, o sistema de alertas calcula um número
sobre uma janela recente e o compara com um limiar. O `alerts.py` avalia quatro regras para "as recusas
subiram" a cada hora da semana reproduzida, e conta o que cada uma teria feito:

```python
"""alerts.py: four rules for "refusals are up", each evaluated every hour of the week as an alerting system would."""
import math
from datetime import datetime, timedelta

import replies

week = replies.week()
RELEASE = datetime(2026, 10, 1, 10)
before = [r["refused"] for r in week if r["at"] < RELEASE]
BASELINE = sum(before) / len(before)


def window(now, hours):
    """(refused, replies) in the HOURS before NOW."""
    rs = [r["refused"] for r in week if now - timedelta(hours=hours) <= r["at"] < now]
    return sum(rs), len(rs)


def lower(k, n, z=1.96):
    """The low end of the 95% Wilson interval of k in n, lesson 9's."""
    if n == 0:
        return 0.0
    p = k / n
    return ((p + z * z / (2 * n)) - z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))) / (1 + z * z / n)


RULES = {
    "last hour above 40%": lambda now: (lambda k, n: n > 0 and k / n > 0.40)(*window(now, 1)),
    "last 6 hours above 40%, 10 replies or more": lambda now: (lambda k, n: n >= 10 and k / n > 0.40)(*window(now, 6)),
    "yesterday above 30%, checked at midnight": lambda now: now.hour == 0 and (lambda k, n: n > 0 and k / n > 0.30)(*window(now, 24)),
    "last 24 hours surely above the baseline": lambda now: lower(*window(now, 24)) > BASELINE,
}
print(f"baseline: {sum(before)} refused of {len(before)} replies before the release, {BASELINE:.1%}")
hours = [datetime(2026, 9, 29) + timedelta(hours=h) for h in range(24 * 6 + 1)]
for name, rule in RULES.items():
    fired = [h for h in hours if rule(h)]
    early = [h for h in fired if h <= RELEASE]
    late = [h for h in fired if h > RELEASE]
    first = f"{late[0]:%a %d %H:%M}, {(late[0] - RELEASE).total_seconds() / 3600:.0f} h after" if late else "never"
    print(f"{name}\n    false alarms before the release {len(early):3}   first after it: {first}"
          f"   firing in {len(late)} of the {sum(h > RELEASE for h in hours)} hours after")
```

```
ana@dev:~/obs$ python alerts.py
baseline: 31 refused of 134 replies before the release, 23.1%
last hour above 40%
    false alarms before the release  12   first after it: Thu 01 14:00, 4 h after   firing in 31 of the 86 hours after
last 6 hours above 40%, 10 replies or more
    false alarms before the release   0   first after it: Thu 01 11:00, 1 h after   firing in 21 of the 86 hours after
yesterday above 30%, checked at midnight
    false alarms before the release   0   first after it: Fri 02 00:00, 14 h after   firing in 3 of the 86 hours after
last 24 hours surely above the baseline
    false alarms before the release   0   first after it: Thu 01 15:00, 5 h after   firing in 55 of the 86 hours after
```

A versão foi ao ar na quinta às 10h. Cada regra é uma troca diferente:

- **"A última hora acima de 40%"** pega a versão quatro horas depois dela, e já disparou **12 vezes** nos
  dois dias e meio anteriores. De dia uma hora tem duas ou três respostas e de madrugada nenhuma ou uma,
  então uma recusa em duas basta. Na quinta ninguém mais a lê. A precisão da aula 11, medida num alerta: a
  maioria dos disparos é falsa.
- **"As últimas seis horas acima de 40%, com 10 respostas ou mais"** nunca dispara em falso e pega a versão
  primeiro, uma hora depois dela, e então **fica quieta**: dispara em 21 das 86 horas seguintes, porque
  toda madrugada cai abaixo de dez respostas e de dia a parcela fica em torno de 40%. Um alerta que se
  resolve sozinho enquanto o problema ainda está lá diz a quem o recebeu que o problema passou.
- **"Ontem acima de 30%, conferido à meia-noite"** é seguro e lento: catorze horas depois da versão, à
  meia-noite, com os clientes da tarde inteira já despachados.
- **"As últimas 24 horas com certeza acima da linha de base"** usa o intervalo da aula 9: dispara quando
  até a ponta de baixo do intervalo de 95% da parcela da janela está acima dos 23,1% dos dias anteriores.
  Ela pega a versão em cinco horas, **não** tem alarme falso, e fica ligada em 55 das 86 horas seguintes.

A quarta regra é a que esta equipe manteria, e o motivo está na definição dela. Ela tem uma amostra
mínima embutida: com poucas respostas o intervalo é largo e a ponta de baixo não passa da linha de base,
então as madrugadas não a disparam, e ninguém precisou escolher um número como dez. Ela compara com o que
este assistente costuma fazer, não com um número que alguém escolheu, então não precisa ser reajustada
quando uma funcionalidade nova muda a parcela usual de recusas. E a janela dela é um dia porque esta loja
tem quarenta respostas por dia: um assistente mais movimentado ganha uma janela mais curta pela mesma
aritmética, e um mais quieto, uma mais longa.
