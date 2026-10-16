---
title: Por que a camada silver saiu maior
version: 1
---

**A aula 5 deixou duas surpresas: a cópia em Parquet dos cliques ficou maior que o CSV com gzip, 396
MB contra 243, e o job que a gravou demorou mais que qualquer anterior.** Este programa grava as 2
milhões de linhas de janeiro de sete jeitos e mede o tamanho de cada um, o tempo para gravá-lo e o
tempo para ler todas as colunas de volta. Salve como `~/big/codecs.py`:

```schooling-example
{
  "language": "python",
  "file": "codecs.py",
  "parts": [
    {
      "code": "\"\"\"January's clicks written in seven ways, and what each costs on disk and to read.\"\"\"\nimport os\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"codecs\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\n\n\ndef mib(path):\n    return sum(os.path.getsize(os.path.join(d, f)) for d, _, names in os.walk(path)\n               for f in names if f.startswith(\"part-\")) / 2**20\n\n\n"
    },
    {
      "code": "def written(label, fmt, **options):\n    path = f\"data/tmp/{label.replace(', ', '-').replace(' ', '-')}\"\n    start = time.time()\n    january.write.mode(\"overwrite\").options(**options).partitionBy(\"day\").format(fmt).save(path)\n    wrote = time.time() - start\n    back = spark.read.format(fmt).load(path)\n    start = time.time()\n    back.agg(F.max(F.length(F.concat_ws(\"|\", *back.columns)))).collect()\n    print(f\"{label:24} {mib(path):7.1f} MiB, written in {wrote:4.1f} s, read in\"\n          f\" {time.time() - start:4.1f} s\")\n\n\n",
      "note": "**Cada jeito é gravado, medido e lido de volta** com uma consulta que precisa de todas as colunas, para que a leitura custe o que custa descomprimir e decodificar o arquivo inteiro."
    },
    {
      "code": "january.write.mode(\"overwrite\").parquet(\"data/tmp/warm-up\")\n\n",
      "note": "**A primeira gravação de um programa também aquece a JVM**, então uma é feita e descartada antes de qualquer uma ser cronometrada."
    },
    {
      "code": "SCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\ncsv = (spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n       .where(F.col(\"day\") < \"2025-02-01\"))\nraw = sum(mib(f\"data/raw/clicks/day=2025-01-{d:02}\") for d in range(1, 32))\nstart = time.time()\ncsv.agg(F.max(F.length(F.concat_ws(\"|\", *csv.columns)))).collect()\nprint(f\"{'csv, gzip (raw)':24} {raw:7.1f} MiB,\"\n      f\" {'':17} read in {time.time() - start:4.1f} s\")\nwritten(\"parquet, snappy\", \"parquet\", compression=\"snappy\")\nwritten(\"parquet, none\", \"parquet\", compression=\"none\")\nwritten(\"parquet, gzip\", \"parquet\", compression=\"gzip\")\nwritten(\"parquet, zstd\", \"parquet\", compression=\"zstd\")\n",
      "note": "**O janeiro da camada raw para comparar**: as mesmas linhas como CSV com gzip, como a aula 1 as gravou, lidas com o esquema da aula 5 e a mesma consulta que o resto."
    },
    {
      "code": "spark.conf.set(\"spark.sql.parquet.outputTimestampType\", \"TIMESTAMP_MICROS\")\nwritten(\"parquet, zstd, micros\", \"parquet\", compression=\"zstd\")\n",
      "note": "**Timestamps como inteiros de 64 bits.** O Spark grava um timestamp no Parquet como `INT96` a menos que digam outra coisa, um tipo de 12 bytes mantido por leitores antigos e que nenhuma codificação consegue encolher. O `TIMESTAMP_MICROS` guarda microssegundos num inteiro comum de 64 bits."
    },
    {
      "code": "written(\"parquet v2, zstd, micros\", \"parquet\", compression=\"zstd\",\n        **{\"parquet.writer.version\": \"v2\"})\n",
      "note": "**E a versão 2 do formato de página do Parquet**: ela acrescenta codificações delta, que guardam cada valor como a diferença para o anterior, a forma certa para ids e timestamps em ordem."
    },
    {
      "code": "print(\"orc codec:\", spark.conf.get(\"spark.sql.orc.compression.codec\"))\nwritten(\"orc\", \"orc\")\n",
      "note": "**ORC**, o outro formato colunar, com o codec padrão deste Spark."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit codecs.py
WARNING: Using incubator modules: jdk.incubator.vector
csv, gzip (raw)             20.1 MiB,                   read in  6.8 s
parquet, snappy             33.0 MiB, written in  5.9 s, read in  2.8 s
parquet, none               54.2 MiB, written in  4.1 s, read in  2.0 s
parquet, gzip               21.4 MiB, written in  4.4 s, read in  2.2 s
parquet, zstd               19.6 MiB, written in  3.0 s, read in  2.1 s
parquet, zstd, micros       14.4 MiB, written in  2.4 s, read in  2.1 s
parquet v2, zstd, micros     7.2 MiB, written in  3.3 s, read in  2.1 s
orc codec: zstd
orc                          6.1 MiB, written in  5.2 s, read in  4.3 s
```

**A primeira resposta é o codec.** O Spark comprime Parquet com Snappy por padrão, que é feito para
ser rápido e não pequeno: 33,0 MiB, onde o gzip leva o mesmo arquivo a 21,4 e o zstd a 19,6. O CSV com
gzip tinha 20,1. Então o CSV não foi vencido por um formato pior; ele foi comprimido por um codec mais
forte.

**A segunda são os timestamps.** O Spark grava um timestamp no Parquet como `INT96`, 12 bytes, um tipo
mantido por leitores dos primeiros anos do Parquet. Nenhuma codificação se aplica a ele, então o `ts`
de cada linha são doze bytes de dígitos quase iguais para o codec achar. Gravado como
`TIMESTAMP_MICROS`, um inteiro de 64 bits, o mesmo arquivo zstd caiu de 19,6 MiB para 14,4.

**A terceira é o formato de página.** A versão 2 acrescenta codificações delta, e com elas o arquivo
caiu para 7,2 MiB, um terço do CSV com gzip e menos de um quarto do formato da camada silver. A
próxima seção o abre para ver para onde foi o espaço.

**E o tempo.** Cada gravação em Parquet aqui levou entre 2,4 e 5,9 segundos para um mês, e cada
leitura de todas as colunas entre 2,0 e 2,8. Ler o mesmo mês do CSV com gzip levou 6,8 segundos, mais
que o dobro da leitura Parquet mais lenta, antes de gravar qualquer coisa. O job da aula 5 leu e interpretou cada linha de texto do ano, que é o que a
camada raw custa toda vez que é lida, e é por isso que a camada silver existe.

**O ORC, o outro formato colunar, saiu o menor de todos**, 6,1 MiB no seu codec padrão, que neste
Spark é o zstd. A seção 08 é sobre ele.
