---
title: Pondo no mapa um cliente que entrou amanhã
version: 1
---

Um mapa dos clientes de hoje é um retrato. Um mapa em que os clientes de amanhã podem ser postos é uma
ferramenta: a equipe de marketing vê onde cai um assinante novo, e um modelo mais adiante pode usar as duas
coordenadas do mapa como colunas. Isso pede que o método tenha um `transform`, a metade do contrato da
aula 15 que aplica a linhas novas o que foi aprendido. Salve isto como `new_points.py`; ele aprende cada
mapa com os primeiros 1.000 clientes e tenta pôr os últimos 200:

```python
# new_points.py
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
from sklearn.preprocessing import StandardScaler
from umap import UMAP

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
known, new = scaled[:1000], scaled[1000:]

for name, method in [("PCA", PCA(n_components=2)), ("UMAP", UMAP(random_state=0, n_jobs=1)),
                     ("t-SNE", TSNE(random_state=0))]:
    method.fit(known)
    if hasattr(method, "transform"):
        print(f"{name:6} placed {len(method.transform(new))} new customers on the map it learned")
    else:
        print(f"{name:6} has no transform: a new customer means drawing the whole map again")
```

A escala aqui é ajustada nas 1.200 linhas. Esse atalho é inofensivo para um retrato e seria o vazamento
de preparação da aula 4 se o mapa alimentasse um modelo. Dentro de um pipeline, como a aula 15 montou, ela
seria ajustada só nos primeiros 1.000.

```
ana@lab:~/ml$ python new_points.py
PCA    placed 200 new customers on the map it learned
UMAP   placed 200 new customers on the map it learned
t-SNE  has no transform: a new customer means drawing the whole map again
```

**O t-SNE não consegue pôr um ponto novo.** Ele não aprende uma função de oito colunas para duas; ele
arruma as linhas específicas que recebeu, e a arrumação não quer dizer nada para uma linha que não estava
lá. Acrescente um cliente e a única opção é desenhar o mapa inteiro de novo, e o mapa novo pode sair
girado, espelhado ou rearrumado.

**A PCA põe pontos novos exatamente**, pelas mesmas somas com pesos, e **o UMAP aproximadamente**,
achando os vizinhos do cliente novo entre os que aprendeu. Então a divisão de trabalho é clara:

| método | o retrato | linhas novas | eixos que querem dizer algo | velocidade |
|---|---|---|---|---|
| PCA | razoável | exatas | sim | instantânea |
| t-SNE | bom | não | não | lento em dados grandes |
| UMAP | bom | aproximadas | não | lento para começar, escala melhor que o t-SNE |
