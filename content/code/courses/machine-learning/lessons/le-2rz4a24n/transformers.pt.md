---
title: Transformadores, e o contrato que eles cumprem
version: 1
---

O scikit-learn tem dois tipos de objeto, e os dois cumprem o mesmo contrato de dois passos.

- Um **estimador que prevê**, como `LogisticRegression`, aprende com linhas no `fit`, e depois responde
  com `predict` ou `predict_proba`.
- Um **transformador**, como `StandardScaler`, `SimpleImputer` ou `OneHotEncoder`, aprende com linhas no
  `fit`, e depois muda linhas com `transform`.

**O que é aprendido é aprendido no `fit`, e só ali.** As médias de uma escala, as medianas de um
preenchedor, a lista de categorias de um codificador: tudo fica guardado no objeto, em nomes que
terminam com sublinhado, e o `transform` só os lê. Essa é a garantia inteira, e é fácil de ver. Salve
isto como `contract.py`:

```python
# contract.py
import pandas as pd
from sklearn.impute import SimpleImputer

from feira import by_time, load_churn

train, test = by_time(load_churn())
imputer = SimpleImputer(strategy="median")
imputer.fit(train[["rating_90d"]])
print(f"fit: the median of the training rows is {imputer.statistics_[0]}")
filled = imputer.transform(test[["rating_90d"]])
print(f"transform: {test['rating_90d'].isna().sum():,} test rows had no rating; "
      f"afterwards {pd.isna(filled).sum()} have none")
```

```
ana@lab:~/ml$ python contract.py
fit: the median of the training rows is 4.2
transform: 1,872 test rows had no rating; afterwards 0 have none
```

O preenchedor aprendeu 4,2 com as linhas de treino e preencheu as lacunas das linhas de teste com isso.
Chamar `transform` em outras mil linhas, ano que vem, as preenche com 4,2 de novo. É a propriedade que o
dicionário de medianas do `by_hand.py` só tinha pelo cuidado de quem programou.

O `fit_transform` faz os dois de uma vez, e só se chama nas linhas de onde se aprende. Uma chamada a
`fit_transform` em linhas de teste é o vazamento de preparação da aula 4 numa linha, e é o jeito mais
comum de cometê-lo.

Mais dois transformadores completam a caixa de ferramentas:

- O **`FunctionTransformer`** embrulha qualquer função de tabela para tabela. Ele não aprende nada, o que
  o torna certo para as marcas da aula 14, cujos limiares estão escritos, e errado para qualquer coisa
  calculada a partir dos dados, como uma mediana.
- O **`ColumnTransformer`** manda colunas diferentes para transformadores diferentes, números para um,
  palavras para outro, e põe os resultados lado a lado. Colunas que não estão nomeadas nele são
  descartadas.

Um **pipeline** encadeia transformadores e termina num modelo, e é ele mesmo um estimador: o `fit` ajusta
cada passo em ordem, cada um na saída do anterior, e o `predict_proba` roda o `transform` de cada passo e
depois o modelo. A próxima seção monta um.
