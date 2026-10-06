---
title: Uma medida na granularidade errada
version: 1
---

O site cobra R$ 14,90 de frete em pedidos abaixo de R$ 150. A cobrança pertence ao pedido: um frete
por pacote, quantos livros houver nele. O gerente quer o frete nos relatórios de vendas, e o lugar
óbvio é a tabela de vendas:

```sql
-- The shipping fee, copied onto every line of its order.
CREATE TABLE sales_with_shipping AS
SELECT f.*, o.shipping_cents
FROM fact_sales f JOIN staging.orders o USING (order_id);

SELECT (SELECT sum(shipping_cents) FROM sales_with_shipping)        AS summed_over_lines,
       (SELECT sum(shipping_cents) FROM staging.orders
         WHERE status <> 'cancelled')                                AS charged;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < shipping-wrong.sql
┌───────────────────┬───────────┐
│ summed_over_lines │  charged  │
│      int128       │  int128   │
├───────────────────┼───────────┤
│         236410850 │ 225246280 │
└───────────────────┴───────────┘
```

**A tabela agora diz que a rede cobrou R$ 2.364.108,50 de frete. Ela cobrou R$ 2.252.462,80.** A
diferença, R$ 111.645,70, é o frete de todo pedido com mais de um item, contado uma vez por item. Um
pedido com três livros carrega o frete três vezes.

Nada falhou. A junção estava correta, cada linha é uma afirmação verdadeira sobre o seu pedido, e a
coluna parece qualquer outra medida da tabela. O erro só aparece diante de um total calculado de outro
jeito, que é exatamente a comparação que ninguém faz numa tarde movimentada.

**O frete tem um valor por pedido, não por item**, então reprova no teste da seção anterior. Dois
reparos mantêm os números honestos, e os dois aparecem em warehouses de verdade:

- **Ratear.** Dividir o frete de cada pedido entre os itens de modo que as partes somem o frete. Aí
  ele *tem* um valor por item, e pode ser somado com todo o resto. A próxima seção constrói isso.
- **Mantê-lo na sua granularidade.** O frete é cobrado por pedido, então vai para uma tabela cujas
  linhas são pedidos. A seção 05 mostra por que essa também é a resposta para os pagamentos.
