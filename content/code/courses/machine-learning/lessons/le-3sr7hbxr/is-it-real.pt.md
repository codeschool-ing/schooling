---
title: O agrupamento é real?
version: 1
---

Sem rótulo, um agrupamento não pode ser medido como certo ou errado. O que pode ser medido é se ele
**voltaria**: um agrupamento que muda quando alguns clientes entram ou saem descreve a amostra, não os
clientes. O teste é ajustar de novo em partes dos dados e ver se os mesmos grupos voltam. Salve isto como
`stability.py`; ele faz isso para quatro grupos e para seis:

```python
# stability.py
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
from sklearn.preprocessing import StandardScaler

baskets = pd.read_csv("data/baskets.csv")
scaled = StandardScaler().fit_transform(baskets.drop(columns="customer_id"))
rng = np.random.default_rng(0)

for k in [4, 6]:
    full = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled)
    agreement = []
    for _ in range(10):
        half = rng.choice(len(scaled), len(scaled) // 2, replace=False)
        part = KMeans(n_clusters=k, n_init=10, random_state=0).fit(scaled[half])
        agreement.append(adjusted_rand_score(full.labels_, part.predict(scaled)))
    print(f"k = {k}: refitted on ten random halves, agreement with the full fit "
          f"from {min(agreement):.3f} to {max(agreement):.3f}")
```

Cada ajuste numa metade depois rotula **todos** os 1.200 clientes com `predict`, para seu agrupamento poder
ser comparado linha a linha com o do ajuste completo.

```
ana@lab:~/ml$ python stability.py
k = 4: refitted on ten random halves, agreement with the full fit from 1.000 to 1.000
k = 6: refitted on ten random halves, agreement with the full fit from 0.812 to 0.980
```

**Quatro grupos voltam exatamente** de toda metade dos dados. Seis não: conforme a metade usada, a
concordância cai até 0,812. Os dois grupos a mais são divisões de grupos reais, traçadas onde aquela
amostra em particular por acaso ficou um pouco mais rala, e uma newsletter escrita para um deles seria
escrita para um acidente.

Agora o luxo mencionado no começo. O `make_data.py` sorteou estes clientes de quatro tipos de família nas
proporções de 30, 30, 25 e 15 por cento, e os quatro grupos têm 345, 342, 329 e 184 de 1.200: 29, 29, 27 e
15 por cento. Os métodos acharam o que foi posto ali. Em dados reais ninguém consegue fazer essa
conferência, e o teste de estabilidade, a concordância entre métodos e uma frase que descreve cada grupo
são o que ficam no lugar dela.

**Um grupo é uma hipótese sobre clientes**, e ele fica útil quando é testado como qualquer hipótese: mande a newsletter de padaria a uma metade sorteada do grupo da padaria e uma simples à outra metade, e veja se algo muda.
