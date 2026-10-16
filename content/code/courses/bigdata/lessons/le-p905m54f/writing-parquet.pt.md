---
title: Escrevendo a camada silver
version: 1
---

**Toda aula até aqui leu os mesmos 365 arquivos CSV compactados e pagou para interpretar texto a
cada vez.** A aula 3 chamou isso de camada raw, guardada como chegou. Esta seção escreve a camada
seguinte, os mesmos eventos tipados e guardados em Parquet, um formato colunar que a aula 10 desmonta.
O resto do curso lê essa camada. Salve como `~/big/to_parquet.py`:

```schooling-example
{
  "language": "python",
  "file": "to_parquet.py",
  "parts": [
    {
      "code": "\"\"\"Write the raw clicks and books again, typed, as Parquet: the silver layer.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"to parquet\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n",
      "note": "A camada raw, lida com o esquema declarado. A coluna `day` vem dos nomes dos diretórios."
    },
    {
      "code": "clicks.write.mode(\"overwrite\").partitionBy(\"day\").parquet(\"data/silver/clicks\")\n\nbooks = (spark.read.option(\"header\", True)\n         .schema(\"book_id INT, category STRING, price_cents INT\").csv(\"data/raw/books\"))\nbooks.write.mode(\"overwrite\").parquet(\"data/silver/books\")\n\n",
      "note": "**Escrito como Parquet, particionado por dia de novo**: a mesma organização, com os tipos guardados nos arquivos. O `overwrite` substitui o que estiver lá, então rodar duas vezes é seguro."
    },
    {
      "code": "print(spark.read.parquet(\"data/silver/clicks\").count(), \"events,\",\n      spark.read.parquet(\"data/silver/books\").count(), \"books\")\n",
      "note": "Lido de volta, para conferir que nada se perdeu."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit to_parquet.py
WARNING: Using incubator modules: jdk.incubator.vector
24000000 events, 3000 books

real	1m44.537s
user	0m41.455s
sys	0m2.534s
ana@lab:~/big$ du -sh data/raw/clicks data/silver/clicks
243M	data/raw/clicks
396M	data/silver/clicks
ana@lab:~/big$ ls data/silver/clicks/day=2025-03-14
part-00012-77d3ee8e-f18d-439a-bc6d-1f55b07e48d3.c000.snappy.parquet
```

**24 milhões de eventos e 3.000 livros, lidos de volta, então nada se perdeu.** A organização é a da
camada raw, um diretório por dia, agora com um arquivo Parquet em cada, e os tipos viajam dentro dos
arquivos: todo programa que lê `data/silver/clicks` recebe o `ts` como timestamp sem ninguém dizer.

Dois números aqui vão surpreender, e os dois são da aula 10. **A cópia em Parquet é maior que o CSV
compactado**, 396 MB contra 243, embora o Parquet devesse ser o formato compacto; e a escrita levou
mais que qualquer job até agora. A aula 10 mede o porquê e conserta os dois mudando como os arquivos
são escritos, e não o que eles guardam.

**O `mode("overwrite")` substitui a saída se ela existir.** Os outros modos são `"error"`, o padrão,
que recusa; `"append"`, que acrescenta arquivos ao lado dos antigos; e `"ignore"`, que não faz nada
se a saída existir. Um job noturno que acrescenta e é rodado duas vezes por engano dobra os dados de
um dia, sem erro, e os formatos de tabela da aula 11 são a cura para isso também.
