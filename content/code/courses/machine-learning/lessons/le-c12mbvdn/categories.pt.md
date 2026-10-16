---
title: Categorias como números
version: 1
---

Um modelo faz conta, então uma coluna de palavras precisa virar números, e há três jeitos de fazer isso
que quem faz ciência de dados encontra toda semana.

A **codificação one-hot** faz uma coluna de 0 ou 1 por valor: `box_small`, `box_medium`, `box_large`.
Ela não supõe nada sobre os valores, o que é certo para `city` ou `payment`, onde não há ordem. É o que
o `get_dummies` fez na aula 5. A versão do scikit-learn, o `OneHotEncoder`, faz uma coisa a mais: **ele lembra as colunas que fez**, então um valor que ele nunca viu ao ajustar
recebe zeros em tudo em vez de uma coluna nova de que o modelo nunca ouviu falar.

A **codificação ordinal** troca cada valor pela posição dele numa ordem que você dá: pequena 0, média 1,
grande 2. Uma coluna em vez de três, e um modelo linear pode então dizer *cada tamanho acima acrescenta
tanto de risco*. Só é certa quando a ordem é real e mais ou menos regular. Codificar `city` assim
inventaria uma ordem de cidades.

A **codificação pelo alvo** troca cada valor pela parte de positivos entre as linhas de treino que o
têm: nos meses de treino São Paulo vira 0,049, Rio de Janeiro 0,079, e assim por diante. Ela transforma
uma coluna com milhares de valores, como um CEP, num número só. É também o codificador que mais vaza,
porque o rótulo da própria linha está dentro da média que ela recebe. O `TargetEncoder` do scikit-learn
evita isso calculando o valor de cada linha só com as outras partes, as partes da aula 3, e vale usá-lo
em vez de escrever o `groupby` à mão.

A diferença entre os dois primeiros é mais fácil de ver em duas linhas novas, uma delas com um plano que
não existia quando o codificador foi ajustado. Em 2026 a Feira em Casa lança um plano **mensal**, e o
`churn_2026.csv` o tem. Salve isto como `encoders.py`:

```python
# encoders.py
import pandas as pd
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder

train = pd.DataFrame({"box": ["small", "large", "medium", "small"],
                      "plan": ["weekly", "fortnightly", "weekly", "weekly"]})
new = pd.DataFrame({"box": ["medium", "large"], "plan": ["fortnightly", "monthly"]})

one_hot = OneHotEncoder(handle_unknown="ignore", sparse_output=False).fit(train)
print(pd.DataFrame(one_hot.transform(new), columns=one_hot.get_feature_names_out()), end="\n\n")

order = OrdinalEncoder(categories=[["small", "medium", "large"]]).fit(train[["box"]])
print(new.assign(box_order=order.transform(new[["box"]])[:, 0]))
```

```
ana@lab:~/ml$ python encoders.py
   box_large  box_medium  box_small  plan_fortnightly  plan_weekly
0        0.0         1.0        0.0               1.0          0.0
1        1.0         0.0        0.0               0.0          0.0

      box         plan  box_order
0  medium  fortnightly        1.0
1   large      monthly        2.0
```

A segunda linha nova tem `plan_fortnightly` e `plan_weekly` os dois em 0. **O modelo vai ler o plano
mensal como "nenhum dos planos que conheço"**, que é a resposta honesta sobre ele, em vez de quebrar ou criar
uma coluna em silêncio. É o `handle_unknown="ignore"` que permite isso; o padrão é levantar um erro, que
é o padrão certo durante o desenvolvimento e o errado às três da manhã quando aparece um plano novo. A
aula 15 roda o modelo de churn inteiro no `churn_2026.csv` e encontra exatamente isto.

E o `box_order` põe pequena, média e grande em 0, 1 e 2 porque a lista mandou. Sem o argumento
`categories` o codificador as teria ordenado alfabeticamente, large 0, medium 1, small 2, uma ordem que
por acaso fica de trás para a frente aqui e poderia ser qualquer coisa em outra coluna.

Para árvores, a codificação importa menos. O `HistGradientBoostingClassifier` aceita categorias
diretamente, como toda aula desde a aula 2 fez com `categorical_features="from_dtype"`, e acha o próprio
agrupamento dos valores em cada corte.
