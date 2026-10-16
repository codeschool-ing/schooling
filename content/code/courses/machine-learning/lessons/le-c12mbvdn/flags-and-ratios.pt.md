---
title: Marcas, tetos e razões
version: 1
---

O programa abaixo refaz a tabela da aula 5, depois acrescenta colunas em duas rodadas, e ajusta uma
regressão logística e um gradient boosting em cada versão. A primeira rodada, **as lacunas**, é o assunto da próxima seção; aqui importa a segunda. Ela acrescenta sete colunas, cada uma com um motivo:

| coluna | o que é | por quê |
|---|---|---|
| `unhappy` | nota abaixo de 3,6 | o penhasco do `shapes.py` |
| `skip_streak` | três pulos ou mais | o limiar |
| `gone_quiet` | mais de 21 dias sem entrar no aplicativo | o salto |
| `young` | menos de 25 anos | a equipe de retenção diz que assinantes mais jovens saem para um aplicativo mais barato |
| `tenure_capped` | tempo de casa, mas nunca acima de 24 | os dois primeiros anos importam; depois disso um mês é um mês |
| `box_price` | preço por caixa, não por mês | o preço mensal de um plano semanal mistura a caixa com a frequência |
| `late_and_new` | entregas atrasadas, contadas só nos primeiros seis meses | uma caixa atrasada no começo quer dizer mais que uma atrasada para quem tem dois anos de caixas boas |

Salve isto como `features.py`:

```python
# features.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.preprocessing import StandardScaler

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
medians = train[NUMERIC].median()

def lesson_5(rows):
    numbers = rows[NUMERIC].fillna(medians)
    words = pd.get_dummies(rows[CATEGORICAL], drop_first=True, dtype=float)
    return pd.concat([numbers, words], axis=1)

def with_gaps(rows):
    table = lesson_5(rows)
    table["no_rating"] = rows["rating_90d"].isna().astype(float)
    table["no_login"] = rows["days_since_login"].isna().astype(float)
    return table

def with_shapes(rows):
    table = with_gaps(rows)
    table["unhappy"] = (rows["rating_90d"] < 3.6).astype(float)
    table["skip_streak"] = (rows["skips_90d"] >= 3).astype(float)
    table["gone_quiet"] = (rows["days_since_login"] > 21).astype(float)
    table["young"] = (rows["age"] < 25).astype(float)
    table["tenure_capped"] = rows["tenure_months"].clip(upper=24)
    boxes = rows["plan"].map({"weekly": 4, "fortnightly": 2, "monthly": 1}).astype(float)
    table["box_price"] = rows["price_month"] / boxes
    table["late_and_new"] = rows["late_90d"] * (rows["tenure_months"] < 6)
    return table

cut = CREDIT / (SAVED * KEPT)
print("features        columns   logistic AUC   net value   boosting AUC   net value")
for name, build in [("lesson 5's", lesson_5), ("+ the gaps", with_gaps), ("+ the shapes", with_shapes)]:
    X_train, X_test = build(train), build(test)
    scale = StandardScaler().fit(X_train)
    line = LogisticRegression(max_iter=2000).fit(scale.transform(X_train), train["churned"])
    trees = HistGradientBoostingClassifier(random_state=0).fit(X_train, train["churned"])
    print(f"{name:14} {X_train.shape[1]:8}", end="")
    for chance in [line.predict_proba(scale.transform(X_test))[:, 1],
                   trees.predict_proba(X_test)[:, 1]]:
        print(f" {roc_auc_score(test['churned'], chance):13.3f}"
              f"   R$ {net_value(test['churned'], chance >= cut):6,.0f}", end="")
    print()
```

Uma nota faltante é `NaN`, e `NaN < 3.6` é falso, então um assinante sem nota não é contado como
insatisfeito. Esse é o padrão certo aqui, e é uma decisão: anote-a quando tomá-la.

As colunas novas passam pelo mesmo `StandardScaler` das antigas, ajustado nas linhas de treino. A
escala é o único tipo de trabalho com atributos que esta aula não revisita: a aula 5 mostrou por que uma
soma com pesos precisa dela e uma árvore não, e nada nisso mudou.

```
ana@lab:~/ml$ python features.py
features        columns   logistic AUC   net value   boosting AUC   net value
lesson 5's           22         0.799   R$ 16,424         0.801   R$ 22,912
+ the gaps           24         0.799   R$ 16,360         0.803   R$ 21,688
+ the shapes         31         0.818   R$ 22,712         0.800   R$ 23,168
```

**A regressão logística foi de R$ 16.424 para R$ 22.712**, e a AUC dela de 0,799 para 0,818, a melhor
nota honesta de qualquer modelo do curso até aqui. Sete colunas, cada uma de uma frase, fizeram mais que
a busca inteira da aula 9 fez pelo boosting. A aula 9 tinha avisado: um bom atributo costuma mover um
modelo mais que um bom botão.

**As árvores do boosting quase não se mexeram**: 0,801, 0,803, 0,800, e valores líquidos que variam mil
reais para cada lado, dentro do ruído que a aula 2 mediu. Elas já tinham achado os penhascos. Toda marca
aqui é um corte que uma árvore faria sozinha, e entregá-lo não poupa nada à árvore.

Duas lições numa tabela, então:

- **A engenharia de atributos importa mais para os modelos que não acham formas**: regressão linear e
  logística, e tudo o que mede distâncias, como os vizinhos mais próximos. Para árvores ela importa
  quando a forma precisa de informação que nenhuma coluna sozinha tem, como uma razão entre duas delas.
- **Um modelo simples com bons atributos consegue empatar com um complexo de colunas cruas**, aqui com
  AUC maior e o dinheiro dentro do ruído, e manter tudo o que a aula 5 valorizava no simples: pesos que
  uma pessoa lê, e uma marca chamada `unhappy` que a equipe de retenção entende sem uma aula de gradient
  boosting.
