---
title: resample, um groupby no calendário
version: 1
---

**O `resample` agrupa uma série temporal em períodos do calendário, um dia, uma semana, um mês, e
agrega cada um.** É assim que uma série diária vira semanal ou mensal, e como todo `groupby` ele
precisa de um cálculo depois.

Totais semanais:

```python
weekly = daily.resample("W").sum()
weekly.head(3)
```

```
started_at
2025-01-05    431
2025-01-12    565
2025-01-19    649
Freq: W-SUN, dtype: int64
```

```python
weekly.tail(2)
```

```
started_at
2025-12-28    609
2026-01-04    342
Freq: W-SUN, dtype: int64
```

**A primeira e a última semana são curtas.** `"W"` corta semanas que terminam no domingo e rotula
cada uma com o seu domingo, então a semana rotulada 5 de janeiro só tem de 1 a 5 de janeiro, cinco
dias, e a rotulada 4 de janeiro de 2026 tem de 29 a 31 de dezembro, três. Os totais de 431 e 342 não
são semanas fracas; são semanas parciais. Um gráfico de totais semanais afunda nas duas pontas de todo
ano por isso, e a correção é descartar os períodos parciais ou mostrar uma média por dia em vez de
uma soma.

## O rótulo de um período

Um mês pode ser rotulado pelo primeiro dia ou pelo último, e as duas grafias dizem qual:

```python
daily.resample("MS").sum().head(3), daily.resample("ME").sum().head(3)
```

```
(started_at
 2025-01-01    2912
 2025-02-01    2756
 2025-03-01    2831
 Freq: MS, dtype: int64,
 started_at
 2025-01-31    2912
 2025-02-28    2756
 2025-03-31    2831
 Freq: ME, dtype: int64)
```

Os mesmos totais, rotulados `2025-01-01` com `"MS"`, início do mês, e `2025-01-31` com `"ME"`, fim
do mês. Nenhum dos dois está errado, mas uma tabela rotulada pelo fim do mês unida a uma rotulada pelo
início não casa nada, e a aula 14 mostrou como isso acontece em silêncio. **Escolha um rótulo para o
projeto e escreva qual.**

## Soma ou média

O que calcular por período depende do que são os valores. Viagens por dia são contagens, então o
total de uma semana é a soma delas. Temperaturas são leituras, então a temperatura de um mês é a média
delas; somá-las dá um número que cresce com o tamanho do mês:

```python
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
temp = weather.set_index("date")["temp_max"]
temp.resample("MS").mean().round(1).head(3), temp.resample("MS").sum().round(1).head(3)
```

```
(date
 2025-01-01    30.3
 2025-02-01    30.5
 2025-03-01    30.4
 Freq: MS, Name: temp_max, dtype: float64,
 date
 2025-01-01    940.4
 2025-02-01    854.7
 2025-03-01    943.7
 Freq: MS, Name: temp_max, dtype: float64)
```

A soma de fevereiro é menor que a de janeiro só porque fevereiro é mais curto. **Contagens e totais
se somam ao longo do tempo; níveis e taxas não**, e essa distinção decide entre `sum` e `mean` em todo
`resample` e toda janela móvel desta aula.
