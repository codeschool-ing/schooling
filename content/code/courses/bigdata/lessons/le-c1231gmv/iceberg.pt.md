---
title: Apache Iceberg
version: 1
---

**O Iceberg veio da Netflix, e a sua primeira preocupação eram tabelas de milhões de arquivos**, em que
até listar um diretório é lento demais. Em vez de um log relido desde o início, cada commit grava um
novo *arquivo de metadados* que aponta para uma *manifest list*, que aponta para *manifests*, que
listam os arquivos de dados com estatísticas de cada um. Um catálogo guarda um ponteiro por tabela,
para o arquivo de metadados atual, e um commit é trocar esse ponteiro. Ler uma tabela nunca lista um
diretório.

Tabelas Iceberg moram num *catálogo*, e este programa usa o mais simples, um diretório. Salve como
`~/big/iceberg_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "iceberg_basics.py",
  "parts": [
    {
      "code": "\"\"\"An Iceberg table of purchases, partitioned by day without a day column.\"\"\"\nimport json\nimport os\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"iceberg basics\")\n         .config(\"spark.sql.extensions\",\n                 \"org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions\")\n         .config(\"spark.sql.catalog.lab\", \"org.apache.iceberg.spark.SparkCatalog\")\n         .config(\"spark.sql.catalog.lab.type\", \"hadoop\")\n         .config(\"spark.sql.catalog.lab.warehouse\", \"file://\" + os.path.abspath(\"data/iceberg\"))\n         .getOrCreate())\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\"))\n\n",
      "note": "**Um catálogo chamado `lab`**, do tipo mais simples que o Iceberg tem: um diretório, em que cada tabela guarda os próprios metadados. Catálogos de produção são serviços (o metastore do Hive, um catálogo REST, o AWS Glue); as tabelas são as mesmas."
    },
    {
      "code": "spark.sql(\"DROP TABLE IF EXISTS lab.shop.purchases\")\nspark.sql(\"\"\"CREATE TABLE lab.shop.purchases\n             (event_id BIGINT, ts TIMESTAMP, visitor_id STRING, book_id INT)\n             USING iceberg PARTITIONED BY (days(ts))\"\"\")\npurchases.where(F.col(\"ts\") < \"2025-02-01\").writeTo(\"lab.shop.purchases\").append()\npurchases.where((F.col(\"ts\") >= \"2025-02-01\") & (F.col(\"ts\") < \"2025-03-01\")) \\\n    .writeTo(\"lab.shop.purchases\").append()\nspark.sql(\"DELETE FROM lab.shop.purchases WHERE visitor_id = 'v0000000'\")\n\n",
      "note": "**Particionamento oculto**: a tabela é particionada por `days(ts)`, uma função de uma coluna que ela já tem. Ninguém grava uma coluna `day`, e uma consulta que filtra por `ts` é podada por dia sem saber que a tabela é particionada."
    },
    {
      "code": "spark.sql(\"\"\"SELECT snapshot_id, operation,\n                    summary['added-data-files'] AS added,\n                    summary['deleted-data-files'] AS deleted,\n                    summary['total-records'] AS records\n             FROM lab.shop.purchases.snapshots ORDER BY committed_at\"\"\").show()\nfirst = spark.sql(\"SELECT min_by(snapshot_id, committed_at) FROM lab.shop.purchases.snapshots\").first()[0]\n",
      "note": "**Todo commit é um snapshot**, e a tabela responde perguntas sobre si mesma por tabelas de metadados com o nome dela."
    },
    {
      "code": "print(\"first snapshot:\", spark.sql(\n    f\"SELECT count(*) FROM lab.shop.purchases VERSION AS OF {first}\").first()[0], \"purchases\")\n\n",
      "note": "**Viagem no tempo pelo id do snapshot**: a tabela depois só do primeiro append."
    },
    {
      "code": "day = spark.sql(\"\"\"SELECT count(*) FROM lab.shop.purchases\n                   WHERE ts >= '2025-02-14' AND ts < '2025-02-15'\"\"\").first()[0]\nprint(\"14 February:\", day, \"purchases\")\ntime.sleep(1)\nsc = spark.sparkContext\nurl = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/sql?details=true&planDescription=false\"\nlast = max(json.load(urllib.request.urlopen(url)), key=lambda q: q[\"id\"])\nfor node in last[\"nodes\"]:\n    if node[\"nodeName\"].startswith(\"BatchScan\"):\n        m = {x[\"name\"]: x[\"value\"] for x in node[\"metrics\"]}\n        print(f\"  {m['number of result data files']} data files read,\"\n              f\" {m['number of skipped data files']} skipped\")\n",
      "note": "**Um filtro só em `ts`**, e depois as métricas da própria leitura pela interface REST do driver, como o `lastscan.py` da aula 6 as leu para o Parquet: quantos arquivos de dados a leitura leu e quantos pulou."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/iceberg-spark-runtime-4.1_2.13-1.12.0.jar iceberg_basics.py
WARNING: Using incubator modules: jdk.incubator.vector
+-------------------+---------+-----+-------+-------+
|        snapshot_id|operation|added|deleted|records|
+-------------------+---------+-----+-------+-------+
|4290993200430658696|   append|   32|   NULL|  80988|
|2530551120499753072|   append|   29|   NULL| 154822|
|9086536705081289043|overwrite|   60|     61| 148537|
+-------------------+---------+-----+-------+-------+

first snapshot: 80988 purchases
14 February: 2469 purchases
  2 data files read, 58 skipped
```

