---
title: Um modelo, medido contra a mesma barra
version: 1
---

Esta seção ajusta um modelo e não o explica. O algoritmo é gradient boosting, assunto da aula 8. Ele
é usado aqui porque aceita os dados como o `load_churn` os deixa, com lacunas e colunas de texto, e
assim o programa fica curto. **Trate-o como uma caixa** por enquanto: linhas entram, uma chance de
sair sai.

A única decisão deste programa é onde cortar essa chance. Um crédito se paga quando a chance de sair
passa de 40 ÷ (0,3 × 480), então é ali que ele manda. A aula 11 trata dessa linha; aqui ela é
simplesmente o ponto de equilíbrio da tabela da aula 1. Salve isto como `first_model.py`:

```python
# first_model.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL

model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
chance = model.predict_proba(test[features])[:, 1]

cut = CREDIT / (SAVED * KEPT)      # where a credit starts to pay for itself
send = chance >= cut
print(f"send when the chance of leaving is at least {cut:.3f}")
print(f"on the test months: {send.sum():,} credits, "
      f"{(send & (test['churned'] == 1)).sum()} to leavers, "
      f"net value R$ {net_value(test['churned'], send):,.0f}")
test.assign(chance=chance).to_csv("first_model_scores.csv", index=False)
```

```
ana@lab:~/ml$ python first_model.py
send when the chance of leaving is at least 0.278
on the test months: 711 credits, 348 to leavers, net value R$ 21,672
```

**R$ 21.672 em seis meses**, onde a melhor regra perdeu R$ 576 e não mandar a ninguém não ganhou
nada. 348 dos 711 créditos foram para quem estava saindo, quase metade, contra mais ou menos um
quarto na regra. A última linha salva cada linha de teste com a sua chance, para a próxima seção
perguntar sobre a diferença sem ajustar o modelo de novo.

## A que distância do teto

A aula 1 pôs preço num modelo perfeito: um crédito para cada pessoa que sai e para mais ninguém.
Nestes seis meses são 1.484 pessoas a R$ 104 cada, **R$ 154.336**. O modelo fica com uns 14% disso:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 200\" role=\"img\" data-fig=\"l02-ceiling\" aria-label=\"Barras horizontais do valor líquido nos seis meses de teste: não mandar a ninguém R$ 0, a melhor regra −R$ 576, o primeiro modelo R$ 21.672 e um modelo perfeito R$ 154.336.\"><path d=\"M230.0 22.0 L230.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"218.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">não mandar a ninguém</text><text x=\"238.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 0</text><text x=\"218.0\" y=\"81.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a melhor regra</text><rect x=\"228.8\" y=\"70.0\" width=\"1.2\" height=\"22.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−R$ 576</text><text x=\"218.0\" y=\"121.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o primeiro modelo</text><rect x=\"230.0\" y=\"110.0\" width=\"46.3\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"284.3\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 21.672</text><text x=\"218.0\" y=\"161.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">perfeito: os 1.484 que saíram</text><rect x=\"230.0\" y=\"150.0\" width=\"330.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"568.0\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 154.336</text></svg>", "caption": "O modelo vale cerca de 14% do que valeria um perfeito, e muito mais do que qualquer coisa mais simples."}
```

As duas metades dessa imagem importam. O modelo é muito melhor que qualquer coisa mais simples, e é
por isso que vale construí-lo. E está longe do perfeito, porque a maioria das pessoas que saem não
dá sinal disso nestas colunas três meses antes. **A linha de base diz se um modelo vale a pena; o
teto diz quanto melhor um modelo poderia ser.** Entre os dois, eles impedem um projeto de desistir
cedo demais ou de polir para sempre.
