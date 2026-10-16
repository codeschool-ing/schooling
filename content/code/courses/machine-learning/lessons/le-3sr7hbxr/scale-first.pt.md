---
title: Escale primeiro, ou uma coluna decide
version: 1
---

O k-means mede distância, e uma distância soma diferenças entre colunas. Uma diferença de R$ 68,8 na cesta
e uma de 5,5 pontos em ovos são ambas "uma diferença típica", mas sem escala a primeira conta mais de doze
vezes a segunda. O programa abaixo agrupa as mesmas linhas duas vezes, com e sem escala, e compara as
duas. Salve isto como `unscaled.py`:

```python
# unscaled.py
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
X = baskets.drop(columns="customer_id")
scaled = KMeans(n_clusters=4, n_init=10, random_state=0).fit(StandardScaler().fit_transform(X))
raw = KMeans(n_clusters=4, n_init=10, random_state=0).fit(X)

print("spread of each column:", ", ".join(f"{c} {s:.1f}" for c, s in X.std().items()))
print(f"agreement between the two clusterings (adjusted Rand): "
      f"{adjusted_rand_score(scaled.labels_, raw.labels_):.3f}")
print(baskets.assign(cluster=raw.labels_).groupby("cluster")[["avg_basket", "orders_month", "fruit",
                                                             "bakery"]].mean().round(1).to_string())
```

O **índice de Rand ajustado** compara dois jeitos de agrupar as mesmas linhas. Ele é 1 quando concordam
exatamente, sejam quais forem os números que cada um deu aos grupos, e cerca de 0 quando concordam só o
quanto o acaso faria.

```
ana@lab:~/ml$ python unscaled.py
spread of each column: orders_month 1.1, avg_basket 68.8, fruit 13.7, vegetables 9.2, greens 7.4, eggs_dairy 5.5, bakery 9.1, extras 5.9
agreement between the two clusterings (adjusted Rand): 0.723
         avg_basket  orders_month  fruit  bakery
cluster                                         
0             327.5           1.6   19.5    12.1
1             207.2           3.5   16.2     6.5
2             138.7           2.0   43.5     5.1
3             260.5           3.9   15.4    22.1
```

Concordância de 0,723: parecidos, mas não o mesmo agrupamento. Leia as cestas dos grupos sem escala:
R$ 139, 207, 261 e 328, bem espaçadas, porque **a cesta é quase tudo o que a distância sem escala
enxerga**. Pedidos por mês, com dispersão de 1,1, quase não contam. O grupo da padaria só sobrevive porque
os clientes de padaria por acaso também gastam uns R$ 260.

Duas lições seguem, e as duas valem além do k-means:

- **Escale antes de qualquer método que mede distância**: k-means, DBSCAN, agrupamento hierárquico,
  vizinhos mais próximos, máquinas de vetores de suporte. Árvores não precisam, porque um corte compara uma
  coluna só com ela mesma.
- **Escalar é uma escolha sobre o que importa.** Padronizar diz que toda coluna conta igual. Se a equipe de
  marketing se importa muito mais com *o que* as pessoas compram do que com *quanto*, as partes poderiam
  ganhar peso, ou as duas colunas de dinheiro ficar de fora. Não há escolha neutra, só uma declarada.