**Três snapshots, um por commit**, cada um com o seu id, e o delete foi registrado como um
`overwrite` que removeu 61 arquivos e acrescentou 60: o Iceberg, como o Delta, reescreveu os arquivos
com as linhas do robô. A viagem no tempo usa o id do snapshot em vez de um número de versão.

**Janeiro foi gravado em 32 arquivos, não 31**, e o motivo é um detalhe que vale conhecer. O
`days(ts)` corta por dias em UTC, e os timestamps do laboratório são de São Paulo, três horas atrás:
um dia local atravessa dois dias UTC, e as compras de janeiro, da meia-noite local do dia 1º à
meia-noite local de 1º de fevereiro, tocam 32 deles. **A consulta de 14 de fevereiro leu dois arquivos
pelo mesmo motivo**, e pulou os outros 58 sem abri-los. Ela nunca citou uma partição; o Iceberg
transformou o filtro em `ts` num filtro sobre os dias. Isso é o *particionamento oculto*, e significa
que o particionamento de uma tabela pode mudar depois sem mudar uma única consulta.

Os metadados, no disco:

```
ana@lab:~/big$ ls data/iceberg/shop/purchases/metadata | grep -v crc
633faf96-6df9-4029-8850-a257690c54aa-m0.avro
633faf96-6df9-4029-8850-a257690c54aa-m1.avro
633faf96-6df9-4029-8850-a257690c54aa-m2.avro
a3e8d1bf-a24f-47af-aaf1-b44789c5383d-m0.avro
a6636b0e-b3bb-45d9-8455-a4dc91686f17-m0.avro
snap-2530551120499753072-1-a6636b0e-b3bb-45d9-8455-a4dc91686f17.avro
snap-4290993200430658696-1-a3e8d1bf-a24f-47af-aaf1-b44789c5383d.avro
snap-9086536705081289043-1-633faf96-6df9-4029-8850-a257690c54aa.avro
v1.metadata.json
v2.metadata.json
v3.metadata.json
v4.metadata.json
version-hint.text
```

Quatro versões dos metadados da tabela, a `v1` da criação e uma por commit. Uma manifest list por
snapshot, os arquivos `snap-`, e os manifests para os quais elas apontam, os arquivos `-m`, todos em
Avro. E o `version-hint.text`, o ponteiro que este catálogo de diretório mantém, que guarda o número
da versão atual. **Catálogos de produção são serviços**: o metastore do Hive
da aula 12, o AWS Glue, o Nessie, ou qualquer servidor que fale o protocolo de catálogo REST do
Iceberg, que é o que deixa motores além do Spark acharem as mesmas tabelas e fazerem commits nelas.
