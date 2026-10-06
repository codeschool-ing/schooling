---
title: Trazendo os dados
version: 1
---

Antes de qualquer modelagem, os dados precisam estar no warehouse. Como eles são movidos, em que
agenda, e o que acontece quando uma carga falha no meio são o assunto de `pipelines-etl`. O
laboratório da Ana faz a coisa mais simples que funciona, e vale a pena vê-la uma vez porque toda
tabela seguinte é construída a partir dela.

A extração é um script de shell que pede ao PostgreSQL cada tabela como um arquivo CSV:

```sh
#!/bin/sh
# Copy every table of the shop's database into extract/, one CSV file each.
set -e
mkdir -p extract
for t in shops categories publishers authors books book_authors customers \
         customer_changes promotions orders order_lines payments stock_counts \
         events event_attendance; do
  psql -q -c "\copy $t TO 'extract/$t.csv' WITH (FORMAT csv, HEADER true)"
done
```

```
ana@lab:~/wh$ sh extract.sh
ana@lab:~/wh$ ls -l extract | head -6
total 91088
-rw-r--r-- 1 ana ana    42211 Oct  6 13:22 authors.csv
-rw-r--r-- 1 ana ana    39358 Oct  6 13:22 book_authors.csv
-rw-r--r-- 1 ana ana   212957 Oct  6 13:22 books.csv
-rw-r--r-- 1 ana ana      707 Oct  6 13:22 categories.csv
-rw-r--r-- 1 ana ana   655344 Oct  6 13:22 customer_changes.csv
ana@lab:~/wh$ head -3 extract/orders.csv
order_id,shop_id,customer_id,ordered_at,status,shipping_cents,paid_at,shipped_at,delivered_at
100001,7,23316,2024-01-01 01:26:22-03,delivered,1490,2024-01-01 01:48:58-03,2024-01-02 15:39:14-03,2024-01-04 16:44:59-03
100002,7,37695,2024-01-01 02:15:39-03,delivered,1490,2024-01-01 02:34:38-03,2024-01-02 14:57:59-03,2024-01-08 10:58:01-03
```

Os arquivos caem em `extract/`, um por tabela, como o banco operacional os tinha no momento da cópia.

## Staging, e um tipo que o arquivo não carrega

Um arquivo CSV não tem tipos: `9786514429742` são treze caracteres, e se eles são um número é um
palpite. Peça ao DuckDB para ler o arquivo de livros e ele palpita:

```
ana@lab:~/wh$ duckdb -c "SELECT isbn, typeof(isbn) AS type FROM read_csv('extract/books.csv') LIMIT 2"
┌───────────────┬─────────┐
│     isbn      │  type   │
│     int64     │ varchar │
├───────────────┼─────────┤
│ 9786514429742 │ BIGINT  │
│ 9786596648567 │ BIGINT  │
└───────────────┴─────────┘
```

**Um ISBN é um identificador feito de dígitos, não um número.** Ninguém soma dois deles. Lido como
inteiro, um código que começa com zero perde o zero, como perderiam um ISBN antigo de dez dígitos ou
um CEP de São Paulo, e uma junção com uma coluna de tipo correto em outro lugar não encontra nada, sem
avisar. Por isso o script de staging diz o que a coluna é:

```sql
-- The extract, loaded as it arrived: one table per CSV file, in a schema of
-- its own, so nothing downstream reads a file directly.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA staging;
CREATE TABLE staging.shops            AS FROM read_csv('extract/shops.csv', sample_size = -1);
CREATE TABLE staging.categories       AS FROM read_csv('extract/categories.csv', sample_size = -1);
CREATE TABLE staging.publishers       AS FROM read_csv('extract/publishers.csv', sample_size = -1);
CREATE TABLE staging.authors          AS FROM read_csv('extract/authors.csv', sample_size = -1);
CREATE TABLE staging.books            AS FROM read_csv('extract/books.csv', sample_size = -1,
                                                    types = {'isbn': 'VARCHAR'});
CREATE TABLE staging.book_authors     AS FROM read_csv('extract/book_authors.csv', sample_size = -1);
CREATE TABLE staging.customers        AS FROM read_csv('extract/customers.csv', sample_size = -1);
CREATE TABLE staging.customer_changes AS FROM read_csv('extract/customer_changes.csv', sample_size = -1);
CREATE TABLE staging.promotions       AS FROM read_csv('extract/promotions.csv', sample_size = -1);
CREATE TABLE staging.orders           AS FROM read_csv('extract/orders.csv', sample_size = -1);
CREATE TABLE staging.order_lines      AS FROM read_csv('extract/order_lines.csv', sample_size = -1);
CREATE TABLE staging.payments         AS FROM read_csv('extract/payments.csv', sample_size = -1);
CREATE TABLE staging.stock_counts     AS FROM read_csv('extract/stock_counts.csv', sample_size = -1);
CREATE TABLE staging.events           AS FROM read_csv('extract/events.csv', sample_size = -1);
CREATE TABLE staging.event_attendance AS FROM read_csv('extract/event_attendance.csv', sample_size = -1);
```

`sample_size = -1` faz o DuckDB ler o arquivo inteiro antes de escolher um tipo, em vez das primeiras
milhares de linhas. `order_lines.promotion_id` está vazio em quase todas as linhas do começo do
arquivo, e um palpite feito a partir delas o transforma em texto.

```
ana@lab:~/wh$ duckdb wh.duckdb < staging.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'staging' ORDER BY rows DESC LIMIT 5"
┌──────────────┬────────┐
│  table_name  │  rows  │
│   varchar    │ int64  │
├──────────────┼────────┤
│ order_lines  │ 895332 │
│ payments     │ 586405 │
│ orders       │ 577468 │
│ stock_counts │ 197574 │
│ customers    │  40000 │
└──────────────┴────────┘
```

**`staging` é um schema próprio, e nada fora da carga o lê.** É a extração como chegou, ainda no
formato operacional: as tabelas dimensionais das próximas seções são construídas a partir dele, e os
relatórios sobre elas. Manter essa camada à parte significa que um relatório nunca depende de como um
arquivo por acaso estava organizado, e que uma carga pode ser refeita a partir do staging sem pedir
nada de novo ao banco da rede.
