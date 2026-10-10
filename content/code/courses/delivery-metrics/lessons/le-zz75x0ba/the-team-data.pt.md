---
title: O histórico do time de Billing, no seu computador
version: 1
---

O programa abaixo escreve o histórico do time de Billing em dois arquivos. **Salve-o como `billing.py` na sua pasta `delivery`**: copie com o botão do bloco, cole em qualquer editor de texto e salve com esse nome. Depois rode.

```python
"""billing.py: the Billing team's history, June to September 2026.

The team is invented. This program simulates its board one working day at a
time and writes what the board and the pipeline would have recorded:

    items.csv     one row per work item, with the date it reached each column
    deploys.csv   one row per deployment, with the items it carried

The random numbers come from a fixed seed, so every computer that runs it
writes exactly the same files. On 3 August the team started limiting its work
in progress; LIMIT_FROM is that date, and lesson 4 asks you to move it.
"""
import csv
import random
import sys
from datetime import date, datetime, timedelta

START, END = date(2026, 6, 1), date(2026, 9, 30)
LIMIT_FROM = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date(2026, 8, 3)
DEVELOPERS = ["Caio", "Duda", "Ines", "Rafa", "Teo"]
rng = random.Random(43)


def workdays(first, last):
    day = first
    while day <= last:
        if day.weekday() < 5:
            yield day
        day += timedelta(days=1)


def new_item(number, created):
    effort = round(rng.lognormvariate(0.8, 0.6), 1)       # days of real work
    guess = effort * rng.lognormvariate(0, 0.5)            # what the team thought
    points = min([1, 2, 3, 5, 8], key=lambda p: abs(p - guess))
    kind = rng.choices(["feature", "bug", "chore"], [6, 3, 1])[0]
    return {"id": f"BIL-{number}", "type": kind, "points": points,
            "created": created, "started": "", "review": "", "merged": "",
            "left": effort}


items, backlog, waiting, parked, deploys = [], [], [], [], []
doing = {name: [] for name in DEVELOPERS}
numbers = iter(range(101, 1000))
for _ in range(25):                                        # the backlog on 1 June
    backlog.append(new_item(next(numbers), START - timedelta(days=rng.randint(3, 30))))

for day in workdays(START, END):
    limited = day >= LIMIT_FROM
    for name, item in parked[:]:                           # unblocked: back to its owner
        if item["until"] <= day:
            parked.remove((name, item))
            doing[name].append(item)
    for _ in range(rng.choice([0, 1, 1, 1, 2, 3])):        # requests that arrive
        backlog.append(new_item(next(numbers), day))
    reviewers = DEVELOPERS[:] if limited else ["Bia"] * rng.choice([0, 1, 1, 2, 2, 3])
    reviewed = []
    for name in reviewers:                                 # review first, oldest first
        if waiting and waiting[0]["review"] < day:
            reviewed.append(name)
            item = waiting.pop(0)
            item["merged"] = datetime(day.year, day.month, day.day,
                                      rng.randint(9, 17), rng.choice([0, 15, 30, 45]))
            items.append(item)
    for name in DEVELOPERS:
        mine = doing[name]
        while len(mine) < (1 if limited else 3) and backlog:
            item = backlog.pop(0)
            item["started"] = day
            mine.append(item)
        if not mine:
            continue
        item = rng.choice(mine)                            # what they work on today
        item["left"] -= (0.5 if name in reviewed else 1) * (1 if len(mine) == 1 else 0.8)
        if rng.random() < 0.02:                            # blocked, waiting on another team
            item["until"] = day + timedelta(days=rng.randint(5, 60))
            mine.remove(item)
            parked.append((name, item))
        elif item["left"] <= 0:
            item["review"] = day
            mine.remove(item)
            waiting.append(item)

    # The pipeline: every Thursday before the limit, every working day after it.
    ready = [i for i in items if i["merged"] and "deploy" not in i]
    if ready and (limited or day.weekday() == 3):
        hour = rng.randint(10, 17) if limited else 16
        at = datetime(day.year, day.month, day.day, hour, rng.choice([0, 20, 40]))
        failed = rng.random() < 1 - 0.96 ** len(ready)     # more changes, more risk
        deploy = {"id": f"D{len(deploys) + 1:03}", "at": at, "failed": int(failed),
                  "items": " ".join(i["id"] for i in ready), "restored": ""}
        if failed:                                         # and longer to undo
            minutes = rng.lognormvariate(3.3 + 0.25 * len(ready), 0.4)
            deploy["restored"] = at + timedelta(minutes=round(minutes))
        deploys.append(deploy)
        for i in ready:
            i["deploy"] = deploy["id"]

unfinished = backlog + waiting + [i for _, i in parked] + [i for m in doing.values() for i in m]
fields = ["id", "type", "points", "created", "started", "review", "merged"]
with open("items.csv", "w", newline="") as f:
    out = csv.DictWriter(f, fields, extrasaction="ignore")
    out.writeheader()
    out.writerows(sorted(items + unfinished, key=lambda i: int(i["id"][4:])))
with open("deploys.csv", "w", newline="") as f:
    out = csv.DictWriter(f, ["id", "at", "items", "failed", "restored"])
    out.writeheader()
    out.writerows(deploys)
print(f"{len(items)} items merged, {len(unfinished)} not yet, {len(deploys)} deploys")
```

