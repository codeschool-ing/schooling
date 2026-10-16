---
title: A constante que acerta 94% das vezes
version: 1
---

O modelo mais barato que existe responde a mesma coisa para toda linha. O scikit-learn tem um,
chamado `DummyClassifier`, e ele existe exatamente para isto: ser ajustado, medido e superado. Com
`strategy="most_frequent"` ele aprende um fato das linhas de treino, qual classe é mais comum, e
prevê essa classe para sempre. Salve isto como `dummy.py`:

```python
# dummy.py
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score

from feira import NUMERIC, by_time, load_churn, net_value

train, test = by_time(load_churn())
print(f"learn from {len(train):,} rows, test on {len(test):,}")

dummy = DummyClassifier(strategy="most_frequent").fit(train[NUMERIC], train["churned"])
said = dummy.predict(test[NUMERIC])
print("it always says:", sorted(set(said.tolist())))
print(f"accuracy: {accuracy_score(test['churned'], said):.3f}")
print(f"net value: R$ {net_value(test['churned'], said):,.0f}")
```

```
ana@lab:~/ml$ python dummy.py
learn from 38,628 rows, test on 24,257
it always says: [0]
accuracy: 0.939
net value: R$ 0
```

**93,9% de acurácia, e não vale nada.** Ele diz 0, *fica*, para todas as 24.257 linhas de teste.
Acerta todo mundo que ficou e erra cada uma das pessoas que saíram, e como quem sai é mais ou menos
uma linha em dezesseis, errar todas elas custa só seis pontos de acurácia.

Essa é a primeira lição de uma linha de base, e ela é sobre a métrica, não sobre o modelo: **numa
classe rara, a acurácia mede o quanto a classe é rara.** Qualquer modelo destes dados vai tirar algo
em torno de 94%, seja excelente ou inútil, então a acurácia não distingue os dois. A aula 10 a
substitui por medidas que distinguem; esta aula usa o valor líquido, em que a constante tira
exatamente o que deve, R$ 0, e um modelo tem de merecer qualquer coisa acima disso.

As variáveis passadas ao `fit` são ignoradas, como o nome promete. Elas estão ali porque todo modelo
do scikit-learn é chamado do mesmo jeito, e é isso que deixa um dummy entrar numa comparação ao lado
de um modelo de verdade sem caso especial no código.

## As constantes para os outros tipos de problema

O `DummyClassifier` tem outras estratégias, e cada uma é o piso honesto de uma pergunta diferente:

| estratégia | prevê | o piso para |
|---|---|---|
| `most_frequent` | a classe mais comum | acurácia, e qualquer contagem de acertos |
| `prior` | a classe mais comum, e as proporções das classes como probabilidades | qualquer coisa medida em probabilidades (aula 10) |
| `stratified` | uma classe sorteada nas proporções do treino | um modelo que só chuta na taxa certa |

O `DummyRegressor` é a mesma ideia para uma quantidade, prevendo a média ou a mediana do alvo de
treino. A seção 08 desta aula usa essa ideia nas entregas.
