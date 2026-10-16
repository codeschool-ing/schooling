---
title: Os processos de um job rodando
version: 1
---

**Todo papel da seção anterior é um processo que dá para listar.** Inicie um job que deixa o cluster
ocupado por uns vinte segundos, com o programa da seção anterior, e olhe a máquina enquanto ele
roda: sessenta tarefas de um segundo cada.

Num terminal:

```sh
spark-submit tasks.py 60 1
```

e num segundo, aberto enquanto o primeiro roda, peça ao `ps` todo processo Java e guarde o nome da
classe do Spark que cada um roda:

```
ana@lab:~/big$ ps -eo pid=,rss=,args= | awk '/java/ {for (i = 3; i <= NF; i++) if ($i ~ /^org\.apache\.spark/) print $1, int($2/1024) " MB", $i}'
9710 239 MB org.apache.spark.deploy.master.Master
9807 219 MB org.apache.spark.deploy.worker.Worker
9898 217 MB org.apache.spark.deploy.worker.Worker
9988 220 MB org.apache.spark.deploy.worker.Worker
10094 370 MB org.apache.spark.deploy.SparkSubmit
10199 245 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
10209 241 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
10227 243 MB org.apache.spark.executor.CoarseGrainedExecutorBackend
```

**Oito processos.** O master e os três workers já estavam lá antes do job e vão continuar depois. O
`SparkSubmit` é o driver, o seu programa. Os três `CoarseGrainedExecutorBackend` são os executores
que os workers iniciaram para esta aplicação, um cada; quando o job termina, eles terminam junto.
Cada um ocupa uns 250 MB de memória antes de ter feito quase nada, que é o custo de uma máquina
virtual Java e se paga uma vez por executor, não uma vez por tarefa.

A página do master lista a aplicação e o que ela recebeu:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.activeapps[] | {id, name, cores, memoryperexecutor, state}'
{"id":"app-20261010163906-0000","name":"tasks 60x1.0","cores":3,"memoryperexecutor":768,"state":"RUNNING"}
```

**Os três núcleos, e 768 MB por executor**, o valor que o `spark-defaults.conf` definiu. Nada mandou
o master dar todos os núcleos a ela: no modo standalone uma aplicação pega todos os núcleos que
conseguir, a menos que diga o contrário, e a seção 05 trata do que isso custa a uma segunda
aplicação.

O driver tem uma página própria, na porta 4040, e ao lado dela uma interface REST que responde em
JSON. É de lá que o curso lê jobs, estágios e tarefas nas aulas 7 e 8. Primeiro o id da aplicação,
depois os seus executores:

```
ana@lab:~/big$ curl -s localhost:4040/api/v1/applications | jq -r '.[0].id'
app-20261010163906-0000
ana@lab:~/big$ curl -s localhost:4040/api/v1/applications/app-20261010163906-0000/executors | jq -c '.[] | {id, hostPort, totalCores}'
{"id":"driver","hostPort":"localhost:35571","totalCores":0}
{"id":"2","hostPort":"127.0.0.1:38055","totalCores":1}
{"id":"1","hostPort":"127.0.0.1:35331","totalCores":1}
{"id":"0","hostPort":"127.0.0.1:42703","totalCores":1}
```

Três executores com um núcleo cada, e uma quarta entrada, `driver`, com nenhum: o driver não roda
tarefas. O endereço de todo executor é `127.0.0.1`, porque todos moram nesta máquina. Num cluster de
verdade cada um apontaria para um host diferente, e a seção 10 encontra o único recurso do Spark que
percebe a diferença.
