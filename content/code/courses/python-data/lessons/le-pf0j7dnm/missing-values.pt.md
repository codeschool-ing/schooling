---
title: Valores faltantes, e o que o pandas faz com eles por padrão
version: 1
---

**O pandas tem três grafias para "faltante": `NaN` para floats e texto, `NaT` para datetimes, e
`pd.NA` para os tipos anuláveis.** `isna()` acha os três, e o resto desta seção é sobre as decisões
que o pandas toma por você quando os encontra.

```python
trips.isna().sum()
```

```
trip_id            0
started_at         0
ended_at         146
start_station      0
end_station      146
plan               0
bike               0
duration         146
dtype: int64
```

`isna()` dá uma tabela de `True` e `False`, e o `.sum()` conta os faltantes de cada coluna: as 146
bicicletas perdidas, em toda coluna que depende do fim da viagem.

## Reduções os pulam

```python
weather["rain_mm"].sum(), weather["rain_mm"].mean().round(3), weather["rain_mm"].count()
```

```
(np.float64(1712.8), np.float64(4.771), np.int64(359))
```

**O pandas pula valores faltantes nas reduções por padrão**, enquanto o NumPy, na aula 5, devolvia
`nan`. O `sum` dá 1712,8 porque os seis dias sem leitura ficaram de fora, e o `count` diz quantos
valores foram usados: 359. O comportamento do NumPy está a um argumento de distância, e é o honesto
quando um buraco deveria tornar a resposta desconhecida:

```python
weather["rain_mm"].sum(skipna=False), pd.Series([np.nan, np.nan]).sum(), pd.Series([np.nan, np.nan]).sum(min_count=1)
```

```
(np.float64(nan), np.float64(0.0), np.float64(nan))
```

O do meio é a armadilha: a soma de **nenhum** valor conhecido é `0.0`, que parece uma semana seca.
`min_count=1` pede pelo menos um valor de verdade e devolve `NaN` se não houver.

## Tirando ou preenchendo

```python
trips.dropna(subset=["end_station"]).shape, weather["rain_mm"].fillna(0).sum()
```

```
((33191, 8), np.float64(1712.8))
```

`dropna(subset=...)` tira as linhas sem valor naquelas colunas; `fillna(0)` troca os faltantes por
0. Os dois são decisões, e a segunda é uma afirmação: que os seis dias sem leitura foram secos.
Escreva por quê, ou não a faça.

## Inteiros que podem faltar

Uma coluna de inteiros com um buraco vira float no NumPy, `14.0` e `nan`. O pandas tem **tipos
inteiros anuláveis**, escritos com maiúscula, que mantêm os inteiros e guardam um faltante:

```python
pd.Series([14, None, 12]).dtype, pd.Series([14, None, 12]).astype("Int64").tolist()
```

```
(dtype('float64'), [14, <NA>, 12])
```

`Int64` guarda `14`, `<NA>` e `12`. A mesma ideia dá `boolean` e `Float64`; o tipo de texto da
primeira seção é a mesma ideia para strings.
