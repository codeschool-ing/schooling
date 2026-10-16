---
title: Os quatro planos de uma consulta
version: 1
---

**Compras por categoria são um join, um filtro, um agrupamento e uma ordenação**, e isso basta para
ver cada passo do planejador. Salve como `~/big/plans.py`:

```schooling-example
{
  "language": "python",
  "file": "plans.py",
  "parts": [
    {
      "code": "\"\"\"Purchases per category: the four plans Spark makes of one query.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"plans\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\n\n"
    },
    {
      "code": "per_category = (clicks.join(books, \"book_id\")\n                .where(F.col(\"kind\") == \"purchase\")\n                .groupBy(\"category\")\n                .agg(F.count(\"*\").alias(\"purchases\"))\n                .orderBy(F.desc(\"purchases\")))\n\n",
      "note": "Um join, um filtro, um agrupamento e uma ordenação. Nada roda ainda."
    },
    {
      "code": "per_category.explain(True)\n",
      "note": "O `explain(True)` imprime todos os planos, do que foi escrito ao que vai rodar. Ele não roda job nenhum."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit plans.py
WARNING: Using incubator modules: jdk.incubator.vector
== Parsed Logical Plan ==
'Sort ['purchases DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Filter (kind#3 = purchase)
      +- Project [book_id#4, event_id#0L, ts#1, visitor_id#2, kind#3, device#5, day#6, category#8, price_cents#9]
         +- Join Inner, (book_id#4 = book_id#7)
            :- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
            +- Relation [book_id#7,category#8,price_cents#9] parquet

== Analyzed Logical Plan ==
category: string, purchases: bigint
Sort [purchases#12L DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Filter (kind#3 = purchase)
      +- Project [book_id#4, event_id#0L, ts#1, visitor_id#2, kind#3, device#5, day#6, category#8, price_cents#9]
         +- Join Inner, (book_id#4 = book_id#7)
            :- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
            +- Relation [book_id#7,category#8,price_cents#9] parquet

== Optimized Logical Plan ==
Sort [purchases#12L DESC NULLS LAST], true
+- Aggregate [category#8], [category#8, count(1) AS purchases#12L]
   +- Project [category#8]
      +- Join Inner, (book_id#4 = book_id#7)
         :- Project [book_id#4]
         :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
         :     +- Relation [event_id#0L,ts#1,visitor_id#2,kind#3,book_id#4,device#5,day#6] parquet
         +- Project [book_id#7, category#8]
            +- Filter isnotnull(book_id#7)
               +- Relation [book_id#7,category#8,price_cents#9] parquet

== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- Sort [purchases#12L DESC NULLS LAST], true, 0
   +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]
      +- HashAggregate(keys=[category#8], functions=[count(1)], output=[category#8, purchases#12L])
         +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]
            +- HashAggregate(keys=[category#8], functions=[partial_count(1)], output=[category#8, count#24L])
               +- Project [category#8]
                  +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                     :- Project [book_id#4]
                     :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                     :     +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                     +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]
                        +- Filter isnotnull(book_id#7)
                           +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

Leia os quatro de cima para baixo.

**O plano interpretado é o programa, de trás para a frente.** Cada linha é uma operação, indentada
sob aquela cuja saída ela lê, então os dados correm de baixo para cima: as duas `Relation`, o join,
um `Project` que o join fez para ficar com um `book_id` dos dois, o filtro, a agregação e a
ordenação. O número depois do `#` em cada coluna é como o Catalyst distingue duas colunas de mesmo
nome, como os dois `book_id`. Um nome, `'purchases` na ordenação, ainda tem um `'`: não foi resolvido.
Um DataFrame resolve cada nome quando cada método é chamado, então quase tudo já é conhecido aqui; a
mesma consulta em SQL chegaria com todos os nomes marcados assim.

**O plano analisado acrescenta o esquema do resultado**, `category: string, purchases: bigint`, e
resolve o último nome. No mais, é o plano interpretado: a análise confere, não rearruma.

**O plano otimizado mudou coisas de lugar.** O filtro sobre `kind` não está mais acima do join: foi
empurrado para *baixo* dele, sobre os cliques, para que o join só veja compras. Cada `Relation` agora
está sob um `Project` que guarda só as colunas que a consulta usa, e filtros `isnotnull` apareceram
nas chaves do join, porque um inner join descarta nulls de qualquer jeito e descartá-los cedo sai
mais barato. Nada disso estava no programa.

**O plano físico diz como.** O join é um `BroadcastHashJoin`: os livros são pequenos o bastante para
ser copiados inteiros para cada tarefa, o join no map da aula 4, escolhido sem ninguém pedir. As duas
linhas `Exchange` são os dois shuffles, um para o agrupamento e outro para a ordenação. E cada
`FileScan` lista o que vai ler e pular, que as seções 05 a 08 tratam uma de cada vez.
