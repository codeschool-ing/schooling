---
title: Zone maps, pular sem índice
version: 1
---

Um arquivo colunar é dividido em blocos de linhas, **grupos de linhas** (row groups) no Parquet, e para
cada grupo e cada coluna ele registra algumas estatísticas: o número de linhas, o número de valores vazios,
e o **mínimo e o máximo**. Aqui estão para `date_key`, no arquivo gravado em ordem de número de pedido:

```
ana@lab:~/wh$ duckdb -c "SELECT row_group_id, row_group_num_rows AS rows, stats_min, stats_max FROM parquet_metadata('by_order.parquet') WHERE path_in_schema = 'date_key' ORDER BY row_group_id"
┌──────────────┬────────┬───────────┬───────────┐
│ row_group_id │  rows  │ stats_min │ stats_max │
│    int64     │ int64  │  varchar  │  varchar  │
├──────────────┼────────┼───────────┼───────────┤
│            0 │ 122880 │ 20240101  │ 20240514  │
│            1 │ 122880 │ 20240514  │ 20240907  │
│            2 │ 122880 │ 20240907  │ 20241212  │
│            3 │ 122880 │ 20241212  │ 20250329  │
│            4 │ 122880 │ 20250329  │ 20250705  │
│            5 │ 122880 │ 20250705  │ 20251007  │
│            6 │ 122880 │ 20251007  │ 20251218  │
│            7 │  27317 │ 20251218  │ 20251231  │
└──────────────┴────────┴───────────┴───────────┘
```

Oito grupos de 122.880 linhas, e cada um cobre um trecho de uns três meses, porque as linhas estão em
ordem de data. Uma consulta de vendas de março de 2025 pode ler esses dezesseis números primeiro e
descartar todo grupo cujo intervalo não inclui março: só os grupos 3 e 4 poderiam ter uma venda de março.

Esses mínimos e máximos por bloco se chamam **zone maps**, e são um índice que quase não custa nada: alguns
bytes por bloco, gravados junto com os dados. Quantos grupos de linhas março obrigaria um leitor a abrir,
no arquivo ordenado e no embaralhado?

```sql
-- Every row group keeps the minimum and maximum of each column. How many
-- row groups of each file could hold a sale from March 2025?
SELECT file_name,
       count(*) AS row_groups,
       count(*) FILTER (WHERE CAST(stats_min AS INTEGER) <= 20250331
                          AND CAST(stats_max AS INTEGER) >= 20250301) AS must_be_read
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet'])
WHERE path_in_schema = 'date_key'
GROUP BY file_name ORDER BY file_name;
```

```
ana@lab:~/wh$ duckdb < zonemaps.sql
┌──────────────────┬────────────┬──────────────┐
│    file_name     │ row_groups │ must_be_read │
│     varchar      │   int64    │    int64     │
├──────────────────┼────────────┼──────────────┤
│ by_order.parquet │          8 │            2 │
│ shuffled.parquet │          8 │            8 │
└──────────────────┴────────────┴──────────────┘
```

**Dois de oito no arquivo ordenado, os oito no embaralhado.** No arquivo embaralhado todo grupo tem datas
dos dois anos inteiros, então todo intervalo inclui março e nada pode ser pulado. Os dados são idênticos;
só a ordem difere.

É a mesma poda das partições da lição 7, um nível mais fina. As partições pulam arquivos pelo nome da
pasta; os zone maps pulam blocos dentro de um arquivo pelas estatísticas. As duas dependem da mesma coisa:
**as linhas que uma consulta quer ficarem juntas**, e por isso a ordem de uma tabela fato é uma decisão de
projeto, e não um detalhe. O DuckDB mantém zone maps também nas suas tabelas, e por isso a busca de um
pedido na seção 12 foi rápida sem índice: a tabela está ordenada por número de pedido.
