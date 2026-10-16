---
title: Um DataFrame são Series que compartilham um índice
version: 1
---

**Um DataFrame é uma tabela: várias Series lado a lado, uma por coluna, todas com um único índice.**
Cada coluna tem o próprio dtype. O índice rotula as linhas. Leia as viagens:

```python
trips = pd.read_csv("trips.csv")
trips.head()
```

```
   trip_id           started_at             ended_at start_station  \
0        1  2025-01-01 12:22:38  2025-01-01 12:57:03           S07   
1        2  2025-01-01 20:08:24  2025-01-01 20:25:16           S20   
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   
3        4  2025-01-01 07:17:40  2025-01-01 07:36:13           S14   
4        5  2025-01-01 22:57:18  2025-01-01 23:04:01           S05   

  end_station    plan      bike  
0         S05     day  electric  
1         S07  annual  electric  
2         S03  annual  electric  
3         S05  annual   classic  
4         S08  annual  electric  
```

A coluna sem nome à esquerda é o índice. Ninguém pediu um, então o pandas criou o padrão, um
**RangeIndex**, os números 0, 1, 2 e assim por diante, que são rótulos que parecem posições. A
próxima seção é sobre o problema que essa semelhança causa.

```python
trips.shape, trips.columns.tolist()
```

```
((33337, 7),
 ['trip_id',
  'started_at',
  'ended_at',
  'start_station',
  'end_station',
  'plan',
  'bike'])
```

Trinta e três mil trezentas e trinta e sete viagens, sete colunas.

## Uma coluna é uma Series

```python
plan = trips["plan"]
type(plan), plan.head(3)
```

```
(pandas.Series,
 0       day
 1    annual
 2    annual
 Name: plan, dtype: str)
```

Um par de colchetes com o nome de uma coluna dá essa coluna, como Series, com o índice da tabela.
Dois pares, com uma lista dentro, dão um DataFrame menor:

```python
trips[["start_station", "end_station"]].head(3)
```

```
  start_station end_station
0           S07         S05
1           S20         S07
2           S16         S03
```

## Uma coluna nova é uma linha

Aritmética entre colunas é aritmética entre Series, vetorizada como a aula 5 ensinou, e atribuir a um
nome novo a acrescenta:

```python
trips["round_trip"] = trips["start_station"] == trips["end_station"]
trips["round_trip"].sum(), trips["round_trip"].mean().round(4)
```

```
(np.int64(2096), np.float64(0.0629))
```

Uma coluna booleana, um valor por viagem, contada e tirada a média do mesmo jeito que a aula 5 fazia
com booleanos do NumPy. Cada linha da coluna nova se alinha com a sua viagem pelo índice
compartilhado; as colunas não conseguem se desencontrar, que é a vantagem sobre guardar arrays
separados.

```python
trips.dtypes
```

```
trip_id          int64
started_at         str
ended_at           str
start_station      str
end_station        str
plan               str
bike               str
round_trip        bool
dtype: object
```

Leia os dtypes antes de qualquer coisa. `trip_id` é inteiro, `round_trip` é booleano, e as outras
seis são `str`: **os horários são texto**. O `read_csv` não reconheceu `2025-01-01 12:22:38` como
data, porque nada o mandou. Não dá para subtrair duas strings e ter uma duração, e a aula 12 trata de
transformá-las em datas de verdade. Até lá, são rótulos que se ordenam na ordem certa por sorte do
formato.
