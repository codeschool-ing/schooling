---
title: Perdendo um executor
version: 1
---

**Inicie de novo as sessenta tarefas de um segundo** e, doze segundos depois, do segundo terminal,
mate um dos executores. O `pgrep -f` acha um processo pela linha de comando, e o `head -n 1` guarda
o primeiro dos três:

```
ana@lab:~/big$ pgrep -f CoarseGrainedExecutorBackend | head -n 1
13651
ana@lab:~/big$ kill -9 13651
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {port, coresused}'
{"port":42487,"coresused":1}
{"port":40871,"coresused":1}
{"port":42343,"coresused":1}
```

Quatro segundos depois do kill, todo worker volta a reportar um núcleo em uso. O worker cujo executor
morreu avisou o master, e o master pediu a ele que iniciasse um novo para a mesma aplicação. O que o
job imprimiu no primeiro terminal:

```
ana@lab:~/big$ spark-submit tasks.py 60 1
WARNING: Using incubator modules: jdk.incubator.vector
16:42:32 ERROR TaskSchedulerImpl: Lost executor 1 on 127.0.0.1: Command exited with code 137
16:42:32 WARN TaskSetManager: Lost task 1.0 in stage 0.0 (TID 1) (127.0.0.1 executor 1): ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason: Command exited with code 137
60 tasks of 1 s: answer 1770, 24.1 s
```

**Um erro, um aviso, e a resposta certa.** O código 137 é como o Linux reporta um processo morto pelo
sinal 9 (128 + 9). O driver percebeu que o executor sumiu, marcou como perdida a tarefa que rodava
nele e mandou essa tarefa a outro executor. O job levou 24 segundos em vez de uns 22: a
tarefa perdida rodou duas vezes, e o executor novo precisou de um instante para subir.

Três coisas tornaram isso barato, e são os três passos da seção anterior:

- **Perceber**: a conexão do executor com o driver fechou quando o processo morreu, então não houve
  tempo limite a esperar. Uma máquina que perde energia não dá esse sinal, e aí o driver espera os
  heartbeats do executor pararem, o que demora mais.
- **Saber o que se perdeu**: só as tarefas que rodavam naquele executor naquele momento. As que ele
  já tinha terminado haviam mandado os resultados ao driver.
- **Refazer só isso**: uma tarefa é uma função aplicada a uma fatia de dados que ainda existe, então
  rodá-la de novo em outro lugar dá o mesmo resultado.

Essa última condição é menos óbvia do que parece, e a aula 5 dá um nome a ela, a *linhagem*: o Spark
consegue recalcular qualquer pedaço perdido porque se lembra de como cada pedaço foi feito. Uma
tarefa que gravasse num banco de dados como efeito colateral gravaria duas vezes ao rodar duas vezes,
e o Spark não teria como saber. **Tarefas são repetidas porque se supõe que sejam repetíveis**, e
mantê-las assim é a metade do acordo que cabe a quem programa.

O Spark desiste quando a mesma tarefa falha quatro vezes, `spark.task.maxFailures`, com o raciocínio
de que uma tarefa que falha em todo lugar é um bug na tarefa e não uma máquina quebrada.
