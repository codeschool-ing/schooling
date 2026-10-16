---
title: Pulando row groups
version: 1
---

**O menor e o maior valor do rodapé deixam um leitor pular um row group sem lê-lo**, quando o filtro
descarta todos os valores entre os dois. A aula 6 mostrou por que isso não fez nada pela camada
silver: o arquivo de cada dia é um row group com todos os tipos e todos os livros, então nenhum
filtro sobre um deles consegue descartá-lo. A aula 6 também prometeu ordenar os dados e medir a
diferença.

Este programa grava uma cópia dos cliques com as linhas de cada dia ordenadas por livro, em row
groups de 256 KB, e roda o mesmo filtro nas duas: os eventos dos livros mais raros, ids de 2.900 para
cima. Ele usa o `lastscan.py` da aula 6 para informar o que cada leitura leu. Salve como
`~/big/skipping.py`:

```schooling-example
{
  "language": "python",
  "file": "skipping.py",
  "parts": [
    {
      "code": "\"\"\"The same filter on the clicks as they are, and on a copy sorted by book within each day.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom lastscan import scans\n\nspark = SparkSession.builder.appName(\"skipping\").getOrCreate()\n\n"
    },
    {
      "code": "(spark.read.parquet(\"data/silver/clicks\")\n .repartition(\"day\").sortWithinPartitions(\"day\", \"book_id\")\n .write.mode(\"overwrite\").option(\"parquet.block.size\", 256 * 1024)\n .partitionBy(\"day\").parquet(\"data/tmp/by-book\"))\n\n\n",
      "note": "**A cópia**: as linhas de cada dia juntadas numa tarefa e ordenadas por `book_id`, gravadas com row groups de 256 KB em vez dos 128 MB padrão, para que o arquivo de um dia, de cerca de 1 MB, tenha vários. Ordenar primeiro por `day` é o que o `partitionBy(\"day\")` precisa de qualquer jeito, e impede o Spark de acrescentar uma ordenação sua que desfaria a ordem por livro."
    },
    {
      "code": "def rare(path):\n    return spark.read.parquet(path).where(F.col(\"book_id\") >= 2900).count()\n\n\nfor path in [\"data/silver/clicks\", \"data/tmp/by-book\"]:\n    rare(path)\n    start = time.time()\n    print(f\"{path:20} {rare(path):,} events in {time.time() - start:.1f} s\")\n    scans(spark)\n",
      "note": "**Os livros raros**: ids de 2.900 para cima, que o cubo da aula 1 torna os menos vistos."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit skipping.py
WARNING: Using incubator modules: jdk.incubator.vector
data/silver/clicks   250,517 events in 5.4 s
  365 files of 388.8 MiB, 24,000,000 rows
data/tmp/by-book     250,517 events in 5.1 s
  365 files of 484.4 MiB, 1,013,862 rows
```

**Os mesmos 250.517 eventos, e a leitura repassou 1 milhão de linhas em vez de 24 milhões.** As duas
leram os 365 arquivos, porque o filtro é sobre uma coluna de dentro deles e só os rodapés podem dizer
o que eles guardam. Mas na cópia ordenada o rodapé de cada arquivo diz que a maioria dos seus row
groups guarda livros bem abaixo de 2.900, e o leitor os pulou. O rodapé do 1º de janeiro da cópia
ordenada:

```
ana@lab:~/big$ ~/pq-env/bin/python footer.py data/tmp/by-book/day=2025-01-01 book_id
65,754 rows in 15 row group(s), 9,594 bytes of footer, written by parquet-mr version 1.16.0 (build 402c3810c372d29603e181771acebfecc71bef61)
column       on disk  decompressed  codec   encodings
                KiB           KiB
event_id       279.4         514.2  SNAPPY  RLE, PLAIN, BIT_PACKED
ts             562.5         875.6  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
visitor_id     448.7         726.8  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
kind            14.4          14.9  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
book_id         24.5          26.2  SNAPPY  RLE, PLAIN, BIT_PACKED
device          17.6          17.5  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
row group  0:   4,663 rows, book_id from None to None
row group  1:   4,502 rows, book_id from 1 to 1
row group  2:   4,484 rows, book_id from 1 to 8
row group  3:   4,484 rows, book_id from 8 to 29
row group  4:   4,484 rows, book_id from 29 to 71
row group  5:   4,484 rows, book_id from 71 to 141
row group  6:   4,484 rows, book_id from 141 to 246
row group  7:   4,484 rows, book_id from 246 to 395
row group  8:   4,484 rows, book_id from 395 to 596
row group  9:   4,484 rows, book_id from 596 to 853
row group 10:   4,484 rows, book_id from 853 to 1185
row group 11:   4,484 rows, book_id from 1185 to 1573
row group 12:   4,484 rows, book_id from 1573 to 2055
row group 13:   4,484 rows, book_id from 2055 to 2598
row group 14:   2,781 rows, book_id from 2598 to 3000
```

**Quinze row groups, e só o último pode ter um livro de 2.900 para cima.** O primeiro guarda as
buscas, cujo `book_id` é vazio, e por isso o intervalo dele é `None`. O seguinte é só o livro 1,
4.502 eventos dele, e o próximo começa com mais: o cubo da aula 1 o torna de longe o livro mais
popular. Cada row group depois cobre um intervalo maior de livros, porque cada livro mais adiante é
mais raro.

**O tempo quase não caiu**, 5,1 segundos contra 5,4, porque abrir 365 arquivos e ler 365
rodapés é um custo em que a ordenação não mexe. Em dados em que cada arquivo tem muitos row groups de
uma tabela grande, a economia fica mais perto da das linhas.
