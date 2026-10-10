---
title: Poda, e os outros freios
version: 1
---

O `max_depth` para todo galho na mesma profundidade, o que é grosseiro: alguns galhos têm linhas de
sobra para descer mais com proveito e outros ficaram sem evidência bem antes. O scikit-learn tem
freios mais finos, e dois deles fazem quase todo o trabalho:

- **`min_samples_leaf`**: nenhuma folha pode ter menos que esse número de linhas de treino. Um galho
  para quando dividir mais deixaria uma folha pequena demais para confiar, seja qual for a
  profundidade.
- **`ccp_alpha`**: **poda por custo-complexidade**. A árvore cresce inteira e depois os galhos que
  acrescentam menos pureza por folha a mais são cortados, um a um, até o que sobra valer o seu
  tamanho. Valores maiores podam mais.

Salve isto como `pruning.py`:

```python
# pruning.py
from sklearn.tree import DecisionTreeClassifier

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
cut = CREDIT / (SAVED * KEPT)
for name, settings in [("no limits", {}),
                       ("min_samples_leaf=200", {"min_samples_leaf": 200}),
                       ("ccp_alpha=0.0003", {"ccp_alpha": 0.0003})]:
    tree = DecisionTreeClassifier(random_state=0, **settings).fit(train[NUMERIC], train["churned"])
    send = tree.predict_proba(test[NUMERIC])[:, 1] >= cut
    print(f"{name:22} {tree.get_n_leaves():5,} leaves, depth {tree.get_depth():2}, "
          f"test R$ {net_value(test['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python pruning.py
no limits              3,328 leaves, depth 30, test R$  -23,856
min_samples_leaf=200     139 leaves, depth 17, test R$   15,960
ccp_alpha=0.0003          10 leaves, depth  4, test R$   11,800
```

**Os dois freios transformam prejuízo em lucro.** Sem limites, 3.328 folhas perdem R$ 23.856. Exigir
200 linhas por folha cresce uma árvore de 139 folhas, com 17 níveis em alguns pontos, e faz
**R$ 15.960**: funda onde os dados são abundantes, rasa onde não são. Podar com `ccp_alpha=0.0003`
deixa só 10 folhas, quatro níveis, e faz R$ 11.800 com uma árvore pequena o bastante para ler.

Nenhum freio foi ajustado; os valores foram escolhidos para mostrar o que cada um faz, e a aula 9 os
ajusta direito. A lição aqui é a forma da troca. **Uma árvore sozinha é pequena e legível ou grande e
precisa, e nunca tão precisa quanto as alternativas**: a regressão logística da aula 5 fez R$ 16.424
com 22 pesos, e o modelo de boosting da aula 2 fez R$ 21.672. A aula 8 trata de cultivar muitas
árvores em vez de uma, que é como as árvores viraram os modelos que costumam vencer em tabelas.
