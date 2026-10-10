---
title: O centro e a dispersão, e por que a média é o primeiro número errado
version: 1
---

Peça "o pedido médio" e a maioria das pessoas, e das ferramentas, calcula a **média**: a soma
dividida pela contagem. Numa distribuição assimétrica a média é puxada para a cauda, e a
**mediana** — o valor com metade das linhas abaixo e metade acima — não é:

```
lantern=# SELECT round(avg(gross_cents) / 100.0, 2) AS mean_brl,
lantern-#        percentile_cont(0.5) WITHIN GROUP (ORDER BY gross_cents) / 100 AS median_brl
lantern-# FROM order_totals;
 mean_brl | median_brl 
----------+------------
   170.23 |       95.8
(1 row)

lantern=# SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gross_cents)
lantern-#        AS quartiles_cents
lantern-# FROM order_totals;
  quartiles_cents  
-------------------
 {4790,9580,16865}
(1 row)
```

O pedido médio é R$ 170,23 e a mediana é R$ 95,80. **Menos da metade dos pedidos da Lantern chega
perto do pedido "médio"**: a média é quase o dobro do que um cliente típico gasta, porque uma
minoria de pedidos grandes a puxa para cima. Se uma campanha fosse planejada em torno de um pedido
típico de R$ 170, seria planejada para um cliente que a loja quase não tem.

O `percentile_cont` recebe a fração de linhas que deve ficar abaixo da resposta, e, se receber uma
lista, responde uma lista. Os três **quartis** dividem os pedidos em quatro grupos do mesmo
tamanho: um quarto está abaixo de R$ 47,90, metade abaixo de R$ 95,80, três quartos abaixo de R$
168,65. A distância entre o primeiro e o terceiro, R$ 120,75, é a **amplitude interquartil**, ou
IQR: a largura da metade do meio dos pedidos. Ao contrário da amplitude do menor ao maior, ela não
se mexe quando chega uma linha absurda.

## A mesma pergunta, feita a cada grupo

O salto no fim do histograma sugeria dois grupos. A Lantern vende para pessoas em casa e para
escritórios, e a coluna `segment` diz qual:

```
lantern=# SELECT c.segment, count(*) AS orders,
lantern-#        round(avg(t.gross_cents) / 100.0, 2) AS mean_brl,
lantern-#        percentile_cont(0.5) WITHIN GROUP (ORDER BY t.gross_cents) / 100 AS median_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY c.segment;
 segment | orders | mean_brl | median_brl 
---------+--------+----------+------------
 home    |   6418 |   120.22 |       85.8
 office  |    684 |   639.51 |     456.25
(2 rows)
```

Dois negócios diferentes. Os 6.418 pedidos home têm mediana de R$ 85,80; os 684 pedidos office
têm mediana de R$ 456,25, mais de cinco vezes isso. **Uma média só sobre os dois não descreve
nenhum**: R$ 170,23 fica muito acima do que um cliente home gasta e muito abaixo do que um
escritório gasta.

Esse é o primeiro hábito que a análise exploratória constrói: antes de resumir uma coluna,
pergunte se ela guarda uma população ou várias. Um número que as mistura não é aritmética errada,
e pode estar errado sobre todo mundo na tabela.
