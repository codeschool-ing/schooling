---
title: Pureza, e como o melhor corte é escolhido
version: 1
---

"Separa melhor as classes" precisa de um número. A árvore mede o quanto um grupo de linhas está
**misturado**, e escolhe o corte depois do qual as duas metades ficam, em média, menos misturadas. Um
grupo só de quem fica, ou só de quem sai, é perfeitamente **puro**. Um grupo meio a meio é o mais
misturado que duas classes conseguem ser.

A medida de costume é a **impureza de Gini**: a chance de duas linhas sorteadas do grupo, com
reposição, serem de classes diferentes. Com uma parte `p` de quem sai, ela é `1 − p² − (1 − p)²`, que
é 0 num grupo puro e 0,5 em meio a meio. A outra comum é a **entropia**, `−p log₂ p − (1 − p) log₂
(1 − p)`, da teoria da informação, que vai de 0 a 1 e quase sempre escolhe os mesmos cortes.

A qualidade de um corte é o **ganho**: a impureza antes, menos a impureza das duas metades ponderada
pelo tamanho delas. Aqui está o cálculo para três cortes candidatos nos meses de treino, feito à mão.
Salve isto como `purity.py`:

```python
# purity.py
import numpy as np

from feira import by_time, load_churn

train, _ = by_time(load_churn())
y = train["churned"].to_numpy()


def gini(labels):
    p = labels.mean()
    return 1 - p**2 - (1 - p)**2


def entropy(labels):
    p = labels.mean()
    return -sum(q * np.log2(q) for q in (p, 1 - p) if q > 0)


print(f"all {len(y):,} rows: leavers {y.mean():.3f}  gini {gini(y):.4f}  entropy {entropy(y):.4f}")
for name, mask in [("rating_90d <= 3.59", train["rating_90d"] <= 3.59),
                   ("skips_90d >= 3", train["skips_90d"] >= 3),
                   ("age <= 30", train["age"] <= 30)]:
    left, right = y[mask.to_numpy()], y[~mask.to_numpy()]
    after = (len(left) * gini(left) + len(right) * gini(right)) / len(y)
    print(f"{name:20} {len(left):6,} rows at {left.mean():.3f}, {len(right):6,} at {right.mean():.3f}"
          f"  gini after {after:.4f}  gain {gini(y) - after:.4f}")
```

```
ana@lab:~/ml$ python purity.py
all 38,628 rows: leavers 0.057  gini 0.1075  entropy 0.3153
rating_90d <= 3.59    3,172 rows at 0.271, 35,456 at 0.038  gini after 0.0992  gain 0.0082
skips_90d >= 3        2,355 rows at 0.183, 36,273 at 0.049  gini after 0.1054  gain 0.0020
age <= 30             9,384 rows at 0.061, 29,244 at 0.056  gini after 0.1075  gain 0.0000
```

**O corte da avaliação vence com folga.** Ele manda 3.172 linhas para um lado em que 27,1% saem e
mantém as outras 35.456 em 3,8%, e a impureza ponderada cai de 0,1075 para 0,0992. O corte dos pulos
acha um grupo menor e menos extremo e ganha um quarto disso. O corte da idade não separa nada: 6,1%
contra 5,6% deixa a impureza onde estava, até a quarta casa decimal.

A árvore faz exatamente isso, para toda coluna e todo limiar possível, e fica com o melhor. Duas
consequências vêm de como a escolha é feita:

- **Colunas com muitos cortes possíveis ganham mais chances.** Uma coluna com milhares de valores
  distintos oferece milhares de limiares e pode achar um corte que parece bom por sorte. A aula 19
  mostra como isso enviesa a importância que uma árvore relata.
- **Uma árvore liga para a ordem, não para a unidade.** `rating_90d <= 3.6` é o mesmo corte seja a
  avaliação medida em estrelas ou em centésimos de estrela. Padronizar, que as aulas 5 e 6 exigiam,
  não faz diferença nenhuma para uma árvore.
