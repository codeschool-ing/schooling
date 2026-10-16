---
title: A tarefa lenta, e a cópia que nunca rodou
version: 1
---

**Uma tarefa que falha é fácil. Uma tarefa que só está lenta é mais difícil**, porque nada avisa o
driver de que algo está errado. Uma máquina com o disco morrendo, ou com a memória tomada pelo
processo de outra pessoa, continua rodando tarefas a uma fração da velocidade das outras. O job
espera a tarefa mais lenta, então uma máquina doente dita o ritmo de todo mundo. Essas tarefas
lentas se chamam *stragglers*.

Este programa encena uma. As doze tarefas levam um segundo cada, menos a primeira tentativa da
tarefa 5, que leva trinta. Salve como `~/big/straggler.py`:

```schooling-example
{
  "language": "python",
  "file": "straggler.py",
  "parts": [
    {
      "code": "\"\"\"Twelve tasks of one second, and one of them stuck on a slow machine.\"\"\"\nimport time\n\nfrom pyspark import TaskContext\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"straggler\").getOrCreate()\n\n\n"
    },
    {
      "code": "def work(slice_):\n    ctx = TaskContext.get()\n    slow = ctx.partitionId() == 5 and ctx.attemptNumber() == 0\n    time.sleep(30 if slow else 1)\n    return sum(slice_)\n\n\nstart = time.time()\ntotal = spark.sparkContext.parallelize(range(12), 12).glom().map(work).sum()\nprint(f\"answer {total}, {time.time() - start:.1f} s\")\n",
      "note": "**A encenação está aqui.** A primeira tentativa da tarefa 5 dorme 30 segundos, como uma tarefa numa máquina com um disco falhando. Qualquer tentativa seguinte da mesma tarefa, em qualquer executor, leva o segundo normal."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit straggler.py
WARNING: Using incubator modules: jdk.incubator.vector
answer 66, 33.1 s
```

**Uns trinta e poucos segundos para onze segundos de trabalho.** Onze tarefas terminaram nos
primeiros segundos, e dois núcleos ficaram parados o resto da execução enquanto a tarefa 5 dormia.

A **execução especulativa** é a resposta do Spark: quando a maioria das tarefas de um estágio
terminou e uma está rodando muito mais que a mediana, lança-se uma segunda cópia dela em outro lugar
e fica-se com a que terminar primeiro. Ela vem desligada por padrão, `spark.speculation`, porque uma
cópia custa um núcleo. O mesmo programa com ela ligada, e com as mensagens informativas do Spark
liberadas para que o raciocínio dele apareça:

```
ana@lab:~/big$ spark-submit --conf spark.speculation=true --conf spark.log.level=INFO straggler.py 2>&1 | grep -E 'speculat|answer'
16:44:51 INFO TaskSchedulerImpl: Starting speculative execution thread
16:45:04 INFO TaskSetManager: Marking task 5 in stage 0.0 (on 127.0.0.1) as speculatable because it ran more than 3084.0 ms(1speculatable tasks in this taskset now)
16:45:30 INFO DAGScheduler: Job 0 is finished. Cancelling potential speculative or zombie tasks for this job
answer 66, 33.0 s
```

**O Spark percebeu o straggler, marcou-o como especulável e nunca rodou a cópia.** A resposta levou
o mesmo tempo. Este é o único lugar do curso em que a máquina única muda o resultado, e não só os
números, e o motivo é uma regra deliberada: **uma cópia especulativa nunca é lançada no mesmo host
da original**, porque a causa mais comum de um straggler é a máquina, e uma cópia na mesma máquina
seria igualmente lenta. Todo executor deste laboratório está em `127.0.0.1`, então não há para onde
ir.

Num cluster de verdade a cópia roda em outra máquina, leva um segundo, e o job termina uns vinte e
cinco segundos antes. Guarde o formato deste resultado para a aula 8, onde uma tarefa é lenta por
causa dos seus dados e não da sua máquina. **A especulação não ajuda ali**: uma cópia de uma tarefa
com dados demais tem exatamente os mesmos dados para atravessar.
