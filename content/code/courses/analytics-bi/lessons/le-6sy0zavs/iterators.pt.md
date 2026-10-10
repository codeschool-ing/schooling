---
title: Iteradores, e as duas médias da aula 2
version: 1
---

`SUM` soma uma coluna. O irmão dele, `SUMX`, recebe uma tabela e uma expressão, avalia a expressão
uma vez por linha da tabela e soma os resultados. Toda agregação tem uma versão **iteradora** assim —
`AVERAGEX`, `MINX`, `COUNTX` — e é com elas que o DAX expressa "para cada … então …".

A aula 2 mostrou que o valor médio do pedido da Lantern é um número como razão das somas e outro
como média da média de cada cliente. Em DAX, o primeiro é a medida de três seções atrás; o segundo
itera sobre os clientes:

```
Net Revenue per Order = DIVIDE ( [Net Revenue], [Orders] )

Average Customer's Revenue per Order =
    AVERAGEX ( VALUES ( customers[customer_id] ), [Net Revenue per Order] )
```

(Não rodou.) `VALUES ( customers[customer_id] )` é a lista de clientes no contexto atual; o
`AVERAGEX` avalia a medida por pedido uma vez para cada um deles, num contexto estreitado àquele
cliente, e tira a média dos resultados. O SQL para 2026 até agora:

```
lantern=# SELECT round(sum(net_revenue) / count(*), 2) AS per_order
lantern-# FROM semantic.orders WHERE order_date >= '2026-01-01';
 per_order 
-----------
    153.27
(1 row)

lantern=# SELECT round(avg(per_customer), 2) AS per_customer
lantern-# FROM (SELECT customer_id, sum(net_revenue) / count(*) AS per_customer
lantern(#       FROM semantic.orders WHERE order_date >= '2026-01-01'
lantern(#       GROUP BY customer_id) AS c;
 per_customer 
--------------
       144.15
(1 row)
```

R$ 153,27 por pedido contra R$ 144,15 do cliente médio: a mesma distância da aula 2, pelo mesmo
motivo. As duas fórmulas estão certas e respondem a perguntas diferentes. **O perigo é as duas
estarem a um nome de função uma da outra**, e um relatório que mostra "Valor médio do pedido" não diz
qual calculou. O nome da medida deveria dizer.

Um detalhe do `AVERAGEX` vale saber porque mexe no número: uma medida citada dentro de um iterador é
avaliada no contexto de cada linha, o que a documentação da Microsoft chama de *transição de
contexto*. Foi isso que fez a média por cliente acima funcionar sem escrever filtro nenhum. É também
por isso que um iterador sobre uma tabela grande pode ser lento: ele avalia a medida uma vez por
linha.
