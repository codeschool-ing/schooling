---
title: Como o planejador escolheu o join
version: 1
---

**O planejador escolheu um broadcast join para compras por categoria sem ninguém mandar**, o join no
map da aula 4. Ele escolheu a partir de uma estimativa do tamanho de cada lado, e a estimativa e a
regra estão as duas à vista. Salve como `~/big/joins_chosen.py`:

```schooling-example
{
  "language": "python",
  "file": "joins_chosen.py",
  "parts": [
    {
      "code": "\"\"\"How Spark chose to join, and what it estimated to choose it.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"joins chosen\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n\ndef joined():\n    return clicks.join(books, \"book_id\").groupBy(\"category\").agg(F.count(\"*\"))\n\n\n\n"
    },
    {
      "code": "joined().explain(\"cost\")\n",
      "note": "O `\"cost\"` imprime o plano lógico otimizado com o tamanho que o Spark estimou para cada passo. Os livros são o passo a olhar."
    },
    {
      "code": "print(spark.conf.get(\"spark.sql.autoBroadcastJoinThreshold\"))\n\n",
      "note": "**O limite abaixo do qual um lado é copiado para cada tarefa em vez de embaralhado**, 10 MB por padrão."
    },
    {
      "code": "spark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\njoined().explain()\n",
      "note": "**Com -1, o limite desliga o broadcast**, e a mesma consulta, montada de novo para ser planejada de novo, é planejada do outro jeito."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit joins_chosen.py
WARNING: Using incubator modules: jdk.incubator.vector
== Optimized Logical Plan ==
Aggregate [category#8], [category#8, count(1) AS count(1)#22L], Statistics(sizeInBytes=783.6 GiB)
+- Project [category#8], Statistics(sizeInBytes=609.5 GiB)
   +- Join Inner, (book_id#4 = book_id#7), Statistics(sizeInBytes=783.6 GiB)
      :- Project [book_id#4], Statistics(sizeInBytes=50.7 MiB)
      :  +- Filter isnotnull(book_id#4), Statistics(sizeInBytes=388.8 MiB)
      :     +- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet, Statistics(sizeInBytes=388.8 MiB)
      +- Project [book_id#7, category#8], Statistics(sizeInBytes=15.5 KiB)
         +- Filter isnotnull(book_id#7), Statistics(sizeInBytes=17.4 KiB)
            +- Relation [book_id#7,category#8,price_cents#9] parquet, Statistics(sizeInBytes=17.4 KiB)

== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- HashAggregate(keys=[category#8], functions=[count(1)], output=[category#8, count(1)#22L])
   +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=40]
      +- HashAggregate(keys=[category#8], functions=[partial_count(1)], output=[category#8, count#24L])
         +- Project [category#8]
            +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
               :- Project [book_id#4]
               :  +- Filter isnotnull(book_id#4)
               :     +- FileScan parquet [book_id#4,day#6] Batched: true, DataFilters: [isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int>
               +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=35]
                  +- Filter isnotnull(book_id#7)
                     +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>


10485760b
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- HashAggregate(keys=[category#8], functions=[count(1)])
   +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=86]
      +- HashAggregate(keys=[category#8], functions=[partial_count(1)])
         +- Project [category#8]
            +- SortMergeJoin [book_id#4], [book_id#7], Inner
               :- Sort [book_id#4 ASC NULLS FIRST], false, 0
               :  +- Exchange hashpartitioning(book_id#4, 200), ENSURE_REQUIREMENTS, [plan_id=78]
               :     +- Project [book_id#4]
               :        +- Filter isnotnull(book_id#4)
               :           +- FileScan parquet [book_id#4,day#6] Batched: true, DataFilters: [isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int>
               +- Sort [book_id#7 ASC NULLS FIRST], false, 0
                  +- Exchange hashpartitioning(book_id#7, 200), ENSURE_REQUIREMENTS, [plan_id=79]
                     +- Filter isnotnull(book_id#7)
                        +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

**Leia as `Statistics` em cada linha do plano otimizado.** A `Relation` dos livros está estimada em
17,4 KiB, que é o tamanho do arquivo Parquet dela, e depois de ficar com duas colunas, 15,5 KiB. Os
cliques são 388,8 MiB. O limite impresso depois do plano é `10485760b`, 10 MB: um lado estimado abaixo
disso vai por broadcast, então os livros vão, e o plano mostra `BroadcastHashJoin`.

As outras estimativas valem uma olhada pelo quanto erram. O join está estimado em 783,6 GiB, duas mil
vezes a entrada, porque sem saber nada dos valores de `book_id` o planejador supõe o pior. Para
escolher um broadcast ele só precisa do lado pequeno, e essa estimativa está boa; um planejador que
escolhesse a ordem dos joins por esses números escolheria mal. O Spark tem um *otimizador baseado em
custo* para isso, que usa estatísticas de coluna calculadas pelo `ANALYZE TABLE` sobre tabelas de um
catálogo, e ele vem desligado por padrão. A aula 12 apresenta o catálogo.

**Com o limite em -1, a mesma consulta vira um `SortMergeJoin`**: os dois lados são embaralhados por
`book_id` em 200 partições, cada partição é ordenada, e os dois fluxos ordenados são mesclados. Dois
nós `Exchange` e dois nós `Sort` onde o broadcast não tinha nenhum do lado dos cliques: 24 milhões de
linhas movidas para encontrar uma tabela de 3.000. É o join no reduce da aula 4, e a aula 8 cronometra
um contra o outro.

O limite é uma configuração porque o broadcast tem limite: o lado pequeno é recolhido pelo driver e
guardado inteiro na memória de cada executor. Um lado estimado como pequeno por engano, mandado em
broadcast com 2 GB, é um jeito comum de deixar um driver ou um executor sem memória, e a aula 8 mostra
como isso aparece.
