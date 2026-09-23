---
title: O laço aninhado da aula 4, contado
version: 2
---

```python
for order in orders:              # n
    for customer in customers:    # × m
        if customer["id"] == order["customer_id"]:
            ...
```

**Dois laços, um dentro do outro, sobre coleções diferentes: `O(n × m)`.** Vinte mil de cada são
quatrocentos milhões de comparações, que é de onde vieram os nove segundos da demonstração.

A forma é fácil de ver quando está escrita assim. A razão de ela sobreviver em código de verdade é
que em geral não está.

## Os três disfarces

```python
for order in orders:
    customer = find_customer(order.customer_id)      # a loop, one frame down
```

Uma função auxiliar. O laço continua lá e o ponto de chamada parece uma operação. Era exatamente
isso o `find_customer` da demonstração, e dividir a função é o que fez o profiler apontar para
ele.

```python
for order in orders:
    if order.customer_id in blocked_list:            # a loop, inside an operator
```

`in` contra uma lista. Duas seções atrás.

```python
matched = [(c, o) for o in orders for c in customers if c.id == o.customer_id]
```

Uma compreensão. Mais curta, e exatamente os mesmos dois laços.

## As três reescritas

**Um índice**, quando você busca as coisas por uma chave — o dicionário, construído uma vez. É
esta que se aplica na maior parte das vezes.

```python
by_id = {c["id"]: c for c in customers}
```

**Um set**, quando o laço de dentro só pergunta se algo está presente.

```python
blocked = set(blocked_ids)
```

**Uma ordenação e uma caminhada só**, quando o casamento é por faixa e não por chave exata —
ordene os dois lados uma vez, `O(n log n)`, e depois caminhe por eles juntos numa passagem. É o
que um banco chama de merge join, e é a resposta quando uma busca por hash não serve.

## Quando deixar em paz

```python
for row in rows:                 # 40 rows
    for column in columns:       # 12 columns
```

Quatrocentas e oitenta operações. Transformar isso num dicionário custa a atenção de quem lê e não
economiza nada que você consiga medir. **`O(n²)` em `n` pequeno está bem**, e o número que importa
é o produto e não a forma.

A pergunta a fazer não é "isto está aninhado" e sim "quão grandes estes ficam, em produção, daqui
a um ano".
