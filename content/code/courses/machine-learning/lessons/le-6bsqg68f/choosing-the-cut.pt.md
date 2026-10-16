---
title: De onde vem o corte
version: 1
---

Há dois jeitos honestos de escolher um corte antes de conhecer os meses de teste, e um desonesto que
parece o mais cuidadoso de todos.

**Pelos custos.** Se as chances forem calibradas, a linha de equilíbrio é o melhor corte por
construção, e não precisa de dado nenhum: 40 / 144. Ela só se move quando os números do negócio se
movem.

**Por um período de validação.** Ajuste o modelo nos meses mais antigos, meça um trecho posterior que
ele não viu e escolha o corte que deu mais dinheiro ali. Isso não precisa de suposição sobre
calibração, e paga por isso com ruído: a resposta vem de algumas centenas de pessoas que saíram.

**Pelos meses de teste**, que é o desonesto. O melhor corte nos meses que estão sendo relatados é o
melhor corte por definição, e citar o dinheiro que ele fez é citar um número que ninguém poderia ter
ganhado.

O programa compara os três. Salve isto como `choose_cut.py`:

```python
# choose_cut.py
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
early = train[train["snapshot"] < "2025-04-01"]
late = train[train["snapshot"] >= "2025-04-01"]
cuts = np.round(np.arange(0.05, 0.51, 0.01), 2)

def chances(learn, score):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    return model.predict_proba(score[features])[:, 1]

def best(rows, chance):
    values = [net_value(rows["churned"], chance >= cut) for cut in cuts]
    return cuts[np.argmax(values)], max(values)

chosen, value = best(late, chances(early, late))
print(f"best cut on April to June: {chosen:.2f}, worth R$ {value:,.0f} there")

chance = chances(train, test)
for name, cut in [("chosen on April to June", chosen), ("break-even, from the costs", CREDIT / (SAVED * KEPT))]:
    print(f"test months, {name:27} {cut:.3f}  R$ {net_value(test['churned'], chance >= cut):,.0f}")
hindsight, value = best(test, chance)
print(f"test months, {'best in hindsight':27} {hindsight:.3f}  R$ {value:,.0f}")
```

```
ana@lab:~/ml$ python choose_cut.py
best cut on April to June: 0.33, worth R$ 7,256 there
test months, chosen on April to June     0.330  R$ 17,984
test months, break-even, from the costs  0.278  R$ 21,672
test months, best in hindsight           0.230  R$ 23,832
```

O período de validação escolheu 0,33, e nos meses de teste esse corte fez R$ 17.984, **R$ 3.688 a
menos que o corte dos custos**. Três meses com 559 pessoas que saíram não bastam para achar o topo de
um morro plano: um punhado de gente de um lado ou do outro de um corte move o melhor ponto em vários
centésimos. O corte dos custos não tinha esse ruído, porque não foi estimado.

A visão de depois diz 0,23 e R$ 23.832. **Esse número é o teto deste modelo nestes meses, e não é um
resultado.** Os R$ 2.160 entre ele e o corte de equilíbrio são o que o aumento de preço custou a um
modelo que não tinha como saber dele.

Para a Feira em Casa, então, a regra que a Ana escreve no enquadramento da aula 1 é: **o corte é a
linha de equilíbrio, calculada com os números do negócio, num modelo que o `reliability.py` diz estar
calibrado.** A busca na validação vale como conferência. Se ela cair longe da linha de equilíbrio, as
chances provavelmente não são honestas, e a seção anterior diz o que fazer.
