---
title: Classificação, e a probabilidade por baixo dela
version: 1
---

**Classificação responde com uma categoria.** Afastado ou não é o menor caso, duas classes, e se
chama **binário**. Um modelo que lê um chamado de suporte e responde *entrega*, *pagamento* ou
*reembolso* é **multiclasse**, e nada nesta seção muda para ele, exceto que há três probabilidades
em vez de duas.

O modelo da lição 1 lia três colunas numéricas. Este lê as dez que o `features.py` monta, incluindo
as três que são palavras, e isso muda o que o programa precisa ser. Salve-o como `classify.py`:

```python
"""classify.py: the lapse model with every feature, categories included."""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

train = features.build("2025-09-30")
test = features.build("2025-11-30")
X = features.NUMERIC + features.CATEGORICAL

model = make_pipeline(
    make_column_transformer(
        (StandardScaler(), features.NUMERIC),
        (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
    ),
    LogisticRegression(max_iter=1000),
)
model.fit(train[X], train["lapsed"])

test["p_lapse"] = model.predict_proba(test[X])[:, 1]
test["predicted"] = model.predict(test[X])
print(test[["member_id", "channel", "recency_days", "p_lapse", "predicted", "lapsed"]]
      .head(4).round(3).to_string(index=False))
print("predicted to lapse:", int(test["predicted"].sum()), "of", len(test))
print("actually lapsed:   ", int(test["lapsed"].sum()), "of", len(test))
```

**`make_pipeline` encadeia os passos num objeto só**, e esse objeto é o modelo. O primeiro passo é
um `ColumnTransformer` que trata as colunas de jeitos diferentes: põe as sete numéricas na mesma
escala, como a lição 1 fez para o k-means, e transforma as três categóricas em números de um jeito
que a próxima seção explica. O segundo passo é a mesma regressão logística. **`fit` roda os dois
passos nas linhas de treino, e `predict_proba` roda os dois nas linhas novas**, então a escala
aprendida em setembro é a escala aplicada em novembro. A lição 6 volta a por que isso importa mais
do que parece.

```
ana@dev:~/ml$ python classify.py
 member_id channel  recency_days  p_lapse  predicted  lapsed
         1   store          17.0    0.129          0       0
         2   store           0.0    0.087          0       0
         3   store          11.0    0.121          0       0
         7   store          14.0    0.068          0       0
predicted to lapse: 248 of 3130
actually lapsed:    530 of 3130
```

## Duas respostas de um modelo

O modelo dá duas coisas para cada membro, e é fácil confundi-las.

`predict_proba` dá a **probabilidade**: o membro 1 tem 0,129 de chance de se afastar. `predict` dá a
**classe**, que é essa probabilidade comparada com **0,5**: 0,129 fica abaixo, então a classe é 0. O
limiar é um padrão escrito no scikit-learn, não algo que o modelo aprendeu.

**E com 0,5 o modelo chama 248 membros de afastados, enquanto 530 de fato se afastaram.** Boa parte
dessa diferença é o limiar e não o modelo: um limiar escolhido para a pergunta de ninguém. Um membro
com 0,4 de chance de se afastar é alguém a quem o marketing mandaria um voucher com prazer, e o
limiar padrão o chama de "fica". A lição 4 escolhe o limiar a partir do que custa um voucher e do
que custa um membro perdido, que é o único jeito honesto de escolher um.

**Esta é a primeira coisa a combinar com quem modela: qual das duas você guarda.** Guarde a classe,
e o limiar fica congelado em cada linha, então mudá-lo significa pontuar todo mundo de novo. Guarde
a probabilidade, e o limiar é um parâmetro de quem lê a tabela. A plataforma guarda a probabilidade.
