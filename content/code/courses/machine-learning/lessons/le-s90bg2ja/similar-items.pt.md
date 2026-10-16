---
title: Produtos comprados pelas mesmas pessoas
version: 1
---

A **filtragem colaborativa** recomenda a partir do comportamento de outros clientes, e não de algo que se
saiba sobre os produtos. A forma mais antiga dela diz: dois produtos são parecidos se os mesmos clientes os
compram. Ninguém lhe diz que farinha e fermento são para fazer pão; ela percebe que quem compra um compra o
outro.

A semelhança é medida entre as **colunas** da tabela. Cada produto é uma coluna de 1.491 zeros e uns, um por
cliente, e a **similaridade de cosseno** de duas colunas fica perto de 1 quando elas têm os uns nas mesmas
linhas. Salve isto como `similar.py`:

```python
# similar.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import split

known, _ = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
similarity = pd.DataFrame(similarity, index=known.columns, columns=known.columns)
for product in ["flour", "coffee", "garlic", "sourdough"]:
    nearest = similarity[product].nlargest(4)
    print(f"{product:10} " + ", ".join(f"{p} {s:.2f}" for p, s in nearest.items()))
```

O `known.T` transforma produtos em linhas, que é o que o `cosine_similarity` compara. A diagonal, a
semelhança de cada produto consigo mesmo, vira 0 para que um produto nunca seja o próprio vizinho mais
próximo.

```
ana@lab:~/ml$ python similar.py
flour      cocoa 0.66, butter 0.65, yeast 0.65, oats 0.64
coffee     papaya 0.67, yoghurt 0.66, honey 0.65, granola 0.64
garlic     olive oil 0.65, chilli 0.65, lime 0.64, coriander 0.64
sourdough  eggs 0.71, cheese 0.70, avocado 0.70, vanilla 0.58
```

**Três cozinhas aparecem sem ninguém dar nome a elas.** A farinha fica ao lado de cacau, manteiga, fermento
e aveia: confeitaria. O café ao lado de mamão, iogurte, mel e granola: café da manhã. O alho ao lado de
azeite, pimenta, limão e coentro: cozinha do dia a dia. A semelhança veio só de quem comprou o quê, e achou o
jeito como os produtos andam juntos numa cozinha.

O pão de fermentação natural é diferente, e merece uma segunda olhada. Os vizinhos dele são ovos, queijo e
abacate, os outros adicionais que todo mundo compra, e depois baunilha, num 0,58 bem mais baixo. Produtos que
quase todo mundo compra parecem uns com os outros sobretudo porque parecem com tudo, e essa é uma fraqueza
conhecida da similaridade de cosseno simples: **itens populares aparecem em toda lista**. Sistemas em
produção costumam descontá-los, e esta aula os deixa como estão, porque quem decide é a taxa de acerto.
