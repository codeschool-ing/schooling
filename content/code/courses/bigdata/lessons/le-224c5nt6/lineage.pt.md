---
title: Uma linhagem que cresce
version: 1
---

**Todo DataFrame carrega o plano que o produz, desde os arquivos.** Foi isso que deixou a seção
anterior refazer uma partição perdida, e em geral sai de graça. Num loop, não. Um DataFrame montado a
partir do DataFrame da iteração anterior carrega o plano anterior dentro do seu, então o plano da
iteração vinte contém outros dezenove.

A seção 04 evitou isso trazendo os ranks de volta ao driver a cada vez. Quando o estado é grande
demais para o driver, ele fica no cluster como um DataFrame, e o plano cresce. Este programa roda o
PageRank desse jeito, num grafo menor feito de compras para que vinte iterações levem minutos, e
imprime o tamanho do plano e o tempo a cada cinco iterações. Salve como `~/big/lineage.py`:

```schooling-example
{
  "language": "python",
  "file": "lineage.py",
  "parts": [
    {
      "code": "\"\"\"PageRank with the ranks kept on the cluster, and the plan that grows with every iteration.\"\"\"\nimport contextlib\nimport io\nimport os\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession, Window\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"lineage\").getOrCreate()\nCHECKPOINT = \"checkpoint\" in sys.argv[1:]\n"
    },
    {
      "code": "spark.sparkContext.setCheckpointDir(\"file://\" + os.path.abspath(\"checkpoints\"))\n\n",
      "note": "**Onde os checkpoints são gravados.** Cada executor grava ali as suas partições e o driver as lê de volta, então num cluster de verdade isto é um diretório no HDFS ou num object store. Aqui todos os processos dividem um disco, e um caminho local funciona."
    },
    {
      "code": "bought = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\nafter = Window.partitionBy(\"visitor_id\").orderBy(\"ts\", \"event_id\")\nlinks = (bought.select(F.col(\"book_id\").alias(\"src\"),\n                       F.lead(\"book_id\").over(after).alias(\"dst\"))\n         .where(F.col(\"dst\").isNotNull() & (F.col(\"src\") != F.col(\"dst\")))\n         .groupBy(\"src\", \"dst\").count()\n         .withColumn(\"share\", F.col(\"count\") / F.sum(\"count\").over(Window.partitionBy(\"src\")))\n         .select(\"src\", \"dst\", \"share\")\n         .cache())\nbooks = spark.read.parquet(\"data/silver/books\").select(F.col(\"book_id\").alias(\"src\"))\nn = books.count()\n\n\ndef plan_lines(df):\n    out = io.StringIO()\n    with contextlib.redirect_stdout(out):\n        df.explain()\n    return len(out.getvalue().splitlines())\n\n\n",
      "note": "**Um grafo menor, só de compras**, para que vinte iterações rodem em minutos: um link é um livro comprado logo depois de outro pelo mesmo visitante."
    },
    {
      "code": "rank = books.withColumn(\"rank\", F.lit(1 / n))\nstart = began = time.time()\nfor i in range(1, 21):\n    received = (links.join(rank, \"src\")\n                .groupBy(\"dst\").agg(F.sum(F.col(\"rank\") * F.col(\"share\")).alias(\"r\")))\n    rank = (books.join(received, books.src == received.dst, \"left\")\n            .select(\"src\", (0.15 / n + 0.85 * F.coalesce(\"r\", F.lit(0.0))).alias(\"rank\")))\n    if i % 5 == 0:\n        #>> **With `checkpoint` on the command line**, the ranks are computed, written to the checkpoint directory and read back as a DataFrame with no history: the plan starts again from a file.\n        #pt> **Com `checkpoint` na linha de comando**, os ranks são calculados, gravados no diretório de checkpoint e lidos de volta como um DataFrame sem histórico: o plano recomeça de um arquivo.\n        if CHECKPOINT:\n            rank = rank.checkpoint()\n        top = rank.orderBy(F.desc(\"rank\")).limit(1).collect()[0]\n        print(f\"iteration {i:2}: plan of {plan_lines(rank):4} lines,\"\n              f\" {time.time() - began:5.1f} s, top book {top.src}\")\n        began = time.time()\nprint(f\"twenty iterations: {time.time() - start:.1f} s\")\n",
      "note": "**Os ranks agora são um DataFrame**, e cada iteração é um DataFrame novo definido sobre o anterior. Nada roda até o `collect` a cada quinta iteração, que calcula os ranks desde a primeira. O tempo impresso é tudo desde a última impressão."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lineage.py
WARNING: Using incubator modules: jdk.incubator.vector
02:38:09 WARN SparkContext: Spark is not running in local mode, therefore the checkpoint directory must not be on the local filesystem. Directory 'file:///home/ana/big/checkpoints' appears to be on the local filesystem.
iteration  5: plan of  291 lines,  53.0 s, top book 1
iteration 10: plan of  576 lines,  28.5 s, top book 1
iteration 15: plan of  861 lines,  32.7 s, top book 1
iteration 20: plan of 1146 lines,  40.5 s, top book 1
twenty iterations: 154.7 s
```

**O plano cresceu 57 linhas por iteração, até 1.146 na vigésima**, e o Spark tem de analisar,
otimizar e planejar tudo isso a cada ação. O tempo cresceu menos que o plano, mas cresceu: 28,5
segundos para as iterações 6 a 10 e 40,5 para as 16 a 20, pela mesma quantidade de trabalho novo a
cada vez.

O aviso no topo é da próxima seção.

**Uma linhagem longa custa em três lugares.** O tempo de planejamento cresce com o plano, e num loop
longo o bastante passa o do trabalho. O recálculo depois de uma falha tem mais para onde voltar,
porque uma partição perdida da iteração vinte pode precisar que as iterações um a dezenove rodem de
novo. E um plano fundo o bastante esgota a pilha do driver enquanto o Spark o percorre, com um
`StackOverflowError` que não aponta linha nenhuma do programa.
