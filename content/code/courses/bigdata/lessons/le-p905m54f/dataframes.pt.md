---
title: DataFrames: uma tabela com esquema
version: 1
---

**Um DataFrame é um RDD cujas linhas têm colunas com nome e tipo declarado**, e a declaração muda o
que o Spark consegue fazer com ele. Uma função num `map` é opaca: o Spark a envia e a roda. Uma
expressão de coluna como `kind = 'purchase'` é algo que o Spark consegue ler, reordenar, empurrar até
o leitor de arquivos e compilar. Salve como `~/big/explore.py`:

```schooling-example
{
  "language": "python",
  "file": "explore.py",
  "parts": [
    {
      "code": "\"\"\"A first look at the clicks as a DataFrame.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"explore\").getOrCreate()\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).csv(\"data/raw/clicks\")\nclicks.printSchema()\n",
      "note": "**Um DataFrame é uma tabela: linhas, e colunas com nome e um tipo cada.** Só com o `header`, o Spark tira os nomes da primeira linha e chama toda coluna de string."
    },
    {
      "code": "clicks.show(3)\n",
      "note": "O `show` é uma ação: roda um job pequeno e imprime as primeiras linhas como tabela."
    },
    {
      "code": "(clicks.where(F.col(\"kind\") == \"purchase\")\n       .groupBy(\"device\")\n       .agg(F.count(\"*\").alias(\"purchases\"))\n       .orderBy(F.desc(\"purchases\"))\n       .show())\n",
      "note": "**A pergunta é dita em colunas, não em funções sobre linhas.** O `where`, o `groupBy` e o `agg` dizem o que calcular; como dividir o trabalho fica com o Spark."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit explore.py
WARNING: Using incubator modules: jdk.incubator.vector
root
 |-- event_id: string (nullable = true)
 |-- ts: string (nullable = true)
 |-- visitor_id: string (nullable = true)
 |-- kind: string (nullable = true)
 |-- book_id: string (nullable = true)
 |-- device: string (nullable = true)
 |-- day: date (nullable = true)

+--------+-------------------+----------+----+-------+-------+----------+
|event_id|                 ts|visitor_id|kind|book_id| device|       day|
+--------+-------------------+----------+----+-------+-------+----------+
|21209482|2025-11-19 13:27:39|  v1497081|cart|      1| mobile|2025-11-19|
|21172603|2025-11-19 00:00:00|  v1399865|cart|   1139|desktop|2025-11-19|
|21209483|2025-11-19 13:27:40|  v1497081|view|    306| mobile|2025-11-19|
+--------+-------------------+----------+----+-------+-------+----------+
only showing top 3 rows
+-------+---------+
| device|purchases|
+-------+---------+
| mobile|   595590|
|desktop|   316622|
| tablet|    47602|
+-------+---------+
```

O esquema veio da linha de cabeçalho, e toda coluna é `string`: um arquivo CSV não traz tipos, então
um timestamp é texto e um id de livro é texto até alguém dizer o contrário. A coluna `day` é
diferente. Ela veio dos nomes dos diretórios, e o Spark reconheceu os valores como datas.

**A pergunta é escrita em colunas.** O `where`, o `groupBy`, o `agg` e o `orderBy` parecem SQL
porque são as mesmas operações, e compilam para o mesmo plano que o SQL da seção 09. O que o programa
não diz é nada sobre partições, pares ou que tarefa recebe o quê; isso é do planejador, e a aula 6
mostra o plano que ele fez.

O DataFrame é a API a usar por padrão. O resto deste curso usa, e só desce ao RDD onde uma seção diz
por quê.
