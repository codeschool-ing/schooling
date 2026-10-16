---
title: Uma máquina maior, ou mais máquinas
version: 1
---

**Quando alguma coisa acaba, há dois jeitos de conseguir mais.** Escalar *verticalmente* é uma
máquina maior: mais memória, mais núcleos, discos mais rápidos. Escalar *horizontalmente* é mais
máquinas, cada uma fazendo uma parte. Não são dois preços para a mesma coisa, e a diferença decide
a maior parte deste curso.

**Escalar verticalmente é mais simples, e deve ser a primeira coisa a considerar.** Nada no seu
programa muda. O `visitors.py` numa máquina de 4 GB nunca teria encontrado a parede. Os provedores
de nuvem alugam máquinas avulsas com vários terabytes de memória, por hora. Os limites são que o
preço cresce mais rápido que o tamanho perto do topo da faixa, e que o topo existe: há uma máquina
maior que todas, e um negócio cujos dados crescem vai passar dela um dia.

**Escalar horizontalmente não tem topo**, e custa complexidade desde a primeira máquina. Os dados
precisam ser divididos, como a seção 09 dividiu, e movidos entre máquinas sempre que a divisão
precisa mudar. Uma máquina pode falhar no meio de um job, então o sistema precisa perceber e refazer
o trabalho perdido: aula 2. E todo passo que junta dados precisa mandá-los por uma rede muito mais
lenta que a memória.

Aqui está a mesma pergunta feita ao cluster que você iniciou na seção 04. Salve como
`~/big/visitors_spark.py`:

```schooling-example
{
  "language": "python",
  "file": "visitors_spark.py",
  "parts": [
    {
      "code": "\"\"\"The same question, asked of the cluster.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"visitors\").getOrCreate()\n"
    },
    {
      "code": "clicks = spark.read.option(\"header\", True).csv(\"data/raw/clicks\")\n",
      "note": "O Spark lê todos os arquivos sob o diretório, e os diretórios `day=` viram uma coluna."
    },
    {
      "code": "(clicks.where(F.col(\"book_id\").isNotNull())\n       .groupBy(\"book_id\")\n       .agg(F.countDistinct(\"visitor_id\").alias(\"visitors\"))\n       .orderBy(F.desc(\"visitors\"))\n       .show(3))\n",
      "note": "**A mesma pergunta, declarada em vez de programada**: agrupar por livro, contar visitantes distintos. Como os conjuntos são divididos e onde são contados fica a cargo do Spark."
    }
  ]
}
```

```
ana@lab:~/big$ time spark-submit visitors_spark.py
WARNING: Using incubator modules: jdk.incubator.vector
+-------+--------+
|book_id|visitors|
+-------+--------+
|      1|  936076|
|      2|  335986|
|      3|  244287|
+-------+--------+
only showing top 3 rows

real	1m13.765s
user	0m30.083s
sys	0m1.518s
```

**Os mesmos três números de novo, em 74 segundos.** Não é mais rápido que o programa Python, e vale
parar aqui, porque essa é a medida mais importante desta aula. O Spark usou três núcleos, onde o
Python usou um, e gastou a diferença em iniciar uma aplicação no cluster, dividir os dados,
movê-los entre os workers e juntá-los de volta. Com 24 milhões de linhas numa máquina só, esse custo
extra é o job inteiro.

O que o Spark comprou foi outra coisa: **nenhum passo segurou o conjunto inteiro**, e as mesmas dez
linhas rodam sem mudança em cem máquinas e cem vezes os dados, onde o programa Python nem roda. Essa
é a troca que um cluster oferece, e ela só compensa quando os dados já passaram da parede.

## Antes de recorrer a um cluster

Uma lista curta, na ordem de tentar:

- **Meça o pico**, como o `visitors.py` fez. A maioria dos programas está longe do limite da sua
  máquina.
- **Processe em fluxo ou em partes**, como o `buckets.py` fez, na máquina que você tem.
- **Use um motor de uma máquina feito para análise.** O DuckDB lê arquivos Parquet por coluna,
  despeja em disco quando falta memória e usa todos os núcleos; o Polars é outro do tipo. A aula 14 roda um deles
  contra a mesma pergunta.
- **Alugue uma máquina maior pela hora que você precisa.**
- **Aí, um cluster.** Quando os dados passaram do que uma máquina lê no tempo que você tem, ou vão
  passar logo e o programa teria de ser reescrito de qualquer jeito.
