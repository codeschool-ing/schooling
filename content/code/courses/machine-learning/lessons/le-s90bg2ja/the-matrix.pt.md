---
title: Clientes, produtos e uma resposta escondida
version: 1
---

A Feira em Casa vende **adicionais**: farinha, café, azeite, pão de fermentação natural, vinte e dois
produtos que um cliente pode pôr na caixa ao lado das frutas e verduras. O aplicativo tem espaço para três
sugestões, e a pergunta é quais três mostrar a cada cliente. Esse é um problema de **recomendação**, e os
dados dele têm uma forma própria: uma tabela com uma linha por cliente, uma coluna por produto, e um 1 onde
o cliente comprou.

O `addons.csv` tem uma linha por cliente e produto, com quantas vezes foi acrescentado. Recomendação não tem
coluna de rótulo para prever, mas ainda pode ser testada com honestidade com um truque: **esconda um
produto que cada cliente comprou, e veja se o recomendador o sugere.** Se três sugestões muitas vezes
incluem o produto escondido, o recomendador sabe algo sobre o que as pessoas querem.

Todo programa desta aula usa o mesmo esconderijo, então ele mora num módulo. Salve isto como `holdout.py`:

```python
# holdout.py
"""Hide one add-on from each customer, and count how often a recommender finds it again."""
import numpy as np
import pandas as pd

def split(seed=0):
    addons = pd.read_csv("data/addons.csv")
    bought = pd.crosstab(addons["customer_id"], addons["product"]).clip(upper=1)
    rng = np.random.default_rng(seed)
    known, hidden = bought.copy(), {}
    for customer, row in bought.iterrows():
        owned = row.index[row == 1]
        if len(owned) >= 2:
            hidden[customer] = rng.choice(owned)
            known.loc[customer, hidden[customer]] = 0
    return known, hidden

def hit_rate(scores, known, hidden, k=3):
    hits = 0
    for customer, product in hidden.items():
        candidates = scores.loc[customer].astype(float).where(known.loc[customer] == 0)
        hits += product in candidates.nlargest(k).index
    return hits / len(hidden)
```

O `crosstab` monta a tabela cliente por produto, e o `clip(upper=1)` transforma contagens em comprou ou
não. O `split` esconde um produto de todo cliente com pelo menos dois, e o `hit_rate` dá a um recomendador
uma tabela de notas, descarta o que cada cliente já sabidamente compra e conta quantas vezes o produto
escondido está entre os três primeiros. Esse número é a **taxa de acerto em 3**.

Agora olhe a tabela. Salve isto como `matrix.py`:

```python
# matrix.py
from holdout import split

known, hidden = split()
per_customer = known.sum(axis=1)
print(f"{known.shape[0]:,} customers x {known.shape[1]} add-ons; {known.values.mean():.1%} of the cells are 1")
print(f"add-ons a customer is known to buy: median {per_customer.median():.0f}, "
      f"from {per_customer.min()} to {per_customer.max()}")
print(f"one add-on hidden from each of {len(hidden):,} customers")
print(known.iloc[:4, :8].to_string())
```

```
ana@lab:~/ml$ python matrix.py
1,491 customers x 22 add-ons; 42.4% of the cells are 1
add-ons a customer is known to buy: median 9, from 1 to 21
one add-on hidden from each of 1,469 customers
product      avocado  butter  cheese  chilli  cocoa  coffee  coriander  eggs
customer_id                                                                 
C00001             1       1       1       0      1       1          0     1
C00002             1       0       0       1      0       1          0     1
C00003             1       1       0       0      0       0          0     0
C00004             1       0       1       1      1       0          1     1
```

**42,4% das células estão preenchidas**, o que é denso para este tipo de dado: um cliente compra nove de
vinte e dois adicionais, depois de um ser escondido. Uma loja com cem mil produtos e clientes que compram
quarenta cada preencheria uma célula em duas mil e quinhentas, e quase tudo o que é difícil em recomendação
em escala vem desse vazio. As ideias desta aula são as mesmas nas duas densidades; aqui a conta é pequena o
bastante para acompanhar.
