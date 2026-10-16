---
title: Datas, de texto para datetime
version: 1
---

**Uma coluna datetime guarda cada momento como um número por baixo, então ela ordena, subtrai e
agrupa certo, e tem um acessor `.dt` para as partes.** Os horários das viagens são texto desde a
aula 9. Converta-os, dizendo ao pandas o formato exato:

```python
fmt = "%Y-%m-%d %H:%M:%S"
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
trips[["started_at", "ended_at"]].dtypes
```

```
started_at    datetime64[us]
ended_at      datetime64[us]
dtype: object
```

`datetime64[us]` é um momento com precisão de microssegundo. O `ended_at` vazio das bicicletas
perdidas virou `NaT`. **Dê o formato.** Sem ele, o pandas deduz um a partir do primeiro valor, o que
funciona numa coluna limpa e falha, ou pior, adivinha errado, numa em que algumas datas estão escritas
`03/04/2025`: 3 de abril no Brasil, 4 de março nos Estados Unidos, e nada na string diz qual.

```python
pd.to_datetime("03/04/2025", format="%d/%m/%Y"), pd.to_datetime("03/04/2025", format="%m/%d/%Y")
```

```
(Timestamp('2025-04-03 00:00:00'), Timestamp('2025-03-04 00:00:00'))
```

## As partes de um momento

```python
start = trips["started_at"]
start.dt.hour.head(3).tolist(), start.dt.day_name().head(3).tolist(), start.dt.month.value_counts().sort_index().head(3)
```

```
([12, 20, 3],
 ['Wednesday', 'Wednesday', 'Wednesday'],
 started_at
 1    2912
 2    2756
 3    2831
 Name: count, dtype: int64)
```

`.dt.hour`, `.dt.day_name()`, `.dt.month`, `.dt.date` e mais uma dúzia, cada um uma coluna do
mesmo comprimento. As viagens por mês se leem direto: janeiro, fevereiro e março, cada um perto de
3.000. A aula 13 agrupa por essas partes, e a aula 16 monta uma série temporal sobre elas.

## Selecionando por data

Comparações com uma data escrita como texto funcionam, porque o pandas converte o texto:

```python
carnival = trips[(start >= "2025-03-01") & (start < "2025-03-06")]
len(carnival), carnival["started_at"].min(), carnival["started_at"].max()
```

```
(421, Timestamp('2025-03-01 01:20:23'), Timestamp('2025-03-05 22:16:59'))
```

O Carnaval de 2025, do sábado, 1º de março, à quarta-feira de cinzas, dia 5, escrito como um
intervalo semiaberto: do primeiro instante do dia 1 até o dia 6, sem incluí-lo. **Use `<` no dia
seguinte** em vez de `<=` no último dia, que pararia à meia-noite do começo dele e deixaria o dia
inteiro de fora.
