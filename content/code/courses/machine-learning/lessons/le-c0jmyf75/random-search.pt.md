---
title: Busca aleatória
version: 1
---

A **busca aleatória** sorteia cada candidato de uma faixa para cada hiperparâmetro, e ajusta quantos
o orçamento permitir. Parece descuidada. Costuma ser melhor que uma grade do mesmo tamanho, por um
motivo que é mais fácil de ver num desenho:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 290\" role=\"img\" data-fig=\"l09-grid-random\" aria-label=\"Dois quadrados, cada um com nove pontos. Horizontal: o hiperparâmetro que importa; vertical: um que não importa. Os nove pontos da grade ficam em três colunas, então testam três valores do botão que importa; os nove pontos ao acaso testam nove valores diferentes. Marcas abaixo de cada quadrado mostram os valores testados.\"><rect x=\"60.0\" y=\"40.0\" width=\"200.0\" height=\"180.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"160.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">grade: 3 valores testados</text><circle cx=\"100.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"100.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"100.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M100.0 228.0 L100.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M160.0 228.0 L160.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"184.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"220.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M220.0 228.0 L220.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"160.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o botão que importa</text><rect x=\"360.0\" y=\"40.0\" width=\"200.0\" height=\"180.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"460.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ao acaso: 9 valores testados</text><circle cx=\"377.1\" cy=\"199.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M377.1 228.0 L377.1 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"407.4\" cy=\"149.6\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M407.4 228.0 L407.4 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"520.3\" cy=\"127.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M520.3 228.0 L520.3 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"476.4\" cy=\"142.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M476.4 228.0 L476.4 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"378.8\" cy=\"114.4\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M378.8 228.0 L378.8 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"446.6\" cy=\"87.2\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M446.6 228.0 L446.6 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"455.8\" cy=\"47.9\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M455.8 228.0 L455.8 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"391.9\" cy=\"168.8\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M391.9 228.0 L391.9 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"506.9\" cy=\"103.3\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M506.9 228.0 L506.9 240.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"460.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o botão que importa</text></svg>", "caption": "Nove ajustes cada. Quando só um botão importa, os pontos ao acaso testaram três vezes mais valores dele."}
```

Suponha que só um de dois hiperparâmetros importa. Nove pontos de grade testam **três** valores dele,
cada um três vezes. Nove pontos ao acaso testam **nove** valores diferentes dele, porque dois pontos
ao acaso não dividem uma coordenada. Seja qual for o botão que importa, a busca aleatória o explorou
com mais detalhe, e ninguém precisa saber antes qual é.

As faixas são sorteadas de distribuições, e a escolha da distribuição é a única decisão que sobra. O
`loguniform(0.01, 0.5)` sorteia uma taxa de modo uniforme em escala logarítmica, então de 0,01 a 0,05
recebe tantas tentativas quanto de 0,1 a 0,5, o que é certo para um botão cujo efeito é de proporção.
O `randint` sorteia números inteiros de modo uniforme. Salve isto como `random_search.py`; ele tem o
mesmo orçamento da grade, 18 candidatos, sobre **cinco** hiperparâmetros em vez de três:

```python
# random_search.py
import time

from scipy.stats import loguniform, randint
from sklearn.model_selection import RandomizedSearchCV

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
space = {"learning_rate": loguniform(0.01, 0.5),
         "max_leaf_nodes": randint(4, 64),
         "max_iter": randint(50, 400),
         "min_samples_leaf": randint(10, 400),
         "l2_regularization": loguniform(1e-3, 10)}
start = time.perf_counter()
search = RandomizedSearchCV(booster(), space, n_iter=18, cv=list(time_folds(train)),
                            scoring=value_per_thousand, n_jobs=-1, random_state=0)
search.fit(train[FEATURES], train["churned"])
print(f"18 candidates x 3 folds, {time.perf_counter() - start:.0f} s")
print(f"best {search.best_score_:.0f}:",
      {k: round(float(v), 3) if isinstance(v, float) else int(v) for k, v in search.best_params_.items()})
```

```
ana@lab:~/ml$ python random_search.py
18 candidates x 3 folds, 19 s
best 792: {'l2_regularization': 0.028, 'learning_rate': 0.093, 'max_iter': 134, 'max_leaf_nodes': 15, 'min_samples_leaf': 334}
```

**R$ 792 por mil linhas**, melhor que a melhor da grade com o mesmo número de ajustes, e variando dois
hiperparâmetros que a grade mantinha fixos. Ela também achou árvores pequenas, 15 folhas, e um
`min_samples_leaf` grande, 334, que é outro jeito de manter as árvores simples.

O acaso é o preço: outro `random_state` acha outro melhor, e talvez pior. Com orçamento de 18, uma
busca amostra muito pouco de um espaço de cinco dimensões. A força dela é que cada ajuste a mais
acrescenta informação sobre todos os botões de uma vez, então ela continua melhorando à medida que o
orçamento cresce, enquanto uma grade só melhora em degraus de uma fileira inteira de valores novos.
