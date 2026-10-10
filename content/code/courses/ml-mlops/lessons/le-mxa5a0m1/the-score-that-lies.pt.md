---
title: A nota que mente
version: 1
---

**Um modelo avaliado nas linhas com que aprendeu está sendo perguntado se se lembra delas**, o que é
uma pergunta diferente de se aprendeu alguma coisa. Um modelo flexível o bastante consegue lembrar
cada linha, e então tira nota perfeita nelas e vai mal em todo o resto.

O programa abaixo torna isso visível com uma **árvore de decisão**, um modelo que divide os membros
de novo e de novo por um atributo de cada vez ("recência acima de 120 dias?", depois "menos de três
visitas?") até cada folha guardar membros com quase um só desfecho. `max_depth` limita quantas
perguntas de profundidade ela pode fazer. Salve-o como `overfit.py`:

```python
"""overfit.py: a tree scored on the rows it learned from, and on rows it did not."""
from sklearn.metrics import roc_auc_score
from sklearn.tree import DecisionTreeClassifier

import features

X = features.NUMERIC
train = features.build("2025-08-31")
valid = features.build("2025-09-30")


def auc(model, rows):
    return roc_auc_score(rows["lapsed"], model.predict_proba(rows[X])[:, 1])


print("depth  train AUC  validation AUC")
scores = {}
for depth in (2, 4, 6, 8, 12, None):
    tree = DecisionTreeClassifier(max_depth=depth, random_state=0).fit(train[X], train["lapsed"])
    scores[depth] = auc(tree, valid)
    print(f"{str(depth):>5}  {auc(tree, train):9.3f}  {scores[depth]:14.3f}")

best = max(scores, key=scores.get)                       # chosen on validation only
tree = DecisionTreeClassifier(max_depth=best, random_state=0).fit(train[X], train["lapsed"])
test = features.build("2025-11-30")                      # opened once, at the end
print(f"chosen depth {best}; test AUC {auc(tree, test):.3f}")
```

A nota desta lição é a **AUC**, um número de 0,5 a 1 que responde uma pergunta: escolha ao acaso um
membro que se afastou e um que ficou, e com que frequência o modelo dá ao que se afastou a
probabilidade maior? 0,5 é uma moeda, 1 é uma ordenação perfeita. A lição 4 é sobre notas e explica
por que esta combina com a pergunta do afastamento melhor que a mais óbvia.

```
ana@dev:~/ml$ python overfit.py
depth  train AUC  validation AUC
    2      0.734           0.719
    4      0.795           0.762
    6      0.831           0.751
    8      0.871           0.723
   12      0.957           0.662
 None      1.000           0.636
chosen depth 4; test AUC 0.769
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-overfit\" aria-label=\"AUC de uma árvore de decisão contra a sua profundidade máxima: 2, 4, 6, 8, 12 e sem limite. Nas linhas de treino ela sobe sem parar: 0,734, 0,795, 0,831, 0,871, 0,957, 1,000. Nas linhas de validação ela sobe até 0,762 na profundidade 4 e depois cai: 0,751, 0,723, 0,662, 0,636.\"><path d=\"M80.0 40.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M80.0 182.5 L560.0 182.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 182.5 L80.0 182.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"182.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,7</text><path d=\"M80.0 135.0 L560.0 135.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 135.0 L80.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><path d=\"M80.0 87.5 L560.0 87.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 87.5 L80.0 87.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,9</text><path d=\"M80.0 40.0 L560.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,0</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">AUC</text><path d=\"M80.0 230.0 L560.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"120.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"200.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"280.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"360.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"440.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><text x=\"520.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem limite</text><text x=\"320.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">profundidade máxima da árvore</text><path d=\"M120.0 166.3 L200.0 137.4 L280.0 120.3 L360.0 101.3 L440.0 60.4 L520.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"120.0\" cy=\"166.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"200.0\" cy=\"137.4\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"280.0\" cy=\"120.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"360.0\" cy=\"101.3\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"440.0\" cy=\"60.4\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><circle cx=\"520.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--paper-dim)\"></circle><path d=\"M120.0 173.5 L200.0 153.0 L280.0 158.3 L360.0 171.6 L440.0 200.5 L520.0 212.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"120.0\" cy=\"173.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"200.0\" cy=\"153.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"280.0\" cy=\"158.3\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"360.0\" cy=\"171.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"440.0\" cy=\"200.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"520.0\" cy=\"212.9\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">melhor na validação</text><path d=\"M580.0 70.0 L610.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"618.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linhas de treino</text><path d=\"M580.0 96.0 L610.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"618.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linhas de validação</text></svg>", "caption": "Quanto mais funda a árvore, melhor ela lembra as linhas com que aprendeu e pior se sai no mês seguinte. A distância entre as linhas é o sobreajuste.", "same": ["AUC"]}
```

**Leia as duas colunas de cima para baixo.** Nas linhas em que treinou, a árvore melhora a cada
nível, até que sem limite tira 1,000: decorou todas elas. Nas linhas de validação, os membros como
estavam um mês depois, ela melhora até a profundidade 4 e depois piora a cada passo, até 0,636 para
a árvore que "aprendeu" tudo. A distância entre as colunas se chama **sobreajuste** (*overfitting*):
o que o modelo aprendeu sobre estes membros em particular e não sobre membros.

A última linha usa um terceiro conjunto de linhas, uma vez só, e a próxima seção é sobre o porquê.
