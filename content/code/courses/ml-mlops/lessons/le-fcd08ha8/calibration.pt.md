---
title: 0,3 quer dizer 30%?
version: 1
---

Uma ordenação só precisa da ordem das probabilidades. **Tudo o que as multiplica precisa que as
próprias probabilidades estejam certas**: a regra de limiar da seção 05, uma previsão de quantos
membros vão se afastar no próximo trimestre, uma receita esperada perdida. Um modelo cujo 0,3 de fato
quer dizer 30% de chance se chama **calibrado**.

A verificação é simples: agrupe os membros pelo que o modelo disse, e compare a predição média de
cada grupo com a fração que de fato se afastou. Salve isto como `calibration.py`:

```python
"""calibration.py: when the model says 0.3, do 30% lapse?"""
import pandas as pd

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

test["band"] = pd.cut(test["p"], [0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0])
table = test.groupby("band", observed=True).agg(
    members=("p", "size"), said=("p", "mean"), happened=("lapsed", "mean"))
print(table.round(3).to_string())
print(f"all members: said {test['p'].mean():.3f}, happened {test['lapsed'].mean():.3f}")
```

```
ana@dev:~/ml$ python calibration.py
            members   said  happened
band                                
(0.0, 0.1]     1442  0.064     0.061
(0.1, 0.2]      946  0.139     0.127
(0.2, 0.3]      254  0.244     0.280
(0.3, 0.5]      240  0.389     0.338
(0.5, 0.7]      128  0.596     0.625
(0.7, 1.0]      120  0.790     0.750
all members: said 0.176, happened 0.169
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-calibration\" aria-label=\"O que o modelo disse contra o que aconteceu, para seis faixas de membros. Os pontos ficam perto da diagonal: 0,064 dito e 0,061 acontecido, 0,139 e 0,127, 0,244 e 0,280, 0,389 e 0,338, 0,596 e 0,625, 0,790 e 0,750.\"><path d=\"M230.0 30.0 L230.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M226.0 270.0 L230.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M230.0 213.5 L480.0 213.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 213.5 L230.0 213.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"213.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M230.0 157.1 L480.0 157.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 157.1 L230.0 157.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"157.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M230.0 100.6 L480.0 100.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 100.6 L230.0 100.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"100.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M230.0 44.1 L480.0 44.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 44.1 L230.0 44.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"44.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><text x=\"230.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que aconteceu</text><path d=\"M230.0 270.0 L480.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M230.0 270.0 L230.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M288.8 270.0 L288.8 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.8\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M347.6 270.0 L347.6 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"347.6\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M406.5 270.0 L406.5 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"406.5\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M465.3 270.0 L465.3 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"465.3\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8</text><text x=\"355.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o que o modelo disse</text><path d=\"M230.0 270.0 L480.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"412.4\" y=\"49.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calibração perfeita</text><circle cx=\"248.8\" cy=\"252.8\" r=\"9.0\" fill=\"var(--phosphor)\"></circle><circle cx=\"270.9\" cy=\"234.1\" r=\"7.859752908908532\" fill=\"var(--phosphor)\"></circle><circle cx=\"301.8\" cy=\"190.9\" r=\"5.518172509538362\" fill=\"var(--phosphor)\"></circle><circle cx=\"344.4\" cy=\"174.6\" r=\"5.4477904781022275\" fill=\"var(--phosphor)\"></circle><circle cx=\"405.3\" cy=\"93.5\" r=\"4.787613414537261\" fill=\"var(--phosphor)\"></circle><circle cx=\"462.4\" cy=\"58.2\" r=\"4.730849245989947\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "Toda faixa cai perto da diagonal, onde uma predição de 0,3 é seguida por 30% dos membros se afastando. Uma nota de ordenação não vê isso; as probabilidades precisam."}
```

Leia uma linha de cada vez. Os 1.442 membros que receberam 0,1 ou menos ouviram 0,064 em média, e
6,1% se afastaram. Os 120 que ouviram mais de 0,7 tiveram média de 0,790, e 75,0% se afastaram.
**Toda faixa fica a poucos pontos da verdade, e sobre todos os membros o modelo disse 0,176 contra
0,169.** A regressão logística se ajusta fazendo as suas probabilidades baterem com os rótulos de
treino, então ela sai perto de calibrada em dados parecidos com aqueles de onde aprendeu. Outros
algoritmos não fazem essa promessa, e a tabela precisa ser montada para cada modelo em vez de
suposta.

**A calibração também é a nota que quebra primeiro em produção.** Se a fração de membros que se
afastam mudar, como a loja da lição 10 vai ver, a ordem dos membros pode continuar mais ou menos
certa enquanto toda probabilidade erra pelo mesmo tanto. A AUC não perceberia. Esta tabela
perceberia, assim que os rótulos chegassem.
