---
title: Duas ações, dois jobs
version: 1
---

**O Spark não guarda nada entre ações a menos que mandem.** A aula 5 mostrou isso com um DataFrame
contado duas vezes: cada `count` leu os arquivos de novo. É o padrão certo, porque a maioria dos
programas usa cada resultado intermediário uma vez, e a memória gasta para guardá-lo seria tirada do
trabalho. É o padrão errado para um resultado usado de novo e de novo, e esta aula é sobre separar
os dois casos.

Este programa faz duas perguntas sobre as mesmas compras, primeiro como estão e depois de um
`cache()`. Ele usa o `stages.py` da aula 7 para mostrar de onde vieram as linhas de cada job. Salve
como `~/big/twice.py`:

```schooling-example
{
  "language": "python",
  "file": "twice.py",
  "parts": [
    {
      "code": "\"\"\"Two actions on the same filtered clicks, without and with a cache.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"twice\").getOrCreate()\n\n\n"
    },
    {
      "code": "def two_actions(purchases):\n    for label, action in [(\"count\", lambda: purchases.count()),\n                          (\"per device\", lambda: purchases.groupBy(\"device\").count().collect())]:\n        start = time.time()\n        action()\n        print(f\"{label:12} {time.time() - start:5.1f} s\")\n        report(spark)\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\npurchases = clicks.where(F.col(\"kind\") == \"purchase\")\nprint(\"without a cache\")\ntwo_actions(purchases)\n\n",
      "note": "**As mesmas duas ações, cronometradas**: quantas compras, e quantas por dispositivo. As duas partem do mesmo DataFrame filtrado."
    },
    {
      "code": "purchases.cache()\nprint(\"with a cache\")\ntwo_actions(purchases)\n",
      "note": "**O `cache()` marca o DataFrame para ser guardado**, e não guarda nada ainda: a primeira ação que o calcula enche o cache de quebra."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit twice.py
WARNING: Using incubator modules: jdk.incubator.vector
without a cache
count          8.0 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     15.2
    4      1      0.0          0.0           0.0        0.0      0.1
per device     4.8 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0          0.0           0.0        0.0     11.2
    7      1      0.0          0.0           0.0        0.0      0.1
with a cache
count          7.9 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    8     15     24.0          0.0           0.0        0.0     20.0
    9     15      0.0          0.0           0.0        0.0      0.7
   11      1      0.0          0.0           0.0        0.0      0.1
per device     1.2 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
   12     15      0.0          0.0           0.0        0.0      1.9
   14      1      0.0          0.0           0.0        0.0      0.1
```

**Sem cache, as duas ações leram as 24 milhões de linhas dos arquivos Parquet**, o `24.0` na
primeira linha de cada relatório, e cada uma pagou a leitura inteira: 8,0 e 4,8 segundos.

**Com cache, a primeira ação rodou um estágio a mais, e as suas tarefas trabalharam mais**: 20,0
segundos de tarefa contra 15,2. Ela leu os arquivos, guardou as compras na memória dos executores no
caminho e depois contou o que tinha guardado. Esse é o preço de um cache: o primeiro uso paga pela
cópia. Aqui os três executores absorveram o custo e a ação levou 7,9 segundos, mais ou menos o que
levou sem o cache; num cluster mais ocupado o trabalho a mais aparece no relógio. **A segunda ação não leu
nada dos arquivos**, `0.0` milhão de linhas de entrada, porque as linhas vieram da memória, e levou
1,2 segundo.

Duas ações já bastaram para ganhar: 7,9 + 1,2 segundos contra 8,0 + 4,8. Cada ação a mais sobre as
compras em cache custaria cerca de um segundo em vez de cinco ou mais.
