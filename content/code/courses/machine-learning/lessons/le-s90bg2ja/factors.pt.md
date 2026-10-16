---
title: Gostos escondidos: fatoração de matrizes
version: 1
---

A tabela de semelhanças comparava produtos dois a dois. A **fatoração de matrizes** procura alguns gostos
escondidos que expliquem a tabela inteira de uma vez. Cada cliente recebe alguns números dizendo quanto
tem de cada gosto, e cada produto alguns números dizendo quanto agrada a cada gosto. Multiplicados, os
dois refazem a tabela e preenchem as células vazias com um palpite. Esses palpites são as recomendações.

É a ideia da aula 17 aplicada a outra tabela. O `TruncatedSVD` é um parente próximo da PCA que trabalha numa
tabela de zeros e uns sem centralizá-la, e o `NMF`, fatoração de matrizes não negativa, faz o mesmo mantendo
todo número em zero ou acima, o que deixa os gostos mais fáceis de ler. Salve isto como `factors.py`; ele
refaz a tabela com vários números de gostos e lê a versão NMF com três:

```python
# factors.py
import pandas as pd
from sklearn.decomposition import NMF, TruncatedSVD

from holdout import hit_rate, split

known, hidden = split()
for k in [2, 3, 4, 6]:
    svd = TruncatedSVD(n_components=k, random_state=0).fit(known)
    rebuilt = pd.DataFrame(svd.transform(known) @ svd.components_, index=known.index,
                           columns=known.columns)
    print(f"{k} factors: finds the hidden add-on {hit_rate(rebuilt, known, hidden):.1%}")

nmf = NMF(n_components=3, random_state=0, max_iter=500).fit(known)
for i, weights in enumerate(nmf.components_):
    top = pd.Series(weights, index=known.columns).nlargest(6)
    print(f"factor {i}: " + ", ".join(top.index))
```

```
ana@lab:~/ml$ python factors.py
2 factors: finds the hidden add-on 55.8%
3 factors: finds the hidden add-on 69.3%
4 factors: finds the hidden add-on 67.6%
6 factors: finds the hidden add-on 60.7%
factor 0: chilli, garlic, coriander, olive oil, lime, ginger
factor 1: papaya, coffee, honey, jam, yoghurt, granola
factor 2: flour, vanilla, cocoa, butter, oats, yeast
```

**Três fatores acham o adicional escondido 69,3% das vezes**, o melhor resultado da aula. Dois são poucos
para descrever os clientes, e com quatro ou seis os fatores a mais começam a se ajustar às lacunas
específicas destes clientes em vez dos gostos deles, e a taxa de acerto cai de novo: o sobreajuste da aula 3,
num recomendador.

Os fatores do NMF são o motivo de três funcionar. **O fator 0 é cozinha, o fator 1 café da manhã, o fator 2
confeitaria**, as mesmas três cozinhas que o `similar.py` achou, agora como dimensões em que todo cliente tem
uma posição. E eles são o que o `make_data.py` pôs ali: o gerador da aula 1 deu a cada comprador um gosto por
confeitaria, café da manhã e cozinha, mais quatro produtos que todo mundo compra. Como com os grupos da aula
16, uma loja de verdade não teria página nenhuma para conferir; a taxa de acerto e os fatores legíveis são o
que fica no lugar dela.

A fatoração tem um custo que a filtragem por itens não tem: **os fatores de um cliente vêm da linha dele**,
então um cliente novo precisa ser ajustado antes de receber recomendações, e os fatores deixam de se explicar
numa frase. Muitos sistemas em produção usam os dois, fatores para ordenar e semelhanças para dizer por quê.
