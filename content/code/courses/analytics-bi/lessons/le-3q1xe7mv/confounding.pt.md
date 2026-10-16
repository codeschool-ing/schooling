---
title: O desconto que parece fazer as pessoas gastarem
version: 1
---

A aula 1 encontrou esse fator de confusão como uma correlação de 0,271, numa consulta exploratória que
ninguém fora do time de dados veria. Aqui ele está na forma em que chega a um slide. O marketing quer saber
se descontos fazem os clientes comprar mais, e a resposta parece vir na hora:

```
lantern=# SELECT discount > 0 AS discounted, count(*) AS orders, round(avg(gross), 2) AS avg_gross
lantern-# FROM semantic.orders WHERE status = 'paid'
lantern-# GROUP BY 1 ORDER BY 1;
 discounted | orders | avg_gross 
------------+--------+-----------
 f          |   4801 |    114.30
 t          |   2040 |    281.72
(2 rows)
```

Pedidos com desconto têm valor bruto médio de R$ 281,72; sem desconto, R$ 114,30. **Cestas com desconto
são 2,5 vezes maiores.** É uma frase muito mais persuasiva que *r* = 0,271, e é exatamente por isso que é
mais perigosa: é a razão entre duas médias, todo mundo a entende, e a proposta se escreve sozinha — dar
mais desconto.

Divida por segmento de cliente, como a aula 1 fez:

```
lantern=# SELECT c.segment, o.discount > 0 AS discounted, count(*) AS orders,
lantern-#        round(avg(o.gross), 2) AS avg_gross
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# WHERE o.status = 'paid'
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 segment | discounted | orders | avg_gross 
---------+------------+--------+-----------
 home    | f          |   4801 |    114.30
 home    | t          |   1383 |    112.87
 office  | t          |    657 |    637.16
(3 rows)
```

Todo pedido de escritório tem desconto, os 15% que escritórios sempre recebem, e pedidos de escritório são
grandes porque escritórios compram em quantidade. Entre clientes de casa, o único grupo em que há pedidos
com e sem desconto, os com desconto têm média de R$ 112,87 e os outros, R$ 114,30: **nenhuma diferença.**
O segmento causa o desconto e a cesta grande, e os 2,5 eram uma comparação de escritórios com casas,
rotulada como com desconto contra preço cheio.

O que torna um fator de confusão difícil de ver num relatório é que a divisão que o revela é uma que
ninguém pediu. A pergunta era sobre descontos; a resposta mora numa coluna sobre clientes. Então o hábito
não é "dividir por segmento", e sim **perguntar o que mais difere entre os dois grupos antes de confiar na
diferença**.

Dividir por toda candidata é a defesa fraca: sempre há mais uma coluna. A forte é o grupo de controle da
aula 9. Se um teste dá o desconto a clientes escolhidos ao acaso, então segmento, região e todo o resto
ficam distribuídos igualmente pelos dois grupos por construção, e a diferença que sobrar é do desconto.

A pergunta que pega isso: **o que mais é diferente entre os dois grupos que estou comparando?**
