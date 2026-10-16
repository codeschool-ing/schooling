---
title: Um ano de cliques, escrito por um programa que você consegue ler
version: 1
---

**Toda linha de dados deste curso é escrita por um programa curto, e quem o roda é você.** É um
programa Spark, então ele também testa o cluster que você acabou de iniciar: se terminar, o master
distribuiu núcleos, os workers iniciaram os seus processos e os dados voltaram. A aula 5 explica a
API que ele usa; por enquanto, leia-o pelo que ele escreve.

Salve-o como `~/big/generate.py`:

```schooling-example
{
  "language": "python",
  "file": "generate.py",
  "parts": [
    {
      "code": "\"\"\"Write a year of Ponto Final's website clickstream, and its book list.\n\nEvery value comes from a hash of the row number, so the same command writes\nthe same rows on every machine. Run it with spark-submit.\n\"\"\"\nimport sys\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "EVENTS = int(sys.argv[1]) if len(sys.argv) > 1 else 24_000_000\nOUT = \"data/raw\"\n\nspark = SparkSession.builder.appName(\"generate\").getOrCreate()\n\n\n",
      "note": "Quantos eventos escrever: 24 milhões, a menos que a linha de comando diga outro número. A seção 06 diz quando pedir menos."
    },
    {
      "code": "def u(seed):\n    \"\"\"A number in [0, 1) drawn from the row number and a seed.\"\"\"\n    return F.pmod(F.xxhash64(\"id\", F.lit(seed)), F.lit(1_000_000)) / 1_000_000\n\n\nSECONDS_2025 = 365 * 24 * 3600\nstart = F.lit(\"2025-01-01 00:00:00\").cast(\"timestamp\")\n\n",
      "note": "**Nenhum número aleatório.** O `xxhash64` do número da linha com uma semente dá o mesmo valor em toda máquina e toda execução, então os seus dados são os dados da Ana, linha por linha."
    },
    {
      "code": "clicks = (\n    spark.range(EVENTS)\n    .withColumn(\"ts\", F.timestamp_seconds(\n        F.unix_timestamp(start) + F.floor(F.col(\"id\") * SECONDS_2025 / EVENTS)))\n    .withColumn(\"session\", F.floor(F.col(\"id\") / 6))\n",
      "note": "O `spark.range` cria os números das linhas. Os eventos se espalham por 2025 na ordem do número, e cada seis eventos seguidos compartilham uma sessão."
    },
    {
      "code": "    .withColumn(\"visitor_id\", F.when(u(7) < 0.04, F.lit(\"v0000000\")).otherwise(\n        F.concat(F.lit(\"v\"), F.lpad(\n            (F.pmod(F.xxhash64(\"session\"), F.lit(1_999_999)) + 1).cast(\"string\"), 7, \"0\"))))\n    .withColumn(\"kind\", F.when(u(4) < 0.80, \"view\").when(u(4) < 0.88, \"search\")\n                .when(u(4) < 0.96, \"cart\").otherwise(\"purchase\"))\n",
      "note": "Uma sessão pertence a um de dois milhões de visitantes. **Quatro eventos em cem pertencem a `v0000000`**, um robô que nunca se identifica. A aula 8 trata do que um visitante desse tamanho faz com um job."
    },
    {
      "code": "    .withColumn(\"book_id\", F.when(F.col(\"kind\") == \"search\", F.lit(None))\n                .otherwise(1 + F.floor(3000 * F.pow(u(3), 3))).cast(\"int\"))\n    .withColumn(\"device\", F.when(u(5) < 0.62, \"mobile\").when(u(5) < 0.95, \"desktop\")\n                .otherwise(\"tablet\"))\n    .withColumn(\"day\", F.to_date(\"ts\"))\n    .select(F.col(\"id\").alias(\"event_id\"), \"ts\", \"visitor_id\", \"kind\", \"book_id\",\n            \"device\", \"day\")\n)\n",
      "note": "Uma busca não cita livro. Os outros eventos citam um de 3.000, e o cubo torna os números baixos muito mais prováveis: o livro 1 aparece em cerca de um evento a cada quinze, como um best-seller."
    },
    {
      "code": "(clicks.repartition(\"day\").write.mode(\"overwrite\").partitionBy(\"day\")\n       .option(\"header\", True).option(\"compression\", \"gzip\")\n       .option(\"timestampFormat\", \"yyyy-MM-dd HH:mm:ss\").csv(OUT + \"/clicks\"))\n\n",
      "note": "Um arquivo CSV compactado com gzip por dia, num diretório chamado `day=2025-01-01` e assim por diante: o formato em que os logs de um servidor web chegam. A aula 3 explica os nomes dos diretórios."
    },
    {
      "code": "CATEGORIES = [\"fiction\", \"crime\", \"fantasy\", \"history\", \"science\", \"children\",\n              \"poetry\", \"travel\", \"cookery\", \"business\"]\nbooks = (\n    spark.range(1, 3001).withColumnRenamed(\"id\", \"book_id\")\n    .withColumn(\"category\", F.element_at(F.array(*map(F.lit, CATEGORIES)),\n                (F.pmod(F.xxhash64(\"book_id\", F.lit(1)), F.lit(10)) + 1).cast(\"int\")))\n    .withColumn(\"price_cents\", (2990 + F.pmod(F.xxhash64(\"book_id\", F.lit(2)),\n                                              F.lit(120)) * 100).cast(\"int\"))\n)\nbooks.coalesce(1).write.mode(\"overwrite\").option(\"header\", True).csv(OUT + \"/books\")\nprint(f\"wrote {EVENTS:,} events and {books.count():,} books under {OUT}/\")\n",
      "note": "Os 3.000 livros da loja, com uma categoria e um preço em centavos, num CSV pequeno."
    }
  ]
}
```

