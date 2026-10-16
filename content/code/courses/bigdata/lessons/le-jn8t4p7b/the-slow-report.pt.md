---
title: Um relatório lento
version: 1
---

**Os analistas da Ponto Final querem, toda manhã, a receita de cada categoria em cada mês.** A
pergunta junta as compras aos livros e soma preços, e cada aula deste curso fez um pedaço dela. Este
programa a responde como foi escrito da primeira vez, com quatro erros que apareceram, cada um, numa
aula anterior, e uma opção para devolver cada um. Salve como `~/big/report.py`:

```schooling-example
{
  "language": "python",
  "file": "report.py",
  "parts": [
    {
      "code": "\"\"\"Revenue per category per month: the report Ponto Final's analysts ask for every morning.\"\"\"\nimport argparse\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "parser = argparse.ArgumentParser()\nparser.add_argument(\"--csv\", action=\"store_true\", help=\"read the raw CSV instead of the silver layer\")\nparser.add_argument(\"--udf\", action=\"store_true\", help=\"take the month with a Python function\")\nparser.add_argument(\"--partitions\", type=int, default=0, help=\"fix the shuffle partitions, AQE off\")\nparser.add_argument(\"--no-broadcast\", action=\"store_true\", help=\"forbid broadcasting the books\")\nargs = parser.parse_args()\n\nspark = SparkSession.builder.appName(\"report\").getOrCreate()\nif args.partitions:\n    spark.conf.set(\"spark.sql.adaptive.enabled\", False)\n    spark.conf.set(\"spark.sql.shuffle.partitions\", args.partitions)\nif args.no_broadcast:\n    spark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\n\nif args.csv:\n    clicks = (spark.read.option(\"header\", True)\n              .schema(\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n                      \"book_id INT, device STRING\")\n              .csv(\"data/raw/clicks\"))\nelse:\n    clicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n",
      "note": "**Cada opção devolve um erro**, para que o mesmo programa possa rodar como foi escrito da primeira vez e depois com cada erro tirado por vez."
    },
    {
      "code": "if args.udf:\n    month = F.udf(lambda ts: ts.strftime(\"%Y-%m\"), \"string\")(\"ts\")\nelse:\n    month = F.date_format(F.date_trunc(\"month\", \"ts\"), \"yyyy-MM\")\n\nstart = time.time()\nreport = (clicks.where(F.col(\"kind\") == \"purchase\")\n          .join(books, \"book_id\")\n          .groupBy(month.alias(\"month\"), \"category\")\n          .agg(F.count(\"*\").alias(\"purchases\"), F.sum(\"price_cents\").alias(\"cents\"))\n          .orderBy(\"month\", F.desc(\"cents\")))\nrows = report.collect()\nprint(f\"{len(rows)} rows in {time.time() - start:.1f} s; top of January:\",\n      [(r.category, r.cents // 100) for r in rows[:2]])\n",
      "note": "**O mês**, ou com o `date_trunc` embutido, que o Catalyst entende e roda na JVM, ou com uma função Python, que manda cada compra a um worker Python e de volta."
    }
  ]
}
```

As opções, e a aula de onde vem cada erro:

| opção | o erro | onde o curso o mediu |
|---|---|---|
| `--csv` | ler o CSV com gzip da camada raw em vez do Parquet da silver | aulas 5 e 10 |
| `--udf` | tirar o mês com uma função Python em vez de uma embutida | aula 6 |
| `--partitions 2000` | um número fixo de partições de shuffle, com a execução adaptativa desligada | aula 7 |
| `--no-broadcast` | proibir o broadcast de uma tabela de 3.000 linhas | aula 8 |

Com os quatro, como o relatório rodou durante meses antes de alguém olhar:

```
ana@lab:~/big$ spark-submit report.py --csv --udf --partitions 2000 --no-broadcast 2>/dev/null
120 rows in 131.1 s; top of January: [('poetry', 997352), ('science', 877502)]
```

**Dois minutos e onze segundos para 120 linhas.** A resposta está certa; o resto desta aula é
sobre o tempo, e depois sobre o que o tempo custa.
