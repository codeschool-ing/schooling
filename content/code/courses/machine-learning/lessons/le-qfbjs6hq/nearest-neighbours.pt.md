---
title: Vizinhos mais próximos, o modelo que lembra
version: 1
---

A ideia mais simples do machine learning cabe numa frase: **para prever uma linha nova, ache as k
linhas mais parecidas com ela nos dados de treino e deixe que votem.** Isso é k vizinhos mais
próximos (*k-nearest neighbours*). Ajustar não faz nada além de guardar as linhas de treino; todo o
trabalho acontece quando se pede uma previsão, o que é o contrário de todos os modelos até aqui. A
chance de sair é simplesmente a parte de quem saiu entre os k vizinhos.

"Mais parecida" quer dizer mais próxima, e mais próxima quer dizer uma **distância**: por padrão, a
distância em linha reta por todas as colunas numéricas ao mesmo tempo, como se cada linha fosse um
ponto num espaço com um eixo por coluna. Duas decisões importam mais que qualquer outra coisa no
modelo: quantos vizinhos, e em que unidade os eixos são medidos. Salve isto como `knn.py`; ele ajusta
oito modelos e prevê 24.257 linhas com cada um, então leva cerca de um minuto:

```python
# knn.py
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
medians = train[NUMERIC].median()
X_train, X_test = train[NUMERIC].fillna(medians), test[NUMERIC].fillna(medians)
cut = CREDIT / (SAVED * KEPT)

scale = StandardScaler().fit(X_train)
for k in [1, 15, 101, 501]:
    for scaled in [False, True]:
        a, b = (scale.transform(X_train), scale.transform(X_test)) if scaled else (X_train, X_test)
        knn = KNeighborsClassifier(n_neighbors=k).fit(a, train["churned"])
        send = knn.predict_proba(b)[:, 1] >= cut
        print(f"k={k:<4} {'scaled' if scaled else 'raw':6}  {send.sum():5,} credits  "
              f"R$ {net_value(test['churned'], send):>8,.0f}")
```

```
ana@lab:~/ml$ python knn.py
k=1    raw     1,134 credits  R$  -22,896
k=1    scaled  1,118 credits  R$  -15,632
k=15   raw       120 credits  R$       96
k=15   scaled    332 credits  R$    7,744
k=101  raw         0 credits  R$        0
k=101  scaled    111 credits  R$    5,784
k=501  raw         0 credits  R$        0
k=501  scaled     16 credits  R$    1,232
```

## Lendo pelo k

**k = 1 perde dinheiro dos dois jeitos.** Um vizinho é a sorte de uma linha: se o assinante mais
parecido dos meses de treino saiu ou não decide tudo, e isso é a árvore sem limites da aula 3 com
outro nome. Os 1.118 créditos dele se espalham quase ao acaso.

**k = 15, padronizado, é o melhor deles, com R$ 7.744.** Quinze vizinhos tiram a média de quase
toda a sorte e ainda mantêm a vizinhança local.

**k grande vira a constante.** Com 501 vizinhos, quase toda vizinhança se parece com a população
inteira, uns 6% saindo, e quase ninguém chega aos 28% em que um crédito se paga. O modelo manda 16
créditos; no limite, com toda linha de treino como vizinha, ele seria a constante da aula 2. **O k é
um botão que vai de decorar a tirar a média**, e o ajuste certo fica entre as pontas, achado em dados
de validação como a aula 9 faz.

Mesmo o melhor dele, R$ 7.744, é menos da metade dos R$ 16.424 da regressão logística e cerca de um
terço do boosting. A seção 08 diz por que esse é o resultado de costume em dados assim, e onde os
vizinhos mais próximos merecem lugar mesmo assim.
