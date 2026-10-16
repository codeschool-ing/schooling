---
title: O preço de uma função Python
version: 1
---

**Uma função nativa roda dentro do processo Java do executor. Uma função Python não**, e essa
diferença é o custo evitável mais comum num job PySpark. O Spark tem centenas de funções nativas, em
`pyspark.sql.functions`: datas, strings, aritmética, arrays, JSON. Quando nenhuma serve, você pode
escrever a sua em Python, uma *função definida pelo usuário*, ou UDF. Salve como `~/big/udf.py`:

```schooling-example
{
  "language": "python",
  "file": "udf.py",
  "parts": [
    {
      "code": "\"\"\"The hour of each event, with a built-in function and with a Python function.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"udf\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nclicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n\n\n"
    },
    {
      "code": "@F.udf(\"int\")\ndef hour_of(ts):\n    return ts.hour\n\n\n",
      "note": "**Uma função definida pelo usuário em Python.** O `@F.udf(\"int\")` transforma uma função comum em algo que um DataFrame consegue chamar, declarando o que ela devolve. O Spark não consegue olhar dentro dela."
    },
    {
      "code": "for name, column in [(\"built-in\", F.hour(\"ts\")), (\"python udf\", hour_of(\"ts\"))]:\n    t = time.time()\n    rows = clicks.groupBy(column.alias(\"hour\")).count().collect()\n    print(f\"{name}: {len(rows)} hours, {time.time() - t:.1f} s\")\n",
      "note": "O mesmo agrupamento duas vezes: uma com o `hour` do próprio Spark, outra com a função Python."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit udf.py
WARNING: Using incubator modules: jdk.incubator.vector
built-in: 24 hours, 22.9 s
python udf: 24 hours, 56.5 s
```

**As mesmas 24 horas, as mesmas contagens, e a função Python levou duas vezes e meia o tempo: 56,5 segundos contra 22,9.** O que a UDF acrescenta é uma viagem para cada
linha: o processo Java do executor serializa o timestamp, manda a um processo Python ao lado, o
Python desserializa, chama o `hour_of`, serializa a resposta e a manda de volta. Vinte e quatro
milhões de vezes. O `hour` nativo faz a conta onde os dados já estão.

E há um custo que o relógio não mostra: **o planejador não vê dentro de uma UDF.** Ele não sabe que o
`hour_of` só lê o `ts`, nem que nunca devolve um valor fora de 0 a 23, então não pode usar nada disso
para planejar. A aula 6 mostra um filtro escrito como UDF derrotando uma otimização que o mesmo
filtro, escrito como expressão de coluna, ganha de graça.

A regra, em ordem:

1. **Procure primeiro uma função nativa.** O `pyspark.sql.functions` tem a maior parte do que se
   escreve como UDF, e uma combinação de duas ou três nativas ganha de uma UDF.
2. **Se precisar ser Python, faça uma UDF vetorizada**, `@F.pandas_udf`, que entrega ao Python um
   lote inteiro de linhas como coluna de uma vez, em vez de uma linha por vez. Ela precisa de `pandas`
   e `pyarrow` instalados ao lado do Spark em toda máquina, o que este laboratório não tem, então não
   foi medida aqui.
3. **Uma UDF comum por último**, e só quando os dados são pequenos ou a lógica realmente não tem
   outra forma.
