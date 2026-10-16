---
title: A coluna que sabe o futuro
version: 1
---

A segunda coluna tem um nome inocente, `days_since_last_order`, e é exatamente o tipo de coluna que
um modelo de cancelamentos deveria ter: quem não pede há semanas está se afastando. Ela passa em
todo teste que uma pessoa pensaria em fazer, menos um: **quando ela foi calculada?**

A resposta está em como o arquivo foi feito: em 1º de janeiro de 2026, quando o `churn.csv` foi
exportado, o sistema calculou os dias desde o último pedido de cada assinante **naquele dia**, e
escreveu o mesmo tipo de número em toda linha, antiga ou nova. Numa linha de julho de 2024 cujo
assinante saiu depois, ela conta os dias do último pedido dele até janeiro de 2026. A primeiríssima
linha do arquivo, C00001, que o `head` imprimiu na aula 1, diz 536. Em 1º de julho de 2024, ninguém
poderia saber esse número:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 210\" role=\"img\" data-fig=\"l04-timeline\" aria-label=\"Uma linha do tempo para o C00001, a primeira linha do churn.csv. O retrato e a decisão do crédito são em 1º de julho de 2024; o cancelamento vem em 14 de julho de 2024; a exportação é em 1º de janeiro de 2026. Um colchete do cancelamento à exportação é o que o days_since_last_order contou.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 100.0 L620.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"90.0\" cy=\"100.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"90.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1º jul 2024</text><circle cx=\"190.0\" cy=\"100.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"190.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14 jul 2024</text><circle cx=\"590.0\" cy=\"100.0\" r=\"6\" fill=\"var(--paper)\"></circle><text x=\"590.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1º jan 2026</text><text x=\"76.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">retrato: o crédito é decidido</text><text x=\"220.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cancela: cancel_reason é escrito</text><path d=\"M190.0 90.0 L216.0 54.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o arquivo é exportado</text><path d=\"M190 152 L190 160 L590 160 L590 152\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o que o days_since_last_order contou: 536 dias</text></svg>", "caption": "Tudo à direita do retrato era desconhecido no dia em que o crédito foi decidido, e as duas colunas que vazam moram ali."}
```

O padrão aparece nos dados assim que a coluna é posta ao lado da data. Salve isto como
`subtle.py`:

```python
# subtle.py
import pandas as pd

churn = pd.read_csv("data/churn.csv", parse_dates=["snapshot"])
churn["quarter"] = churn["snapshot"].dt.to_period("Q")
table = churn.pivot_table(index="quarter", columns="churned",
                          values="days_since_last_order", aggfunc="median")
print(table.rename(columns={0: "stayed", 1: "left"}))
```

```
ana@lab:~/ml$ python subtle.py
churned  stayed   left
quarter               
2024Q3     11.0  493.0
2024Q4      8.0  420.0
2025Q1      6.0  317.0
2025Q2      6.0  225.0
2025Q3      5.0  136.0
2025Q4      4.0   40.0
```

**Uma variável legítima não faz isso.** Para quem ficou, a mediana fica em poucos dias em todo
trimestre. Para quem saiu, ela é 493 no terceiro trimestre de 2024 e cai sem parar até 40 no fim de
2025, porque mede a distância da saída de cada um até a data da exportação. A coluna é um relógio que
começou depois do resultado. Agora dê a coluna ao modelo e meça o modelo dos dois jeitos que a aula 3
comparou. Salve isto como `leak_test.py`:

```python
# leak_test.py
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

churn = load_churn()
cut = CREDIT / (SAVED * KEPT)
splits = {"random": train_test_split(churn, test_size=0.3, random_state=0),
          "by time": by_time(churn)}
for extra in [[], ["days_since_last_order"]]:
    features = NUMERIC + CATEGORICAL + extra
    for name, (learn, check) in splits.items():
        model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
        model.fit(learn[features], learn["churned"])
        chance = model.predict_proba(check[features])[:, 1]
        value = net_value(check["churned"], chance >= cut) / len(check) * 1000
        label = "with the column" if extra else "without it"
        print(f"{label:16} {name:8} AUC {roc_auc_score(check['churned'], chance):.3f}"
              f"   R$ {value:5.0f} per 1,000 rows")
```

```
ana@lab:~/ml$ python leak_test.py
without it       random   AUC 0.797   R$   933 per 1,000 rows
without it       by time  AUC 0.804   R$   893 per 1,000 rows
with the column  random   AUC 0.958   R$  2422 per 1,000 rows
with the column  by time  AUC 0.500   R$     0 per 1,000 rows
```

A coluna AUC é uma nota que a aula 10 explica direito; por ora, leia **1,0 como perfeito e 0,5 como
uma moeda**. Com a coluna, numa divisão ao acaso, o modelo tira **0,958** e vale **R$ 2.422 por mil
linhas**, duas vezes e meia o modelo honesto. Esse é o número que faz um modelo ser aprovado. Com a
mesma coluna e uma divisão por tempo, ele tira 0,500 e vale **R$ 0**: não manda crédito nenhum,
porque nos meses de teste os números de quem sai são pequenos e o modelo aprendeu que os números de
quem sai são grandes.

A divisão por tempo expôs este vazamento, e isso foi sorte, não garantia. Aconteceu porque a
distorção da coluna muda com a data. Uma coluna calculada a partir do futuro de um jeito que não
deriva passaria pela divisão por tempo e só falharia em produção, onde o valor é calculado no dia 1º
e não se parece em nada com o que o modelo aprendeu.

## O conserto

Calcule a coluna **na data do retrato**: dias do último pedido antes do retrato até o próprio
retrato. É outro número, é legítimo, e precisa vir do histórico de pedidos e não da exportação. No
`churn_2026.csv`, que o sistema escreve no dia 1º de cada mês como o modelo vai vê-lo, é isso que a
coluna contém, e a aula 22 o usa.
