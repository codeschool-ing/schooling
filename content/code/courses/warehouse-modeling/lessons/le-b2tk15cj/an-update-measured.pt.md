---
title: Uma renomeação, medida de três jeitos
version: 1
---

Pegue a desnormalização mais extrema que existe: toda venda, com todo atributo de toda dimensão escrito
na sua linha. **Uma tabela larga** (one big table, OBT):

```sql
-- One big table: every sale with every attribute of its dimensions on the row.
CREATE TABLE sales_wide AS
SELECT f.order_id, f.line_no, f.quantity, f.gross_cents, f.discount_cents, f.net_cents,
       d.date, d.year, d.month, d.month_name, d.day_name, d.is_weekend, d.is_holiday,
       s.shop_name, s.city AS shop_city, s.state AS shop_state, s.region, s.channel,
       b.isbn, b.title, b.authors, b.format, b.category, b.subcategory, b.department,
       b.publisher,
       c.tier, c.city AS customer_city, c.state AS customer_state,
       p.code AS promotion_code, p.promotion_name
FROM fact_sales f
JOIN dim_date d      USING (date_key)
JOIN dim_shop s      USING (shop_key)
JOIN dim_book b      USING (book_key)
JOIN dim_customer c  USING (customer_key)
JOIN dim_promotion p USING (promotion_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < obt.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS rows, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'sales_wide') AS columns FROM sales_wide"
┌────────┬─────────┐
│  rows  │ columns │
│ int64  │  int64  │
├────────┼─────────┤
│ 887477 │      31 │
└────────┴─────────┘
```

887.477 linhas, 31 colunas, e nenhuma junção sobrando para alguém escrever. Agora suponha que a rede
renomeie o departamento *Non-fiction* para *Nonfiction*. Onde isso grava?

```sql
-- The department "Non-fiction" is renamed "Nonfiction". Where does that write?
SELECT (SELECT count(*) FROM sf_department_demo WHERE department = 'Non-fiction') AS snowflake_rows,
       (SELECT count(*) FROM dim_book WHERE department = 'Non-fiction')            AS star_rows,
       (SELECT count(*) FROM sales_wide WHERE department = 'Non-fiction')          AS wide_rows;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -c "CREATE TABLE sf_department_demo AS SELECT DISTINCT department FROM dim_book"
ana@lab:~/wh$ duckdb wh.duckdb < rename.sql
┌────────────────┬───────────┬───────────┐
│ snowflake_rows │ star_rows │ wide_rows │
│     int64      │   int64   │   int64   │
├────────────────┼───────────┼───────────┤
│              1 │      1185 │    375294 │
└────────────────┴───────────┴───────────┘
```

**Uma linha numa tabela de departamentos normalizada. 1.185 linhas na `dim_book` da estrela. 375.294
linhas na tabela larga.** A estrela repete o nome uma vez por livro, e a carga o reescreve sem perceber.
A tabela larga o repete uma vez por venda, e uma renomeação vira uma operação sobre quase metade da
maior tabela do warehouse.

Agora suponha que essa operação seja interrompida. A atualização reescreveu 2025 e ainda não chegou a
2024:

```sql
-- The rename, interrupted halfway: 2025 has been rewritten and 2024 not yet.
BEGIN;
UPDATE sales_wide SET department = 'Nonfiction'
WHERE department = 'Non-fiction' AND year = 2025;

SELECT year, department, count(*) AS lines
FROM sales_wide WHERE department IN ('Non-fiction', 'Nonfiction')
GROUP BY ALL ORDER BY ALL;
ROLLBACK;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < half-update.sql
┌───────┬─────────────┬────────┐
│ year  │ department  │ lines  │
│ int64 │   varchar   │ int64  │
├───────┼─────────────┼────────┤
│  2024 │ Non-fiction │ 168480 │
│  2025 │ Nonfiction  │ 206814 │
└───────┴─────────────┴────────┘
```

Aí está a anomalia de atualização da seção 02, viva num warehouse: um departamento com dois nomes, e todo
relatório agrupado por departamento mostrando duas linhas para ele, divididas por ano. A transação a
desfez, então a tabela está inteira de novo. Uma carga que atualizasse no lugar sem transação, ou uma
pessoa corrigindo um nome à mão, a teria deixado assim.

**Este é o custo real da tabela larga, e não é armazenamento.** A tabela larga é uma cópia derivada, e o
jeito seguro de mudá-la é reconstruí-la a partir da estrela. Tratada assim, é uma conveniência. Editada
no lugar, é uma tabela com todas as anomalias da normalização e nenhuma das defesas dela.
