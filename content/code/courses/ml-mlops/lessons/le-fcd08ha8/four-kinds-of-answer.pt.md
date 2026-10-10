---
title: Quatro tipos de resposta
version: 1
---

Um modelo de sim ou não pode acertar de dois jeitos e errar de dois jeitos, e eles custam valores
diferentes. Arrumados numa tabela, eles se chamam **matriz de confusão**. Salve isto como
`confusion.py`:

```python
"""confusion.py: the four kinds of answer, at the default threshold of 0.5."""
from sklearn.metrics import confusion_matrix, precision_score, recall_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
predicted = lapse.predict(test[COLUMNS])

(tn, fp), (fn, tp) = confusion_matrix(test["lapsed"], predicted)
print(f"                 predicted stays  predicted lapses")
print(f"actually stayed  {tn:15}  {fp:16}")
print(f"actually lapsed  {fn:15}  {tp:16}")
print(f"precision {precision_score(test['lapsed'], predicted):.3f}  "
      f"recall {recall_score(test['lapsed'], predicted):.3f}")
```

```
ana@dev:~/ml$ python confusion.py
                 predicted stays  predicted lapses
actually stayed             2522                78
actually lapsed              360               170
precision 0.685  recall 0.321
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l04-confusion\" aria-label=\"Uma grade de dois por dois. Linhas: de fato ficou, de fato se afastou. Colunas: previsto fica, previsto se afasta. Ficou e previsto fica: 2.522 verdadeiros negativos. Ficou mas previsto se afasta: 78 alarmes falsos. Se afastou mas previsto fica: 360 perdidos. Se afastou e previsto se afasta: 170 acertos.\"><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">previsto fica</text><text x=\"550.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">previsto se afasta</text><text x=\"236.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">de fato ficou</text><rect x=\"250.0\" y=\"50.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">2.522</text><text x=\"350.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">verdadeiro negativo</text><rect x=\"450.0\" y=\"50.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">78</text><text x=\"550.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">alarme falso</text><text x=\"236.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">de fato se afastou</text><rect x=\"250.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">360</text><text x=\"350.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">perdido</text><rect x=\"450.0\" y=\"140.0\" width=\"200.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"700\" fill=\"var(--paper)\">170</text><text x=\"550.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">acerto</text></svg>", "caption": "As duas células certas são para onde a acurácia olha. As duas erradas são onde está o negócio, e elas custam valores diferentes."}
```

Cada célula tem um nome que vale saber, porque toda outra nota desta lição é feita a partir delas:

| | o modelo disse fica | o modelo disse se afasta |
| --- | --- | --- |
| **ficou** | **verdadeiro negativo**: 2.522 | **falso positivo**, um alarme falso: 78 |
| **se afastou** | **falso negativo**, um perdido: 360 | **verdadeiro positivo**, um acerto: 170 |

A acurácia são as duas células certas sobre o total: (2.522 + 170) / 3.130. Ela não distingue um
modelo que pega 170 afastamentos de um que não pega nenhum, desde que os perdidos sejam poucos perto
da multidão que ficou.

**O negócio está nas células.** Um alarme falso custa um voucher mandado a alguém que ia voltar de
qualquer jeito. Um perdido custa um membro que foi embora sem ninguém tentar. No limiar padrão de 0,5
este modelo dá 78 alarmes falsos e perde 360 membros, e **se essa é uma boa troca é uma pergunta
sobre dinheiro, não sobre modelos**, que a seção 05 responde com números.
