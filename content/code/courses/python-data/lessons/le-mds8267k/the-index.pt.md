---
title: Escolhendo um índice
version: 1
---

**O índice é a coluna que o pandas usa para alinhar linhas, e quem escolhe é você.** O RangeIndex
padrão é só um marcador de lugar. Quando uma tabela tem uma coluna que dá nome às linhas, uma data ou
um id, torná-la o índice dá a todo alinhamento, toda consulta e toda junção algo com significado para
usar.

```python
weather = pd.read_csv("weather.csv", index_col="date")
weather.head(3), weather.index[:3]
```

```
(            rain_mm  temp_max
 date                         
 2025-01-01      0.0      29.9
 2025-01-02      6.8      30.0
 2025-01-03      7.9      30.7,
 Index(['2025-01-01', '2025-01-02', '2025-01-03'], dtype='str', name='date'))
```

`index_col` fez de `date` o índice já na leitura. A mesma coisa numa tabela já carregada é
`set_index`, e o oposto, `reset_index`, devolve o índice a uma coluna comum:

```python
by_id = trips.set_index("trip_id")
by_id.loc[1, "start_station"], by_id.reset_index().columns[:3].tolist()
```

```
('S07', ['trip_id', 'started_at', 'ended_at'])
```

## Consultas por rótulo

Com as datas como índice, uma linha se pede pela data e uma faixa de linhas por duas datas:

```python
weather.loc["2025-03-22"], weather.loc["2025-03-20":"2025-03-23", "rain_mm"]
```

```
(rain_mm     45.9
 temp_max    30.0
 Name: 2025-03-22, dtype: float64,
 date
 2025-03-20    25.0
 2025-03-21    14.3
 2025-03-22    45.9
 2025-03-23     0.0
 Name: rain_mm, dtype: float64)
```

**Uma faixa de rótulos inclui as duas pontas**, ao contrário de uma fatia por posição:
`"2025-03-20":"2025-03-23"` dá quatro dias. A aula 11 torna a diferença precisa.

## Um índice que não é único

Nada obriga um índice a ser único, e o `stations.csv` mostra por que isso importa:

```python
stations = pd.read_csv("stations.csv", index_col="station_id")
stations.index.is_unique, stations.loc["S07"]
```

```
(False,
                    name  docks  valid_from
 station_id                                
 S07         Rua da Hora     17  2025-01-01
 S07          Espinheiro     17  2025-07-01)
```

Pedir `S07` devolve **duas linhas**, não uma: a estação foi renomeada em julho, e o arquivo tem uma
linha para cada nome, cada uma a partir da sua data. Um código que esperava que
`stations.loc[código, "name"]` fosse um nome recebe uma Series de dois. `is_unique` é a
conferência, e a aula 14 é sobre o que uma chave duplicada faz com uma junção, onde o estrago é maior
que aqui.
