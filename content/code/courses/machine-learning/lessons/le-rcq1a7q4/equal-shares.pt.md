---
title: Quanto custa tratar todos igual
version: 1
---

Suponha que alguém insista na paridade demográfica: toda faixa de idade recebe créditos na mesma taxa. Dá
para fazer sem treinar nada de novo, dando a cada faixa o seu próprio corte, posto de modo que a mesma
parte de cada faixa fique acima dele. O custo disso vira um número, e pôr números nas opções é o que
transforma uma discussão sobre justiça numa decisão. Salve isto como `parity.py`:

```python
# parity.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
chance = pd.Series(model.predict_proba(test[features])[:, 1], index=test.index)
band = pd.cut(test["age"], [17, 24, 34, 49, 64, 99], labels=["18-24", "25-34", "35-49", "50-64", "65+"])

one_cut = chance >= CREDIT / (SAVED * KEPT)
share = one_cut.mean()
equal = chance >= chance.groupby(band, observed=True).transform(lambda c: c.quantile(1 - share))

print(f"share credited overall: {share:.1%}")
print("policy                    net value   credited 18-24   credited 65+   leavers reached")
for name, send in [("one cut for everybody", one_cut), ("same share in every band", equal)]:
    reached = send[test["churned"] == 1].mean()
    print(f"{name:24} R$ {net_value(test['churned'], send):8,.0f} {send[band == '18-24'].mean():14.1%}"
          f" {send[band == '65+'].mean():14.1%} {reached:17.1%}")
```

O `transform` dá a cada linha o corte da sua própria faixa: a chance acima da qual estão os 2,9% do topo
daquela faixa.

```
ana@lab:~/ml$ python parity.py
share credited overall: 2.9%
policy                    net value   credited 18-24   credited 65+   leavers reached
one cut for everybody    R$   21,672           3.9%           1.9%             23.5%
same share in every band R$   20,584           3.0%           3.0%             23.0%
```

**Partes iguais custaram R$ 1.088 em seis meses e alcançaram um pouco menos de gente que saiu**, 23,0%
contra 23,5%. Os jovens perdem créditos, de 3,9% para 3,0%, embora sejam os que mais saem; os mais velhos
ganham. É a paridade demográfica fazendo o que promete, e nesta decisão ela tira créditos do grupo que
mais precisa deles.

O ponto não é que a paridade esteja errada. É que **toda política de justiça tem um preço e um conjunto de
ganhadores e perdedores**, e os dois podem ser calculados antes de alguém decidir. Aqui o preço é pequeno
em dinheiro e real em quem é alcançado. Um corte por faixa escolhido para igualar o **recall**
moveria créditos para as faixas de recall mais baixo, 25-34 e 65+, e um pouco para longe da mais jovem,
cujo recall já é o maior; o mesmo programa, com o quantil trocado, põe preço nele.

Duas cautelas com cortes por grupo. Usar uma característica protegida para definir um limiar diferente já
é tratar as pessoas de forma diferente por essa característica, o que pode ser exatamente o que a lei
proíbe em algumas decisões, mesmo quando a intenção é corrigir um viés. E numa faixa de 369 assinantes, um
corte definido por um quantil se mexe com cada punhado de linhas de cada mês. As duas coisas são motivos
para fazer essa escolha junto com quem responde pela decisão, e a próxima seção é essa conversa.
