---
title: Lendo um plano físico
version: 1
---

**O plano físico é uma árvore, e o `explain("formatted")` a imprime numerada**, com os detalhes de
cada nó abaixo, sob o seu número, o que é bem mais fácil de ler do que a forma indentada. Salve como
`~/big/formatted.py`:

```schooling-example
{
  "language": "python",
  "file": "formatted.py",
  "parts": [
    {
      "code": "\"\"\"The physical plan of the same query, numbered, and then run.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"formatted\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\nper_category = (clicks.join(books, \"book_id\")\n                .where(F.col(\"kind\") == \"purchase\")\n                .groupBy(\"category\")\n                .agg(F.count(\"*\").alias(\"purchases\"))\n                .orderBy(F.desc(\"purchases\")))\n\n"
    },
    {
      "code": "per_category.explain(\"formatted\")\n",
      "note": "O `\"formatted\"` imprime o plano físico como uma árvore numerada, e depois os detalhes de cada nó sob o seu número."
    },
    {
      "code": "print(per_category.collect()[:3])\nper_category.explain()\n",
      "note": "O `collect` roda exatamente esta consulta. Depois dele, o `explain()` mostra o plano que o Spark acabou usando, que pode ser diferente do de cima: seção 10."
    }
  ]
}
```

A primeira parte do que ele imprime:

```
ana@lab:~/big$ spark-submit formatted.py
WARNING: Using incubator modules: jdk.incubator.vector
== Physical Plan ==
AdaptiveSparkPlan (14)
+- Sort (13)
   +- Exchange (12)
      +- HashAggregate (11)
         +- Exchange (10)
            +- HashAggregate (9)
               +- Project (8)
                  +- BroadcastHashJoin Inner BuildRight (7)
                     :- Project (3)
                     :  +- Filter (2)
                     :     +- Scan parquet  (1)
                     +- BroadcastExchange (6)
                        +- Filter (5)
                           +- Scan parquet  (4)


(1) Scan parquet 
Output [3]: [kind#3, book_id#4, day#6]
Batched: true
Location: InMemoryFileIndex [file:/home/ana/big/data/silver/clicks]
PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)]
ReadSchema: struct<kind:string,book_id:int>

(2) Filter
Input [3]: [kind#3, book_id#4, day#6]
Condition : ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))

(3) Project
Output [1]: [book_id#4]
Input [3]: [kind#3, book_id#4, day#6]

(4) Scan parquet 
Output [2]: [book_id#7, category#8]
Batched: true
Location: InMemoryFileIndex [file:/home/ana/big/data/silver/books]
PushedFilters: [IsNotNull(book_id)]
ReadSchema: struct<book_id:int,category:string>

(5) Filter
Input [2]: [book_id#7, category#8]
Condition : isnotnull(book_id#7)

(6) BroadcastExchange
Input [2]: [book_id#7, category#8]
Arguments: HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]

(7) BroadcastHashJoin
Left keys [1]: [book_id#4]
Right keys [1]: [book_id#7]
Join type: Inner
Join condition: None

(8) Project
Output [1]: [category#8]
Input [3]: [book_id#4, book_id#7, category#8]

(9) HashAggregate
Input [1]: [category#8]
Keys [1]: [category#8]
Functions [1]: [partial_count(1)]
Aggregate Attributes [1]: [count#23L]
Results [2]: [category#8, count#24L]

(10) Exchange
Input [2]: [category#8, count#24L]
Arguments: hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]

(11) HashAggregate
Input [2]: [category#8, count#24L]
Keys [1]: [category#8]
Functions [1]: [count(1)]
Aggregate Attributes [1]: [count(1)#22L]
Results [2]: [category#8, count(1)#22L AS purchases#12L]

(12) Exchange
Input [2]: [category#8, purchases#12L]
Arguments: rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]

(13) Sort
Input [2]: [category#8, purchases#12L]
Arguments: [purchases#12L DESC NULLS LAST], true, 0

(14) AdaptiveSparkPlan
Output [2]: [category#8, purchases#12L]
Arguments: isFinalPlan=false
```

Leia a árvore das folhas para cima, que é a ordem em que os dados se movem:

- **(1) a (3), os cliques.** Um scan que lê duas colunas, `kind` e `book_id`, um filtro que fica com
  as compras e uma projeção que fica só com o `book_id`.
- **(4) a (6), os livros**, lidos, filtrados e entregues a um `BroadcastExchange`: recolhidos pelo
  driver e mandados inteiros a cada executor.
- **(7) o join**, feito dentro de cada tarefa que lê cliques, contra a própria cópia dos livros. O
  `BuildRight` quer dizer que o lado direito, os livros, é o que fica na memória.
- **(9) a (11), a agregação em duas metades**, o combiner da aula 4 com outro nome. O `partial_count`
  conta dentro de cada tarefa antes do shuffle; o `Exchange` em (10) manda cada categoria a um lugar,
  `hashpartitioning(category#8, 200)`, em 200 partições; e o segundo `HashAggregate` soma as
  contagens parciais.
- **(12) e (13), a ordenação.** Outro `Exchange`, desta vez `rangepartitioning`: para ordenar
  globalmente, o Spark tira uma amostra dos valores, divide-os em faixas e manda cada faixa a uma
  tarefa, para que as saídas saiam em ordem. É o particionador por faixas que a aula 4 disse que uma
  saída ordenada precisa.

**Todo `Exchange` é um shuffle, e todo shuffle é a fronteira de um estágio.** Contar os exchanges é a
estimativa mais rápida do custo de uma consulta: esta tem dois, os dois sobre dados pequenos, depois
que o join e a contagem parcial encolheram 24 milhões de linhas a dez categorias por tarefa. A aula 7
conta os estágios em que eles se transformam.

O `200` aparece duas vezes, e nada na consulta o pediu. É o número padrão de partições de shuffle, e
com dez categorias isso quer dizer 190 vazias. A seção 10 mostra o Spark percebendo.
