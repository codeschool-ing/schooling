---
title: Que linhas vão para que máquina
version: 1
---

O jeito usual de espalhar uma tabela entre nós é por **hash de uma coluna**: calcula-se um hash do valor
da coluna, tira-se o resto pela quantidade de nós, e esse é o nó. O mesmo valor sempre cai no mesmo nó, o
que importa para as junções, e valores diferentes se espalham mais ou menos por igual, o que importa para
o equilíbrio. A coluna se chama **chave de distribuição**; o Redshift a chama de `DISTKEY`, e a lição 9 a
mostra lá.

Há uma máquina no laboratório, então os quatro nós aqui são aritmética: um hash módulo 4, contado. Duas
chaves candidatas para a tabela de vendas, o número do pedido e a loja:

```sql
-- Where the sales rows would go on four machines, by two choices of key.
SELECT hash(order_id) % 4 AS node, count(*) AS rows_by_order
FROM fact_sales GROUP BY node ORDER BY node;

SELECT hash(shop_key) % 4 AS node, count(*) AS rows_by_shop
FROM fact_sales GROUP BY node ORDER BY node;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < nodes.sql
┌────────┬───────────────┐
│  node  │ rows_by_order │
│ uint64 │     int64     │
├────────┼───────────────┤
│      0 │        221229 │
│      1 │        221827 │
│      2 │        222387 │
│      3 │        222034 │
└────────┴───────────────┘
┌────────┬──────────────┐
│  node  │ rows_by_shop │
│ uint64 │    int64     │
├────────┼──────────────┤
│      0 │       643004 │
│      1 │        60805 │
│      2 │       183668 │
└────────┴──────────────┘
```

**Por número de pedido, os quatro nós recebem entre 221.229 e 222.387 linhas cada**: uma diferença de meio
por cento. Há 572.439 números de pedido diferentes, então o hash tem valores de sobra para espalhar, e a
lei dos grandes números faz o resto.

**Por loja, um nó recebe 643.004 linhas, um recebe 60.805, um recebe 183.668, e o quarto não recebe
nada.** Há só sete lojas, então o hash tem sete valores para pôr em quatro nós, e os pôs de forma
desigual, como sete valores costumam cair. Uma consulta nesse arranjo é tão lenta quanto o nó com 643.004
linhas, que são 72% da tabela, enquanto um nó fica parado.

A lição dos dois resultados é a primeira regra de escolha de uma chave de distribuição: **ela precisa de
muitos valores distintos, espalhados por igual.** Um número de pedido, um número de cliente, um id de
item. Nunca um status, um país, uma loja ou uma data com um punhado de valores. A próxima seção mostra a
segunda regra, que é sobre os valores estarem *espalhados por igual*, e por que sete lojas seriam
desiguais mesmo com sete nós.
