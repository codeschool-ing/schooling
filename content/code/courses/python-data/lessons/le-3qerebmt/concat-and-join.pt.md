---
title: concat empilha, e join casa pelo índice
version: 1
---

**O `pd.concat` empilha tabelas que têm o mesmo tipo de linha, uma debaixo da outra.** Ele casa
colunas por nome, não linhas por chave. O caso comum são dados que chegam em pedaços, um arquivo por
mês:

```python
months = [part for _, part in trips.groupby(trips["started_at"].dt.month)]
len(months), [len(m) for m in months[:3]]
```

```
(12, [2912, 2756, 2831])
```

Doze tabelas, uma por mês. Empilhá-las de volta dá o ano:

```python
year = pd.concat(months, ignore_index=True)
len(year), year.index[-3:]
```

```
(33337, RangeIndex(start=33334, stop=33337, step=1))
```

`ignore_index=True` numera as linhas de novo, de 0 a 33.336. Sem ele cada pedaço mantém os próprios
rótulos, que aqui por acaso são únicos porque vieram de uma tabela só; pedaços lidos de doze arquivos
começariam cada um em 0, e o resultado teria doze linhas com rótulo 0, o índice duplicado da aula 9.

Quando os pedaços não têm as mesmas colunas, o `concat` mantém todas e preenche as lacunas:

```python
a = pd.DataFrame({"trip_id": [1, 2], "bike": ["classic", "electric"]})
b = pd.DataFrame({"trip_id": [3], "bike": ["classic"], "battery": [0.8]})
pd.concat([a, b], ignore_index=True)
```

```
   trip_id      bike  battery
0        1   classic      NaN
1        2  electric      NaN
2        3   classic      0.8
```

**Uma coluna que existe só em alguns pedaços vira `NaN` nos outros**, e um nome de coluna escrito
errado no arquivo de um mês vira uma segunda coluna, meio vazia, ao lado da certa. Depois de um
`concat`, confira `columns` além do comprimento.

## join, um merge pelo índice

O `DataFrame.join` é o `merge` com o **índice** da tabela da direita como chave. Com uma tabela de
estações indexada pelo código, ele fica fácil de ler:

```python
docks = stations.drop_duplicates("station_id").set_index("station_id")[["docks"]]
trips.join(docks, on="start_station")[["trip_id", "start_station", "docks"]].head(3)
```

```
   trip_id start_station  docks
0        1           S07     17
1        2           S20     13
2        3           S16     20
```

Aqui o `drop_duplicates` é seguro, e na seção anterior não era: as duas linhas da `S07` têm 17 docas,
então qualquer uma está certa. Unir também as docas da estação final põe uma segunda coluna `docks` na
mesma tabela, e o `join` não escolhe um nome por você:

```python
trips.join(docks, on="start_station").join(docks, on="end_station")
```

```
ValueError: columns overlap but no suffix specified: Index(['docks'], dtype='str')
```

```python
both = trips.join(docks, on="start_station").join(docks, on="end_station", rsuffix="_end")
both[["start_station", "docks", "end_station", "docks_end"]].head(3)
```

```
  start_station  docks end_station  docks_end
0           S07     17         S05       20.0
1           S20     13         S07       17.0
2           S16     20         S03       20.0
```

`docks_end` é float porque as bicicletas perdidas não têm estação final, e um valor faltante
transforma uma coluna de inteiros em floats, como a aula 12 mostrou.

O `merge` faz o mesmo com `suffixes=("_x", "_y")` por padrão e **não** se recusa, então um merge de
duas tabelas que dividem um nome de coluna dá `docks_x` e `docks_y` sem perguntar. Dê os nomes você
mesmo, `suffixes=("_start", "_end")`, para a tabela ainda ser legível daqui a um mês.

**`concat` para linhas do mesmo tipo, `merge` para uma chave numa coluna, `join` para uma chave no
índice.** Os três podem perder ou multiplicar linhas, e o mesmo hábito pega os três: contar antes e
depois.
