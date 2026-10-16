---
title: Apache Hudi
version: 1
---

**O Hudi veio da Uber, e a sua primeira preocupação eram upserts**: um fluxo de mudanças, algumas
linhas novas e algumas correções de antigas, aplicado a uma tabela grande a cada poucos minutos. Toda
tabela Hudi tem uma chave de registro, e uma gravação é um upsert por padrão. Salve como
`~/big/hudi_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "hudi_basics.py",
  "parts": [
    {
      "code": "\"\"\"A Hudi table of purchases, and an upsert that corrects some of them and adds more.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"hudi basics\")\n         .config(\"spark.serializer\", \"org.apache.spark.serializer.KryoSerializer\")\n         .config(\"spark.kryo.registrator\", \"org.apache.spark.HoodieSparkKryoRegistrar\")\n         .config(\"spark.sql.extensions\", \"org.apache.spark.sql.hudi.HoodieSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.hudi.catalog.HoodieCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/hudi/purchases\")\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\", \"day\")\n             .withColumn(\"updated\", F.unix_micros(\"ts\")))\n\n",
      "note": "**O Hudi pede o Kryo**, o serializador mais rápido do Spark, com as próprias classes registradas, além da extensão e do catálogo que os outros dois formatos pediram."
    },
    {
      "code": "options = {\n    \"hoodie.table.name\": \"purchases\",\n    \"hoodie.datasource.write.recordkey.field\": \"event_id\",\n    \"hoodie.datasource.write.precombine.field\": \"updated\",\n    \"hoodie.datasource.write.partitionpath.field\": \"day\",\n    \"hoodie.datasource.write.table.type\": \"COPY_ON_WRITE\",\n}\n\njanuary = purchases.where(F.col(\"day\") < \"2025-02-01\")\njanuary.write.format(\"hudi\").options(**options).mode(\"overwrite\").save(PATH)\nprint(\"after January:\", spark.read.format(\"hudi\").load(PATH).count(), \"purchases\")\n\n",
      "note": "**Uma chave de registro e um campo de ordenação são o que torna um upsert possível**: uma linha cujo `event_id` já está na tabela a substitui, e quando duas versões de uma linha se encontram, vence a de `updated` maior. O `updated` é o momento em que a linha mudou pela última vez, em microssegundos; uma coluna de timestamp como campo de ordenação falhou nesta versão do Hudi com o Spark 4.1, e um número é o que toda versão aceita."
    },
    {
      "code": "corrected = (january.orderBy(\"event_id\").limit(1000)\n             .withColumn(\"book_id\", F.lit(42))\n             .withColumn(\"updated\", F.col(\"updated\") + 86_400_000_000))\nfebruary = purchases.where((F.col(\"day\") >= \"2025-02-01\") & (F.col(\"day\") < \"2025-03-01\"))\n(corrected.unionByName(february).write.format(\"hudi\").options(**options)\n .option(\"hoodie.datasource.write.operation\", \"upsert\").mode(\"append\").save(PATH))\n\ntable = spark.read.format(\"hudi\").load(PATH)\nprint(\"after the upsert:\", table.count(), \"purchases,\",\n      table.where(F.col(\"updated\") > F.unix_micros(\"ts\")).count(), \"of them corrected\")\n",
      "note": "**O upsert**: mil das compras de janeiro mandadas de novo com um livro corrigido e um `updated` mais tarde, um dia depois do original, junto com fevereiro inteiro. Nada no lote diz quais linhas são novas."
    },
    {
      "code": "table.groupBy(\"_hoodie_commit_time\").count().orderBy(\"_hoodie_commit_time\").show()\n",
      "note": "**Toda linha carrega o commit que a gravou por último**, numa coluna que o Hudi acrescenta: `_hoodie_commit_time`."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/hudi-spark4.1-bundle_2.13-1.2.1.jar hudi_basics.py 2>/dev/null
# WARNING: Unable to get Instrumentation. Dynamic Attach failed. You may add this JAR as -javaagent manually, or supply -Djdk.attach.allowAttachSelf
# WARNING: Unable to attach Serviceability Agent. Unable to attach even with module exceptions: [org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed., org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed., org.apache.hudi.org.openjdk.jol.vm.sa.SASupportException: Sense failed.]
after January: 80988 purchases
after the upsert: 154822 purchases, 1000 of them corrected
+-------------------+-----+
|_hoodie_commit_time|count|
+-------------------+-----+
|  20261016034138060|79988|
|  20261016034229238|74834|
+-------------------+-----+
```

**O lote tinha 1.000 correções e fevereiro, e a tabela terminou com cada compra uma vez**: 154.822, a
mesma contagem de janeiro mais fevereiro, 1.000 delas com o `updated` mais tarde. O Hudi procurou
cada `event_id` que chegava, substituiu as linhas que achou e inseriu o resto. Com o Delta ou o
Iceberg a mesma coisa é um `MERGE INTO`; com o Hudi é a gravação comum.

**O `_hoodie_commit_time` diz qual commit gravou cada linha por último**: 79.988 linhas de janeiro do
primeiro commit, e 74.834 do segundo, as 73.834 de fevereiro mais as 1.000 correções. O Hudi
acrescenta cinco colunas assim a cada linha, e é isso que torna possíveis leituras incrementais: *me
dê o que mudou desde este commit*, sem comparar tabelas.

As duas linhas `# WARNING` vêm de uma biblioteca dentro do pacote do Hudi que estima o tamanho de
objetos na memória e tenta se conectar à JVM em execução para isso; ela passa a estimar sem a
conexão, e nada mais depende disso. A timeline, o log do Hudi:

```
ana@lab:~/big$ ls data/hudi/purchases/.hoodie/timeline
20261016034138060.commit.requested
20261016034138060.inflight
20261016034138060_20261016034226170.commit
20261016034229238.commit.requested
20261016034229238.inflight
20261016034229238_20261016034250468.commit
history
```

**Cada commit passa por três estados, cada um um arquivo**: `requested`, `inflight` e o commit
concluído, com o nome dos seus horários de início e fim. Um leitor só confia em commits concluídos;
um escritor que morre deixa um `inflight` que o próximo escritor desfaz.

Esta tabela é *copy on write*: um upsert reescreve todo arquivo que tem uma linha alterada, então as
leituras são Parquet comum e as gravações custam mais. O outro tipo do Hudi, *merge on read*, grava
as mudanças em arquivos de log pequenos ao lado do Parquet e as junta quando a tabela é lida, até uma
*compactação* incorporá-las: gravações baratas, leituras mais caras, para tabelas que mudam a cada
poucos minutos.
