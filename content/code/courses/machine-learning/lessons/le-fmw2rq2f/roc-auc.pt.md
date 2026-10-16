---
title: ROC AUC, e o que o número quer dizer
version: 1
---

A área sob a curva ROC, a **AUC**, resume a curva num número: 0,5 para a diagonal, 1,0 para um modelo
perfeito. A aula 4 a usou antes de explicá-la; aqui está o que ela quer dizer, que é mais útil que a
geometria. **A AUC é a probabilidade de alguém que sai, sorteado ao acaso, receber uma nota maior que
alguém que fica, sorteado ao acaso.** Isso pode ser conferido direto, sorteando pares. Salve isto como
`ranking.py`:

```python
# ranking.py
import numpy as np
import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

scores = pd.read_csv("scores.csv")
y, chance = scores["churned"].to_numpy(), scores["chance"].to_numpy()
print(f"ROC AUC {roc_auc_score(y, chance):.3f}   average precision {average_precision_score(y, chance):.3f}")
print(f"leavers among all test rows: {y.mean():.3f}")

rng = np.random.default_rng(0)
leaver = rng.choice(chance[y == 1], 100_000)
stayer = rng.choice(chance[y == 0], 100_000)
print(f"a random leaver scored above a random stayer in {np.mean(leaver > stayer):.1%} of 100,000 pairs")
```

```
ana@lab:~/ml$ python ranking.py
ROC AUC 0.804   average precision 0.322
leavers among all test rows: 0.061
a random leaver scored above a random stayer in 80.4% of 100,000 pairs
```

**A área é 0,804, e em 100.000 pares ao acaso quem saiu superou quem ficou em 80,4% das vezes.** As
duas são a mesma grandeza, calculada de dois jeitos. Então a AUC é sobre ordenação e nada mais: ela não
liga para o valor das notas, só para a ordem delas, e não depende de corte nenhum.

Isso a torna boa para algumas tarefas e errada para outras.

**Ela é boa para comparar modelos antes de escolher um corte**, e para achar o impossível: o 0,958 da
aula 4 era um modelo ordenando quem sai muito melhor do que o comportamento permite. Ela não muda quando
todas as notas são multiplicadas ou deslocadas, então um modelo com probabilidades mal calibradas pode
ter uma AUC excelente.

**Ela é errada para julgar uma decisão.** O crédito vai para as poucas centenas de assinantes do topo a
cada mês, e a AUC pesa a ordem entre os vinte mil de baixo exatamente tanto quanto a ordem no topo. Dois
modelos com a mesma AUC podem diferir muito na região onde os créditos são de fato enviados.

O segundo número que o `ranking.py` imprimiu é o assunto da próxima seção.
