---
title: Sensível pelo que revela
version: 1
---

`sales.order_items` tem cinco colunas: um pedido, um número de linha, um produto, uma quantidade e
um preço. Nada ali foi projetado como dado de saúde. Eis o que ela diz dos clientes da Ipê:

```sql
-- What a pharmacy's order lines say about the people who placed them.
SET ROLE ipe_owner;
SELECT p.category,
       count(DISTINCT o.customer_id) AS customers
FROM sales.order_items i
JOIN sales.orders o   USING (order_id)
JOIN sales.products p USING (product_id)
WHERE p.category IN ('psychiatric', 'diabetes', 'contraceptive',
                     'diagnostic', 'cardiovascular', 'thyroid')
GROUP BY p.category ORDER BY customers DESC;
```

```
ana@lab:~/gov$ psql -f inferred.sql
SET
    category    | customers 
----------------+-----------
 psychiatric    |      3531
 cardiovascular |      2581
 diabetes       |      2560
 contraceptive  |      1664
 thyroid        |      1645
 diagnostic     |      1606
(6 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT name, category FROM sales.products WHERE category = 'diagnostic'"
SET
       name        |  category  
-------------------+------------
 Teste de gravidez | diagnostic
(1 row)
```

3.531 clientes compraram um remédio psiquiátrico; 2.560, algo para diabetes; 1.664, um
anticoncepcional. E o único produto de `diagnostic`:

**Um teste de gravidez.** 1.606 clientes compraram um. Um histórico de compras é, portanto, dado
sobre saúde e vida sexual de boa parte dos clientes da Ipê — dado sensível no sentido do artigo 5º,
II, não porque alguém o rotulou assim, e sim pelo que revela. As compras do laboratório são geradas
e espalhadas por igual entre os produtos, então os números são maiores do que os de uma farmácia
real; a conclusão não depende deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l6-inference\" aria-label=\"Uma linha de pedido guarda um id de produto. O produto pertence a uma categoria. A categoria diz algo da saúde de quem comprou: psiquiátrico, diabetes, anticoncepcional, um teste de gravidez. A linha de pedido é, portanto, dado de saúde, embora nenhuma coluna diga isso.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">order_items</text><text x=\"95.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_id = 25</text><rect x=\"215.0\" y=\"60.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">products</text><text x=\"290.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Clonazepam 2 mg</text><rect x=\"410.0\" y=\"60.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">category</text><text x=\"480.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">psychiatric</text><rect x=\"595.0\" y=\"50.0\" width=\"105.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">revela</text><text x=\"647.5\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma condição</text><text x=\"647.5\" y=\"105.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de saúde</text><path d=\"M170.0 90.0 L213.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M365.0 90.0 L408.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><path d=\"M550.0 90.0 L593.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhuma coluna de order_items se chama saúde, e a linha é dado de saúde</text></svg>", "caption": "O que uma linha revela, e não onde ela está arquivada, decide se ela é sensível.", "same": ["Clonazepam 2 mg"]}
```

## O que decorre disso

**`product_id` nas linhas de pedido de uma farmácia é uma coluna sensível**, e a seção 7 a classifica
assim. A consequência é concreta:

- a concessão dos analistas em `order_items`, da aula 2, é uma concessão sobre dado de saúde, e
  precisa da base legal e do cuidado que isso implica;
- uma exportação de linhas de pedido para um parceiro de marketing é uma transferência de dado de
  saúde;
- um modelo treinado com históricos de compra para "recomendar produtos" está tratando dado de saúde,
  e pode estar fazendo inferências sobre condições de pessoas que elas nunca compartilharam.

**A inferência funciona também sem nome de produto.** Um padrão de pedidos a cada 30 dias do mesmo
item sob receita, a hora das compras, uma mudança no tamanho da cesta — colunas derivadas e modelos
podem revelar o que a tabela crua não mostrava de relance. Um exercício de classificação que só lê
nomes de colunas perde tudo isso; um que pergunta *"o que alguém concluiria disto?"* acha.
