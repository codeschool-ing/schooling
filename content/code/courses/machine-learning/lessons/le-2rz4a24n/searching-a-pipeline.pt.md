---
title: Ajustando um pipeline, sem o vazamento
version: 1
---

Um pipeline é um estimador, então a busca da aula 9 o aceita inteiro. Duas coisas mudam, e as duas são
melhorias.

**A preparação é reajustada dentro de cada parte.** Quando o `GridSearchCV` ajusta um candidato nos meses
antes de maio e o mede em maio, ele ajusta o pipeline inteiro nos meses anteriores: as medianas, as médias
da escala, as categorias do codificador, tudo só daqueles meses. O vazamento de preparação da aula 4, e o
de reamostragem da aula 13, não têm como acontecer, porque não há nada fora do pipeline para ajustar nas
linhas erradas.

**Um ajuste lá dentro é chamado pelo caminho.** O `C` da regressão logística, a força da regularização da
aula 5, é `logistic__C`: o nome do passo, dois sublinhados, o ajuste. A estratégia de um preenchedor seria
`prepare__numbers__simpleimputer__strategy`. Longo, e sem ambiguidade.

Salve isto como `search.py`; ele usa as partes e a nota da aula 9, do `tuning.py`:

```python
# search.py
from sklearn.model_selection import GridSearchCV

from churn_model import build
from feira import by_time, load_churn
from tuning import time_folds, value_per_thousand

train, _ = by_time(load_churn())
search = GridSearchCV(build(), {"logistic__C": [0.01, 0.1, 1, 10]},
                      cv=list(time_folds(train)), scoring=value_per_thousand)
search.fit(train, train["churned"])
for C, score in zip(search.cv_results_["param_logistic__C"], search.cv_results_["mean_test_score"]):
    print(f"C = {C:<5}  R$ {score:5.0f} per thousand rows, averaged over three months")
```

O `value_per_thousand` pede ao modelo o `predict_proba`, e o pipeline responde, então a nota escrita para
o gradient boosting na aula 9 funciona sem mudança num modelo diferente.

```
ana@lab:~/ml$ python search.py
C = 0.01   R$   868 per thousand rows, averaged over three months
C = 0.1    R$   915 per thousand rows, averaged over three months
C = 1.0    R$   917 per thousand rows, averaged over three months
C = 10.0   R$   917 per thousand rows, averaged over three months
```

De C = 0,1 para cima a nota é plana, de R$ 915 a R$ 917 por mil linhas: o padrão de 1 é tão bom quanto
qualquer outro. Só a regularização mais forte, 0,01, custa algo. Com 36 colunas e 38.628 linhas, há pouco
de que a regularização proteja. É a conclusão da aula 9 de novo, vinda de outro modelo: com os atributos
certos, os botões importam menos do que o tempo gasto com eles sugere.
