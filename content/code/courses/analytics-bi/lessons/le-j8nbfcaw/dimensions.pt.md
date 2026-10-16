---
title: Dimensões, e os níveis dentro de uma
version: 1
---

Uma **dimensão** é um atributo pelo qual você agrupa uma medida. Os clientes da Lantern carregam
três — o estado onde moram, o segmento e o canal por onde chegaram — e a data do pedido é uma
quarta que toda tabela tem. A maior parte do trabalho com uma dimensão não está no agrupamento,
que é um `GROUP BY`, e sim em combinar quais são os valores dela.

## Uma dimensão muitas vezes tem níveis

Os estados se agrupam nas cinco regiões do Brasil, e um relatório para o conselho quer regiões
enquanto um para a logística quer estados. O agrupamento é uma **hierarquia**, e ele também
precisa ser escrito:

```sql
SELECT CASE c.state WHEN 'SP' THEN 'Southeast' WHEN 'RJ' THEN 'Southeast'
                    WHEN 'MG' THEN 'Southeast' WHEN 'PR' THEN 'South'
                    WHEN 'RS' THEN 'South'     WHEN 'BA' THEN 'Northeast'
                    WHEN 'AC' THEN 'North' END AS region,
       count(DISTINCT c.customer_id) AS customers,
       round(sum(r.net_cents) / 100.0, 2) AS net_brl
FROM order_revenue r JOIN customers c USING (customer_id)
WHERE r.status = 'paid' AND r.customer_id <> 1
GROUP BY 1 ORDER BY 3 DESC;
```

```
lantern=# SELECT CASE c.state WHEN 'SP' THEN 'Southeast' WHEN 'RJ' THEN 'Southeast'
lantern-#                     WHEN 'MG' THEN 'Southeast' WHEN 'PR' THEN 'South'
lantern-#                     WHEN 'RS' THEN 'South'     WHEN 'BA' THEN 'Northeast'
lantern-#                     WHEN 'AC' THEN 'North' END AS region,
lantern-#        count(DISTINCT c.customer_id) AS customers,
lantern-#        round(sum(r.net_cents) / 100.0, 2) AS net_brl
lantern-# FROM order_revenue r JOIN customers c USING (customer_id)
lantern-# WHERE r.status = 'paid' AND r.customer_id <> 1
lantern-# GROUP BY 1 ORDER BY 3 DESC;
  region   | customers |  net_brl  
-----------+-----------+-----------
 Southeast |      2008 | 810624.75
 South     |       417 | 186736.44
 Northeast |       183 |  84818.42
 North     |        16 |   5761.78
(4 rows)
```

O Sudeste é a maior parte da loja: 2.008 dos clientes que pagaram, e R$ 810.624,75 de receita
líquida. O Acre, o único estado do Norte nos dados, tem 16.

**O mapeamento dentro daquele `CASE` é uma definição como qualquer outra.** No dia em que alguém
escrever um segundo relatório com um `CASE` próprio e puser a Bahia em outra região, os dois
relatórios vão discordar sobre o Nordeste e os dois vão parecer certos. A aula 3 leva mapeamentos
como esse para uma tabela, para que toda consulta leia o mesmo.

## Qual valor, e quando

Uma cliente que se mudou do Paraná para São Paulo em março tem dois estados: o que tinha quando
pediu em fevereiro, e o que tem agora. Agrupar os pedidos de fevereiro pelo estado atual da
cliente os leva para São Paulo depois do fato, e o relatório do ano passado muda toda vez que
alguém atualiza um endereço. A tabela da Lantern guarda só um estado por cliente, então a questão
não surge aqui — mas surge em toda loja real, e se uma dimensão mostra o valor **da época do
evento ou o atual** faz parte da definição dela. Modelar os dois é o assunto das dimensões de
mudança lenta, em `warehouse-modeling`.
