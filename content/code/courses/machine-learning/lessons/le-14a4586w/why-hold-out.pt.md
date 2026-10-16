---
title: Por que a nota nas linhas de treino não significa nada
version: 1
---

**Um modelo consegue decorar.** Com liberdade suficiente, ele guarda a resposta de cada linha que
viu e a repete, e nessas linhas ele é perfeito. Essa perfeição não diz nada sobre a próxima linha,
que é a única sobre a qual alguém vai perguntar. Por isso um modelo é julgado em linhas que ele não
viu enquanto aprendia, e a distância entre as duas notas é a primeira coisa a olhar.

Uma árvore de decisão sem limites mostra essa distância no máximo. Ela continua dividindo as linhas
de treino até cada folha ter linhas de uma classe só, o que é decorar por construção. A aula 7 trata
de árvores; aqui é só um modelo sem freio. Salve isto como `overfit.py`:

```python
# overfit.py
from sklearn.metrics import accuracy_score
from sklearn.tree import DecisionTreeClassifier

from feira import NUMERIC, by_time, load_churn, net_value

train, test = by_time(load_churn())
X_train, X_test = train[NUMERIC].fillna(-1), test[NUMERIC].fillna(-1)

tree = DecisionTreeClassifier(random_state=0).fit(X_train, train["churned"])
print(f"leaves: {tree.get_n_leaves():,} for {len(train):,} training rows")
for name, X, y in [("training", X_train, train["churned"]), ("test", X_test, test["churned"])]:
    said = tree.predict(X)
    print(f"{name:9} accuracy {accuracy_score(y, said):.3f}   net value R$ {net_value(y, said):>9,.0f}")
```

```
ana@lab:~/ml$ python overfit.py
leaves: 3,421 for 38,628 training rows
training  accuracy 1.000   net value R$   228,592
test      accuracy 0.892   net value R$   -25,816
```

**Perfeita nas linhas de que aprendeu, e pior que a constante nas que não viu.** 3.421 folhas para
38.628 linhas são umas onze linhas por folha: a árvore recortou uma regiãozinha para quase toda
combinação de valores que viu, cada uma com o rótulo do que aconteceu ali. Nas linhas de treino isso
vale R$ 228.592. Nos meses de teste ela manda créditos às pessoas erradas com tanta frequência que
perde R$ 25.816, e a acurácia, 0,892, fica abaixo dos 0,939 do modelo que sempre diz *fica*.

Isso é **sobreajuste**: o modelo aprendeu o ruído das linhas de treino junto com o sinal, e o ruído
não se repete. A cura é em parte um modelo com freio, que as aulas 5 a 9 trazem, e por inteiro um
teste que não pode ser decorado. O `fillna(-1)` só dá à árvore um número onde falta uma avaliação ou
um login; a aula 14 faz isso direito.

## A regra que decorre disso

**Todo número usado para escolher qualquer coisa tem de vir de linhas que a escolha não viu.** Isso
vale para os parâmetros do modelo, que o `fit` define, e para tudo o que uma pessoa define em volta
deles: qual modelo, quais colunas, qual limiar, qual regra. O resto desta aula é a maquinaria para
cumprir essa regra sem ficar sem dados.
