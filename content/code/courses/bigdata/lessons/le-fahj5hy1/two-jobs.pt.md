---
title: Dois jobs, e o disco entre eles
version: 1
---

**Uma pergunta que precisa de dois agrupamentos precisa de dois jobs MapReduce**, porque um job tem
exatamente um shuffle. A próxima pergunta da Ana tem dois: quantos eventos cada visitante tem, e
depois, quantos visitantes têm cada número de eventos? O segundo agrupa o resultado do primeiro.

O job 1 precisa de um mapper com o visitante como chave, `~/big/per_visitor.py`:

```schooling-example
{
  "language": "python",
  "file": "per_visitor.py",
  "parts": [
    {
      "code": "\"\"\"Map for job 1: for every event, emit its visitor and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    print(f\"{line.split(',')[2]}\\t1\")\n",
      "note": "O mesmo formato do `mapper.py`, com o visitante como chave em vez do tipo. O `reducer.py` então conta os eventos de cada visitante, sem mudança."
    }
  ]
}
```

O job 2 lê a saída do job 1 e usa a contagem como chave, `~/big/histogram.py`:

```schooling-example
{
  "language": "python",
  "file": "histogram.py",
  "parts": [
    {
      "code": "\"\"\"Map for job 2: read job 1's 'visitor<TAB>events' and emit the events and a 1.\"\"\"\nimport sys\n\n"
    },
    {
      "code": "for line in sys.stdin:\n    visitor, events = line.rstrip(\"\\n\").split(\"\\t\")\n    print(f\"{events}\\t1\")\n",
      "note": "A entrada do job 2 é a saída do job 1, lida de volta do HDFS: uma linha por visitante. A chave agora é o número de eventos, então o `reducer.py` conta quantos visitantes tiveram cada número."
    }
  ]
}
```

Os dois reduzem com o `reducer.py`, e o job 1 também combina com ele. Rode um depois do outro, com o
diretório de saída do job 1 como entrada do job 2:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files per_visitor.py,reducer.py -mapper 'python3 per_visitor.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/per-visitor 2> job1.log

real	0m51.183s
user	2m13.911s
sys	0m7.766s
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files histogram.py,reducer.py -mapper 'python3 histogram.py' -reducer 'python3 reducer.py' -input /out/per-visitor -output /out/histogram 2> job2.log

real	0m8.949s
user	0m16.357s
sys	0m1.017s
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' job1.log | grep -E 'Reduce output records'
		Reduce output records=1729141
ana@lab:~/big$ hdfs dfs -du -s -h /out/per-visitor
19.3 M  57.8 M  /out/per-visitor
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | sort -n | head -n 3
2	15
3	623
4	11098
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | sort -n | tail -n 2
69	1
960905	1
ana@lab:~/big$ hdfs dfs -cat /out/histogram/part-00000 | wc -l
65
```

**Cerca de um minuto para os dois jobs juntos, 51 segundos e 9. O job 1 escreveu 1.729.141 linhas,
uma por visitante, no HDFS: 19,3 MB, guardados três vezes, 57,8 MB em disco. O job 2 as leu de
volta.** Esse arquivo existe só para levar a resposta de um job ao seguinte, e foi escrito com todo o
cuidado que o HDFS dá a qualquer coisa: três cópias, checksums, um commit. O histograma em si tem 65
linhas. A maioria dos visitantes tem um punhado de eventos, e na ponta oposta está um visitante com
960.905: o robô, de novo.

Os mesmos dois agrupamentos como um programa Spark, `~/big/two_steps.py`:

```schooling-example
{
  "language": "python",
  "file": "two_steps.py",
  "parts": [
    {
      "code": "\"\"\"Both jobs as one Spark program.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"two steps\").getOrCreate()\nclicks = (spark.read.csv(\"hdfs://localhost:9000/raw/clicks-2025.csv\")\n          .toDF(\"event_id\", \"ts\", \"visitor_id\", \"kind\", \"book_id\", \"device\"))\n"
    },
    {
      "code": "per_visitor = clicks.groupBy(\"visitor_id\").agg(F.count(\"*\").alias(\"events\"))\nhistogram = per_visitor.groupBy(\"events\").agg(F.count(\"*\").alias(\"visitors\"))\nhistogram.orderBy(\"events\").show(5)\nhistogram.orderBy(F.desc(\"events\")).show(2)\n",
      "note": "**Dois agrupamentos, escritos um depois do outro, rodam como uma aplicação.** O primeiro resultado nunca é escrito no HDFS: o Spark o passa de um estágio ao seguinte pelos arquivos de shuffle da aula 7."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit two_steps.py
WARNING: Using incubator modules: jdk.incubator.vector
+------+--------+
|events|visitors|
+------+--------+
|     2|      15|
|     3|     623|
|     4|   11098|
|     5|  106136|
|     6|  423168|
+------+--------+
only showing top 5 rows
+------+--------+
|events|visitors|
+------+--------+
|960905|       1|
|    69|       1|
+------+--------+
only showing top 2 rows

real	1m4.424s
user	0m31.948s
sys	0m2.228s
```

**O mesmo histograma, em 64 segundos, e nada mais rápido.** Isso merece a mesma honestidade da
medida da aula 1. Numa máquina, sobre 1,2 GB, dois jobs MapReduce no executor local levaram mais ou
menos o mesmo tempo que o Spark, e o Spark gastou boa parte do minuto iniciando uma aplicação e
lendo CSV em três núcleos.

O que a medida não mostra é como a diferença cresce. Num cluster de verdade, cada job MapReduce
também espera o YARN iniciar um contêiner para cada tarefa, alguns segundos por vez. E um job de dez
passos são dez jobs, cada um lendo a entrada do HDFS e escrevendo a saída três vezes. Algoritmos de
aprendizado de máquina e de grafos repetem o mesmo passo dezenas de vezes sobre os mesmos dados,
então pagam a ida e volta pelo HDFS dezenas de vezes. A aula 9 roda um laço desses no Spark, com os
dados guardados na memória entre um passo e outro, que é o caso para o qual o Spark foi feito.
