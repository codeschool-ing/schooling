---
title: O mesmo resultado, duas vezes
version: 1
---

Um resultado que não pode ser produzido de novo não pode ser conferido, comparado nem confiado. Três
coisas decidem se um modelo ajustado hoje pode ser ajustado de novo no mês que vem e dar a mesma
resposta: os dados, o acaso e as versões. Os dados são o `make_data.py` e suas impressões digitais da aula
1. As outras duas são esta seção.

**O acaso se esconde em mais lugares do que parece.** Todo modelo deste curso passa `random_state=0`, e
aqui está o porquê. Salve isto como `seeds.py`; ele ajusta o gradient boosting da aula 2 quatro vezes,
duas sem semente e duas com:

```python
# seeds.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
for seed in [None, None, 0, 0]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=seed)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= CREDIT / (SAVED * KEPT)
    print(f"random_state={seed!s:4}  {model.n_iter_:3} trees  R$ {net_value(test['churned'], send):,.0f}")
```

```
ana@lab:~/ml$ python seeds.py
random_state=None   38 trees  R$ 21,120
random_state=None   41 trees  R$ 21,152
random_state=0      40 trees  R$ 21,672
random_state=0      40 trees  R$ 21,672
```

Nada na chamada diz *aleatório*, e mesmo assim duas chamadas idênticas deram modelos diferentes. Com mais
de dez mil linhas, o `HistGradientBoostingClassifier` liga sozinho a parada antecipada da aula 8, e a
parada antecipada separa um décimo sorteado das linhas para decidir quando parar. Outro décimo, outro
número de árvores, outro resultado: 38 árvores e 41 aqui, R$ 21.120 e R$ 21.152. Enquanto esta aula era
escrita, outro par de execuções sem semente saiu R$ 1.464 distante. As suas duas linhas quase certamente
vão diferir destas e uma da outra, e esse é o ponto. **Com `random_state=0` o modelo é o mesmo toda vez**,
e o mesmo dos R$ 21.672 de toda aula anterior.

Esse é o outro motivo para fixar a semente: uma comparação entre dois ajustes só é comparação se nada mais
mudou entre os dois.

**As versões são a terceira coisa.** Uma versão nova do scikit-learn pode mudar um padrão, o número de
faixas de um histograma, o resolvedor de uma regressão logística, e um padrão mudado muda um número. É por
isso que a aula 1 fixou toda biblioteca no `requirements.txt`, e que o script de capturas de cada aula
registra as versões com que rodou. Para um modelo que vai ser usado, guarde três coisas com ele:

- as **versões fixadas**, o `requirements.txt` ou a saída de `pip freeze`;
- o **código que o construiu**, o `churn_model.py`, no commit que o ajustou;
- os **dados de onde ele aprendeu**, ou uma impressão digital deles, como o `sha256sum` da aula 1
  imprimiu.

A aula 21 salva o pipeline ajustado num arquivo, e esse arquivo só é tão útil quanto o registro de que
código, que dados e que versões o produziram.
