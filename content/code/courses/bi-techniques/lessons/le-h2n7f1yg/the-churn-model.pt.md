---
title: Um modelo de churn
version: 1
---

**Um modelo de classificação estima, para cada caso, a probabilidade de ele pertencer a uma
categoria.** Aqui o caso é um cliente que ainda está pedindo, e a categoria é "não vai pedir nos
próximos 90 dias". O modelo é a **regressão logística**, o modelo da aula 21 de `statistics`: ele pesa
as entradas, soma, e transforma a soma numa probabilidade entre 0 e 1.

A divisão importa mais que o modelo. Os clientes com que ele aprende são os de 31 de dezembro de 2024,
cujos 90 dias seguintes já são conhecidos; os clientes em que ele é testado são os de 30 de junho de
2025. **Um modelo usado para prever o futuro é testado num futuro**, exatamente como as previsões das
aulas 3 a 5. Dividir os clientes ao acaso deixaria o modelo aprender com clientes cujo comportamento se
sobrepõe no tempo ao dos clientes em que é testado, e relatar uma acurácia que ele não vai ter em uso.

```schooling-example
{"language": "python", "file": "churn_model.py", "parts": [{"code": "import pandas as pd\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.metrics import confusion_matrix\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"]).set_index(\"customer\")\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])"}, {"code": "def snapshot(day):\n    day = pd.Timestamp(day)\n    past = orders[orders[\"date\"] <= day]\n    recent = past[past[\"date\"] > day - pd.Timedelta(days=90)]\n    after = orders[(orders[\"date\"] > day) & (orders[\"date\"] <= day + pd.Timedelta(days=90))]\n    t = pd.DataFrame({\"recency\": (day - past.groupby(\"customer\")[\"date\"].max()).dt.days,\n                      \"orders_90\": recent.groupby(\"customer\").size()}).fillna({\"orders_90\": 0})\n    t = t.join(customers)\n    t[\"tenure\"] = (day - t[\"signup\"]).dt.days\n    t[\"social\"] = (t[\"channel\"] == \"social\").astype(int)\n    t[\"referral\"] = (t[\"channel\"] == \"referral\").astype(int)\n    t[\"weekly\"] = (t[\"plan\"] == \"weekly\").astype(int)\n    t = t[t[\"recency\"] <= 60]\n    t[\"churned\"] = (~t.index.isin(after[\"customer\"])).astype(int)\n    return t", "note": "Tudo o que se sabe de cada cliente num dado dia, e a resposta: churn quer dizer nenhum pedido nos 90 dias seguintes. Só ficam os clientes que pediram nos últimos 60 dias, porque a pergunta é sobre clientes que ainda estão aqui. Canal e plano viram colunas de 0 ou 1, a forma que um modelo consegue usar."}, {"code": "inputs = [\"recency\", \"orders_90\", \"tenure\", \"social\", \"referral\", \"weekly\"]\ntrain, test = snapshot(\"2024-12-31\"), snapshot(\"2025-06-30\")\nmodel = LogisticRegression(max_iter=1000).fit(train[inputs], train[\"churned\"])\ntest[\"risk\"] = model.predict_proba(test[inputs])[:, 1]\ntest.to_csv(\"scored.csv\")", "note": "Aprende com os clientes de 31 de dezembro de 2024, cujos 90 dias seguintes são conhecidos, e pontua os clientes de 30 de junho de 2025: uma divisão no tempo, como nas aulas de previsão. `predict_proba` dá a cada cliente uma probabilidade de churn. As notas ficam salvas para a próxima etapa."}, {"code": "print(f\"train: {len(train):,} customers on 31 Dec 2024, {train['churned'].mean():.1%} churned\")\nprint(f\"test:  {len(test):,} customers on 30 Jun 2025, {test['churned'].mean():.1%} churned\")\nflag = (test[\"risk\"] >= 0.5).astype(int)\ntn, fp, fn, tp = confusion_matrix(test[\"churned\"], flag).ravel()\nprint(f\"\\nat a threshold of 0.5: {tp} churners caught, {fn} missed, {fp} false alarms, {tn} left alone\")\nprint(f\"accuracy {(tp + tn) / len(test):.1%}, precision {tp / (tp + fp):.1%}, recall {tp / (tp + fn):.1%}\")\nprint(f\"predicting 'stays' for everyone: accuracy {1 - test['churned'].mean():.1%}, recall 0.0%\")", "note": "Marca todo cliente com probabilidade de pelo menos 0,5 e conta os quatro resultados possíveis."}], "output": "train: 2,130 customers on 31 Dec 2024, 18.2% churned\ntest:  2,558 customers on 30 Jun 2025, 16.5% churned\n\nat a threshold of 0.5: 204 churners caught, 217 missed, 55 false alarms, 2082 left alone\naccuracy 89.4%, precision 78.8%, recall 48.5%\npredicting 'stays' for everyone: accuracy 83.5%, recall 0.0%"}
```

O modelo aprendeu com 2.130 clientes e foi testado em 2.558, dos quais 16,5% saíram. As quatro
contagens formam a **matriz de confusão**, a tabela de onde se lê todo classificador:

| | previsto sair | previsto ficar |
|---|---|---|
| **saiu** | 204 pegos, verdadeiros positivos | 217 perdidos, falsos negativos |
| **ficou** | 55 alarmes falsos, falsos positivos | 2.082 deixados em paz, verdadeiros negativos |

A próxima etapa lê essa tabela.
