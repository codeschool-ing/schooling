---
title: Particionando na escrita
version: 1
---

**Cada tarefa do estágio que escreve produz o próprio arquivo e, com `partitionBy`, o próprio arquivo
em cada diretório para o qual tem linhas.** Então o número de arquivos que um job escreve é decidido
por como o seu último estágio está particionado, o que é fácil de esquecer porque o programa nunca
fala disso. Salve como `~/big/write_files.py`, que escreve os cliques de janeiro de três jeitos:

```schooling-example
{
  "language": "python",
  "file": "write_files.py",
  "parts": [
    {
      "code": "\"\"\"January's clicks written three ways, and the files each way left on disk.\"\"\"\nimport os\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"write files\").getOrCreate()\njanuary = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"day\") < \"2025-02-01\")\nprint(f\"{january.count():,} rows in January\")\n\n\n"
    },
    {
      "code": "def files(path):\n    sizes = [os.path.getsize(os.path.join(d, f))\n             for d, _, names in os.walk(path) for f in names\n             if f.startswith(\"part-\")]\n    return len(sizes), sum(sizes) / len(sizes) / 2**10\n\n\ndef written(label, df, partition_by=None):\n    path = f\"data/tmp/{label.split()[0]}\"\n    start = time.time()\n    writer = df.write.mode(\"overwrite\")\n    if partition_by:\n        writer = writer.partitionBy(partition_by)\n    writer.parquet(path)\n    n, kib = files(path)\n    print(f\"{label:34} {n:6} files of {kib:7.1f} KiB on average, {time.time() - start:5.1f} s\")\n\n\n",
      "note": "**Todos os arquivos sob um diretório, contados e medidos.** O marcador `_SUCCESS` do próprio Spark e os arquivos de checksum ao lado de cada parte ficam de fora."
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nwritten(\"grouped, 200 partitions\", january.groupBy(\"visitor_id\").count())\nspark.conf.set(\"spark.sql.adaptive.enabled\", True)\n",
      "note": "**Um agrupamento com a execução adaptativa desligada**: 200 partições de shuffle, então 200 tarefas, então 200 arquivos, por menos que cada um tenha."
    },
    {
      "code": "written(\"scattered by day\", january.repartition(50), \"day\")\n",
      "note": "**Particionado por dia, depois de `repartition(50)`**: cada uma das 50 tarefas tem linhas de todos os dias, e escreve um arquivo no diretório de cada dia."
    },
    {
      "code": "written(\"gathered by day\", january.repartition(\"day\"), \"day\")\n",
      "note": "**Particionado por dia, depois de `repartition(\"day\")`**: todas as linhas de um dia estão numa tarefa, então cada dia recebe um arquivo."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit write_files.py
WARNING: Using incubator modules: jdk.incubator.vector
2,038,357 rows in January
grouped, 200 partitions               200 files of    12.1 KiB on average,  14.8 s
scattered by day                     1550 files of    32.6 KiB on average,  24.4 s
gathered by day                        31 files of  1090.2 KiB on average,   5.2 s
```

**A primeira linha é o job prometido na aula 3: duzentos arquivos**, porque um agrupamento com a
execução adaptativa desligada termina em 200 partições de shuffle, e cada uma escreveu 12 KiB. Com a
execução adaptativa ligada, o mesmo agrupamento teria sido juntado em poucas partições e escrito
poucos arquivos; ela vem ligada por padrão, e este é um dos motivos.

**A segunda é a que enche um namenode.** O `repartition(50)` distribui as linhas de cada dia pelas 50
tarefas, e cada tarefa escreve um arquivo em cada um dos 31 diretórios de dia: 1.550 arquivos de 33
KiB, onde 31 bastariam. Na leitura, cada um desses arquivos custa uma abertura e a leitura de um
rodapé, o custo de abertura de 4 MB da aula 7, por 33 KiB de dados. Foi também a escrita mais lenta,
24,4 segundos.

**A terceira junta cada dia numa tarefa antes**, com `repartition("day")`, e escreve 31 arquivos de
1,1 MB em 5,2 segundos. Esse é o padrão a lembrar para uma escrita particionada: reparticionar pela
coluna de partição, depois `partitionBy` pela mesma coluna.

Mas ele já traz embutido o desbalanceamento desta aula. Um dia com dez vezes o tráfego é uma tarefa
com dez vezes as linhas e um arquivo dez vezes maior. Duas configurações lidam com isso. O
`spark.sql.files.maxRecordsPerFile` limita as linhas de um arquivo, então uma tarefa grande escreve
vários arquivos em vez de um enorme. E um repartition pela coluna de partição mais um sal,
`repartition("day", F.pmod(F.xxhash64("event_id"), F.lit(4)))`, espalha cada dia por quatro tarefas e
quatro arquivos, que é o truque da seção 07 aplicado a uma escrita.
