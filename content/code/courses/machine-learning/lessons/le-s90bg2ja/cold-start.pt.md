---
title: A partida a frio
version: 1
---

Todo recomendador desta aula aprende com histórico, e histórico é exatamente o que falta a um cliente novo ou
a um produto novo. Essa é a **partida a frio**, e ela vem de duas formas.

**Um cliente novo** comprou pouco ou nada, então não há com o que comparar e nenhuma linha para fatorar. Quanto
histórico basta pode ser medido: divida os clientes por quantos adicionais sabidamente compram, e compare os
dois recomendadores em cada grupo. Salve isto como `cold_start.py`:

```python
# cold_start.py
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

from holdout import hit_rate, split

known, hidden = split()
similarity = cosine_similarity(known.T)
np.fill_diagonal(similarity, 0)
similar = pd.DataFrame(known.values @ similarity, index=known.index, columns=known.columns)
popular = pd.DataFrame([known.sum()] * len(known), index=known.index)

count = known.sum(axis=1)
print("add-ons known   customers   popular   similar")
for low, high in [(1, 3), (3, 6), (6, 23)]:
    group = {c: p for c, p in hidden.items() if low <= count[c] < high}
    print(f"{low:>4} to {high - 1:<6} {len(group):11,} {hit_rate(popular, known, group):9.1%}"
          f" {hit_rate(similar, known, group):9.1%}")
```

```
ana@lab:~/ml$ python cold_start.py
add-ons known   customers   popular   similar
   1 to 2               74     16.2%     24.3%
   3 to 5              181     23.2%     35.4%
   6 to 22           1,214     45.4%     73.1%
```

**Com um ou dois adicionais conhecidos, todo recomendador sofre**: 16,2% para a popularidade, 24,3% para a
semelhança. Com seis ou mais, a semelhança acha o produto escondido 73,1% das vezes. A semelhança ainda vence
a popularidade em todo nível, mesmo com um produto conhecido: uma única compra de farinha diz muito. Mas a
distância e o nível crescem com o histórico, e para um cliente sem nada, a semelhança não tem entrada e a
popularidade é tudo o que há.

**Um produto novo** é a forma mais difícil. Ninguém o comprou, então a coluna dele é toda zero: nenhuma
semelhança com nada, nenhuma carga nos fatores, nunca recomendado, então nunca comprado, então nunca
recomendado. A filtragem colaborativa não quebra esse ciclo sozinha.

O que quebra é informação que não vem de compras:

- **Pergunte.** Um cliente novo que escolhe *"faço pão"* no cadastro começa com um gosto em vez de começar do zero.
- **Descreva o produto.** Um tempero novo pode pegar emprestados os vizinhos dos produtos com que mais se
  parece, por categoria, por ingredientes, por preço. Isso é recomendação **baseada em conteúdo**, e combinada
  com a filtragem colaborativa se chama híbrida.
- **Explore de propósito.** Mostre o produto novo a uma parte pequena e sorteada dos clientes por um tempo, para
  ele juntar o histórico de que precisa. Uma parte da receita é gasta em aprender, e isso é uma decisão a tomar
  de propósito em vez de deixar ao acaso.

Para a Feira em Casa o plano segue da tabela: popularidade para clientes com menos de três adicionais,
semelhança entre itens a partir de três, uma pergunta no cadastro para encurtar a primeira fase, e todo produto
novo mostrado a um cliente em vinte no primeiro mês.
