---
title: Uma tabela Delta, à mão
version: 1
---

O laboratório tem a biblioteca `deltalake`, o delta-rs, uma implementação do Delta Lake em Rust com interface
Python. Sem servidor e sem cluster: uma tabela Delta é uma pasta, e a biblioteca é o que lê e escreve o log
dentro dela.

O primeiro programa de Ana pega um ano de `fact_sales` do warehouse e o grava numa tabela Delta no lake,
particionada por ano:

```schooling-example
{
  "language": "python",
  "file": "write_sales.py",
  "parts": [
    {
      "code": "\"\"\"Write one year of fact_sales from the warehouse into a Delta table on the lake.\"\"\"\nimport sys\n\nimport duckdb\nfrom deltalake import write_deltalake\n\n",
      "note": "Duas bibliotecas e mais nada: DuckDB para ler o warehouse, `deltalake` para gravar a tabela. Nenhuma precisa de servidor."
    },
    {
      "code": "year, mode = int(sys.argv[1]), sys.argv[2]\n\n",
      "note": "O ano a copiar, e o modo: `overwrite` substitui a tabela, `append` acrescenta a ela. Os dois viram um commit."
    },
    {
      "code": "con = duckdb.connect(\"wh.duckdb\", read_only=True)\nrows = con.sql(f\"\"\"\n    SELECT f.*, d.year\n    FROM fact_sales f JOIN dim_date d USING (date_key)\n    WHERE d.year = {year}\n\"\"\").to_arrow_table()\n\n",
      "note": "O warehouse é aberto só para leitura, e um ano de vendas sai como uma tabela Arrow, o formato colunar em memória que as duas bibliotecas falam, então nada é convertido linha a linha."
    },
    {
      "code": "write_deltalake(\"lake/sales\", rows, mode=mode, partition_by=[\"year\"])\nprint(f\"wrote {rows.num_rows} rows of {year} with mode={mode}\")",
      "note": "Uma chamada grava os arquivos Parquet sob `year=…` e depois o commit em `_delta_log`. Enquanto o commit não existe, os arquivos novos não fazem parte da tabela."
    }
  ]
}
```

Ela grava 2024 primeiro, substituindo o que houvesse ali, e depois acrescenta 2025:

```
ana@lab:~/wh$ python write_sales.py 2024 overwrite
wrote 404067 rows of 2024 with mode=overwrite
ana@lab:~/wh$ python write_sales.py 2025 append
wrote 483410 rows of 2025 with mode=append
ana@lab:~/wh$ find lake/sales -type f | sort | sed "s/part-.*parquet/part-….parquet/"
lake/sales/_delta_log/00000000000000000000.json
lake/sales/_delta_log/00000000000000000001.json
lake/sales/year=2024/part-….parquet
lake/sales/year=2025/part-….parquet
```

Dois anos, duas pastas, um arquivo Parquet em cada, e uma pasta chamada `_delta_log` com dois arquivos numerados.
**Os arquivos Parquet são os dados, e são Parquet comum**: DuckDB, Spark ou qualquer outra coisa poderia lê-los
diretamente. Os dois arquivos JSON são a tabela: o commit 0 a criou com o arquivo de 2024, o commit 1 acrescentou
o de 2025.

As pastas de partição têm nomes no estilo das da lição 7, `year=2024`. O Delta registra os valores de partição
também no log, então um leitor que conhece o formato não precisa interpretar nomes de pasta, e um leitor que não
conhece ainda vê o arranjo familiar.

Daqui em diante, toda mudança nesta tabela passa pela biblioteca e vira mais um commit no log. A próxima seção
abre o log.
