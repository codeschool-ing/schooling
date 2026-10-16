---
title: A rodada mensal
version: 1
---

A aula 21 terminou numa escolha: o crédito é uma decisão em lote, tomada uma vez por mês para todos,
então a vida de trabalho do modelo é um programa que roda no dia 1º de cada mês. Esta aula é esse
programa rodando de janeiro a março de 2026, e o que acontece em volta dele: o que dá para conferir no
dia, o que só dá para conferir um mês depois, e o que fazer quando os dois discordam.

O programa mensal é curto, porque a aula 21 fez o trabalho. Ele carrega o modelo gravado pelo
`stored.load`, então uma máquina com as versões erradas se recusa a rodar, pontua o retrato de um mês e
grava as chances num arquivo com o nome do mês, com o nome do modelo em cada linha. Salve isto como
`monthly.py`:

```python
# monthly.py
import sys
from pathlib import Path

import stored
from feira import CREDIT, KEPT, SAVED, load_churn

month = sys.argv[1]
model, card = stored.load("churn-2025-12")
rows = load_churn("data/churn_2026.csv")
rows = rows[rows["snapshot"] == month]
chance = model.predict_proba(rows)[:, 1]
scores = rows[["customer_id", "snapshot"]].assign(chance=chance.round(4), model=card["name"],
                                                  credit=chance >= CREDIT / (SAVED * KEPT))
Path("scores").mkdir(exist_ok=True)
scores.to_csv(f"scores/{month[:7]}.csv", index=False)
print(f"{month[:7]}: {len(scores):,} subscribers, mean chance {chance.mean():.3f}, "
      f"{scores['credit'].sum()} credits, from {card['name']}")
```

Numa implantação de verdade o `churn_2026.csv` seria uma exportação nova a cada mês e o programa rodaria
num horário marcado. Aqui os três meses já estão no arquivo, então três rodadas fazem o papel de três
dias 1º. O arquivo do modelo é o da aula 21; se o `models/churn-2025-12.joblib` não estiver lá, rode
`python save_model.py` antes.

```
ana@lab:~/ml$ for month in 2026-01-01 2026-02-01 2026-03-01; do python monthly.py $month; done
2026-01: 4,226 subscribers, mean chance 0.061, 154 credits, from churn-2025-12
2026-02: 4,388 subscribers, mean chance 0.065, 173 credits, from churn-2025-12
2026-03: 4,540 subscribers, mean chance 0.065, 180 credits, from churn-2025-12
ana@lab:~/ml$ ls scores
2026-01.csv
2026-02.csv
2026-03.csv
ana@lab:~/ml$ head -3 scores/2026-03.csv
customer_id,snapshot,chance,model,credit
C00003,2026-03-01,0.01,churn-2025-12,False
C00005,2026-03-01,0.0135,churn-2025-12,False
```

O arquivo que cada rodada grava é o registro que importa: **quem foi pontuado, por qual modelo, com que
chance e se recebeu o crédito.** Sem ele não há o que comparar quando as respostas chegarem. É a versão
em lote do `scores.jsonl` da aula 21, e ele é guardado, não sobrescrito: a rodada do mês seguinte grava o
arquivo do mês seguinte.

As três rodadas já dizem uma coisa que vale notar. A chance média é 0,061, 0,065 e 0,065. Os meses de
treino terminaram com os meses depois do aumento de preço de setembro, quando até 7,2% dos assinantes
saíam por mês, então um modelo ajustado neles espera um nível alto. Se janeiro de 2026 ainda é assim,
ninguém sabe no dia 1º de janeiro.
