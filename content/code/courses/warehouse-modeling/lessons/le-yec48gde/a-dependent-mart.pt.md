---
title: Um mart dependente, feito de views
version: 1
---

O time de vendas da Ponto Final quer uma coisa: vendas líquidas por loja e por mês. Ana dá a eles um esquema
próprio, com uma view, construída sobre a estrela:

```sql
-- The sales team's mart: views over the warehouse's star, nothing copied.
CREATE SCHEMA mart_sales;
CREATE VIEW mart_sales.monthly AS
SELECT d.year, d.month, s.shop_name,
       count(DISTINCT f.order_id) AS orders,
       sum(f.net_cents)           AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
GROUP BY ALL;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < mart_sales.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT shop_name, orders, net_cents FROM mart_sales.monthly WHERE year = 2025 AND month = 12 ORDER BY net_cents DESC"
┌───────────┬────────┬───────────┐
│ shop_name │ orders │ net_cents │
│  varchar  │ int64  │  int128   │
├───────────┼────────┼───────────┤
│ Online    │  20054 │ 347127604 │
│ Paulista  │   6347 │ 110429646 │
│ Pinheiros │   5162 │  90713293 │
│ Savassi   │   3688 │  65405886 │
│ Cambuí    │   3160 │  54340150 │
│ Batel     │   2693 │  46884660 │
│ Moinhos   │   2355 │  40913243 │
└───────────┴────────┴───────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12"
┌───────────┐
│ december  │
│  int128   │
├───────────┤
│ 755814482 │
└───────────┘
```

**Nada foi copiado.** Uma view guarda sua consulta, não suas linhas, então o mart não ocupa espaço e nunca fica
atrás do warehouse: toda pergunta que ele responde é feita à `fact_sales` no momento em que é feita. O time de vendas
vê uma tabela com o nome da loja, sem chaves e sem junções, e o número de dezembro do warehouse, 755.814.482
centavos.

O que o torna dependente está à vista na consulta. A medida é a `net_cents` do warehouse, com a regra do warehouse
sobre pedidos cancelados já aplicada dentro da `fact_sales`. O mês vem da `dim_date` e a loja da `dim_shop`, as
mesmas linhas que todo outro mart vai usar. O time de vendas não consegue tirar deste mart uma resposta diferente da
do warehouse, porque só há um lugar de onde a resposta vem.

Um mart tão fino é uma questão de conveniência: um esquema ao qual o time pode receber acesso, e nomes que ele
consegue ler. Quando views sobre uma tabela fato grande ficam lentas, o mesmo mart pode ser feito de tabelas de
resumo, os agregados da lição 6, refeitos a cada carga. Continua dependente, porque continua construído a partir da
estrela; só passa a precisar ser refeito, e a lição 6 mostrou o que acontece quando alguém esquece.