Você não precisa ler o programa para usá-lo, mas ele é curto o bastante para ler, e uma leitura diz do que o histórico é feito.

**É uma simulação do quadro, um dia útil por vez.** Todo dia chegam pedidos novos no backlog, as pessoas revisam o que está esperando revisão, e cada dev trabalha num dos seus itens abertos. Um item termina quando recebeu tantos dias de trabalho quanto precisava e depois foi revisado. De vez em quando um item fica bloqueado, esperando outro time, e é posto de lado até ser liberado. Todo item ganha uma estimativa em story points, tirada do que ele de fato custou com bastante erro por cima, porque é isso que estimativas são; a aula 9 mede quanto.

**As regras mudam em 3 de agosto.** Antes dessa data cada dev mantém até três itens abertos e só a Bia revisa, entre as outras tarefas dela. A partir dessa data cada dev mantém um, e todo mundo revisa antes de começar algo novo. A variável `LIMIT_FROM` guarda a data, e o programa aceita outra na linha de comando, que é como a aula 4 roda o mesmo time com as regras mudando em outro dia.

**O pipeline muda no mesmo dia.** Antes do limite, o que foi integrado vai para produção toda quinta à tarde, num lote só. Depois dele, o que foi integrado vai para produção todo dia útil. Um deploy que leva mais mudanças tem mais chance de falhar, e um que falha demora mais para ser desfeito. As aulas 5 a 7 medem o que isso fez.

## Rodando

```
ana@laptop:~/delivery$ python3 billing.py
118 items merged, 17 not yet, 47 deploys
ana@laptop:~/delivery$ head -5 items.csv
id,type,points,created,started,review,merged
BIL-101,bug,2,2026-05-28,2026-06-01,2026-06-02,2026-06-03 11:45:00
BIL-102,feature,1,2026-05-26,2026-06-01,2026-06-10,2026-06-11 13:00:00
BIL-103,feature,3,2026-05-02,2026-06-01,2026-07-02,2026-07-03 09:00:00
BIL-104,feature,3,2026-05-03,2026-06-01,2026-06-12,2026-06-15 16:30:00
ana@laptop:~/delivery$ head -3 deploys.csv
id,at,items,failed,restored
D001,2026-06-04 16:20:00,BIL-105 BIL-108 BIL-101 BIL-112,0,
D002,2026-06-11 16:40:00,BIL-119 BIL-114 BIL-116 BIL-102 BIL-117,0,
```

O `head` imprime as primeiras linhas de um arquivo. Ele não é um comando do Windows; no PowerShell, `Get-Content items.csv -Head 5` faz o mesmo, e abrir o arquivo em qualquer editor de texto ou planilha também.

Os seus arquivos são byte a byte iguais a estes, porque os números aleatórios vêm de uma semente fixa. Se a primeira linha disser qualquer coisa diferente de 118, 17 e 47, o programa mudou ao ser copiado, e a próxima seção diz como achar onde.

## O que os dois arquivos guardam

O `items.csv` tem uma linha por item de trabalho, **135 ao todo**: os 118 integrados até 30 de setembro e os 17 que não foram.

| coluna | o que registra |
|---|---|
| `id` | o nome do item no quadro, a partir de `BIL-101` |
| `type` | `feature`, `bug` ou `chore` |
| `points` | a estimativa do time, em story points |
| `created` | o dia em que entrou no backlog |
| `started` | o dia em que alguém começou; vazio se ninguém começou |
| `review` | o dia em que foi entregue para revisão |
| `merged` | a data e a hora em que a revisão terminou e a mudança foi integrada |

O `deploys.csv` tem uma linha por deploy: um `id`, a data e a hora em que saiu, os itens que levou, se falhou (`failed` 1) ou não (0) e, para um que falhou, quando o serviço foi restaurado (`restored`).

**Essas são exatamente as colunas que um quadro e um pipeline de verdade dão**, com outros nomes. Jira, Linear e GitHub Projects registram quando um item mudou de coluna; toda ferramenta de deploy registra quando rodou e como terminou. Cada aula que lê esses arquivos diz qual coluna usa, então você pode apontar o mesmo programa para uma exportação do quadro do seu time.
