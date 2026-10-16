---
title: Quando as respostas chegam
version: 1
---

Um mês depois de cada rodada, as respostas do mês existem: no dia 1º de fevereiro já se sabe quem saiu em janeiro. O `churn_2026_labels.csv` as guarda para os três meses, do jeito que o sistema da empresa as
teria entregado, um mês de cada vez. Agora as pontuações podem ser avaliadas, e a avaliação é a mesma de
toda aula: a ordenação se mantém, o nível é honesto, e quanto os créditos renderam. Salve isto como
`labels.py`:

```python
# labels.py
import pandas as pd
from sklearn.metrics import roc_auc_score

from feira import CREDIT, KEPT, SAVED

scores = pd.concat(pd.read_csv(f"scores/2026-0{m}.csv") for m in [1, 2, 3])
labels = pd.read_csv("data/churn_2026_labels.csv")
rows = scores.merge(labels, on=["customer_id", "snapshot"], validate="one_to_one")

for month, g in rows.groupby("snapshot"):
    sent = g[g["credit"]]
    promised = (SAVED * KEPT * sent["chance"] - CREDIT).sum()
    delivered = SAVED * KEPT * sent["churned"].sum() - CREDIT * len(sent)
    print(f"{month[:7]}: chance {g['chance'].mean():.3f}, left {g['churned'].mean():.3f}, "
          f"AUC {roc_auc_score(g['churned'], g['chance']):.3f}, "
          f"value promised R$ {promised:,.0f}, delivered R$ {delivered:,.0f}")
```

O `validate="one_to_one"` faz a junção falhar se um assinante aparecer duas vezes de algum lado, que é um
jeito barato de descobrir no dia que as pontuações e as respostas não descrevem as mesmas pessoas.
**Prometido** é o que as próprias chances do modelo diziam que os créditos renderiam: cada crédito vale
R$ 144 vezes a chance de o assinante estar saindo, menos R$ 40. **Entregue** é o valor líquido da aula 2,
a partir do que aconteceu.

```
ana@lab:~/ml$ python labels.py
2026-01: chance 0.061, left 0.049, AUC 0.810, value promised R$ 3,600, delivered R$ 1,904
2026-02: chance 0.065, left 0.047, AUC 0.808, value promised R$ 4,723, delivered R$ 2,008
2026-03: chance 0.065, left 0.056, AUC 0.788, value promised R$ 4,783, delivered R$ 1,296
```

**A ordenação se manteve.** AUC 0,810 e 0,808, perto do 0,818 que a aula 15 mediu nos meses de teste, e
0,788 em março, um pouco abaixo. As pessoas que o modelo pôs no topo ainda eram, na maior parte, as que
saíram.

**O nível não.** O modelo disse que de 6,1% a 6,5% sairiam, e saíram 4,9%, 4,7% e 5,6%. O efeito
posterior do aumento de preço tinha passado em janeiro, e um modelo ajustado nos meses que o incluíam
continuou esperando por ele. A aula 11 avisou exatamente isso: uma decisão que compara uma chance com um
número fixo herda o erro da chance.

**E os créditos renderam cerca de metade do prometido**, ou menos: R$ 1.904 contra R$ 3.600 em janeiro, R$ 1.296
contra R$ 4.783 em março. Ainda positivo, então o programa ainda valia rodar. Mas uma equipe que
planejasse um orçamento pelo número prometido estaria explicando uma diferença de R$ 7.898 no fim de
março, e a explicação não é "o modelo piorou". É que o modelo ordena as pessoas tão bem quanto antes, e é
pessimista demais sobre quantas delas vão sair. A próxima seção procura onde.
