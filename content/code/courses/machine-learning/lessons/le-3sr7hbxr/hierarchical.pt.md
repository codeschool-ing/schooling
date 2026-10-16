---
title: Agrupamento hierárquico
version: 1
---

O **agrupamento aglomerativo** começa com cada cliente num grupo só seu e junta os dois grupos mais
próximos, de novo e de novo, até sobrar um. O resultado é uma árvore de junções, e cortá-la em qualquer
altura dá um agrupamento: perto do topo, poucos grupos grandes; perto da base, muitos pequenos. Ele
responde *"quantos?"* com *"escolha uma altura"*, e mostra toda a família de respostas de uma vez.

O que *grupos mais próximos* quer dizer é a **ligação**, e ela muda o resultado mais que qualquer outra
coisa:

- **ward** junta o par que menos aumenta a dispersão total dentro dos grupos. Faz grupos compactos de
  tamanho parecido, o mesmo objetivo do k-means.
- **average** usa a distância média entre cada linha de um grupo e cada linha do outro.
- **single** usa a distância entre as duas linhas mais próximas. Um cliente a meio caminho entre dois
  grupos basta para juntá-los.

Salve isto como `hierarchy.py`; ele corta cada árvore em quatro grupos e compara com o k-means:

```python
# hierarchy.py
import numpy as np
import pandas as pd
from sklearn.cluster import AgglomerativeClustering, KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
kmeans = KMeans(n_clusters=4, n_init=10, random_state=0).fit(scaled)
for linkage in ["ward", "average", "single"]:
    tree = AgglomerativeClustering(n_clusters=4, linkage=linkage).fit(scaled)
    print(f"{linkage:8} sizes {sorted(np.bincount(tree.labels_).tolist(), reverse=True)}   "
          f"agreement with k-means {adjusted_rand_score(kmeans.labels_, tree.labels_):.3f}")
```

```
ana@lab:~/ml$ python hierarchy.py
ward     sizes [345, 342, 329, 184]   agreement with k-means 1.000
average  sizes [346, 341, 329, 184]   agreement with k-means 0.998
single   sizes [687, 329, 183, 1]   agreement with k-means 0.646
```

**As ligações ward e average concordam com o k-means quase exatamente.** Três métodos diferentes,
construídos sobre ideias diferentes, acharam os mesmos quatro grupos, e essa é a evidência mais forte que
esta aula consegue oferecer de que os grupos estão nos dados.

**A ligação single fez outra coisa**: um grupo de 687, que são dois grupos encadeados, e um grupo de um
cliente só. Essa é a fraqueza conhecida dela, chamada **encadeamento**, e é também a sua utilidade: a
ligação single é a que consegue seguir formas longas, finas e sinuosas, e a que acha primeiro o ponto
fora da curva.

O agrupamento hierárquico compara todo par de linhas, então o custo dele cresce com o quadrado do número de
linhas. Em 1.200 clientes isso não é nada; em um milhão fica fora de alcance, e a resposta é o k-means ou
uma amostra.
