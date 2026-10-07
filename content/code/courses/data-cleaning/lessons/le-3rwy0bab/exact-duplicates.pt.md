---
title: Duplicados exatos: a mesma linha duas vezes
version: 1
---

**Um duplicado exato é uma linha que repete outra em todas as colunas.** É o tipo fácil, e só é
fácil depois de decidir que duas linhas idênticas são uma coisa contada duas vezes, e não duas
coisas que por acaso se parecem. Num arquivo de clientes com uma coluna de id, essa decisão é
segura: duas linhas com o mesmo id e tudo o mais igual são um cliente.

As duas ferramentas os contam do mesmo jeito:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('raw/customers.csv', dtype=str); print(c.duplicated().sum(), c['customer_id'].duplicated().sum())"
37 37
ana@lab:~/clean$ psql -c 'SELECT count(*) AS rows, count(DISTINCT c) AS distinct_rows FROM raw.customers c'
 rows | distinct_rows 
------+---------------
 2413 |          2376
(1 row)
```

`duplicated()` marca toda linha que repete uma anterior, então a soma é o número de cópias a
mais: 37. As mesmas 37 linhas repetem o `customer_id`, o que confirma que as cópias são linhas inteiras e
não dois clientes dividindo um id. Em SQL, `count(DISTINCT c)` conta linhas inteiras distintas,
porque `c` é a própria linha; 2.413 linhas e 2.376 distintas.

Removê-las é `drop_duplicates()` no pandas e `SELECT DISTINCT` em SQL, e os dois mantêm uma cópia
de cada. **O perfil da aula 2 achou essas 37 antes de alguém ir procurar**, como a diferença entre
preenchidos e distintos em `customer_id`.

## Quando é preciso manter uma de propósito

`DISTINCT` não escolhe qual cópia sobrevive, o que não importa quando as cópias são idênticas.
Quando não são, a ferramenta é uma função de janela que numera as cópias dentro de cada chave:

```
ana@lab:~/clean$ psql -c "SELECT order_id, total, row_number() OVER (PARTITION BY order_id ORDER BY order_id) AS copy FROM raw.orders WHERE order_id IN (SELECT order_id FROM raw.orders GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id LIMIT 6"
 order_id | total | copy 
----------+-------+------
 102757   | 56.55 |    1
 102757   | 56.55 |    2
 102918   | 37.00 |    1
 102918   | 37.00 |    2
 105385   | 27.20 |    1
 105385   | 27.20 |    2
(6 rows)
```

Todo pedido repetido aparece com `copy` 1 e 2, e manter `copy = 1` mantém um de cada. Com um
`ORDER BY` dentro da janela — o horário mais recente primeiro, por exemplo — a mesma consulta
mantém uma cópia escolhida em vez de uma qualquer, que é o que a próxima seção precisa.
