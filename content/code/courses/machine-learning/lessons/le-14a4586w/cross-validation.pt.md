---
title: Validação cruzada, e quanto uma nota se mexe
version: 1
---

A **validação cruzada em k partes** (*k-fold*) corta as linhas de treino em k partes, chamadas
*folds*. Ela ajusta o modelo k vezes, cada vez em k − 1 partes, e mede na parte que ficou de fora.
Cada linha é usada para medir exatamente uma vez e para treinar k − 1 vezes, e o resultado não é uma
nota, são k notas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 230\" role=\"img\" data-fig=\"l03-folds\" aria-label=\"Cinco linhas, uma por ajuste. Cada linha são os dados de treino cortados em cinco partes; em cada linha uma parte diferente é medida e as outras quatro servem para ajustar.\"><text x=\"320.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">as linhas de treino, em cinco partes</text><text x=\"106.0\" y=\"55.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ajuste 1</text><rect x=\"122.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">medida</text><rect x=\"202.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"40.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nota 1</text><text x=\"106.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ajuste 2</text><rect x=\"122.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">medida</text><rect x=\"282.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"78.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nota 2</text><text x=\"106.0\" y=\"131.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ajuste 3</text><rect x=\"122.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">medida</text><rect x=\"362.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"116.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nota 3</text><text x=\"106.0\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ajuste 4</text><rect x=\"122.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">medida</text><rect x=\"442.0\" y=\"154.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nota 4</text><text x=\"106.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ajuste 5</text><rect x=\"122.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"282.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"362.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"442.0\" y=\"192.0\" width=\"76.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">medida</text><text x=\"534.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nota 5</text></svg>", "caption": "Toda linha é medida uma vez e usada no ajuste quatro vezes. Saem cinco notas, e a dispersão delas é a sorte do corte."}
```

As k notas são o ponto. A média delas é uma estimativa melhor que qualquer nota isolada, e a
**dispersão delas é uma medida da sorte**: o quanto a nota se mexe quando só muda a escolha das
linhas. O scikit-learn faz as partes; o laço que as usa é curto o bastante para ser escrito por
extenso, e mostra exatamente o que é ajustado em quê. Salve isto como `folds.py`:

```python
# folds.py
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import GroupKFold, KFold, StratifiedKFold

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, _ = by_time(load_churn())
X, y = train[NUMERIC + CATEGORICAL], train["churned"]
cut = CREDIT / (SAVED * KEPT)


def per_fold(splitter, groups=None):
    values = []
    for fit_rows, check_rows in splitter.split(X, y, groups):
        model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
        model.fit(X.iloc[fit_rows], y.iloc[fit_rows])
        send = model.predict_proba(X.iloc[check_rows])[:, 1] >= cut
        values.append(net_value(y.iloc[check_rows], send) / len(check_rows) * 1000)
    return np.array(values)


for name, splitter, groups in [
        ("KFold", KFold(5, shuffle=True, random_state=0), None),
        ("StratifiedKFold", StratifiedKFold(5, shuffle=True, random_state=0), None),
        ("GroupKFold", GroupKFold(5), train["customer_id"])]:
    v = per_fold(splitter, groups)
    print(f"{name:16} R$ per 1,000 rows: " + "  ".join(f"{x:6.0f}" for x in v)
          + f"   mean {v.mean():6.0f}  sd {v.std():5.0f}")
```

```
ana@lab:~/ml$ python folds.py
KFold            R$ per 1,000 rows:   1044     972     687     775     641   mean    824  sd   158
StratifiedKFold  R$ per 1,000 rows:    597     751     994     764     686   mean    758  sd   132
GroupKFold       R$ per 1,000 rows:    845    1116     684     700     589   mean    787  sd   184
```

O valor líquido é dividido pelo tamanho de cada parte para que partes de tamanhos diferentes se
comparem, e por isso ele aparece em reais por mil linhas. Três coisas nele.

**O mesmo modelo em cinco partes vai de uns R$ 640 a R$ 1.040 por mil linhas.** Nada mudou entre
elas a não ser quais assinantes caíram onde. Qualquer comparação entre dois modelos que diferem menos
que uma dispersão dessas é uma comparação de sorte, o ponto que a aula 2 fez com o bootstrap, feito
aqui pelo outro lado.

**Cada parte é ajustada do zero.** Dentro do laço um modelo novo é criado toda vez. Reaproveitar um
modelo ajustado entre as partes o mediria em linhas de que ele aprendeu, que é o erro da seção
anterior escondido dentro de um laço.

**As três linhas de resultado usam três jeitos de cortar**, e as duas próximas seções tratam do
segundo e do terceiro.

## Quantas partes

Cinco ou dez é o costume, e a troca é fácil de dizer. Mais partes quer dizer que cada modelo aprende
com mais linhas, então a estimativa fica mais perto do que o modelo final vai fazer, e quer dizer
mais ajustes. Cinco ajustes de um modelo que leva um segundo não custam nada; cinco ajustes de um que
leva uma hora são um dia de trabalho. Com 38.628 linhas e um modelo que se ajusta em cerca de um
segundo, cinco bastam.
