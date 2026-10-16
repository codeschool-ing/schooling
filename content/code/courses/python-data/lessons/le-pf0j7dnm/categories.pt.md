---
title: Categorias, para colunas com poucos valores distintos
version: 1
---

**Uma coluna categórica guarda cada valor distinto uma vez e dá a cada linha um inteiro pequeno
apontando para ele.** Para uma coluna como `plan`, com dois valores repetidos 33.337 vezes, isso é
muito menos memória, e ela leva junto a lista dos valores permitidos.

```python
plan = trips["plan"].astype("category")
plan.dtype, plan.cat.categories.tolist(), trips["plan"].memory_usage(deep=True), plan.memory_usage(deep=True)
```

```
(CategoricalDtype(categories=['annual', 'day'], ordered=False, categories_dtype=str),
 ['annual', 'day'],
 437153,
 33495)
```

A coluna de texto ocupa mais de 400 kB; a categórica, menos de 35. A aula 20 faz isso com toda coluna
que permite. Os dados não mudam: `value_counts`, comparações e filtros funcionam como antes.

## Categorias que não estão lá

Uma categoria pode existir sem linha nenhuma, e uma coluna categórica se lembra dela:

```python
weekday = pd.Categorical(["Mon", "Tue", "Mon"], categories=["Mon", "Tue", "Wed"])
pd.Series(weekday).value_counts()
```

```
Mon    2
Tue    1
Wed    0
Name: count, dtype: int64
```

`Wed` é contada com 0. Para um relatório que precisa mostrar todo dia da semana, inclusive os
vazios, isso está exatamente certo; o `groupby` da aula 13 tem o mesmo comportamento, e um argumento
`observed` para quando você quer os grupos vazios de fora.

## Categorias ordenadas

Quando os valores têm ordem, diga, e as comparações e a ordenação a seguem em vez do alfabeto. O
`pd.cut` cria categorias ordenadas a partir de números, uma faixa para cada intervalo:

```python
weather = pd.read_csv("weather.csv")
band = pd.cut(weather["rain_mm"], bins=[-0.1, 0, 10, 100], labels=["dry", "light", "heavy"])
band.dtype, band.value_counts(sort=False), (band > "light").sum()
```

```
(CategoricalDtype(categories=['dry', 'light', 'heavy'], ordered=True, categories_dtype=str),
 rain_mm
 dry      192
 light    104
 heavy     63
 Name: count, dtype: int64,
 np.int64(63))
```

`bins` são as bordas: até 0, acima de 0 até 10, acima de 10 até 100. As faixas saem ordenadas, então
`band > "light"` quer dizer mais forte que leve, não depois no alfabeto. E os seis dias sem leitura
são `NaN`, em faixa nenhuma: o `value_counts` os deixa de fora, e as três contagens somam 359, não
365.
