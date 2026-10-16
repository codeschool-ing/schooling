---
title: A mesma resposta pelos dois caminhos
version: 1
---

Agora há dois jeitos de pontuar um assinante: o jeito em lote de todas as aulas anteriores,
`predict_proba` numa tabela lida com `pd.read_csv`, e o jeito servido, uma linha transformada em JSON,
enviada, conferida pelo `Subscriber`, remontada numa tabela de uma linha e só então entregue ao modelo. O
jeito servido é o que o negócio usa, e o jeito em lote é o que este curso mediu. **Se os dois discordam,
todo número do curso descreve um modelo que ninguém está rodando.**

O nome dessa discordância é **desalinhamento entre treino e serviço** (*training–serving skew*), e é um
dos jeitos mais comuns de um modelo em produção dar errado sem ninguém ver um erro. Ele não vem do
modelo. Vem do caminho de entrada: um tipo convertido de outro jeito, um valor ausente escrito de outro
jeito, uma coluna calculada por um segundo pedaço de código que devia bater com o primeiro. Então o teste
é mandar todo assinante de março de 2026 pelos dois caminhos e comparar. Com o servidor ainda rodando no
segundo terminal, salve isto como `compare.py`:

```python
# compare.py
import json
import time
import urllib.request

import numpy as np

import stored
from feira import CREDIT, KEPT, SAVED, load_churn

model, card = stored.load("churn-2025-12")
new = load_churn("data/churn_2026.csv")
march = new[new["snapshot"] == "2026-03-01"]
start = time.perf_counter()
expected = model.predict_proba(march)[:, 1].round(4)
batch = time.perf_counter() - start


def ask(row):
    body = json.dumps(row).encode()
    request = urllib.request.Request("http://localhost:8000/score", body,
                                     {"content-type": "application/json"})
    with urllib.request.urlopen(request) as answer:
        return json.load(answer)["chance"]


rows = json.loads(march.drop(columns=["snapshot", "days_since_last_order"]).to_json(orient="records"))
start = time.perf_counter()
served = np.array([ask(row) for row in rows])
took = time.perf_counter() - start
print(f"one request per subscriber: {len(rows):,} requests, {1000 * took / len(rows):.1f} ms each")
print(f"the whole month in one call to the model: {1000 * batch:.0f} ms")
print(f"largest difference between the two: {np.abs(served - expected).max():.4f}")

cut = CREDIT / (SAVED * KEPT)
gaps = [i for i, row in enumerate(rows) if row["days_since_login"] is None]
zeros = np.array([ask({**rows[i], "days_since_login": 0}) for i in gaps])
print(f"{len(gaps):,} subscribers without the app, sent as 0 instead of null:")
print(f"  mean chance {served[gaps].mean():.3f} -> {zeros.mean():.3f}, "
      f"credits {(served[gaps] >= cut).sum()} -> {(zeros >= cut).sum()}")
```

O `urllib.request` é o jeito da biblioteca padrão de fazer o que o `curl` fez, então não precisa de
biblioteca nova. Leva cerca de um minuto, um pedido de cada vez.

```
ana@lab:~/ml$ python compare.py
one request per subscriber: 4,540 requests, 12.0 ms each
the whole month in one call to the model: 32 ms
largest difference between the two: 0.0000
1,133 subscribers without the app, sent as 0 instead of null:
  mean chance 0.071 -> 0.065, credits 52 -> 46
```

**A maior diferença é zero**, até as quatro casas que o servidor arredonda. Os 4.540 assinantes receberam
a mesma chance pelos dois caminhos. Isso não é formalidade: no caminho servido um `null` chega como o
`None` do Python e não como o `NaN` do pandas, todo número chega por JSON, e cada linha é uma tabela
própria. Desta vez nada disso mudou uma resposta, e agora isso é sabido em vez de suposto.

As duas últimas linhas são o desalinhamento que este teste existe para pegar, feito de propósito. **Os
1.133 assinantes sem o app não têm login, então `days_since_login` é `null`.** Um cliente escrito por
alguém que achou que um número ausente devia ser 0, uma suposição feita em milhares de sistemas, manda 0
no lugar. Para o modelo, 0 quer dizer *entrou hoje*, o mais engajado que um assinante pode ser. A chance
média deles cai de 0,071 para 0,065 e seis perdem um crédito. Nada falhou. Todo pedido voltou 200, toda
resposta era um número plausível, e o único lugar onde a mudança aparece é numa comparação como esta.

É esse o argumento para guardar o `compare.py`, ou um teste parecido, e rodá-lo sempre que o cliente, o
servidor ou o modelo mudar: **um modelo em produção é conferido contra o lote em que foi medido, linha por
linha, não olhando algumas respostas e achando-as razoáveis.**
