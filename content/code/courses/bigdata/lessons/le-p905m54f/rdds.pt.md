---
title: RDDs, e a linhagem por trás de todo resultado
version: 1
---

**O *Resilient Distributed Dataset* é a abstração original do Spark, e tudo o que veio depois foi
construído sobre ela.** Um RDD é uma coleção de elementos cortada em partições, uma por tarefa, que o
Spark sabe calcular nos executores. Você cria um a partir de dados, e toda operação sobre ele cria um
novo. Salve como `~/big/rdd_kinds.py`:

```schooling-example
{
  "language": "python",
  "file": "rdd_kinds.py",
  "parts": [
    {
      "code": "\"\"\"Count the events of each kind with the RDD API, and print its lineage.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"rdd kinds\").getOrCreate()\nsc = spark.sparkContext\n\n"
    },
    {
      "code": "lines = sc.textFile(\"data/raw/clicks/*/*.csv.gz\")\n",
      "note": "**Um RDD é uma coleção cortada em partições, espalhada pelos executores.** O `textFile` cria um cujos elementos são linhas; é preciso um glob porque ele não lê os diretórios `day=` sozinho. Nada é lido ainda."
    },
    {
      "code": "events = lines.filter(lambda line: not line.startswith(\"event_id\"))\npairs = events.map(lambda line: (line.split(\",\")[3], 1))\ncounts = pairs.reduceByKey(lambda a, b: a + b)\n\n",
      "note": "Cada transformação devolve um RDD novo e deixa o antigo em paz. O `filter` tira as linhas de cabeçalho, o `map` transforma uma linha num par, e o `reduceByKey` soma os 1 de cada tipo: o map, o combine e o reduce da aula 4, em três linhas."
    },
    {
      "code": "print(counts.toDebugString().decode())\n",
      "note": "O `toDebugString` imprime a *linhagem*: como o `counts` seria calculado a partir dos arquivos, passo a passo. O Spark a guarda para todo RDD."
    },
    {
      "code": "print(sorted(counts.collect()))\nprint(\"partitions:\", lines.getNumPartitions(), counts.getNumPartitions())\n",
      "note": "O `collect` é a primeira linha que pede um resultado, então é ela que roda o job."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit rdd_kinds.py
WARNING: Using incubator modules: jdk.incubator.vector
(365) PythonRDD[6] at RDD at PythonRDD.scala:59 []
  |   MapPartitionsRDD[5] at mapPartitions at PythonRDD.scala:171 []
  |   ShuffledRDD[4] at partitionBy at NativeMethodAccessorImpl.java:0 []
  +-(365) PairwiseRDD[3] at reduceByKey at /home/ana/big/rdd_kinds.py:10 []
      |   PythonRDD[2] at reduceByKey at /home/ana/big/rdd_kinds.py:10 []
      |   data/raw/clicks/*/*.csv.gz MapPartitionsRDD[1] at textFile at NativeMethodAccessorImpl.java:0 []
      |   data/raw/clicks/*/*.csv.gz HadoopRDD[0] at textFile at NativeMethodAccessorImpl.java:0 []
[('cart', 1920654), ('purchase', 959814), ('search', 1920318), ('view', 19199214)]
partitions: 365 365
```

As contagens são as das aulas 3 e 4, por um terceiro programa. O bloco do topo é o propósito desta
seção.

**Essa é a *linhagem* do `counts`**, lida de baixo para cima: um `HadoopRDD` que lê os arquivos, um
`MapPartitionsRDD` de linhas, o `filter` e o `map` do Python fundidos num `PythonRDD`, os pares, e
então, no `+-` onde a indentação muda, um shuffle: o `ShuffledRDD` é a fronteira que a aula 4 chamou
de shuffle, entre o lado do map e o lado do reduce. O `(365)` em cada nível é o número de partições,
uma por arquivo gzip, porque um arquivo gzip não pode ser dividido e por isso cada um é lido por uma
tarefa.

**A linhagem é o *resilient* do nome.** As partições de um RDD não ficam guardadas em lugar nenhum
por padrão. O que o Spark guarda é a receita, e se um executor morre segurando partições do
`counts`, o Spark roda a receita de novo para exatamente essas partições, a partir dos arquivos, que
ainda existem. É o que a aula 2 viu sem ter um nome para isso: a tarefa perdida rodou de novo porque
a entrada dela podia ser recalculada a partir do registro de como foi feita.

Os RDDs continuam lá, por baixo de todo DataFrame, e são a ferramenta certa quando os dados não têm
um formato que uma tabela consiga expressar. Para tudo o que tem, o resto desta aula prefere o
DataFrame, por motivos que o planejador da aula 6 torna concretos.
