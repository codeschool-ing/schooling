---
title: Declare o esquema, ou pague por um palpite
version: 1
---

**Um arquivo CSV não tem tipos, então alguém precisa fornecê-los**: o Spark, lendo os dados e
adivinhando, ou você, dizendo. A diferença se mede. Salve como `~/big/schema.py`:

```schooling-example
{
  "language": "python",
  "file": "schema.py",
  "parts": [
    {
      "code": "\"\"\"Reading the same CSV with an inferred schema and with a declared one.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"schema\").getOrCreate()\n\n"
    },
    {
      "code": "t = time.time()\nguessed = (spark.read.option(\"header\", True).option(\"inferSchema\", True)\n           .csv(\"data/raw/clicks\"))\nprint(f\"inferred: {time.time() - t:.1f} s\")\nguessed.printSchema()\n\n",
      "note": "**O `inferSchema` faz o Spark ler a entrada inteira uma vez só para adivinhar o tipo de cada coluna**, antes de o job que você pediu começar."
    },
    {
      "code": "SCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nt = time.time()\ndeclared = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\nprint(f\"declared: {time.time() - t:.1f} s\")\ndeclared.printSchema()\n",
      "note": "Um esquema declarado, numa string de nomes e tipos, não custa nada para ler. Ele também diz `LONG` para um id que vai passar do tamanho de um `int`, o que nenhum palpite sabe."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit schema.py
WARNING: Using incubator modules: jdk.incubator.vector
inferred: 44.1 s
root
 |-- event_id: integer (nullable = true)
 |-- ts: timestamp (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: integer (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)

declared: 4.7 s
root
 |-- event_id: long (nullable = true)
 |-- ts: timestamp (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: integer (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)
```

**O palpite custou uma leitura inteira de 1,3 GB de texto antes de o job de verdade poder começar**:
44,1 segundos contra 4,7. O esquema declarado custou uma listagem dos diretórios. Os dois dão as mesmas colunas,
com uma diferença que vale notar: o palpite fez do `event_id` um `integer`, porque nenhum valor de
2025 passou do que um `int` comporta, e o arquivo do ano que vem pode não concordar. Um `LONG`
declarado serve para os dois.

Mais três motivos para declarar, além do tempo:

- **Um palpite muda quando os dados mudam.** Uma linha malformada, uma coluna vazia num arquivo novo,
  uma data em outro formato, e o tipo inferido muda sem ninguém ter decidido, e todo job adiante vê
  outra tabela.
- **Uma declaração falha alto onde um palpite falha calado.** Com um esquema declarado, um valor que
  não cabe vira `null`, ou, com `.option("mode", "FAILFAST")`, para o job com a linha que o quebrou.
- **Ela documenta os dados.** A string única do `schema.py` é a descrição mais clara dos cliques em
  todo este curso.

Formatos que guardam o esquema no arquivo, como o Parquet da seção 08 e da aula 10, fazem a questão
desaparecer: os tipos são escritos uma vez, pelo job que escreveu os dados, e todo leitor os recebe
de graça.
