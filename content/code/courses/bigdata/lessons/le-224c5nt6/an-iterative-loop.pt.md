---
title: Um loop iterativo
version: 1
---

**A aula 4 deixou uma promessa: um loop que faz o mesmo passo sobre os mesmos dados muitas vezes, que
o MapReduce pagava gravando no HDFS e lendo de volta a cada vez.** Este é esse loop no Spark. O
algoritmo é o PageRank, que classifica as páginas de uma web por como os links levam a elas; aqui as
páginas são livros, e um link de um livro a outro é um visitante vendo o segundo logo depois do
primeiro. Um livro para o qual muitos leitores vão fica bem classificado, e também um livro para o
qual livros bem classificados mandam leitores.

Cada iteração espalha o rank de cada livro pelos seus links e soma o que cada livro recebe. Os links
são os mesmos em toda iteração, e são a parte cara: cada visualização de cada visitante, ordenada
por tempo, pareada com a seguinte e contada. Salve como `~/big/pagerank.py`:

```schooling-example
{
  "language": "python",
  "file": "pagerank.py",
  "parts": [
    {
      "code": "\"\"\"PageRank over the books, where a link is one book viewed right after another.\"\"\"\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession, Window\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"pagerank\").getOrCreate()\nCACHE = \"cache\" in sys.argv[1:]\n\n"
    },
    {
      "code": "views = spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"view\")\nafter = Window.partitionBy(\"visitor_id\").orderBy(\"ts\", \"event_id\")\nlinks = (views.select(F.col(\"book_id\").alias(\"src\"),\n                      F.lead(\"book_id\").over(after).alias(\"dst\"))\n         .where(F.col(\"dst\").isNotNull() & (F.col(\"src\") != F.col(\"dst\")))\n         .groupBy(\"src\", \"dst\").count()\n         .withColumn(\"share\", F.col(\"count\") / F.sum(\"count\").over(Window.partitionBy(\"src\")))\n         .select(\"src\", \"dst\", \"share\"))\n",
      "note": "**Os links**: as visualizações de cada visitante em ordem de tempo, e cada uma pareada com a seguinte pelo `lead`. Um link do livro a ao livro b recebe a fração das saídas de a que foram para b."
    },
    {
      "code": "if CACHE:\n    links.cache()\n\n",
      "note": "**A única diferença entre as duas execuções.** Com `cache`, os links ficam na memória dos executores na primeira vez que uma iteração os calcula."
    },
    {
      "code": "books = [r.book_id for r in spark.read.parquet(\"data/silver/books\").select(\"book_id\").collect()]\nrank = {b: 1 / len(books) for b in books}\nstart = time.time()\nfor i in range(1, 11):\n    began = time.time()\n    current = spark.createDataFrame(list(rank.items()), \"src int, rank double\")\n    received = (links.join(current, \"src\")\n                .groupBy(\"dst\").agg(F.sum(F.col(\"rank\") * F.col(\"share\")).alias(\"r\"))\n                .collect())\n    got = {row.dst: row.r for row in received}\n    rank = {b: 0.15 / len(books) + 0.85 * got.get(b, 0.0) for b in books}\n    print(f\"iteration {i:2}: {time.time() - began:5.1f} s\")\nprint(f\"ten iterations: {time.time() - start:.1f} s\")\nprint(\"top three:\", [(b, round(r, 5)) for b, r in sorted(rank.items(), key=lambda x: -x[1])[:3]])\n",
      "note": "**Os ranks são 3.000 números, pequenos o bastante para morar no driver** como um dicionário Python. Cada iteração os manda ao cluster, que espalha o rank de cada livro pelos seus links e soma o que cada livro recebe."
    }
  ]
}
```

Rode duas vezes, sem e com o cache:

```
ana@lab:~/big$ spark-submit pagerank.py
WARNING: Using incubator modules: jdk.incubator.vector
iteration  1:  50.4 s
iteration  2:  36.0 s
iteration  3:  34.5 s
iteration  4:  34.8 s
iteration  5:  36.3 s
iteration  6:  37.2 s
iteration  7:  34.3 s
iteration  8:  33.2 s
iteration  9:  36.3 s
iteration 10:  32.9 s
ten iterations: 365.9 s
top three: [(1, 0.05579), (2, 0.01525), (3, 0.01073)]
```

