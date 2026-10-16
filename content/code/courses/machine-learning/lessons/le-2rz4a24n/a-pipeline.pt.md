---
title: O modelo de churn como um objeto
version: 1
---

A melhor regressão logística da aula 14 tem três etapas: acrescentar as sete colunas, preparar números e
palavras de jeitos diferentes, ajustar o modelo. Como pipeline ela mora num arquivo só, que todo
programa seguinte importa, do jeito que `feira.py` e `tuning.py` são importados. Salve isto como
`churn_model.py`:

```schooling-example
{
  "language": "python",
  "file": "churn_model.py",
  "parts": [
    {
      "code": "# churn_model.py\n\"\"\"Lesson 14's logistic regression, as one object that can be fitted and used anywhere.\"\"\"\nfrom sklearn.compose import ColumnTransformer\nfrom sklearn.impute import SimpleImputer\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.pipeline import Pipeline, make_pipeline\nfrom sklearn.preprocessing import FunctionTransformer, OneHotEncoder, StandardScaler\n\nfrom feira import CATEGORICAL, NUMERIC\n",
      "note": "O terceiro arquivo compartilhado do curso, depois do `feira.py` e do `tuning.py`: o modelo de churn inteiro como um objeto só."
    },
    {
      "code": "SHAPES = [\"unhappy\", \"skip_streak\", \"gone_quiet\", \"young\", \"tenure_capped\", \"box_price\",\n          \"late_and_new\"]\n\ndef add_shapes(rows):\n    rows = rows.copy()\n    rows[\"unhappy\"] = (rows[\"rating_90d\"] < 3.6).astype(float)\n    rows[\"skip_streak\"] = (rows[\"skips_90d\"] >= 3).astype(float)\n    rows[\"gone_quiet\"] = (rows[\"days_since_login\"] > 21).astype(float)\n    rows[\"young\"] = (rows[\"age\"] < 25).astype(float)\n    rows[\"tenure_capped\"] = rows[\"tenure_months\"].clip(upper=24)\n    boxes = rows[\"plan\"].astype(str).map({\"weekly\": 4, \"fortnightly\": 2, \"monthly\": 1})\n    rows[\"box_price\"] = rows[\"price_month\"] / boxes\n    rows[\"late_and_new\"] = rows[\"late_90d\"] * (rows[\"tenure_months\"] < 6)\n    return rows\n",
      "note": "**As sete colunas da aula 14**, agora uma função de tabela para tabela. Ela não aprende nada com os dados, todo limiar está escrito aqui, então é segura em quaisquer linhas."
    },
    {
      "code": "\ndef build(C=1.0):\n    numbers = make_pipeline(SimpleImputer(strategy=\"median\", add_indicator=True), StandardScaler())",
      "note": "**Os números** recebem a mediana do treino onde têm lacuna, uma coluna dizendo que a lacuna estava ali, e a escala. O `make_pipeline` dá aos passos o nome das classes deles."
    },
    {
      "code": "    words = OneHotEncoder(handle_unknown=\"ignore\")",
      "note": "**As palavras** viram colunas one-hot, e um valor nunca visto no treino vira zeros em vez de erro: o plano mensal de 2026."
    },
    {
      "code": "    prepare = ColumnTransformer([(\"numbers\", numbers, NUMERIC + SHAPES),\n                                 (\"words\", words, CATEGORICAL)])",
      "note": "**O `ColumnTransformer` manda cada lista de colunas para o seu tratamento** e põe os resultados lado a lado. Colunas que ele não recebe são descartadas, e é assim que `churned`, `customer_id` e as duas colunas que vazam da aula 4 ficam de fora."
    },
    {
      "code": "    return Pipeline([(\"shapes\", FunctionTransformer(add_shapes)),\n                     (\"prepare\", prepare),\n                     (\"logistic\", LogisticRegression(C=C, max_iter=2000))])",
      "note": "**O pipeline são os três passos em ordem**, com nomes. O `fit` roda o `fit` de cada passo nas linhas de treino e passa o resultado adiante; o `predict_proba` roda o `transform` de cada passo e depois o modelo."
    }
  ]
}
```

Depois ajuste e meça os meses de teste. Salve isto como `pipeline.py`:

```python
# pipeline.py
from sklearn.metrics import roc_auc_score

from churn_model import build
from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
model = build().fit(train, train["churned"])
chance = model.predict_proba(test)[:, 1]
print("steps:", " -> ".join(model.named_steps))
columns = model.named_steps["prepare"].get_feature_names_out()
print(f"{len(columns)} columns reach the logistic regression, from {columns[0]} to {columns[-1]}")
print(f"test months: AUC {roc_auc_score(test['churned'], chance):.3f}, "
      f"net value R$ {net_value(test['churned'], chance >= CREDIT / (SAVED * KEPT)):,.0f}")
```

**O pipeline recebe a tabela crua**, `train` e `test` como o `load_churn` os devolve, com toda coluna,
inclusive `churned`. Nada é preparado fora dele.

```
ana@lab:~/ml$ python pipeline.py
steps: shapes -> prepare -> logistic
36 columns reach the logistic regression, from numbers__age to words__channel_referral
test months: AUC 0.818, net value R$ 22,184
```

AUC 0,818, como na aula 14. O valor líquido é R$ 22.184 em vez de R$ 22.712, e a diferença tem causa: o
`OneHotEncoder` mantém todo valor como coluna, onde o `get_dummies` descartava o primeiro de cada. Duas
tabelas quase iguais dão a uma regressão logística dois problemas um pouco diferentes. É um lembrete
pequeno de que **refazer a preparação é em si uma mudança no modelo**, e o pipeline agora é a versão que
é medida, usada e guardada.

As 36 colunas têm nomes, de `numbers__age` a `words__channel_referral`, feitos dos nomes dos passos, então
os pesos no estilo da aula 5 ainda podem ser lidos: `model.named_steps["logistic"].coef_` os tem na mesma
ordem. A aula 19 lê um modelo assim.
