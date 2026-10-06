---
title: Três marts, três respostas
version: 1
---

O financeiro nunca usou o warehouse. Construiu seu próprio mart, a partir da extração, para responder à sua própria
pergunta: quanto dinheiro entrou. O marketing fez o mesmo, um ano depois, para os relatórios de campanha. Nenhum dos
dois está errado para aquilo para que foi feito:

```sql
-- Finance's mart, built by another team straight from the extract:
-- the money customers paid, by the day of the order.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_finance;
CREATE TABLE mart_finance.receipts AS
SELECT CAST(o.ordered_at AS DATE) AS day, o.shop_id,
       sum(p.amount_cents) AS amount_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
```

```sql
-- Marketing's mart, a third team's: payments by the day they were made.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_marketing;
CREATE TABLE mart_marketing.revenue AS
SELECT CAST(o.paid_at AS DATE) AS day,
       sum(p.amount_cents) AS revenue_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
```

Os três times recebem a mesma pergunta na mesma reunião: **qual foi a receita de dezembro?**

```
ana@lab:~/wh$ duckdb wh.duckdb < mart_finance.sql && duckdb wh.duckdb < mart_marketing.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT 'sales' AS mart, sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12
UNION ALL SELECT 'finance', sum(amount_cents) FROM mart_finance.receipts WHERE day BETWEEN '2025-12-01' AND '2025-12-31'
UNION ALL SELECT 'marketing', sum(revenue_cents) FROM mart_marketing.revenue WHERE day BETWEEN '2025-12-01' AND '2025-12-31'"
┌───────────┬───────────┐
│   mart    │ december  │
│  varchar  │  int128   │
├───────────┼───────────┤
│ sales     │ 755814482 │
│ finance   │ 773739182 │
│ marketing │ 365065882 │
└───────────┴───────────┘
```

Três números, entre R$ 3,65 milhões e R$ 7,74 milhões, de três marts que fizeram, cada um, o que seus autores
pretendiam. Ninguém errou o SQL. Eles tomaram três decisões diferentes sobre uma palavra:

- **Vendas** conta o valor dos livros vendidos em pedidos não cancelados, no dia do pedido.
- **Financeiro** conta todo pagamento, o que inclui o frete que o cliente pagou, no dia do pedido.
- **Marketing** conta todo pagamento no dia em que foi pago, e só pedidos que têm data de pagamento.

Na reunião, a conversa que se segue é sobre qual número está certo, e ela ocupa o resto da hora. **A pergunta que a
resolveria é qual número responde a qual pergunta**, e isso exige saber como cada um foi construído, o que só seus
autores sabem. A próxima seção faz o trabalho que a reunião não fez.
