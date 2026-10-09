---
title: Carregando um mês de cada vez
version: 2
---

A maioria das origens não guarda registro de mudanças. O que o warehouse recebe é uma **foto**
(snapshot): a tabela de clientes inteira, como está no momento da extração. O gerador da lição 1
escreveu três em `extracts/`, tiradas à meia-noite do primeiro dia de outubro, novembro e dezembro
de 2025. O tipo 2 a partir de fotos funciona por comparação: o que diz a extração, contra o que
dizem as linhas atuais da dimensão?

Esta dimensão é construída ao lado da do warehouse, como `dim_customer_m`. A primeira carga é todo
mundo, uma versão cada:

```sql
-- A type 2 customer dimension loaded from monthly extracts. The first month:
-- one current version of everybody, from the day of the extract.
CREATE SEQUENCE customer_key_seq START 1;
CREATE TABLE dim_customer_m (
    customer_key BIGINT PRIMARY KEY,
    customer_id  BIGINT NOT NULL,
    name         VARCHAR,
    tier         VARCHAR,
    city         VARCHAR,
    state        VARCHAR,
    valid_from   DATE NOT NULL,
    valid_to     DATE NOT NULL,
    is_current   BOOLEAN NOT NULL
);
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), customer_id, name, tier, city, state,
       DATE '2025-10-01', DATE '9999-12-31', true
FROM read_csv('extracts/customers_2025-10-01.csv');
```

Todo mês seguinte roda o mesmo script, com a data do mês numa variável:

```sql
-- Load one month's extract into the type 2 dimension. Run with the extract's
-- date in the variable load_date.
BEGIN;
CREATE OR REPLACE TEMP TABLE ext AS
SELECT * FROM read_csv('extracts/customers_' || getvariable('load_date') || '.csv');

-- 1. Type 1: a corrected name is written into every version of the customer.
UPDATE dim_customer_m d SET name = e.name
FROM ext e
WHERE d.customer_id = e.customer_id AND d.name <> e.name;

-- 2. Close the current version of everybody whose tracked attributes changed.
UPDATE dim_customer_m d SET valid_to = getvariable('load_date'), is_current = false
FROM ext e
WHERE d.customer_id = e.customer_id AND d.is_current
  AND (d.tier, d.city, d.state) IS DISTINCT FROM (e.tier, e.city, e.state);

-- 3. Open a version for everybody who now has no current row: the ones just
--    closed, and customers who joined during the month.
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), e.customer_id, e.name, e.tier, e.city, e.state,
       getvariable('load_date'), DATE '9999-12-31', true
FROM ext e
WHERE NOT EXISTS (SELECT 1 FROM dim_customer_m d
                  WHERE d.customer_id = e.customer_id AND d.is_current);
COMMIT;

SELECT count(*) AS rows, count(*) FILTER (WHERE is_current) AS current,
       count(*) FILTER (WHERE valid_to = getvariable('load_date')) AS closed_now,
       count(*) FILTER (WHERE valid_from = getvariable('load_date')) AS opened_now
FROM dim_customer_m;
```

Três passos, cada um sobre conjuntos, dentro de uma transação:

1. **A coluna tipo 1 primeiro.** Um nome corrigido é gravado em todas as versões do cliente, inclusive
   as antigas, porque ele nunca se escreveu do outro jeito.
2. **Fechar o que mudou.** Toda linha atual cujo nível, cidade ou estado difere da extração recebe como
   `valid_to` a data da extração e deixa de ser atual. `IS DISTINCT FROM` trata dois valores vazios como
   iguais, o que o `<>` comum não faz.
3. **Abrir o que falta.** Todo cliente da extração sem linha atual ganha uma: os clientes fechados no
   passo 2, e os que entraram durante o mês. Um `INSERT` serve aos dois.

```
ana@lab:~/wh$ duckdb wh.duckdb < first_load.sql
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-11-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 39328 │   39065 │        263 │       1214 │
└───────┴─────────┴────────────┴────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-12-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 40532 │   40000 │        269 │       1204 │
└───────┴─────────┴────────────┴────────────┘
```

Novembro fechou 263 versões e abriu 1.214: as 263 versões novas de quem mudou, e 951 clientes que
entraram em outubro. Dezembro fechou 269 e abriu 1.204, e terminou com 40.000 linhas atuais, uma por
cliente, como deve ser.

## Rode duas vezes

Uma carga que falha no meio é rodada de novo. Aqui está dezembro, rodado uma segunda vez:

```
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-12-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 40532 │   40000 │        269 │       1204 │
└───────┴─────────┴────────────┴────────────┘
```

**Nada mudou.** Depois da primeira execução toda linha atual já bate com a extração, então o passo 2 não
acha nada para fechar e o passo 3 nada para abrir. Uma carga que pode ser repetida sem dano se chama
**idempotente**, e é a propriedade que deixa alguém rodar de novo o job da noite às nove da manhã sem
antes descobrir até onde ele chegou. `pipelines-etl` faz disso uma regra para toda carga.
