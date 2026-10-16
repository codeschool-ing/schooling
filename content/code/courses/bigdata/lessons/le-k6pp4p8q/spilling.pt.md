---
title: Spill, e quando ele não importa
version: 1
---

**Quando os dados de uma tarefa não cabem na memória de execução, ela escreve parte deles em disco e
segue em frente.** Isso é um *spill*, e é como o Spark sobrevive a tarefas maiores que a memória sem
falhar: uma ordenação ordena o que cabe, escreve a sequência ordenada em disco, ordena a próxima, e
mescla as sequências no fim. Os `Spilled Records` da aula 4 eram o MapReduce fazendo o mesmo.

Uma ordenação de todos os eventos é o jeito mais claro de provocar um. Salve como `~/big/spill.py`:

```schooling-example
{
  "language": "python",
  "file": "spill.py",
  "parts": [
    {
      "code": "\"\"\"Sort every event by visitor and time, with 200 shuffle partitions and with 3.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"spill\").getOrCreate()\n"
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n",
      "note": "Execução adaptativa desligada, para que o número de partições pedido seja o usado."
    },
    {
      "code": "for n in (200, 3):\n    spark.conf.set(\"spark.sql.shuffle.partitions\", n)\n    start = time.time()\n    clicks.orderBy(\"visitor_id\", \"ts\").write.mode(\"overwrite\").parquet(\"data/tmp/sorted\")\n    print(f\"{n} partitions: {time.time() - start:.0f} s\")\n    report(spark)\n",
      "note": "**A mesma ordenação duas vezes.** Com 3 partições, cada uma das três tarefas de reduce precisa ordenar um terço de 24 milhões de linhas dentro de uns 280 MB de memória."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit spill.py
WARNING: Using incubator modules: jdk.incubator.vector
200 partitions: 61 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     32.5
    3     15     24.0        592.8           0.0        0.0     35.6
    4    200      0.0          0.0         592.8        0.0     90.8
3 partitions: 41 s
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0          0.0           0.0        0.0     17.4
    6     15     24.0        593.8           0.0        0.0     24.1
    7      3      0.0          0.0         593.8      557.2     69.2
```

**Com 200 partições, nada foi despejado. Com 3, o estágio de reduce despejou 557,2 MiB dos seus
593,8 MiB.** Cada uma das três tarefas tinha um terço de 24 milhões de linhas para ordenar e uns
280 MiB para isso, então a maior parte do que leu foi ao disco e voltou.

**E mesmo assim a execução com 3 partições terminou primeiro.** 41 segundos contra 61, e o estágio de reduce dela
somou menos segundos de tarefa que o de 200 tarefas, 69,2 contra 90,8. Nesta máquina, o
spill foi para um disco local rápido que o sistema operacional conseguia pôr em cache, enquanto 200
tarefas pagaram cada uma o seu custo fixo e escreveram cada uma o próprio arquivo Parquet. O spill é
um custo, não uma falha, e aqui foi o custo menor.

Essa é a versão honesta do conselho de costume, que diz que spill é sempre ruim. **O spill é ruim
quando o disco é lento ou está cheio, quando se repete** (uma tarefa que despeja, mescla e despeja de
novo), **ou quando é o sintoma de uma tarefa muito maior que as outras**, assunto da aula 8. Ele é
inofensivo quando poucas tarefas despejam um pouco em discos locais rápidos. O número `spill` do
estágio é o que vigiar, e um número grande ao lado de um tempo de tarefa longo é o que consertar.

As correções, na ordem de tentar: mais partições, para cada tarefa ter menos; menos dados em cada
linha, selecionando colunas antes de uma operação larga; e mais memória por tarefa, dando mais
memória aos executores ou menos núcleos. A aula 14 põe preço na última.
