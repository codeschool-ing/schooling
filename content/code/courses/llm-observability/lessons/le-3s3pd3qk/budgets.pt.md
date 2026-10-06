---
title: Orçamentos no código
version: 1
---

Um relatório diz o que foi gasto. Um orçamento diz o que pode ser gasto, e os úteis são conferidos pela
aplicação, não lidos por uma pessoa no fim do mês. Dois tipos funcionam para um sistema como este.

**Um orçamento por funcionalidade por dia** diz quanto o produto aceita gastar com cada coisa que faz.
Ultrapassá-lo não é um erro; é um sinal de que o uso ou o custo por pedido mudou, e alguém deveria
olhar. **Um teto por usuário por dia** protege contra uma conta, ou um script, gastar o que todos os
outros juntos gastariam. Ultrapassá-lo é uma decisão que a aplicação toma na hora: ir mais devagar,
usar um modelo mais barato, ou recusar até amanhã.

Os orçamentos do laboratório são um arquivo, e o `budget.py` confronta a semana com eles:

```python
"""budget.py: each day's spend per feature against a daily budget, and the users over a daily cap."""
import json
from collections import defaultdict
from decimal import Decimal

import costs

BUDGET = {k: Decimal(v) for k, v in json.load(open("budgets.json"))["daily"].items()}
CAP = Decimal(json.load(open("budgets.json"))["per_user_daily"])
day_feature, day_user = defaultdict(Decimal), defaultdict(Decimal)
for r in costs.requests():
    day = r["at"].strftime("%a %d")
    day_feature[day, r["feature"]] += r["cost"]
    day_user[day, r["user"]] += r["cost"]
print(f"{'day':7}" + "".join(f"{f:>16}" for f in BUDGET))
for day in dict.fromkeys(d for d, _ in day_feature):
    cells = []
    for f, b in BUDGET.items():
        spent = day_feature[day, f]
        cells.append(f"{spent:.4f}{' OVER' if spent > b else '     '}".rjust(16))
    print(f"{day:7}" + "".join(cells))
over = sorted((v, d, u) for (d, u), v in day_user.items() if v > CAP)
print(f"users over {CAP} a day: {len(over)}")
for v, d, u in over[-3:]:
    print(f"  {d}  {u}  {v:.4f}")
```

```
ana@lab:~/obs$ cat budgets.json
{"daily": {"help": "0.10", "order": "0.04", "summary": "0.012"}, "per_user_daily": "0.005"}
ana@lab:~/obs$ python budget.py
day                help           order         summary
Mon 28      0.0986          0.0434 OVER     0.0121 OVER
Tue 29      0.1130 OVER     0.0383          0.0126 OVER
Wed 30      0.1220 OVER     0.0322          0.0116     
Thu 01      0.0827          0.0334          0.0070     
Fri 02      0.0751          0.0200          0.0067     
Sat 03      0.0423          0.0094          0.0048     
Sun 04      0.0439          0.0083          0.0054     
users over 0.005 a day: 8
  Mon 28  29732abf5563ccec  0.0060
  Tue 29  adc7eb33a816d390  0.0066
  Tue 29  3f5e7afb6e2effd3  0.0074
```

Os orçamentos foram definidos olhando a semana, que é como um primeiro orçamento se define na prática,
e é por isso que os estouros se concentram onde a semana foi mais movimentada. `help` passou dos seus
0,10 na terça e na quarta, `order` dos seus 0,04 na segunda, e `summary` dos seus 0,012 na segunda e na
terça. De quinta em diante nada chega perto, o que nesta semana é o corte de preço e depois a versão,
não contenção.

Oito vezes na semana um usuário passou de meio centavo num dia, nenhuma delas por muito: a maior foi
0,0074. Nenhuma assusta, e é para isso que serve um teto. Ele não custa nada até o dia em que importa.

## Onde fica a verificação

O `budget.py` lê os spans depois do fato, o que está certo para um relatório diário e é tarde demais
para um teto. Um teto é conferido **antes da chamada**: mantenha um total corrente por usuário no dia,
no mesmo armazém que a aplicação já usa para sessões, some o custo de cada pedido quando ele termina, e
olhe o total antes de começar o próximo. Os spans continuam sendo o registro; o total corrente é o
freio.

E os limites do próprio fornecedor ficam atrás dos dois. A aula 21 do `ai-models` define limites de
gasto e alertas nos consoles dos fornecedores. Eles são a última linha, a que segura quando a
verificação da própria aplicação tem um defeito; nunca deveriam ser a primeira.
