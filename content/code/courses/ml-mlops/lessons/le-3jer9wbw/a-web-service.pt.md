---
title: Um serviço web que responde por um membro
version: 1
---

Um modelo em tempo real é um programa que espera um pedido, calcula uma resposta e a devolve. **O
trabalho que pode ser feito uma vez é feito na partida, e o trabalho por pedido fica no mínimo**:
carregar o modelo uma vez e, para cada pedido, ler uma linha e fazer uma predição. Salve isto como
`serve.py`:

```python
"""serve.py: the lapse model as a web service, one member at a time.

    uvicorn serve:app --port 8000
"""
import mlflow
import pandas as pd
from fastapi import FastAPI, HTTPException
from mlflow import MlflowClient

from featurestore import get
from model import COLUMNS
from project import ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
VERSION = MlflowClient().get_model_version_by_alias("lapse", "champion").version
MODEL = mlflow.sklearn.load_model(f"models:/lapse/{VERSION}")   # loaded once, at start-up

app = FastAPI()


@app.get("/lapse/{member_id}")
def lapse(member_id: int):
    row = get(member_id)
    if row is None:
        raise HTTPException(404, "no features fresh enough for this member")
    p = MODEL.predict_proba(pd.DataFrame([row])[COLUMNS])[0, 1]
    return {"member_id": member_id, "p_lapse": round(float(p), 3),
            "features_as_of": row["as_of"], "model_version": VERSION}
```

`@app.get("/lapse/{member_id}")` diz que um pedido para `/lapse/2` chama a função abaixo dele com
`member_id` 2, e o FastAPI confere o tipo: qualquer coisa que não seja um número inteiro é recusada
antes de a função rodar. Três escolhas ali são da plataforma:

- **os atributos vêm do armazenamento online**, o `get` da lição 6, nunca calculados aqui, e é
  assim que o desvio da lição 5 fica de fora por construção;
- **um membro para quem o armazenamento não tem nada fresco recebe um 404**, uma recusa com motivo,
  que é a decisão que a lição 6 disse que um serviço precisa tomar de antemão;
- **o modelo é fixado na partida à versão que o apelido apontava naquele momento**, e a resposta diz
  qual. Mover o apelido não muda nada até o serviço reiniciar, então ninguém é pontuado por duas
  versões dentro de um mesmo processo.

Inicie-o num segundo terminal, a partir de `~/ml`, com o ambiente ativo:

```sh
uvicorn serve:app --port 8000
```

`serve:app` é o arquivo e o objeto dentro dele. O Uvicorn imprime uma linha quando está pronto,
`Uvicorn running on http://127.0.0.1:8000`, e depois uma linha para cada pedido que responde.
