---
title: A referência: o que todo mundo compra
version: 1
---

A regra da aula 2 vale aqui também: antes de qualquer coisa sofisticada, meça a coisa mais simples que poderia
funcionar. Em recomendação isso é a **popularidade**: mostrar a todo cliente os três adicionais mais
vendidos que ele ainda não compra. Não precisa de modelo e muitas vezes é difícil de vencer, porque produtos
populares são populares por algum motivo. Salve isto como `popular.py`:

```python
# popular.py
import pandas as pd

from holdout import hit_rate, split

known, hidden = split()
popularity = known.sum()
print("most bought:", ", ".join(f"{p} {n}" for p, n in popularity.nlargest(5).items()))

scores = pd.DataFrame([popularity] * len(known), index=known.index)
unbought = (known == 0).sum(axis=1)[list(hidden)]
print(f"three guesses at random would find it {(3 / unbought).mean():.1%} of the time")
print(f"the three most popular add-ons not yet bought find it {hit_rate(scores, known, hidden):.1%}")
```

A tabela de notas dá a todo cliente a mesma linha, a contagem de compradores de cada produto, e o
`hit_rate` descarta o que cada um já tem.

```
ana@lab:~/ml$ python popular.py
most bought: avocado 936, sourdough 936, cheese 924, eggs 922, flour 605
three guesses at random would find it 28.3% of the time
the three most popular add-ons not yet bought find it 41.2%
```

Três palpites ao acaso entre os adicionais que um cliente não compra achariam o escondido 28,3% das vezes;
a popularidade acha **41,2%**. É um ganho real e não custa nada, e é o número que todo outro recomendador
desta aula precisa vencer.

Quatro dos cinco primeiros são os adicionais que todo mundo compra, abacate, pão de fermentação natural,
queijo e ovos, e a popularidade os mostra a todo mundo. A fraqueza dela é exatamente essa: **ela recomenda
os mesmos três produtos a quem faz pão e a quem toma café**, e depois que um cliente tem esses três, ela não
tem nada a dizer sobre o que aquela pessoa em particular gostaria de comprar. As próximas seções usam o que cada
cliente comprou para escolher por ele.
