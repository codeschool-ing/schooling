---
title: A mesma pergunta, de três jeitos
version: 1
---

**Compras por dispositivo, perguntadas com a API de RDD, a API de DataFrame e SQL.** Cada uma roda
duas vezes, alternando, para que a primeira não pague sozinha por aquecer a máquina. Salve como
`~/big/three_ways.py`:

```schooling-example
{
  "language": "python",
  "file": "three_ways.py",
  "parts": [
    {
      "code": "\"\"\"Purchases per device, asked three ways.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"three ways\").getOrCreate()\nSCHEMA = (\"event_id LONG, ts TIMESTAMP, visitor_id STRING, kind STRING, \"\n          \"book_id INT, device STRING\")\nclicks = spark.read.option(\"header\", True).schema(SCHEMA).csv(\"data/raw/clicks\")\n"
    },
    {
      "code": "clicks.createOrReplaceTempView(\"clicks\")\n\n\ndef rdd():\n    return (spark.sparkContext.textFile(\"data/raw/clicks/*/*.csv.gz\")\n            .filter(lambda line: \",purchase,\" in line)\n            .map(lambda line: (line.split(\",\")[5], 1))\n            .reduceByKey(lambda a, b: a + b).collect())\n\n\ndef dataframe():\n    return clicks.where(\"kind = 'purchase'\").groupBy(\"device\").count().collect()\n\n\ndef sql():\n    return spark.sql(\"SELECT device, count(*) FROM clicks \"\n                     \"WHERE kind = 'purchase' GROUP BY device\").collect()\n\n\n",
      "note": "Uma *view temporária* dá ao DataFrame um nome que o SQL consegue usar, enquanto este programa rodar."
    },
    {
      "code": "for round_ in (1, 2):\n    for name, ask in [(\"rdd\", rdd), (\"dataframe\", dataframe), (\"sql\", sql)]:\n        t = time.time()\n        answer = sorted(tuple(row) for row in ask())\n        print(round_, f\"{name:9}\", answer, f\"{time.time() - t:.1f} s\")\n",
      "note": "Cada um duas vezes, alternando, para que o primeiro a rodar não pague sozinho por aquecer a máquina."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit three_ways.py
WARNING: Using incubator modules: jdk.incubator.vector
1 rdd       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 28.6 s
1 dataframe [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 18.9 s
1 sql       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 13.5 s
2 rdd       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 22.6 s
2 dataframe [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 12.5 s
2 sql       [('desktop', 316622), ('mobile', 595590), ('tablet', 47602)] 12.2 s
```

**Três respostas idênticas.** Olhe a segunda rodada, onde ninguém está pagando por mais nada.
O DataFrame levou 12,5 segundos e o SQL 12,2, o mesmo dentro do ruído de uma máquina compartilhada;
o RDD levou 22,6, quase o dobro. A primeira rodada mostra por que uma medida só não basta: ali o
DataFrame pagou 18,9 segundos por ser o primeiro a ler os arquivos com um esquema.

O DataFrame e o SQL levam o mesmo tempo porque são a mesma coisa: duas grafias de uma consulta,
compiladas por um planejador num plano só. O RDD é mais lento pelo motivo da UDF da seção 07: o
`filter` e o `map` dele são funções Python, então cada uma das 24 milhões de linhas vai do Java ao
Python e volta. E o Spark não pôde deixar de ler coluna nenhuma, porque para um RDD uma linha é uma
string e não uma linha de tabela com colunas.

**Escolhendo entre eles**:

- **SQL** quando a pergunta é uma consulta e quem a lê sabe SQL. A maioria dos jobs analíticos.
- **A API de DataFrame** quando a pergunta é montada por um programa: colunas escolhidas em tempo de
  execução, um pipeline de passos escritos como funções, testes para cada passo. O mesmo desempenho
  do SQL.
- **O RDD** quando os dados não têm formato de tabela, ou para uma operação que nenhum dos outros
  expressa. Raro, e uma escolha deliberada quando acontece.

A próxima aula abre o planejador e lê o plano em que estes programas se transformaram.
