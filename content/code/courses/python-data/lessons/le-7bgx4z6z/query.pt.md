---
title: query, uma condição escrita como texto
version: 1
---

**`DataFrame.query` recebe uma condição como string e devolve as linhas que a satisfazem.** Diz o
mesmo que um `loc` com máscara, com menos colchetes, e com os nomes das colunas escritos sem nada em
volta:

```python
trips.query("plan == 'day' and bike == 'e-bike' and start_station == end_station").shape
```

```
(223, 9)
```

Dentro da string, `and`, `or` e `not` funcionam, porque o `query` interpreta o texto por conta
própria em vez de entregá-lo ao Python, então o erro da aula 7 sobre `and` em arrays não acontece. A
mesma seleção com `loc`:

```python
mask = (trips["plan"] == "day") & (trips["bike"] == "e-bike") & (trips["start_station"] == trips["end_station"])
trips.loc[mask].shape
```

```
(223, 9)
```

Uma variável do notebook entra com `@`:

```python
station = "S07"
trips.query("start_station == @station").shape
```

```
(2636, 9)
```

Qual usar é questão de leitura: o `query` é mais curto para uma condição de várias partes, e o `loc`
é o que também escolhe colunas e atribui. Dois limites valem saber: um nome de coluna com espaço
precisa de crases dentro da string, e um erro de digitação num nome de coluna só falha quando a linha
roda, como no `loc`.