Rode-o com `spark-submit`, o comando que entrega um programa Python ao cluster:

```
ana@lab:~/big$ time spark-submit generate.py
WARNING: Using incubator modules: jdk.incubator.vector
wrote 24,000,000 events and 3,000 books under data/raw/
04:21:04 WARN Dispatcher: Message RemoteProcessDisconnected(127.0.0.1:49650) dropped. Could not find OutputCommitCoordinator.

real	1m4.011s
user	0m23.271s
sys	0m1.393s
```

Pouco mais de um minuto, em três workers de um núcleo cada. O que ele escreveu:

```
ana@lab:~/big$ ls data/raw/clicks | head -3
_SUCCESS
day=2025-01-01
day=2025-01-02
ana@lab:~/big$ ls data/raw/clicks | wc -l
366
ana@lab:~/big$ du -sh data/raw/clicks data/raw/books
243M	data/raw/clicks
68K	data/raw/books
ana@lab:~/big$ zcat data/raw/clicks/*/*.gz | wc -c
1291255017
```

Um diretório por dia de 2025, 365 deles, cada um com um arquivo CSV compactado dentro; o 366º nome
é `_SUCCESS`, um arquivo vazio que o Spark escreve quando um job termina, para que um leitor
distinga uma saída completa de uma ainda sendo escrita. Os 24 milhões de eventos ocupam 243 MB
compactados, e o `zcat` conta 1.291.255.017 bytes descompactados, cerca de cinco vezes mais. As
primeiras linhas de um dia:

```
ana@lab:~/big$ zcat data/raw/clicks/day=2025-03-14/*.gz | head -5
event_id,ts,visitor_id,kind,book_id,device
4734247,2025-03-14 00:00:00,v0094455,view,1967,mobile
4734248,2025-03-14 00:00:01,v0094455,view,786,desktop
4734249,2025-03-14 00:00:03,v0094455,view,37,desktop
4734250,2025-03-14 00:00:04,v0094455,search,,desktop
```

**Cada linha é uma coisa que um visitante fez**: quando, quem, que tipo de evento, que livro, se
houver, e em que dispositivo. A linha 0 é o primeiro segundo de 2025 e a última linha é o último
segundo, então os números à esquerda também dizem quão adiantado no ano está um evento. O diretório
`books` guarda os 3.000 livros, com uma categoria e um preço em centavos.

**Os dados são sintéticos, e dizem isso.** Nenhuma pessoa está neles, e os ids de visitante não
nomeiam ninguém. O formato é o que os torna úteis: a maioria dos eventos são visualizações, poucos
são compras, um punhado de livros fica com uma fatia grande da atenção, e um "visitante" é um robô
responsável por quatro eventos em cada cem. Cada uma dessas características está ali porque uma
aula adiante precisa dela.