```
ana@lab:~/big$ spark-submit pagerank.py cache
WARNING: Using incubator modules: jdk.incubator.vector
iteration  1:  67.7 s
iteration  2:  10.4 s
iteration  3:  11.2 s
iteration  4:  10.4 s
iteration  5:   9.2 s
iteration  6:   9.1 s
iteration  7:  10.3 s
iteration  8:   9.0 s
iteration  9:   8.3 s
iteration 10:   7.7 s
ten iterations: 153.3 s
top three: [(1, 0.05579), (2, 0.01525), (3, 0.01073)]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-iterations\" aria-label=\"Segundos gastos por cada uma de dez iterações do PageRank, em duas execuções. Sem cache toda iteração leva cerca de 35 segundos, a primeira 50. Com os links em cache, a primeira iteração leva 68 segundos enquanto enche a cópia, e cada uma das seguintes leva de 8 a 11.\"><path d=\"M70.0 40.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 230.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 202.9 L690.0 202.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 202.9 L70.0 202.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"202.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M70.0 175.7 L690.0 175.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 175.7 L70.0 175.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"175.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M70.0 148.6 L690.0 148.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 148.6 L70.0 148.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"148.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M70.0 121.4 L690.0 121.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 121.4 L70.0 121.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"121.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M70.0 94.3 L690.0 94.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 94.3 L70.0 94.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"94.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M70.0 67.1 L690.0 67.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 67.1 L70.0 67.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"67.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M70.0 40.0 L690.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 40.0 L70.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">segundos</text><path d=\"M70.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M101.0 230.0 L101.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"101.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M163.0 230.0 L163.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M225.0 230.0 L225.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"225.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M287.0 230.0 L287.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"287.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M349.0 230.0 L349.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"349.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M411.0 230.0 L411.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"411.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M473.0 230.0 L473.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M535.0 230.0 L535.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"535.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M597.0 230.0 L597.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"597.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M659.0 230.0 L659.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"659.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"380.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">iteração</text><rect x=\"79.0\" y=\"93.2\" width=\"20.0\" height=\"136.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"101.0\" y=\"46.2\" width=\"20.0\" height=\"183.8\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"141.0\" y=\"132.3\" width=\"20.0\" height=\"97.7\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"163.0\" y=\"201.8\" width=\"20.0\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"203.0\" y=\"136.4\" width=\"20.0\" height=\"93.6\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"225.0\" y=\"199.6\" width=\"20.0\" height=\"30.4\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"265.0\" y=\"135.5\" width=\"20.0\" height=\"94.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"287.0\" y=\"201.8\" width=\"20.0\" height=\"28.2\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"131.5\" width=\"20.0\" height=\"98.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"349.0\" y=\"205.0\" width=\"20.0\" height=\"25.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"389.0\" y=\"129.0\" width=\"20.0\" height=\"101.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"205.3\" width=\"20.0\" height=\"24.7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"451.0\" y=\"136.9\" width=\"20.0\" height=\"93.1\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"473.0\" y=\"202.0\" width=\"20.0\" height=\"28.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"513.0\" y=\"139.9\" width=\"20.0\" height=\"90.1\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"535.0\" y=\"205.6\" width=\"20.0\" height=\"24.4\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"575.0\" y=\"131.5\" width=\"20.0\" height=\"98.5\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"597.0\" y=\"207.5\" width=\"20.0\" height=\"22.5\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"637.0\" y=\"140.7\" width=\"20.0\" height=\"89.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"659.0\" y=\"209.1\" width=\"20.0\" height=\"20.9\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"470.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"488.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem cache</text><rect x=\"590.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">links em cache</text></svg>", "caption": "O cache custa mais na primeira iteração, e muito menos em cada uma das seguintes."}
```

**Sem cache, toda iteração calculou de novo os links a partir das 19 milhões de visualizações**:
cerca de 35 segundos cada, e seis minutos para a execução inteira. **Com cache, a primeira iteração
pagou mais de um minuto para calcular os links e encher a cópia, e cada uma das seguintes levou de
8 a 11 segundos**, o tempo do join e da soma sozinhos. A execução inteira levou dois minutos e meio.

Os ranks nunca saíram do driver por muito tempo. 3.000 números cabem num dicionário Python, e
mandá-los ao cluster a cada vez é barato; os links, milhões de linhas, são o que tem de ficar no
cluster e ser calculado uma vez. Essa divisão, estado pequeno no driver e dados grandes e fixos em
cache nos executores, é a forma da maior parte do trabalho iterativo no Spark. É também por isso que o
Spark existe: o artigo que apresentou os seus conjuntos de dados em 2012 mediu loops como este, o
PageRank entre eles, contra o Hadoop.

**O livro 1 fica em primeiro**, com mais de três vezes o rank do livro 2. Ele é o livro mais visto
por construção, o cubo da aula 1 que torna populares os ids baixos, e o PageRank o achou só pelos
links.
