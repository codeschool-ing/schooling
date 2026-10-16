---
title: O crédito, por idade
version: 1
---

O modelo de churn decide quem ganha R$ 40 de desconto numa caixa. É um benefício pequeno, distribuído por
uma máquina, e umas pessoas recebem e outras não. **Justiça** (em inglês, *fairness*) pergunta se a linha
entre elas cai ao longo de uma característica que não devia decidir esse tipo de coisa: idade, sexo, raça,
religião, deficiência, as características que a lei e a decência comum tratam como **protegidas**. O
`churn.csv` tem uma delas, `age`, e todos os modelos desde a aula 2 a leram.

O primeiro passo é olhar, antes de discutir qualquer coisa. Divida os meses de teste em faixas de idade e
pergunte quatro coisas a cada uma: quantos saíram, que parte recebeu crédito, que parte de quem saiu
recebeu (o **recall** da aula 10) e que parte dos créditos chegou a alguém que saiu (a **precisão**). E
faça duas vezes: uma com `age` entre as colunas, como toda aula fez, e outra sem ela, que é o que o
primeiro instinto da maioria das pessoas manda fazer. Salve isto como `by_age.py`:

```python
# by_age.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
band = pd.cut(test["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])
without_age = [c for c in NUMERIC if c != "age"] + CATEGORICAL

for name, features in [("with age", NUMERIC + CATEGORICAL), ("without age", without_age)]:
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= CREDIT / (SAVED * KEPT)
    rows = test.assign(send=send, band=band)
    groups = rows.groupby("band", observed=True)
    table = pd.DataFrame({
        "subscribers": groups.size(),
        "left": groups["churned"].mean(),
        "credited": groups["send"].mean(),
        "recall": groups.apply(lambda g: g.loc[g["churned"] == 1, "send"].mean()),
        "precision": groups.apply(lambda g: g.loc[g["send"], "churned"].mean()),
    })
    print(f"{name}: net value R$ {net_value(test['churned'], send):,.0f}")
    print(table.round(3).to_string(), end="\n\n")
```

```
ana@lab:~/ml$ python by_age.py
with age: net value R$ 21,672
       subscribers   left  credited  recall  precision
band                                                  
18-24         2572  0.074     0.039   0.267      0.505
25-34         6109  0.052     0.026   0.216      0.439
35-49        11220  0.059     0.028   0.234      0.492
50-64         3987  0.071     0.033   0.240      0.519
65+            369  0.073     0.019   0.185      0.714

without age: net value R$ 21,336
       subscribers   left  credited  recall  precision
band                                                  
18-24         2572  0.074     0.027   0.194      0.536
25-34         6109  0.052     0.025   0.219      0.458
35-49        11220  0.059     0.028   0.241      0.502
50-64         3987  0.071     0.034   0.230      0.485
65+            369  0.073     0.033   0.259      0.583
```

Comece pela primeira tabela, o modelo como ele foi até aqui. **A faixa mais jovem é a que mais sai**,
7,4%, e o modelo sabe disso: ela recebe mais créditos, 3,9%, e tem o maior recall entre as faixas
grandes. A faixa mais velha sai quase na mesma proporção, 7,3%, e recebe menos créditos, 1,9%.

Leia essa última linha com cuidado. **A faixa de 65+ tem 369 assinantes e uns 27 que saíram em seis
meses**, então o recall de 0,185 são cinco pessoas, e a precisão de 0,714 são cinco de sete. Uma diferença
medida num punhado de gente ainda não é evidência de nada, em nenhuma direção. Isso é um problema de
justiça por si só: os grupos com mais chance de serem tratados de um jeito incomum costumam ser os
menores, onde nada se mede com confiança.

Agora a segunda tabela. Tirar `age` custou R$ 336 de valor líquido, o que é ruído, e mudou quem recebe o
crédito: a faixa mais jovem cai de 3,9% para 2,7%, e o recall dela de 0,267 para 0,194; a faixa mais velha
sobe. A próxima seção trata de por que tirar a coluna fez isso, e de por que não tirou a idade.
