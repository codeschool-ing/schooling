---
title: O broadcast join, cronometrado
version: 1
---

**A aula 6 mostrou o planejador escolhendo um broadcast para os livros; esta seção cronometra a
escolha.** Dois joins, cada um rodado dos dois jeitos com um hint: os cliques com os livros, 3.000
linhas, e os cliques com os visitantes da seção 02, 1,7 milhão de linhas. Salve como
`~/big/join_times.py`:

```schooling-example
{
  "language": "python",
  "file": "join_times.py",
  "parts": [
    {
      "code": "\"\"\"The same two joins, as a broadcast and as a sort-merge, timed.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"join times\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nbooks = spark.read.parquet(\"data/silver/books\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\n\n\n"
    },
    {
      "code": "def timed(label, make):\n    make().collect()\n    start = time.time()\n    make().collect()\n    print(f\"{label:28} {time.time() - start:5.1f} s\")\n\n\n",
      "note": "Cada join roda duas vezes e fica o segundo tempo, como na aula 6, com a consulta montada de novo a cada vez."
    },
    {
      "code": "for name, small in [(\"books\", books), (\"visitors\", visitors)]:\n    key = \"book_id\" if name == \"books\" else \"visitor_id\"\n    timed(f\"{name}, broadcast\", lambda: clicks.join(F.broadcast(small), key)\n          .groupBy(\"device\").count())\n    timed(f\"{name}, sort-merge\", lambda: clicks.join(small.hint(\"merge\"), key)\n          .groupBy(\"device\").count())\n",
      "note": "**Hints escolhem a estratégia**: o `F.broadcast(df)` pede um broadcast join, e o `df.hint(\"merge\")` um sort-merge join, seja o que for que o planejador teria escolhido."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit join_times.py
WARNING: Using incubator modules: jdk.incubator.vector
books, broadcast               4.4 s
books, sort-merge             19.8 s
visitors, broadcast            8.9 s
visitors, sort-merge          19.0 s
```

| | broadcast | sort-merge | |
|---|---|---|---|
| livros, 3.000 linhas | 4,4 s | 19,8 s | 4,5 vezes mais rápido |
| visitantes, 1,7 milhão de linhas | 8,9 s | 19,0 s | 2,1 vezes mais rápido |

**Para os livros, o broadcast ganha pelo custo inteiro de um shuffle**: o plano sort-merge move 24
milhões de linhas de cliques pelo cluster e as ordena para encontrar uma tabela de 3.000, e o
broadcast move 3.000 linhas para três executores. O planejador teria escolhido o broadcast para os
livros sozinho.

**Para os visitantes, depende da consulta.** O planejador estima um lado pelo tamanho dos seus
arquivos, reduzido às colunas que a consulta usa. Esta consulta usa só o `visitor_id`, e a estimativa
fica logo abaixo do limite de 10 MB, então o planejador teria feito broadcast dos visitantes sem que
ninguém pedisse. A consulta da seção 02 usa também o `first_day`, o que leva a estimativa acima da
linha e o plano a um sort-merge join; o `explain("cost")`, da aula 6, mostra os dois números. **O
limite é um palpite feito para um cluster de tamanho desconhecido**, e uma tabela de 14 MB em disco
foi duas vezes mais rápida em broadcast para três executores de 768 MB cada. Em executores com
gigabytes sobrando, subir o limite para 50 ou 100 MB é uma das mudanças mais baratas que existem.

O broadcast também cura, de quebra, o problema desta aula: **um broadcast join não tem
desbalanceamento**, porque não há shuffle no lado grande. Cada tarefa junta as linhas que já tem
com a tabela inteira, e os eventos do robô ficam espalhados pelas partições em que foram lidos.
Quando o lado pequeno de um join desbalanceado cabe na memória, é a primeira coisa a tentar.
