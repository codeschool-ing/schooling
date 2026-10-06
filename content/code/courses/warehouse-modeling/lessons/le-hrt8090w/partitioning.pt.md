---
title: Particionamento, que não é distribuição
version: 1
---

As pessoas confundem as duas palavras o tempo todo, e elas fazem trabalhos diferentes.

- **Distribuição** decide em que máquina uma linha mora, para espalhar o trabalho.
- **Particionamento** decide em que arquivo ou segmento uma linha mora, para uma consulta poder pular
  os que não precisa.

São independentes: uma tabela pode ser distribuída entre nós por número de pedido e, em cada nó,
particionada por mês. Uma máquina basta para ver o particionamento funcionando. Grave as vendas como
arquivos Parquet, uma pasta por ano e mês:

```sql
-- The sales, written as Parquet files, one folder per year and month.
COPY (SELECT f.*, d.year, d.month FROM fact_sales f JOIN dim_date d USING (date_key))
TO 'sales_by_month' (FORMAT parquet, PARTITION_BY (year, month));
```

```
ana@lab:~/wh$ duckdb wh.duckdb < lake.sql
ana@lab:~/wh$ ls sales_by_month sales_by_month/year=2025 | head -8
sales_by_month:
year=2024
year=2025

sales_by_month/year=2025:
month=1
month=10
month=11
ana@lab:~/wh$ find sales_by_month -name "*.parquet" | wc -l
24
```

Os nomes das pastas carregam os valores: `year=2025/month=3` guarda as vendas de março de 2025 e mais
nada. Esse arranjo se chama **particionamento no estilo Hive**, por causa do sistema que o popularizou, e
todo motor das lições 9 e 10 o lê. Agora peça março de 2025, e pergunte ao DuckDB o que ele leu:

```sql
EXPLAIN ANALYZE
SELECT sum(net_cents)
FROM read_parquet('sales_by_month/*/*/*.parquet', hive_partitioning = true)
WHERE year = 2025 AND month = 3;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < pruning.sql | grep -E 'Filters|year = |Scanning|Total Files'
EXPLAIN ANALYZE SELECT sum(net_cents) FROM read_parquet('sales_by_month/*/*/*.parquet', hive_partitioning = true) WHERE year = 2025 AND month = 3;
│       File Filters:       │
│  (year = 2025)(month = 3) │
│    Scanning Files: 1/24   │
│    Total Files Read: 1    │
```

**`Scanning Files: 1/24`.** O DuckDB aplicou o filtro em `year` e `month` aos nomes das pastas antes
de abrir qualquer coisa, e nunca tocou 23 dos 24 arquivos. Isso é **poda de partições**
(partition pruning), e é o ganho de velocidade mais barato da análise de dados: o trabalho não feito sai
de graça.

Três regras fazem compensar:

- **Particione pelo que as consultas filtram.** Quase toda consulta de warehouse filtra por data, e por
  isso a data é a escolha usual.
- **Não fino demais.** Particionar as vendas por dia daria 731 pastas de arquivos pequenos, e abrir um
  arquivo tem um custo fixo, por menos que haja nele. A lição 10 volta ao problema dos arquivos pequenos.
- **Não grosso demais.** Uma partição por ano leria um ano inteiro para responder a uma pergunta sobre
  março.
