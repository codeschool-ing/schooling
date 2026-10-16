---
title: A avaliação como uma etapa, com a sua linha de base
version: 1
---

A quarta etapa pontua o modelo salvo no arquivo de teste e guarda as notas ao lado do modelo. **Ela
recarrega o modelo do disco em vez de usar o que está na memória**, e esse é o ponto: o que ela
pontua é o arquivo que seria publicado, não um objeto que só existiu enquanto o treino rodava. Salve
isto como `evaluate.py`:

```python
"""evaluate.py: score a saved model on a later cutoff, beside the baseline.

    python evaluate.py models/lapse.joblib data/test.csv
"""
import json
import sys

import joblib
import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

from model import COLUMNS
from project import ROOT

model = joblib.load(ROOT / sys.argv[1])
rows = pd.read_csv(ROOT / sys.argv[2])
p = model.predict_proba(rows[COLUMNS])[:, 1]
top = rows.assign(p=p).nlargest(300, "p")

scores = {
    "test": sys.argv[2],
    "cutoff": rows["cutoff"].iloc[0],
    "members": len(rows),
    "lapsed": int(rows["lapsed"].sum()),
    "roc_auc": round(roc_auc_score(rows["lapsed"], p), 3),
    "average_precision": round(average_precision_score(rows["lapsed"], p), 3),
    "baseline_average_precision": round(rows["lapsed"].mean(), 3),
    "lapsed_in_top_300": int(top["lapsed"].sum()),
    "said": round(p.mean(), 3),
}
(ROOT / sys.argv[1]).with_suffix(".scores.json").write_text(json.dumps(scores, indent=2) + "\n")
print(json.dumps(scores, indent=2))
```

As notas são as da lição 4, cada uma com o que precisa para significar algo.
`baseline_average_precision` é a fração que se afastou, o que um modelo que não soubesse nada
tiraria; `lapsed_in_top_300` responde ao orçamento do marketing; `said` é a probabilidade média, para
comparar com a fração que de fato se afastou e pegar um modelo que deixou de estar calibrado.

```
ana@dev:~/ml$ python evaluate.py models/lapse.joblib data/test.csv
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 190,
  "said": 0.177
}
```

O modelo da lição 4 tirou 0,790 e 195 nos 300 primeiros. **Este, treinado um mês antes, em 31 de
agosto, tira 0,793 e 190.** Nenhuma das diferenças é uma melhora ou uma piora que valha ler: são o
ruído de treinar com um mês em vez de outro. Vale saber disso antes que alguém comemore a próxima
mudança de três milésimos.
