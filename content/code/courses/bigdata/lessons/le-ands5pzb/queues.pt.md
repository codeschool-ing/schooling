---
title: Duas filas, um cluster
version: 1
---

**A parte de uma fila é uma promessa sobre o momento em que duas cargas querem o cluster ao mesmo
tempo.** Este script inicia o job de streaming noturno, depois o job Spark dos analistas vinte segundos
mais tarde, e lê a resposta REST do agendador a cada dez segundos enquanto eles rodam. Salve como
`~/big/queues.sh`:

```schooling-example
{
  "language": "sh",
  "file": "queues.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# The nightly streaming job and the analysts' Spark job, started together,\n# with each queue's use of its share printed every ten seconds.\nhdfs dfs -rm -r -f -skipTrash /out/kinds-q > /dev/null 2>&1\n\n"
    },
    {
      "code": "hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar \\\n  -D mapreduce.job.queuename=nightly -files mapper.py,reducer.py \\\n  -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' \\\n  -input /raw/clicks-2025.csv -output /out/kinds-q > nightly.log 2>&1 &\n\n",
      "note": "**O job noturno**, a contagem por streaming da aula 4, em segundo plano."
    },
    {
      "code": "sleep 20\nHADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop spark-submit --master yarn --deploy-mode cluster \\\n  --queue analysts --driver-memory 512m --executor-memory 512m --num-executors 1 \\\n  --conf spark.driver.memoryOverhead=256m --conf spark.executor.memoryOverhead=256m \\\n  kinds_yarn.py > analysts.log 2>&1 &\n\n",
      "note": "**Vinte segundos depois, o job dos analistas**, o da seção 05, também em segundo plano."
    },
    {
      "code": "for i in 1 2 3 4 5 6 7 8 9 10 11 12; do\n  sleep 10\n  curl -s localhost:8088/ws/v1/cluster/scheduler | jq -r '[.scheduler.schedulerInfo.queues.queue[]\n    | \"\\(.queueName): \\(.usedCapacity | floor)% of its share, \\(.numApplications) running\"] | join(\"   \")'\ndone\nwait\n",
      "note": "**A visão do agendador, a cada dez segundos**: para cada fila, a parte da sua capacidade em uso e quantas aplicações ela roda."
    }
  ]
}
```

```
ana@lab:~/big$ sh queues.sh
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 95% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 59% of its share, 1 running   analysts: 0% of its share, 0 running
nightly: 59% of its share, 1 running   analysts: 41% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 41% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 23% of its share, 1 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
nightly: 0% of its share, 0 running   analysts: 83% of its share, 1 running
```

**A fila noturna encheu a sua parte e parou ali**, em 95%: tantos contêineres de 512 MB quanto cabiam
nos seus 70%, com dez tarefas de map esperando por eles. **O job dos analistas achou os seus 30% livres
quando chegou** e usou 83% deles, um driver e um executor de 768 MB cada. O `usedCapacity` é uma
porcentagem da parte de cada fila, então 100 significaria uma fila usando tudo o que lhe prometeram.
Sem as filas, as tarefas de map do job de streaming teriam pegado todos os contêineres conforme
aparecessem, e o job dos analistas teria esperado atrás delas.

**O limite tem um custo, e ele aparece quando os analistas não estão lá**: a fila noturna deixa então
30% do cluster ocioso em vez de pegá-los emprestados. Clusters de produção costumam deixar uma fila
crescer além da sua parte para dentro da capacidade ociosa, com `maximum-capacity` acima de
`capacity`, e ligam a *preempção*, para que, quando o dono da parte emprestada volta, o agendador mate
contêineres suficientes de quem pegou emprestado para devolvê-la. Uma tarefa de map morta simplesmente
roda de novo mais tarde, e é por isso que MapReduce e Spark toleram bem a preempção, e uma tarefa de
uma hora morta no minuto cinquenta e nove é por que ela tem limites.

Quando o YARN não for mais preciso, pare-o e inicie de novo o cluster standalone:

```sh
sh yarn.sh stop
start-master.sh
start-worker.sh spark://localhost:7077
```
