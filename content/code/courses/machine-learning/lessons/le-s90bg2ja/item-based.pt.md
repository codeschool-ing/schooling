---
title: Recomendando a partir do que o cliente já compra
version: 1
---

Com uma semelhança entre todo par de produtos, as recomendações de um cliente são uma soma: **para cada
produto que ele não compra, some a semelhança dele com cada produto que ele compra.** Um cliente que compra
farinha, manteiga e cacau dá ao fermento três semelhanças grandes e ao café três pequenas, então o fermento
vem primeiro. Essa é a **filtragem colaborativa baseada em itens**, e em forma de matriz é uma multiplicação
só: a linha de uns do cliente vezes a tabela de semelhanças. Salve isto como `item_based.py`:

```python
# item_based.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import hit_rate, split

known, hidden = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
scores = pd.DataFrame(known.values @ similarity, index=known.index, columns=known.columns)
popular = pd.DataFrame([known.sum()] * len(known), index=known.index)

print(f"most popular not yet bought:  {hit_rate(popular, known, hidden):.1%}")
print(f"most similar to what they buy: {hit_rate(scores, known, hidden):.1%}")
```

As semelhanças são calculadas com `known`, com o produto escondido de cada cliente já removido, para o
recomendador nunca ver a resposta em que está sendo testado. Calculá-las com a tabela completa seria o
vazamento da aula 4 com outra roupa.

```
ana@lab:~/ml$ python item_based.py
most popular not yet bought:  41.2%
most similar to what they buy: 66.0%
```

**66,0% contra 41,2%.** Recomendar o que combina com o que o cliente já compra acha o adicional escondido em
dois casos de três, contra dois em cinco da popularidade. O ganho vem das cozinhas: quando o recomendador
sabe que alguém faz pão, o próximo produto de confeitaria é um palpite muito melhor que o mais vendido.

A filtragem baseada em itens tem propriedades que explicam por que ela durou. **Ela se explica**: *"porque
você compra farinha"* é uma frase que o aplicativo pode mostrar. **Ela é barata**: a tabela de semelhanças
tem uma linha por produto, não por cliente, e muda devagar. E **ela precisa de histórico**, que é o assunto
da última seção.
