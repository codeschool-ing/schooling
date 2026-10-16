---
title: Escrevendo a aritmética uma vez
version: 1
---

As três consultas da última seção calcularam o desconto cada uma por conta própria, e a mesma
expressão escrita três vezes são três chances de escrevê-la diferente. A aula 1 pôs o valor bruto
do pedido numa view; esta põe o desconto e o valor líquido ao lado:

```sql
CREATE VIEW order_revenue AS
SELECT order_id, customer_id, ordered_at, status, gross_cents,
       gross_cents * discount_pct / 100 AS discount_cents,
       gross_cents - gross_cents * discount_pct / 100 AS net_cents
FROM order_totals;
```

Digite no `psql lantern`. Ela se apoia em `order_totals`, então essa view precisa existir; se você
reiniciou a loja desde a aula 1, crie-a de novo primeiro.

```
lantern=# CREATE VIEW order_revenue AS
lantern-# SELECT order_id, customer_id, ordered_at, status, gross_cents,
lantern-#        gross_cents * discount_pct / 100 AS discount_cents,
lantern-#        gross_cents - gross_cents * discount_pct / 100 AS net_cents
lantern-# FROM order_totals;
CREATE VIEW
```

Três pedidos, para ver o que ela faz:

```
lantern=# SELECT order_id, status, gross_cents, discount_cents, net_cents
lantern-# FROM order_revenue WHERE order_id IN (5001, 5002, 5003);
 order_id | status | gross_cents | discount_cents | net_cents 
----------+--------+-------------+----------------+-----------
     5001 | paid   |       12990 |              0 |     12990
     5002 | paid   |       29610 |           4441 |     25169
     5003 | paid   |      112790 |          16918 |     95872
(3 rows)
```

O pedido 5001 não teve desconto, então o líquido é igual ao bruto. O pedido 5002 é de escritório,
com 15% de desconto: 15% de 29.610 centavos são 4.441,5, e a view diz 4.441. **A divisão inteira
joga fora o meio centavo**, então o cliente paga meio centavo a mais do que diz a aritmética
exata. Para que lado arredondar é uma regra de negócio, e o ponto é que agora ela está escrita num
lugar só: se o financeiro decidir que a loja arredonda para o outro lado, uma linha muda e todo
número construído sobre a view se move junto.

Daqui em diante, "receita líquida" neste curso significa `sum(net_cents)` sobre pedidos com status
`paid`, sem o cliente 1. Essa frase é uma definição, e o resto desta aula a desmonta para ver do
que ela é feita.
