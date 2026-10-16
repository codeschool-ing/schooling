---
title: k-means
version: 1
---

O **k-means** é o algoritmo de agrupamento que todo mundo conhece primeiro, e é simples o bastante para
rodar à mão.

1. Escolha *k*, o número de grupos, e ponha *k* centros em algum lugar entre as linhas.
2. Dê cada linha ao centro mais próximo.
3. Mova cada centro para a média das linhas que recebeu.
4. Repita 2 e 3 até nada se mexer.

Cada rodada só pode deixar as linhas mais perto dos seus centros, então ele sempre para. Onde ele para
depende de onde os centros começaram, então o scikit-learn o começa `n_init` vezes de lugares diferentes e
fica com o melhor. A **inércia** é o que *melhor* quer dizer: a soma das distâncias ao quadrado de cada
linha ao seu centro.

A distância é o coração dele, então toda coluna precisa contar em unidades comparáveis, que é o que o
`StandardScaler` da aula 5 faz. A próxima seção mostra o que acontece sem isso. Salve isto como
`kmeans.py`; ele pede quatro grupos, um número que a seção depois da próxima questiona:

```python
# kmeans.py
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
scaled = StandardScaler().fit_transform(X)

kmeans = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)
baskets["cluster"] = kmeans.labels_
profile = baskets.groupby("cluster")[X.columns].mean().round(1)
profile.insert(0, "customers", baskets["cluster"].value_counts().sort_index())
print(profile.to_string())
```

O agrupamento acontece nas colunas escaladas; o perfil faz a média das colunas **originais**, em reais e
pontos, porque é isso que uma pessoa consegue ler.

```
ana@lab:~/ml$ python kmeans.py
         customers  orders_month  avg_basket  fruit  vegetables  greens  eggs_dairy  bakery  extras
cluster                                                                                            
0              342           3.5       210.0   15.2        39.5    25.0        10.3     4.9     5.1
1              184           1.2       327.4   20.1        20.1    14.9        14.7    10.3    19.9
2              345           1.9       139.8   44.9        25.4     9.8         9.9     5.1     5.0
3              329           4.0       261.1   15.1        19.9     9.8        20.1    24.9    10.2
```

Quatro grupos, e cada um pode ser descrito numa frase, que é o primeiro teste que um agrupamento precisa
passar:

| grupo | clientes | numa frase |
|---|---|---|
| 0 | 342 | frequentes, cestas médias, pesadas em **legumes e folhas** |
| 1 | 184 | pedidos **raros e grandes**, uns R$ 327, com um quinto gasto em extras |
| 2 | 345 | cestas pequenas, quase metade **fruta** |
| 3 | 329 | os mais frequentes, com um quarto em **padaria** e um quinto em ovos e laticínios |

Os números de 0 a 3 não querem dizer nada. São a ordem em que o algoritmo por acaso numerou seus centros,
e outro `random_state` poderia trocá-los. Dê nome aos grupos pelo que eles têm, como faz a coluna da
direita, e a equipe de marketing tem quatro newsletters para escrever.

Se quatro é o número certo, e se estes grupos voltariam de outra amostra de clientes, são as perguntas que
as seções seguintes respondem.
