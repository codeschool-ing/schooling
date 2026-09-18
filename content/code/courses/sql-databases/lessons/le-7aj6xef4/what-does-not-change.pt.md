---
title: A parte que é igual em todo lugar
version: 1
---

Antes das diferenças, a coisa sobre a qual elas se apoiam: **quase tudo que este curso ensinou
roda sem mudança nos quatro motores.** Isso não é gentileza. É o motivo pelo qual as onze aulas
anteriores valeram como assunto e não como manual.

Aqui está um relatório contra a loja — três tabelas, uma junção, um filtro, uma agregação e uma
ordenação. O mesmo texto, mandado para três motores:

```
shop=# SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
   city    | orders | revenue 
-----------+--------+---------
 Curitiba  |      1 | 2998.00
 Recife    |      2 | 1928.70
 Sao Paulo |      1 |  228.90
(3 rows)
```

```
mysql> SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
+-----------+--------+---------+
| city      | orders | revenue |
+-----------+--------+---------+
| Curitiba  |      1 | 2998.00 |
| Recife    |      2 | 1928.70 |
| Sao Paulo |      1 |  228.90 |
+-----------+--------+---------+
```

```
sqlite> SELECT c.city, count(DISTINCT o.id) AS orders, sum(l.quantity * l.unit_price) AS revenue FROM customers c JOIN orders o ON o.customer_id = c.id JOIN order_lines l ON l.order_id = o.id WHERE o.status <> 'cancelled' GROUP BY c.city ORDER BY revenue DESC;
city       orders  revenue
---------  ------  -------
Curitiba   1       2998   
Recife     2       1928.7 
Sao Paulo  1       228.9  
```

As mesmas linhas, na mesma ordem, com as mesmas contagens. As molduras ao redor são dos clientes —
o `psql` traça uma régua sob os títulos, o cliente do MySQL desenha uma caixa, o shell do SQLite
não desenha nenhum dos dois a menos que você peça — e nada disso é o banco.

## O que é portátil, e é a maior parte

| aula | o que atravessa |
|---|---|
| 1, 2 | o modelo relacional, chaves, normalização. Não é recurso de motor nenhum |
| 3 | `CREATE TABLE`, `NOT NULL`, `UNIQUE`, `PRIMARY KEY`, `FOREIGN KEY`, `CHECK` |
| 4 | `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` |
| 5 | `INNER`, `LEFT` e `CROSS JOIN` |
| 6 | os agregados, `GROUP BY`, `HAVING`, e funções de janela nos quatro |
| 7 | subconsultas, `EXISTS`, `WITH`, views |
| 8 | `BEGIN`, `COMMIT`, `ROLLBACK`, e as anomalias que dão nome aos níveis de isolamento |
| 9 | `CREATE INDEX`, o prefixo mais à esquerda, por que uma função sobre a coluna derruba um índice |
| 10 | que existe um plano, e que você o lê antes de mudar qualquer coisa |

Funções de janela são o item mais novo dessa lista e o que vale datar, porque a internet ainda
carrega conselho de antes de elas chegarem: o SQLite tem desde a 3.25, em 2018; o MySQL desde a
8.0, em 2018; o MariaDB desde a 10.2, em 2017. O PostgreSQL tem desde 2009. Em qualquer versão que
alguém instale hoje, os quatro têm.

## Então o que sobra

As diferenças se dividem em quatro grupos, e o resto da aula é uma seção para cada:

**O que o motor recusa.** O mesmo `INSERT` é um erro em um e uma linha guardada em outro. É a
maior distância dos quatro e não está perto.

**Como o texto é comparado.** Se `'ANA@EXAMPLE.COM'` encontra `ana@example.com` é um padrão do
motor, e decide se uma restrição `UNIQUE` sobre um endereço significa o que você acha.

**O dialeto.** Sintaxe miúda: como uma chave se autonumera, o que `||` faz, quanto é `5 / 2`, se
existe `RETURNING`.

**Como ele é operado.** Replicação, backup, atualizações e quem está de plantão — que é o que de
fato decide um motor numa empresa, e não tem nada a ver com SQL.

A aula 10 já cobriu o quinto grupo, o `EXPLAIN`, que se lê de um jeito em cada um dos três
servidores e tem uma seção própria lá. Esta aula não repete isso.
