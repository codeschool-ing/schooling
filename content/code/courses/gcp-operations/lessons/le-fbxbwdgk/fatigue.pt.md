---
title: Fadiga de plantão, medida
version: 1
---

**Um alerta que dispara quando não há nada a fazer ensina quem está de plantão a ignorar alertas.** Isso é
fadiga, e não é questão de temperamento: depois de um mês de chamados que se resolvem sozinhos, uma pessoa
razoável para de levantar por eles, inclusive pelo que importava. A cura começa por contar, porque cada alerta
parece razoável sozinho e só a lista do mês mostra quais são ruído.

O programa abaixo gera um mês de notificações da loja, o tipo de lista que o histórico de incidentes do Cloud
Monitoring dá, e a resume. Escreva-o em `~/gcp/pages.py`:

```python
# pages.py
"""pages.py: a month of the shop's alert notifications, and what they say about on-call.

The notifications are generated, seeded. Each has the policy that sent it, when
it opened, how long the incident lasted, and whether anybody had to do anything.
"""
import random
from datetime import datetime, timedelta

rng = random.Random(5)
start = datetime(2026, 10, 1)
POLICIES = {                       # name: (notifications a month, minutes open, acted on?)
    "cpu above 80%": (61, (2, 6), 0.0),
    "payment retries high": (9, (10, 40), 0.8),
    "uptime check failing": (4, (3, 20), 1.0),
    "fast error-budget burn": (2, (30, 90), 1.0),
}
pages = []
for name, (n, (lo, hi), acted) in POLICIES.items():
    for _ in range(n):
        at = start + timedelta(minutes=rng.randint(0, 30 * 24 * 60))
        pages.append((name, at, rng.randint(lo, hi), rng.random() < acted))

night = lambda t: t.hour < 7 or t.hour >= 22
print(f'{"policy":<24}{"pages":>6}{"at night":>9}{"closed <10 min":>15}{"acted on":>9}')
for name in POLICIES:
    p = [x for x in pages if x[0] == name]
    print(f'{name:<24}{len(p):>6}{sum(night(t) for _, t, _, _ in p):>9}'
          f'{sum(m < 10 for _, _, m, _ in p):>15}{sum(a for *_, a in p):>9}')
print(f'{"total":<24}{len(pages):>6}{sum(night(t) for _, t, _, _ in pages):>9}'
      f'{sum(m < 10 for _, _, m, _ in pages):>15}{sum(a for *_, a in pages):>9}')
```

```
ana@laptop:~/gcp$ python3 pages.py
policy                   pages at night closed <10 min acted on
cpu above 80%               61       31             61        0
payment retries high         9        1              0        5
uptime check failing         4        0              2        4
fast error-budget burn       2        1              0        2
total                       76       33             63       11
```

**76 notificações num mês, 33 delas à noite, e 11 em que alguém agiu.** Leia as linhas:

- **`cpu above 80%`** mandou 61, metade à noite, todas fechadas sozinhas em dez minutos, e ninguém nunca fez nada.
  CPU no Cloud Run fica alta quando o serviço está ocupado, que é quando ele está fazendo o trabalho dele. Esta
  política é ruído puro: mede uma causa, não um sintoma que quem usa sente, e o SLI da lição 13 já diz se quem usa
  está falhando. **Apague-a.**
- **`payment retries high`** mandou 9, e 5 precisaram de ação. É um sinal útil no canal errado: é trabalho para o
  horário comercial, e vai para a fila de chamados, como a seção anterior fez.
- **`uptime check failing`** e **`fast error-budget burn`** mandaram 6 entre as duas, e as 6 precisaram de alguém.
  Esses são chamados urgentes.

Apagar uma política leva o mês de 76 notificações para 15, e de 33 noturnas para 2. Nada na capacidade da loja de
perceber uma falha real muda, porque as políticas que percebem falhas reais ficam intactas.

## Perguntas para toda política

1. **É um sintoma que quem usa sente?** Se é uma causa (CPU, memória, profundidade de uma fila), pertence a um
   painel, onde alguém investigando vai olhar, não a um telefone.
2. **Alguém agiu nela no mês passado?** Uma política cujas notificações fecham todas sem ação é ruído por medição,
   seja qual for o motivo pelo qual foi criada.
3. **Precisa de uma pessoa agora?** Se não, um chamado na fila.
4. **A notificação diz o que fazer?** O campo `documentation` é a primeira coisa lida às 3 da manhã.

## O plantão em si

A loja tem duas pessoas. Cada uma pega uma semana de plantão por vez, com a outra como segundo nível se a primeira
não reconhecer o chamado em quinze minutos. Uma semana com mais de dois chamados noturnos é revisada na segunda
seguinte, política por política, com as quatro perguntas desta lição, e um chamado que chegou e não precisava de
nada é um defeito numa política, corrigido como um defeito no código. A próxima lição é o que acontece quando um
chamado precisa mesmo de alguém.
