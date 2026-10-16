---
title: Notas para uma ordenação, não para um corte
version: 1
---

Acurácia, precisão e revocação precisam de um limiar antes. **Uma nota que julga todos os limiares
de uma vez julga a ordem em que o modelo põe os membros**, e para um modelo cuja saída é uma lista a
percorrer, a ordem é o produto.

Salve isto como `ranking.py`:

```python
"""ranking.py: scores that judge the order of the probabilities, not one cut of them."""
from sklearn.metrics import average_precision_score, roc_auc_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

print(f"ROC AUC            {roc_auc_score(test['lapsed'], test['p']):.3f}   (a coin: 0.5)")
print(f"average precision  {average_precision_score(test['lapsed'], test['p']):.3f}   "
      f"(a coin: {test['lapsed'].mean():.3f}, the share who lapse)")
for n in (100, 300, 530):
    top = test.nlargest(n, "p")
    print(f"of the top {n:3}, lapsed: {top['lapsed'].sum():3} ({top['lapsed'].mean():.0%})")
```

```
ana@dev:~/ml$ python ranking.py
ROC AUC            0.790   (a coin: 0.5)
average precision  0.522   (a coin: 0.169, the share who lapse)
of the top 100, lapsed:  75 (75%)
of the top 300, lapsed: 195 (65%)
of the top 530, lapsed: 263 (50%)
```

Três notas, três perguntas.

**ROC AUC, 0,790**, é a que a lição 3 usou: escolha um membro que se afastou e um que ficou, e ela é
a chance de o modelo pôr o que se afastou mais alto. Uma moeda tira 0,5, qualquer que seja a fração
de membros que se afasta, o que torna a AUC fácil de comparar entre conjuntos de dados e também cega
para o quão rara é a classe positiva.

**Precisão média (*average precision*), 0,522**, é a área sob a curva de precisão e revocação: a
precisão tirada em média em cada ponto em que a revocação sobe. A moeda dela não é 0,5, e sim a
fração que se afasta, **0,169**, porque um modelo que aponta ao acaso tem precisão igual a essa
fração em todo limiar. A distância de 0,169 a 0,522 é o ganho real do modelo sobre o chute, e é a
nota que mantém desfechos raros honestos.

**Precisão em k** responde exatamente à pergunta do orçamento. Dos cem membros de que o modelo tem
mais certeza, 75 se afastaram; dos trezentos primeiros, 195; dos 530 primeiros, tantos quantos de
fato se afastaram, 263, então metade. Se o marketing pode mandar trezentos vouchers, **195 deles
chegam a alguém que estava indo embora**, e essa é a frase a escrever no relatório.

| a pergunta | a nota |
| --- | --- |
| o modelo ordena bem os membros, em geral? | ROC AUC |
| quão melhor que o acaso ele é para achar um desfecho raro? | precisão média, ao lado da taxa de base |
| quão boa é a lista em que podemos agir? | precisão em k, com k o orçamento |
