---
title: JSON, e os tipos que o read_json decide sozinho
version: 1
---

**JSON é como serviços web entregam dados: objetos com campos nomeados, que o pandas transforma em
linhas e colunas.** É texto, como CSV, e mais ou menos o dobro do tamanho, porque cada linha repete o
nome de cada campo. O formato de tabela comum é um objeto por linha, chamado **JSON Lines**:

```python
trips.to_json("trips.jsonl", orient="records", lines=True)
with open("trips.jsonl") as f:
    print(f.readline())
```

```
{"trip_id":1,"started_at":"2025-01-01 12:22:38","ended_at":"2025-01-01 12:57:03","start_station":"S07","end_station":"S05","plan":"day","bike":"electric"}

```

`orient="records"` escreve cada linha como um objeto, e `lines=True` põe um por linha, o que deixa
um programa ler um arquivo enorme uma linha de cada vez. Leia de volta:

```python
back = pd.read_json("trips.jsonl", lines=True)
back.dtypes
```

```
trip_id                   int64
started_at       datetime64[us]
ended_at         datetime64[us]
start_station               str
end_station                 str
plan                        str
bike                        str
dtype: object
```

**Duas colunas mudaram de tipo na volta.** `started_at` e `ended_at` saíram como texto e voltaram
como datetimes, enquanto `start_station` não. O `read_json` converte colunas em datas sozinho quando
o nome parece de data para ele: terminado em `_at` ou `_time`, começando com `timestamp`, ou
chamado `date` ou `modified`, entre outros. Aqui ajudou. Numa coluna chamada `created_at` que guarda
algo que só parece data, é uma surpresa. `convert_dates=False` desliga isso, e nomear as colunas a
converter, `convert_dates=["started_at"]`, o torna explícito.

## JSON aninhado

A resposta de uma API costuma ser aninhada: um objeto dentro de um campo. `pd.json_normalize` a
achata em colunas com nomes pontuados:

```python
answer = [{"station": "S01", "status": {"bikes": 9, "docks_free": 5}},
          {"station": "S02", "status": {"bikes": 3, "docks_free": 17}}]
pd.json_normalize(answer)
```

```
  station  status.bikes  status.docks_free
0     S01             9                  5
1     S02             3                 17
```

Cada campo aninhado virou uma coluna, `status.bikes` e `status.docks_free`, que é o que uma tabela
precisa. Uma lista dentro de um campo, as últimas dez viagens de uma estação, por exemplo, não se
achata em colunas, e o `json_normalize` tem um argumento `record_path` para transformar uma lista
assim em linhas.
