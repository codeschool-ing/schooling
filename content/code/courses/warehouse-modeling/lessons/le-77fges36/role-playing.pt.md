---
title: Uma tabela de datas, vários papéis
version: 1
---

`fact_fulfilment` tem quatro chaves de data: pedido, pagamento, envio e entrega. As quatro apontam
para a `dim_date`. Uma única dimensão física usada em vários papéis numa tabela fato é uma **dimensão
de papéis** (role-playing), e a data quase sempre é a primeira que um warehouse encontra.

A dificuldade está na consulta. Um relatório que precisa do dia em que o pedido foi feito *e* do dia
em que saiu tem de ligar a `dim_date` duas vezes, e uma coluna chamada `day_name` passa a ser ambígua.
A resposta comum é uma view por papel, para que cada papel tenha um nome que uma pessoa consiga ler:

```sql
-- One date dimension, two roles: the day an order was placed, and the day it left.
CREATE VIEW dim_order_date AS SELECT * FROM dim_date;
CREATE VIEW dim_ship_date  AS SELECT * FROM dim_date;

SELECT od.day_name AS ordered_on, sd.day_name AS shipped_on, count(*) AS orders
FROM fact_fulfilment f
JOIN dim_order_date od ON od.date_key = f.ordered_date_key
JOIN dim_ship_date  sd ON sd.date_key = f.shipped_date_key
WHERE od.day_of_week = 5
GROUP BY ALL ORDER BY orders DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < roles.sql
┌────────────┬────────────┬────────┐
│ ordered_on │ shipped_on │ orders │
│  varchar   │  varchar   │ int64  │
├────────────┼────────────┼────────┤
│ Friday     │ Monday     │  17091 │
│ Friday     │ Tuesday    │  11170 │
│ Friday     │ Wednesday  │   5502 │
└────────────┴────────────┴────────┘
```

Pedidos feitos numa sexta saíram mais na segunda que em qualquer outro dia, porque o depósito não
despacha nos fins de semana; quase todo o resto saiu na terça. As duas views não custam nada de
armazenamento, já que cada uma é a mesma tabela com outro nome, e fazem a consulta dizer a que data se
refere em cada linha.

**Use o nome do papel em todo lugar que uma pessoa for ver.** Uma ferramenta de relatório mostra
`dim_ship_date.month_name` como *Ship date › Month*, e ninguém precisa adivinhar a qual das quatro
datas uma coluna pertence. Alguns times renomeiam também as colunas dentro de cada view (`ship_month`,
`order_month`) para que o papel sobreviva mesmo quando o nome da tabela não aparece.

Outras dimensões também fazem papéis, sempre que um fato se refere a duas coisas do mesmo tipo: uma
transferência de estoque de uma loja para outra aponta para a `dim_shop` duas vezes, como a loja que
envia e a loja que recebe.
