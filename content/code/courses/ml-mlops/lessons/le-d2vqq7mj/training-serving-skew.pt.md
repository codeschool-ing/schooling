---
title: A diferença entre treino e serviço
version: 1
---

Um modelo aprende o que os seus atributos significavam **no código que os calculou para o treino**.
Quando ele é usado, alguém calcula os atributos de novo, muitas vezes outra pessoa, muitas vezes em
outra linguagem, dentro da aplicação que pede a predição. **Se os dois cálculos diferem, o modelo
recebe números que significam algo diferente do que aprendeu**, e nada em lugar nenhum levanta um
erro. Isso é a **diferença entre treino e serviço** (*training-serving skew*), e é o jeito mais comum
de um bom modelo dar errado em silêncio em produção.

Veja como acontece na Ponto Final. O time do site quer uma nota de afastamento na página do membro, e
calcula os atributos no seu próprio serviço. Ele guarda dinheiro em reais, como as telas mostram, e a
fração online como porcentagem. Cada coluna tem o nome certo. Este programa dá os mesmos membros de
teste ao mesmo modelo salvo duas vezes, uma com os atributos deste curso e outra com os deles. Salve-o
como `skew.py`:

```python
"""skew.py: the same model, fed features computed by somebody else's code."""
import joblib
import pandas as pd
from sklearn.metrics import roc_auc_score

from model import COLUMNS
from project import ROOT

model = joblib.load(ROOT / "models/lapse.joblib")
ours = pd.read_csv(ROOT / "data/test.csv")

# the website team's copy of the features: money in reais, shares in percent
theirs = ours.copy()
theirs["spend_180d"] = ours["spend_180d"] / 100
theirs["basket_avg"] = ours["basket_avg"] / 100
theirs["online_share"] = ours["online_share"] * 100


def top_300(rows, p):
    return set(rows.assign(p=p).nlargest(300, "p")["member_id"])


p_ours = model.predict_proba(ours[COLUMNS])[:, 1]
p_theirs = model.predict_proba(theirs[COLUMNS])[:, 1]
for name, p in (("our features", p_ours), ("their features", p_theirs)):
    print(f"{name:15} mean p {p.mean():.3f}  AUC {roc_auc_score(ours['lapsed'], p):.3f}")
shared = top_300(ours, p_ours) & top_300(theirs, p_theirs)
print(f"members in both top-300 lists: {len(shared)}")
print(f"members whose probability moved by more than 0.1: {(abs(p_ours - p_theirs) > 0.1).sum()}")
```

```
ana@dev:~/ml$ python skew.py
our features    mean p 0.177  AUC 0.793
their features  mean p 0.157  AUC 0.770
members in both top-300 lists: 281
members whose probability moved by more than 0.1: 160
```

**O modelo respondeu sobre todos os membros nas duas vezes.** Com os atributos do site a probabilidade
média caiu de 0,177 para 0,157, a AUC caiu de 0,793 para 0,770, 19 dos 300 primeiros membros eram
outras pessoas, e **160 membros tiveram a probabilidade mexida em mais de 0,1.** Cada um desses
números é plausível sozinho; uma probabilidade de 0,157 não parece errada. O scaler dentro do modelo
esperava gasto em centavos, recebeu reais, e encolheu o gasto de cada membro cem vezes, e a fração
online foi para o outro lado.

A defesa não é cuidado, porque todo mundo foi cuidadoso. **É ter uma implementação só dos atributos,
usada tanto pelo treino quanto pelo serviço.** Neste curso essa é o `features.py`, importado por toda
etapa, e a lição 6 o transforma numa feature store que o site consulta em vez de calcular a sua
própria. Onde duas implementações não podem ser evitadas, a segunda melhor defesa é um teste que dá
às duas as mesmas linhas cruas e falha se os atributos delas diferirem.
