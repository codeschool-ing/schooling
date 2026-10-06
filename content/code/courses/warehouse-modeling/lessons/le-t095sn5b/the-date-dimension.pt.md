---
title: A data é uma dimensão, não uma coluna
version: 1
---

`fact_sales` tem um `date_key` em vez de uma data, e o aponta para uma tabela com uma linha para cada
dia. Parece um desvio, já que todo banco consegue tirar o mês de uma data. A tabela existe para tudo
o que uma função de data não consegue calcular.

```sql
-- One row per calendar day of the period, and one for a date not reached yet.
CREATE TABLE dim_date AS
WITH days AS (
    SELECT CAST(d AS DATE) AS date
    FROM range(DATE '2024-01-01', DATE '2026-01-01', INTERVAL 1 DAY) AS t(d)
),
holidays (date, holiday) AS (VALUES
    (DATE '2024-01-01', 'New Year'),          (DATE '2024-03-29', 'Good Friday'),
    (DATE '2024-04-21', 'Tiradentes'),        (DATE '2024-05-01', 'Labour Day'),
    (DATE '2024-09-07', 'Independence Day'),  (DATE '2024-10-12', 'Our Lady of Aparecida'),
    (DATE '2024-11-02', 'All Souls'),         (DATE '2024-11-15', 'Republic Day'),
    (DATE '2024-11-20', 'Black Consciousness'), (DATE '2024-12-25', 'Christmas'),
    (DATE '2025-01-01', 'New Year'),          (DATE '2025-04-18', 'Good Friday'),
    (DATE '2025-04-21', 'Tiradentes'),        (DATE '2025-05-01', 'Labour Day'),
    (DATE '2025-09-07', 'Independence Day'),  (DATE '2025-10-12', 'Our Lady of Aparecida'),
    (DATE '2025-11-02', 'All Souls'),         (DATE '2025-11-15', 'Republic Day'),
    (DATE '2025-11-20', 'Black Consciousness'), (DATE '2025-12-25', 'Christmas')
)
SELECT CAST(strftime(date, '%Y%m%d') AS INTEGER) AS date_key,
       date,
       year(date)                  AS year,
       quarter(date)               AS quarter,
       month(date)                 AS month,
       monthname(date)             AS month_name,
       day(date)                   AS day_of_month,
       isodow(date)                AS day_of_week,
       dayname(date)               AS day_name,
       isodow(date) >= 6           AS is_weekend,
       holiday IS NOT NULL         AS is_holiday,
       coalesce(holiday, '')       AS holiday
FROM days LEFT JOIN holidays USING (date)
UNION ALL
SELECT 0, NULL, NULL, NULL, NULL, 'Not yet', NULL, NULL, 'Not yet', NULL, NULL, ''
ORDER BY date_key;
```

Três linhas dela:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_date WHERE date_key IN (0, 20250418, 20250419)"
┌──────────┬────────────┬───────┬─────────┬───────┬────────────┬──────────────┬─────────────┬──────────┬────────────┬────────────┬─────────────┐
│ date_key │    date    │ year  │ quarter │ month │ month_name │ day_of_month │ day_of_week │ day_name │ is_weekend │ is_holiday │   holiday   │
│  int32   │    date    │ int64 │  int64  │ int64 │  varchar   │    int64     │    int64    │ varchar  │  boolean   │  boolean   │   varchar   │
├──────────┼────────────┼───────┼─────────┼───────┼────────────┼──────────────┼─────────────┼──────────┼────────────┼────────────┼─────────────┤
│        0 │ NULL       │  NULL │    NULL │  NULL │ Not yet    │         NULL │        NULL │ Not yet  │ NULL       │ NULL       │             │
│ 20250418 │ 2025-04-18 │  2025 │       2 │     4 │ April      │           18 │           5 │ Friday   │ false      │ true       │ Good Friday │
│ 20250419 │ 2025-04-19 │  2025 │       2 │     4 │ April      │           19 │           6 │ Saturday │ true       │ false      │             │
└──────────┴────────────┴───────┴─────────┴───────┴────────────┴──────────────┴─────────────┴──────────┴────────────┴────────────┴─────────────┘
```

**Um feriado não está na aritmética do calendário.** A Sexta-feira Santa muda todo ano, e se um dia é
feriado no Brasil é um fato que alguém anota — aqui, vinte linhas de `VALUES`. Escrito uma vez, é uma
coluna pela qual toda tabela fato pode agrupar. Sem a tabela, é uma lista que cada analista mantém na
própria consulta, e não há duas listas iguais.

Com ela, uma pergunta como "as lojas vendem mais num feriado?" é uma junção:

```sql
-- Revenue per shop-day in physical shops: holidays against ordinary days.
SELECT d.is_holiday,
       count(DISTINCT (f.date_key, f.shop_key))             AS shop_days,
       round(sum(f.net_cents) / 100 / count(DISTINCT (f.date_key, f.shop_key)), 2)
                                                            AS brl_per_shop_day
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.channel = 'store' AND NOT d.is_weekend
GROUP BY d.is_holiday
ORDER BY d.is_holiday;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < holidays.sql
┌────────────┬───────────┬──────────────────┐
│ is_holiday │ shop_days │ brl_per_shop_day │
│  boolean   │   int64   │      double      │
├────────────┼───────────┼──────────────────┤
│ false      │      2763 │         13018.08 │
│ true       │        44 │         13461.74 │
└────────────┴───────────┴──────────────────┘
```

Num feriado em dia útil, uma loja física faturou R$ 13.461,74 em média, contra R$ 13.018,08 num dia
útil comum: um pouco mais, em 44 dias-loja de feriado. A consulta se lê como a pergunta. O ano
fiscal, as férias escolares, a semana da Black Friday e o dia em que a rede mudou os preços seriam,
cada um, mais uma coluna, escrita uma vez.

## A linha de uma data que ainda não aconteceu

A primeira das três linhas tem `date_key` 0 e diz `Not yet`. **Ela representa uma data que ainda não
existe**: a seção 09 tem um pacote que foi despachado e não chegou, e a data de entrega dele aponta
para cá em vez de não apontar para nada. Um fato que não aponta para nada some de toda junção interna,
e uma contagem de pacotes por mês de entrega perderia, sem avisar, os que ainda estão na estrada.

## Por que uma chave inteira como `20250418`

Ela ordena como uma data, é legível numa linha fato sem junção, e ocupa quatro bytes. É a única chave
do warehouse que tem permissão para significar algo, porque um dia do calendário não muda de
identidade. A lição 4 é sobre por que todas as outras chaves não podem.
