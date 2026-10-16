---
title: Mudando valores num passo só
version: 1
---

**Para mudar alguns valores de uma tabela, selecione as linhas e a coluna com um único `loc` do lado
esquerdo do `=`.** Um passo, um par de colchetes, na tabela que você quer mudar: essa é a regra
inteira, e é a mesma que a aula 7 deu para o NumPy.

Os passes diários custam R$ 12 e o plano anual sai a R$ 1,50 por viagem. Registre um preço por
viagem, em centavos para continuar exato:

```python
trips["price_cents"] = 150
trips.loc[trips["plan"] == "day", "price_cents"] = 1200
trips.groupby("plan")["price_cents"].first()
```

```
plan
annual     150
day       1200
Name: price_cents, dtype: int64
```

A primeira linha cria a coluna com um valor em todo lugar. A segunda seleciona as linhas de passe
diário e a coluna `price_cents` juntas e atribui na própria tabela. A última confere, usando o
`groupby`, que é o assunto da aula 13; aqui ele só mostra um valor por plano.

## Uma coluna nova a partir de uma condição

Quando o valor depende de uma condição com dois resultados, o `numpy.where` da aula 5 monta a coluna
inteira numa expressão:

```python
import numpy as np

trips["return"] = np.where(trips["end_station"].isna(), "lost", "docked")
trips["return"].value_counts()
```

```
return
docked    33191
lost        146
Name: count, dtype: int64
```

## Montando uma cópia modificada sem tocar no original

`assign` devolve um DataFrame **novo** com colunas acrescentadas ou trocadas, e deixa o original em
paz. É a forma a usar numa cadeia de passos:

```python
cheap = trips.assign(price_reais=trips["price_cents"] / 100).loc[lambda d: d["price_reais"] < 5]
cheap.shape, "price_reais" in trips.columns
```

```
((23438, 10), False)
```

O `lambda d:` dentro do `loc` recebe o DataFrame naquele ponto da cadeia, o que tem a coluna nova,
que o nome `trips` não teria. O próprio `trips` não ganhou coluna nenhuma. Mudar uma tabela ou
montar uma nova é uma escolha; a próxima seção é sobre os casos em que o pandas escolhe por você.
