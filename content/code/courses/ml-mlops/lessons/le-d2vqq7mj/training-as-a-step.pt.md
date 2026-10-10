---
title: O treino como uma etapa que deixa um registro
version: 1
---

A etapa de treino lê um arquivo validado, ajusta o modelo do `model.py` e o salva. **E ela anota o
que fez**, porque um arquivo de modelo sozinho não consegue dizer quais linhas o fizeram. Salve isto
como `train.py`:

```python
"""train.py: fit the lapse model on a validated training set and save it.

    python train.py data/train.csv models/lapse.joblib
"""
import json
import sys
from hashlib import sha256

import joblib
import pandas as pd
import sklearn

from model import COLUMNS, make_model
from project import ROOT

data, out = ROOT / sys.argv[1], ROOT / sys.argv[2]
rows = pd.read_csv(data)
model = make_model().fit(rows[COLUMNS], rows["lapsed"])

out.parent.mkdir(exist_ok=True)
joblib.dump(model, out)
record = {
    "model": sys.argv[2],
    "trained_on": sys.argv[1],
    "data_sha256": sha256(data.read_bytes()).hexdigest()[:16],
    "cutoff": rows["cutoff"].iloc[0],
    "rows": len(rows),
    "scikit_learn": sklearn.__version__,
}
out.with_suffix(".json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record, indent=2))
```

`joblib.dump` salva o pipeline ajustado inteiro, scaler e codificador incluídos, num arquivo só; o
`joblib` vem com o scikit-learn. Ao lado dele, a etapa grava um pequeno registro JSON:

- **`data_sha256`** é uma impressão digital dos bytes do arquivo de treino, os seus primeiros
  dezesseis caracteres hexadecimais. Mude uma linha e ela muda, então dois modelos com a mesma
  impressão digital aprenderam com as mesmas linhas, seja qual for o nome dos arquivos;
- **`cutoff` e `rows`** dizem o que eram os dados, em palavras que uma pessoa confere contra um
  relatório;
- **`scikit_learn`** é a versão da biblioteca, porque um modelo salvo só tem garantia de carregar na
  versão que o salvou.

```
ana@dev:~/ml$ python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
```

**Esse registro é o começo da linhagem**: a corrente de um modelo de volta aos dados e ao código que
o fizeram. Ele é incompleto de um jeito óbvio. Nomeia os dados mas não o código: se alguém muda o
`features.py` e monta um arquivo de treino novo, a impressão digital muda e nada diz por quê. A lição
7 fecha essa lacuna com Git, DVC e MLflow, que registram juntas a versão do código e a dos dados;
este arquivo é o que o pipeline consegue fazer só com Python.
