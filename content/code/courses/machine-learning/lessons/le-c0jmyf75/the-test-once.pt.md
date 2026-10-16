---
title: O teste, uma vez, e o que ele diz
version: 1
---

Três buscas, cada uma anunciando a sua melhor nota nos meses de validação. **Essas melhores notas são
otimistas**, todas, pelo motivo que a aula 2 deu sobre a melhor de cinco regras: o vencedor de uma
busca é em parte o ajuste que era melhor e em parte o que teve mais sorte naqueles três meses. Quanto
mais ajustes uma busca testa, mais a melhor nota dela deve à sorte. O único número honesto para o
ajuste escolhido vem de linhas que não tiveram papel nenhum na escolha.

Então o ajuste escolhido, o da busca bayesiana, é ajustado uma vez nos doze meses de treino e medido
uma vez nos seis meses de teste, ao lado dos padrões, com o bootstrap da aula 2 na diferença. Salve
isto como `test_once.py`:

```python
# test_once.py
import numpy as np

from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value
from tuning import FEATURES, booster

train, test = by_time(load_churn())
models = {"defaults": booster(),
          "tuned": booster(learning_rate=0.124, max_leaf_nodes=4, max_iter=150)}
send = {}
for name, model in models.items():
    model.fit(train[FEATURES], train["churned"])
    send[name] = model.predict_proba(test[FEATURES])[:, 1] >= CREDIT / (SAVED * KEPT)
    print(f"{name:8} R$ {net_value(test['churned'], send[name]):,.0f} on the test months")

rng = np.random.default_rng(0)
rows = test.groupby("customer_id").indices
people = list(rows)
y = test["churned"].to_numpy()
gaps = []
for _ in range(1000):
    idx = np.concatenate([rows[people[i]] for i in rng.choice(len(people), len(people))])
    gaps.append(net_value(y[idx], send["tuned"][idx]) - net_value(y[idx], send["defaults"][idx]))
low, high = np.percentile(gaps, [2.5, 97.5])
print(f"tuned minus defaults: 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}")
```

```
ana@lab:~/ml$ python test_once.py
defaults R$ 21,248 on the test months
tuned    R$ 22,464 on the test months
tuned minus defaults: 95% of resamples between R$ -1,001 and R$ 3,457
```

**O modelo otimizado faz R$ 22.464 contra R$ 21.248 dos padrões: R$ 1.216 a mais em seis meses.** Os
padrões aqui são os do `booster()`, com a parada antecipada desligada, e é por isso que fazem R$ 21.248 e
não os R$ 21.672 da aula 2. Nos
meses de validação a diferença parecia maior, R$ 846 contra R$ 610 por mil linhas, o que seria mais de
R$ 5.000 nas 24.257 linhas do teste. Parte disso era a sorte da busca, e ela ficou para trás.

E o intervalo da diferença vai **de −R$ 1.001 a R$ 3.457**. Ele cruza o zero. Nestes dados, otimizar
provavelmente ajuda um pouco, e o teste não consegue descartar que não ajude nada. É a situação que a
aula 2 descreveu: um modelo que supera outro por menos que o ruído da medição.

Isso não é motivo para pular a otimização. É motivo para **relatá-la com honestidade**: o modelo
otimizado é a melhor aposta, por uns mil reais por semestre, com incerteza larga. E é motivo para
parar de otimizar aqui. Outra busca, nos mesmos três meses de validação, correria atrás de ganhos
menores por meio de ainda mais sorte.

## Validação cruzada aninhada

A pergunta *quão bom é um modelo cujos ajustes foram otimizados?* também pode ser respondida sem um
teste separado, **aninhando**: uma validação cruzada de fora e, dentro de cada parte de treino de fora,
uma busca completa com as suas próprias partes de dentro. A nota de fora mede então o procedimento
inteiro, busca incluída, em linhas que a busca nunca viu. Ela custa o número de partes de fora vezes o
custo de uma busca, e é a ferramenta certa quando há dados de menos para separar um teste. Com seis
meses guardados, a Ana não precisa dela.
