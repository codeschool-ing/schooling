---
title: Uma linha para cada pedido
version: 1
---

Toda checagem de velocidade e de erros parte da mesma matéria-prima: **um registro por pedido,
dizendo quando ele chegou, o que pediu, como terminou, quanto tempo levou e o que o modelo disse.**
O Uvicorn imprime uma linha por pedido no terminal dele, mas um terminal rola para longe; o registro
precisa ir para um arquivo que um programa consiga ler.

Substitua o `serve.py` por esta versão. O modelo, os atributos e a rota são os mesmos da lição 8; o
que é novo é o logger e a função acima da rota:

```python
"""serve.py: the lapse model as a web service, one member at a time, every request logged.

    uvicorn serve:app --port 8000
"""
import json
import logging
import time

import mlflow
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from mlflow import MlflowClient

from featurestore import get
from model import COLUMNS
from project import ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
VERSION = MlflowClient().get_model_version_by_alias("lapse", "champion").version
MODEL = mlflow.sklearn.load_model(f"models:/lapse/{VERSION}")   # loaded once, at start-up

LOG = logging.getLogger("requests")
LOG.addHandler(logging.FileHandler(ROOT / "requests.log"))
LOG.setLevel(logging.INFO)

app = FastAPI()


@app.middleware("http")
async def log_every_request(request: Request, call_next):
    started = time.perf_counter()
    response = await call_next(request)
    LOG.info(json.dumps({
        "at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "path": request.url.path,
        "status": response.status_code,
        "ms": round((time.perf_counter() - started) * 1000, 2),
        "p_lapse": getattr(request.state, "p_lapse", None),
        "model_version": VERSION,
    }))
    return response


@app.get("/lapse/{member_id}")
def lapse(member_id: int, request: Request):
    row = get(member_id)
    if row is None:
        raise HTTPException(404, "no features fresh enough for this member")
    p = round(float(MODEL.predict_proba(pd.DataFrame([row])[COLUMNS])[0, 1]), 3)
    request.state.p_lapse = p
    return {"member_id": member_id, "p_lapse": p,
            "features_as_of": row["as_of"], "model_version": VERSION}
```

**Um middleware é uma função pela qual todo pedido passa na ida e na volta.** Este liga um relógio,
deixa o pedido seguir para a rota com `call_next` e, quando a resposta volta, grava uma linha de
JSON: a hora, o caminho, o status, os milissegundos, a probabilidade e a versão. A rota deixa a sua
probabilidade em `request.state`, um lugar que viaja junto com o pedido, para o middleware poder
registrá-la; um pedido recusado nunca a define, e a linha dele diz `null`.

**Cada linha é um objeto JSON sozinho**, um formato chamado JSON Lines: um programa o lê uma linha de
cada vez, e uma linha escrita pela metade quando o processo morreu estraga só a si mesma. Quem grava é
o módulo logging, porque ele pode ser chamado com segurança das threads em que o FastAPI roda a rota.

Pare o serviço da lição 8 com Ctrl+C se ele ainda estiver rodando, e inicie este do mesmo jeito, no
segundo terminal:

```sh
uvicorn serve:app --port 8000
```

Depois, no primeiro terminal, um membro que tem nota e um que não tem, e as duas últimas linhas do
log:

```
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/2; echo
{"member_id":2,"p_lapse":0.098,"features_as_of":"2026-02-28","model_version":1}
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/8; echo
{"detail":"no features fresh enough for this member"}
ana@dev:~/ml$ tail -2 requests.log
{"at": "2026-10-15T22:00:02", "path": "/lapse/2", "status": 200, "ms": 42.14, "p_lapse": 0.098, "model_version": 1}
{"at": "2026-10-15T22:00:02", "path": "/lapse/8", "status": 404, "ms": 1.15, "p_lapse": null, "model_version": 1}
```

Os dois pedidos estão no arquivo, a recusa inclusive, com a sua probabilidade `null`. **Um log que só
registrasse sucessos deixaria a taxa de erro em zero por construção.**
