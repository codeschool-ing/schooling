---
title: Parada antecipada, e o boosting do scikit-learn
version: 1
---

O modelo que a aula 2 usou como caixa era o `HistGradientBoostingClassifier`, o gradient boosting
rápido do scikit-learn. *Hist* vem de histograma: antes de ajustar, cada coluna numérica é cortada em
no máximo 255 faixas, e as árvores procuram cortes entre faixas e não entre cada par de valores. Em
dezenas de milhares de linhas isso é muito mais rápido e quase não perde nada. Ele também lê
categorias do pandas e lacunas como estão.

Quantas árvores crescer é a pergunta que o boosting sempre levanta, e a resposta que ele dá é
observar. Com `early_stopping=True`, o modelo separa uma parte das linhas de treino, aqui 15%, mede
essas linhas depois de cada árvore e para quando `n_iter_no_change` árvores seguidas não melhoram a
nota. As linhas separadas são dados de validação no sentido da aula 3, tirados só dos meses de
treino. Salve isto como `hist_boost.py`:

```python
# hist_boost.py
import time

from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

for rate, early in [(0.1, False), (0.1, True), (0.03, True)]:
    start = time.perf_counter()
    model = HistGradientBoostingClassifier(learning_rate=rate, max_iter=2000,
                                           early_stopping=early, validation_fraction=0.15,
                                           n_iter_no_change=30, categorical_features="from_dtype",
                                           random_state=0)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= cut
    print(f"learning_rate={rate:<5} early_stopping={str(early):5} trees {model.n_iter_:4}  "
          f"R$ {net_value(test['churned'], send):7,.0f}  {time.perf_counter() - start:4.1f} s")
```

```
ana@lab:~/ml$ python hist_boost.py
learning_rate=0.1   early_stopping=False trees 2000  R$  13,424   6.4 s
learning_rate=0.1   early_stopping=True  trees   60  R$  20,856   0.4 s
learning_rate=0.03  early_stopping=True  trees  172  R$  21,296   0.9 s
```

**Sem parada antecipada, 2.000 árvores com taxa 0,1 fazem R$ 13.424**: o modelo continuou ajustando
muito depois de o sinal acabar, e as árvores extras aprenderam ruído. Com parada antecipada na mesma
taxa ele para depois de **60** árvores e faz R$ 20.856, numa fração do tempo. Numa taxa mais suave,
0,03, ele leva **172** árvores e faz R$ 21.296, que é o padrão de costume: taxa mais lenta, mais
árvores, resultado um pouco melhor.

Essa última linha é o que toda biblioteca de boosting recomenda de um jeito ou de outro: **ponha a
taxa baixa, o número de árvores alto, e deixe a parada antecipada decidir quando parar**. Isso
transforma o número de árvores de um botão que alguém precisa adivinhar numa medição.

Um cuidado da aula 3 vale direto aqui. Os 15% separados são sorteados dentro dos meses de treino,
então compartilham meses com o resto. Uma versão mais rígida separa os **últimos** meses, e para quando
o modelo deixa de melhorar nos dados mais recentes. O sorteio do scikit-learn serve aqui porque os
meses são só doze e a deriva dentro deles é pequena; para um modelo que vai encontrar um mundo em
mudança, separe pelo tempo.
