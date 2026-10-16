---
title: Acurácia, e por que ela esconde a classe rara
version: 1
---

A **acurácia** é a parte das linhas que o modelo acertou: os verdadeiros positivos e os verdadeiros
negativos sobre tudo. É a primeira métrica que qualquer pessoa usa, e nestes dados ela é quase inútil.
Salve isto como `metrics.py`; ele calcula as métricas desta aula em cinco cortes, ao lado do valor
líquido:

```python
# metrics.py
import pandas as pd
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score

from feira import CREDIT, KEPT, SAVED, net_value

scores = pd.read_csv("scores.csv")
y = scores["churned"]
print("cut    accuracy  precision  recall    F1     net value")
for cut in [0.5, 0.4, CREDIT / (SAVED * KEPT), 0.2, 0.1]:
    said = scores["chance"] >= cut
    print(f"{cut:<6.3f} {accuracy_score(y, said):8.3f} {precision_score(y, said):10.3f} "
          f"{recall_score(y, said):7.3f} {f1_score(y, said):6.3f}  R$ {net_value(y, said):8,.0f}")
```

```
ana@lab:~/ml$ python metrics.py
cut    accuracy  precision  recall    F1     net value
0.500     0.940      0.603   0.079  0.139  R$    9,088
0.400     0.941      0.589   0.131  0.215  R$   14,840
0.278     0.938      0.489   0.235  0.317  R$   21,672
0.200     0.931      0.417   0.328  0.367  R$   23,448
0.100     0.892      0.283   0.493  0.359  R$    1,848
```

Leia a coluna de acurácia. **Entre 0,892 e 0,941, em todo corte**, e mais alta em 0,4, onde o modelo
faz R$ 14.840. O corte que mais dá dinheiro destes cinco, 0,2, tem acurácia *menor* que o que quase não
manda crédito a ninguém. A acurácia e o negócio puxam para lados diferentes.

O motivo são os 94% de linhas de quem fica. A acurácia conta toda linha igual, então é dominada pelos
verdadeiros negativos, e o modelo consegue ir bem nela dizendo *fica* para quase todo mundo, que é a
constante da aula 2 de novo, com 0,939. Mandar mais créditos acha mais gente que sai e também faz mais
falsos positivos entre quem fica, e numa classe rara o segundo efeito vence a contagem da acurácia toda
vez.

**A acurácia é uma métrica sensata quando as classes são mais ou menos equilibradas e os dois erros
custam mais ou menos o mesmo.** Nada disso vale aqui, e nada disso vale para a maioria dos problemas em
que machine learning compensa: fraude, doença, churn, defeitos. Quando o que se procura é raro, as
métricas que vale ler são as que deixam os verdadeiros negativos de fora, que é o que as duas próximas
fazem.
