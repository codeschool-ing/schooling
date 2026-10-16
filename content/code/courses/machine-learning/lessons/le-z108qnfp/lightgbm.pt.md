---
title: LightGBM
version: 1
---

O **LightGBM**, da Microsoft, é a outra biblioteca que domina o boosting em tabelas. Ele difere do
XGBoost principalmente em como uma árvore cresce. O XGBoost, por padrão, cresce **nível a nível**: toda
folha de uma profundidade é dividida antes de qualquer folha da seguinte. O LightGBM cresce **folha a
folha**: a cada passo, divide a folha que mais ganha, esteja onde estiver, então uma árvore pode
descer fundo num galho e ficar rasa nos outros.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l08-growth\" aria-label=\"Duas árvores pequenas com três cortes e quatro folhas cada. À esquerda, nível a nível: todo nó de uma profundidade é dividido antes da seguinte. À direita, folha a folha: um galho desce três níveis enquanto o outro para depois do primeiro corte.\"><path d=\"M160.0 57.0 L100.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M160.0 57.0 L220.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 107.0 L70.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 107.0 L130.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220.0 107.0 L190.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220.0 107.0 L250.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"50.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"100.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"220.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"70.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"130.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"190.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"250.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><path d=\"M480.0 57.0 L430.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M480.0 57.0 L560.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M430.0 107.0 L400.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M430.0 107.0 L470.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 157.0 L440.0 193.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 157.0 L500.0 193.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"480.0\" cy=\"50.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"430.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"100.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"400.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"470.0\" cy=\"150.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"440.0\" cy=\"200.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"500.0\" cy=\"200.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nível a nível: XGBoost por padrão</text><text x=\"480.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">folha a folha: LightGBM</text><text x=\"160.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quatro folhas numa profundidade</text><text x=\"480.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a melhor folha é a próxima a dividir, onde estiver</text></svg>", "caption": "O mesmo número de cortes, formas diferentes. Um círculo cheio é uma pergunta; um vazio é uma folha."}
```

Isso faz o ajuste importante ser o `num_leaves`, o total de folhas que uma árvore pode ter, e não uma
profundidade. O crescimento folha a folha chega a uma dada precisão com menos cortes e é mais rápido
em dados grandes; também pode sobreajustar mais rápido em dados pequenos, e por isso o `num_leaves`
fica moderado e a mesma subamostragem do XGBoost é usada. O LightGBM lê categorias do pandas sozinho
e, como os outros, aceita lacunas. Salve isto como `lgbm.py`:

```python
# lgbm.py
import time

import lightgbm

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

start = time.perf_counter()
model = lightgbm.LGBMClassifier(n_estimators=400, learning_rate=0.05, num_leaves=15,
                                subsample=0.8, subsample_freq=1, colsample_bytree=0.8,
                                random_state=0, verbose=-1)
model.fit(train[features], train["churned"])
send = model.predict_proba(test[features])[:, 1] >= cut
print(f"LightGBM {lightgbm.__version__}: R$ {net_value(test['churned'], send):,.0f}, "
      f"{send.sum():,} credits, {time.perf_counter() - start:.1f} s")
```

```
ana@lab:~/ml$ python lgbm.py
LightGBM 4.7.0: R$ 22,304, 760 credits, 1.0 s
```

**R$ 22.304**, com ajustes escolhidos para combinar com o `xgb.py` o tanto que duas bibliotecas
permitem: 400 árvores com 0,05, 15 folhas, a mesma subamostragem. O `verbose=-1` cala as mensagens de
treino que o LightGBM imprime por padrão.

Diferenças de velocidade entre os dois só aparecem em tabelas muito maiores que esta; com 38.628
linhas os dois ajustam em cerca de um segundo. Qual usar é mais questão de hábito e do que o resto da
equipe já roda. A próxima seção pergunta se a diferença em reais entre eles quer dizer alguma coisa.
