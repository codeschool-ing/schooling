---
title: Um modelo num arquivo, e a ficha que vai junto
version: 1
---

Todo programa até aqui ajustou o seu modelo, usou e jogou fora quando terminou. Isso bastava enquanto a
pergunta era *quão bom ele é*. A pergunta agora é *quem usa*: o sistema da equipe de retenção, que
pergunta por um assinante de cada vez, o dia todo, e precisa receber a mesma resposta que o curso vem
medindo. Para isso o modelo ajustado precisa sobreviver ao programa que o ajustou, o que quer dizer
gravá-lo num arquivo.

Gravar é uma chamada, `joblib.dump`. A parte difícil é a lista da aula 15: um arquivo de modelo só é tão
útil quanto o registro de **quais dados, qual código e quais versões** o produziram. Então o quarto
arquivo compartilhado do curso grava os dois, o modelo e uma pequena ficha que o descreve, e se recusa a
carregar o modelo onde a ficha não vale. Salve isto como `stored.py`:

```python
# stored.py
"""Save a fitted model with a record of what made it, and load it only where that record holds."""
import hashlib
import json
import platform
from pathlib import Path

import joblib
import numpy
import pandas
import sklearn

MODELS = Path("models")


def versions():
    return {"python": platform.python_version(), "scikit-learn": sklearn.__version__,
            "pandas": pandas.__version__, "numpy": numpy.__version__}


def save(model, name, data, rows):
    MODELS.mkdir(exist_ok=True)
    joblib.dump(model, MODELS / f"{name}.joblib")
    card = {"name": name, "data": data, "sha256": hashlib.sha256(Path(data).read_bytes()).hexdigest(),
            "rows": len(rows), "from": str(rows["snapshot"].min().date()),
            "to": str(rows["snapshot"].max().date()), "versions": versions()}
    (MODELS / f"{name}.json").write_text(json.dumps(card, indent=2) + "\n")
    return card


def load(name):
    card = json.loads((MODELS / f"{name}.json").read_text())
    if card["versions"] != versions():
        raise RuntimeError(f"{name} was saved by {card['versions']}, and this is {versions()}")
    return joblib.load(MODELS / f"{name}.joblib"), card
```

O modelo a gravar é o pipeline da aula 15, ajustado em todo o `churn.csv` como o `score_2026.py` o
ajustou. É a regressão logística e não as árvores de boosting de propósito: a aula 15 fez dela um objeto
só que recebe a tabela crua, com as sete colunas extras e os codificadores dentro, e **o objeto que
recebe a tabela crua é o que vale a pena servir**. Tudo o que quem chama tivesse de preparar antes seria
uma segunda cópia da preparação, e as próximas seções mostram quanto custa uma segunda cópia. Salve isto
como `save_model.py`:

```python
# save_model.py
import stored
from churn_model import build
from feira import load_churn

history = load_churn()
model = build().fit(history, history["churned"])
card = stored.save(model, "churn-2025-12", "data/churn.csv", history)
print(f"saved {card['name']}: {card['rows']:,} rows from {card['from']} to {card['to']}")
```

```
ana@lab:~/ml$ python save_model.py
saved churn-2025-12: 62,885 rows from 2024-07-01 to 2025-12-01
ana@lab:~/ml$ ls -l models
total 12
-rw-r--r-- 1 ana ana 7258 Oct 16 01:33 churn-2025-12.joblib
-rw-r--r-- 1 ana ana  319 Oct 16 01:33 churn-2025-12.json
```

**O modelo inteiro tem 7.258 bytes.** Trinta e seis pesos e um intercepto, uma mediana, uma média e um
desvio-padrão para cada número, e a lista de valores que cada coluna de palavras tinha. Isso é tudo o que
o pipeline aprendeu de 62.885 linhas, e é por isso que uma regressão logística é fácil de levar de um
lugar a outro. As florestas da aula 8, com cem árvores fundas cada, chegam a megabytes; nada abaixo muda
além do tamanho.

O nome diz o que o modelo é e quando ele para de saber das coisas: **churn, ajustado com dados até
dezembro de 2025**. Um nome como `model_final_v2` não diz nada em seis meses, quando houver quatro deles.

A ficha é a outra metade:

```
ana@lab:~/ml$ cat models/churn-2025-12.json
{
  "name": "churn-2025-12",
  "data": "data/churn.csv",
  "sha256": "500d90cc1cfdfced677236baa90fb269e5c2731b344e36cd361e454b535c257a",
  "rows": 62885,
  "from": "2024-07-01",
  "to": "2025-12-01",
  "versions": {
    "python": "3.12.3",
    "scikit-learn": "1.9.1",
    "pandas": "3.0.6",
    "numpy": "2.5.3"
  }
}
```

`sha256` é a impressão digital do `churn.csv` da aula 1, então quem tiver a ficha pode verificar que tem
os mesmos dados com que o modelo aprendeu. `versions` é o que o `load` compara. O código que construiu o
modelo é a única coisa que a ficha não guarda, e a próxima seção mostra por que não pode.
