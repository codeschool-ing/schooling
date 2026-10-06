---
title: Quatro regras para um alerta
version: 1
---

Um alerta é uma regra avaliada num horário: a cada hora, digamos, o sistema de alertas calcula um número
sobre uma janela recente e o compara com um limiar. O `alerts.py` avalia quatro regras para "as recusas
subiram" a cada hora da semana reproduzida, e conta o que cada uma teria feito:

```python
"""alerts.py: four rules for "refusals are up", each evaluated every hour of the week as an alerting system would."""
import math
from datetime import datetime, timedelta

import replies

week = replies.week()
RELEASE = datetime(2026, 10, 2, 10)
before = [r["refused"] for r in week if r["at"] < datetime(2026, 10, 1)]
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
    "last 3 hours above 40%, 30 replies or more": lambda now: (lambda k, n: n >= 30 and k / n > 0.40)(*window(now, 3)),
    "yesterday above 30%, checked at midnight": lambda now: now.hour == 0 and (lambda k, n: n > 0 and k / n > 0.30)(*window(now, 24)),
    "last 6 hours surely above the baseline": lambda now: lower(*window(now, 6)) > BASELINE,
}
print(f"baseline: {sum(before)} refused of {len(before)} replies before 1 October, {BASELINE:.1%}")
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
ana@lab:~/obs$ python alerts.py
baseline: 136 refused of 551 replies before 1 October, 24.7%
last hour above 40%
    false alarms before the release  19   first after it: Fri 02 13:00, 3 h after   firing in 25 of the 62 hours after
last 3 hours above 40%, 30 replies or more
    false alarms before the release   0   first after it: Fri 02 14:00, 4 h after   firing in 6 of the 62 hours after
yesterday above 30%, checked at midnight
    false alarms before the release   0   first after it: Sat 03 00:00, 14 h after   firing in 3 of the 62 hours after
last 6 hours surely above the baseline
    false alarms before the release   1   first after it: Fri 02 14:00, 4 h after   firing in 28 of the 62 hours after
```

A versão foi ao ar na sexta às 10h. Cada regra é uma troca diferente:

- **"A última hora acima de 40%"** pega a versão três horas depois dela, e já disparou **19 vezes** nos
  três dias anteriores, quase sempre de madrugada, quando uma hora tem uma ou duas respostas. Na sexta
  ninguém mais a lê. A precisão da aula 11, medida num alerta: a maior parte dos disparos é falsa.
- **"As últimas três horas acima de 40%, com 30 respostas ou mais"** nunca dispara em falso, pega a
  versão em quatro horas, e depois **fica quieta**: dispara em 6 das 62 horas seguintes, porque a parcela
  fica em torno de 40% e toda madrugada cai abaixo do mínimo. Um alerta que se resolve sozinho enquanto o
  problema continua diz a quem o recebeu que o problema passou.
- **"Ontem acima de 30%, conferido à meia-noite"** é seguro e lento: catorze horas depois da versão, à
  meia-noite, com os clientes da noite inteira já dispensados.
- **"As últimas seis horas com certeza acima da linha de base"** usa o intervalo da aula 9: dispara quando
  até o extremo inferior do intervalo de 95% da parcela da janela está acima dos 24,7% dos dias
  anteriores. Pega a versão em quatro horas, fica ligado em 28 das 62 horas seguintes, e tem **um** alarme
  falso em três dias.

A quarta regra é a que esta equipe manteria, e a razão está na definição dela. Ela tem uma amostra mínima
embutida: com poucas respostas o intervalo é largo e o extremo inferior não passa da linha de base, então
as madrugadas não a disparam. E ela compara com o que este assistente costuma fazer, não com um número que
alguém escolheu, então não precisa de novo ajuste quando uma funcionalidade nova muda a parcela habitual de
recusas.
