---
title: Orçamentos no código
version: 2
---

Um relatório diz o que foi gasto. Um orçamento diz o que pode ser gasto, e os úteis são conferidos pela
aplicação, não lidos por uma pessoa no fim do mês. Dois tipos funcionam para um sistema como este.

**Um orçamento por funcionalidade por dia** diz quanto o produto aceita gastar com cada coisa que faz.
Ultrapassá-lo não é um erro; é um sinal de que o uso ou o custo por pedido mudou, e alguém deveria
olhar. **Um teto por usuário por dia** protege contra uma conta, ou um script, gastar o que todos os
outros juntos gastariam. Ultrapassá-lo é uma decisão que a aplicação toma na hora: ir mais devagar,
usar um modelo mais barato, ou recusar até amanhã.

Os orçamentos são um arquivo, e o `budget.py` confronta a semana com eles:

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

Salve os orçamentos como `budgets.json`:

```json
{"daily": {"help": "0.020", "order": "0.008", "summary": "0.003"}, "per_user_daily": "0.002"}
```

```
ana@dev:~/obs$ python budget.py
day                help           order         summary
Mon 28      0.0183          0.0086 OVER     0.0038 OVER
Tue 29      0.0212 OVER     0.0073          0.0025     
Wed 30      0.0166          0.0068          0.0013     
Thu 01      0.0114          0.0054          0.0024     
Fri 02      0.0081          0.0044          0.0036 OVER
Sat 03      0.0073          0.0020          0.0016     
Sun 04      0.0067          0.0032          0.0007     
users over 0.002 a day: 3
  Tue 29  2b86d5011760317d  0.0026
  Wed 30  bfc965310daf2eda  0.0030
  Mon 28  91aa3bdfe71fb999  0.0032
```

Os orçamentos foram definidos olhando a semana, que é como um primeiro orçamento se define na
prática, e é por isso que os estouros se concentram onde a semana foi mais movimentada. `help`
passou dos seus 0,020 na terça, `order` dos seus 0,008 na segunda, e `summary` dos seus 0,003 na
segunda. De quarta em diante, `help` e `order` nem chegam perto, o que nesta semana é o corte de
preço e depois a versão, não contenção. **`summary` passou de novo na sexta**, depois dos dois,
porque nenhum deles o tocou: um resumo não busca nada, então o piso não consegue encurtar o prompt
dele, e a equipe de atendimento simplesmente pediu mais resumos naquele dia. Um orçamento por
funcionalidade é o que separa essas duas histórias.

Três vezes na semana um usuário passou de um quinto de centavo num dia, nenhuma delas por muito: a
maior foi 0,0032. Nenhuma assusta, e é para isso que serve um teto. Ele não custa nada até o dia em
que importa.

## Onde fica a verificação

O `budget.py` lê os spans depois do fato, o que está certo para um relatório diário e é tarde demais
para um teto. Um teto é conferido **antes da chamada**: mantenha um total corrente por usuário no dia,
no mesmo armazém que a aplicação já usa para sessões, some o custo de cada pedido quando ele termina, e
olhe o total antes de começar o próximo. Os spans continuam sendo o registro; o total corrente é o
freio.

E os limites do próprio fornecedor ficam atrás dos dois. A aula 21 do `ai-models` define limites de
gasto e alertas nos consoles dos fornecedores. Eles são a última linha, a que segura quando a
verificação da própria aplicação tem um defeito; nunca deveriam ser a primeira.
