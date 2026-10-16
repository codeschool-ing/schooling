---
title: Uma taxa sobre quatro pedidos
version: 1
---

Taxas de reembolso por região, em toda a vida da loja:

```
lantern=# SELECT c.region, count(*) AS orders,
lantern-#        count(*) FILTER (WHERE o.status = 'refunded') AS refunded,
lantern-#        round(100.0 * count(*) FILTER (WHERE o.status = 'refunded') / count(*), 1) AS refund_pct
lantern-# FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
lantern-# GROUP BY 1 ORDER BY 2 DESC;
  region   | orders | refunded | refund_pct 
-----------+--------+----------+------------
 Southeast |   5437 |      201 |        3.7
 South     |   1126 |       39 |        3.5
 Northeast |    486 |       13 |        2.7
 North     |     49 |        4 |        8.2
(4 rows)
```

Lido como ranking, o Norte reembolsa mais que o dobro de qualquer outro lugar: 8,2% contra 3,7%. Lido
como contagem, o Norte teve 49 pedidos e quatro reembolsos. **Um reembolso a mais o levaria a 10,2%; um a
menos, a 6,1%.** Uma taxa convence mais quanto menos deveria merecer confiança, porque um denominador
pequeno produz justamente os valores extremos que fazem uma manchete.

A aula 6 encontrou a mesma coisa num painel, como uma região com cinco pedidos num mês. A versão do
analista para a regra é mais forte que "mostre a contagem":

- **Decida um mínimo antes de ler o ranking.** Uma taxa abaixo do mínimo não é mostrada como número, ou
  aparece esmaecida com a contagem, e o mínimo está escrito na página.
- **Olhe um intervalo, não um ponto.** Com 4 reembolsos em 49, o erro padrão da aula 9 é
  √(0,082 × 0,918 / 49), cerca de 3,9 pontos. A taxa do Norte está "em algum lugar entre uns 0% e 16%",
  o que inclui os 3,7% do Sudeste.
- **Pergunte se a diferença sobreviveria a um mês.** Se no mês seguinte o Norte tiver 2 reembolsos em 5
  pedidos, são 40%, e ninguém deveria mudar uma política por isso também.

A pergunta que pega isso: **quantas coisas esta taxa está contando?**
