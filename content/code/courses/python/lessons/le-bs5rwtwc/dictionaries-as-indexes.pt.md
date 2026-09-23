---
title: Construir uma busca uma vez, em vez de procurar repetidamente
version: 2
---

```python
for order in orders:                      # 5,000 orders
    for customer in customers:            # 5,000 customers
        if customer["id"] == order["customer_id"]:
            out.append((customer["name"], order["cents"]))
            break
```

```python
by_id = {c["id"]: c for c in customers}   # one pass, built once
out = [(by_id[o["customer_id"]]["name"], o["cents"]) for o in orders]
```

```sh
slow     0.5485s   5000 rows
fast     0.0030s   5000 rows
same answer: True
```

**O(n²) virando O(n), por uma linha.** Medido em cinco mil de cada; em vinte mil a distância é
quinhentas vezes, que é a demonstração no fim desta aula.

## Por que funciona

O laço de dentro é uma busca, e uma busca é o que um dict faz num passo. Construir o índice é uma
passagem sobre os clientes — `O(n)` — e aí cada consulta é `O(1)`, então o todo é `O(n + m)` em
vez de `O(n × m)`.

Você paga uma passagem e alguma memória. Você economiza uma passagem por linha.

## As formas que servem

```python
by_id = {c["id"]: c for c in customers}              # one value per key
```

```python
from collections import defaultdict
by_country = defaultdict(list)
for c in customers:
    by_country[c["country"]].append(c)               # many values per key
```

```python
from collections import Counter
counts = Counter(o["country"] for o in orders)       # just the count
```

O `defaultdict(list)` é o de agrupar e ele aparece o tempo todo — é `sort | uniq` sem o sort, e o
`groupby` da próxima aula é a mesma ideia sobre uma tabela.

## Onde construí-lo

**Fora de todo laço que o usa**, e uma vez por programa em vez de uma vez por chamada:

```python
def report(orders, customers):
    by_id = {c["id"]: c for c in customers}    # once
    for o in orders:
        ...
```

Construí-lo dentro do laço é o mesmo engano do `set(items)` dentro de uma condição: o índice é
`O(n)` para construir, então construí-lo `n` vezes é o `O(n²)` que você estava removendo.

## E o limite honesto

Isso funciona quando você busca as coisas **por uma chave exata**. Uma busca por "qualquer cliente
cujo nome comece com estas letras", ou "o valor mais próximo", é outro problema — `bisect` sobre
uma lista ordenada para faixas, e um índice de verdade ou um banco para qualquer coisa maior.
