---
title: Poda de colunas
version: 1
---

**Uma consulta que usa duas colunas de sete deveria ler duas colunas de sete**, e com um formato
colunar ela consegue. O Parquet guarda cada coluna de um arquivo separada, então um leitor que quer
`kind` e `book_id` pode pular os bytes de `ts`, `visitor_id` e do resto. A aula 10 abre um arquivo
para mostrar como.

O planejador decide quais colunas são necessárias trabalhando de trás para a frente a partir do
resultado, e escreve a resposta no scan como `ReadSchema`. Os três scans do `pruning.py`, como o
planejador os escreveu, a partir de um programa que só os explica, `~/big/scan_plans.py`:

```schooling-example
{
  "language": "python",
  "file": "scan_plans.py",
  "parts": [
    {
      "code": "\"\"\"The scan node of three of pruning.py's queries, as the planner wrote it.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"scan plans\").getOrCreate()\npurchases = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\nis_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, \"boolean\")\n\n"
    },
    {
      "code": "for label, query in [\n        (\"one column\", purchases.agg(F.countDistinct(\"book_id\"))),\n        (\"one day\", purchases.where(F.col(\"day\") == \"2025-03-14\")\n                             .agg(F.countDistinct(\"book_id\"))),\n        (\"one day, udf\", purchases.where(is_pi_day(\"day\"))\n                                  .agg(F.countDistinct(\"book_id\")))]:\n    print(f\"--- {label}\")\n    query.explain(\"formatted\")\n",
      "note": "As mesmas três consultas do `pruning.py`, explicadas em vez de rodadas. Cada uma imprime um plano numerado; a aula lê só as linhas do scan."
    }
  ]
}
```

O `explain("formatted")` imprime um plano longo para cada um; o `grep` guarda as linhas do scan:

```
ana@lab:~/big$ spark-submit scan_plans.py 2>&1 | grep -E '^(---|PartitionFilters|PushedFilters|ReadSchema)'
--- one column
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
--- one day
PartitionFilters: [isnotnull(day#6), (day#6 = 2025-03-14)]
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
--- one day, udf
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase)]
ReadSchema: struct<kind:string,book_id:int>
```

**Duas colunas, `kind` e `book_id`, nos três.** É tudo de que a consulta precisa: o `kind` para o
filtro e o `book_id` para a contagem. Os tempos da seção anterior são o efeito: ler todas as colunas
de todas as compras levou cerca do dobro de ler estas duas.

O que o planejador não consegue podar, ele lê. Três jeitos comuns de ler mais do que se precisa:

- **Um `select("*")` cedo num pipeline**, ou nenhum `select`, seguido de um `collect` ou de uma
  escrita de linhas inteiras: toda coluna é necessária, então toda coluna é lida.
- **Uma UDF Python sobre a linha inteira**, como `udf(lambda row: ...)(F.struct("*"))`, que o
  planejador precisa alimentar com todas as colunas porque não vê quais a função usa.
- **Um formato por linhas.** Uma linha de CSV precisa ser lida inteira para achar qualquer coluna
  nela; a poda no `ReadSchema` economiza interpretação ali, e não economiza leitura.
