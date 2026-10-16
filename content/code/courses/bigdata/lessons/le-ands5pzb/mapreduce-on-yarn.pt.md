---
title: MapReduce no YARN
version: 1
---

**O job de streaming da aula 4 rodou no executor local do MapReduce: um processo Java, cada tarefa uma
thread.** Com `mapreduce.framework.name` em `yarn`, o mesmo comando vira uma aplicação YARN. A única
mudança é a fila, citada com `-D`:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.job.queuename=nightly -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-yarn 2> kinds-yarn.log
packageJobJar: [/tmp/hadoop-unjar3357421975958680633/] [] /tmp/streamjob9869232074237175939.jar tmpDir=null

real	1m52.910s
user	0m9.873s
sys	0m0.807s
ana@lab:~/big$ hdfs dfs -cat /out/kinds-yarn/part-00000
cart	1920654
purchase	959814
search	1920318
view	19199214
```

**As mesmas quatro contagens, e levou quase o dobro do tempo**: 1 minuto e 53 segundos contra 1
minuto e 1 da aula 4. Nada deu errado. No YARN cada tarefa de map é um contêiner, e cada contêiner é um processo
Java novo iniciado, com o seu classpath montado, e parado, onde o executor local reaproveitava um
processo para tudo. E os 70% de 6 GB da fila noturna são cerca de 4,2 GB, espaço para o
ApplicationMaster e sete tarefas de 512 MB por vez, em quatro cores divididos entre todos.

Os contadores no fim de `kinds-yarn.log` dizem o que o job foi:

```
ana@lab:~/big$ grep -E 'Launched (map|reduce) tasks|Killed map tasks|local map tasks' kinds-yarn.log
		Killed map tasks=2
		Launched map tasks=10
		Launched reduce tasks=1
		Rack-local map tasks=10
```

**Dez tarefas de map, uma por bloco de 128 MB do arquivo de 1,2 GB**, como a aula 4 as contou, e um
reduce. **Mais duas tentativas foram mortas**: o MapReduce no YARN roda uma segunda cópia de uma
tarefa que fica para trás, a especulação da aula 2, ligada por padrão aqui, e para a cópia que
terminar em segundo. **E as dez contaram como rack-local, não data-local**, a localidade da aula 3 um
nível abaixo. O NodeManager chama esta máquina de `lab` e os datanodes da aula 3 se chamam
`127.0.0.1`, então o YARN não conseguiu ver que o bloco e a tarefa estavam na mesma máquina. Num
cluster de verdade, com nomes que concordam, a maioria dos maps é data-local, e um job cujos maps não
são está lendo a sua entrada pela rede.

Num cluster de verdade é para isso que serve o YARN. Os contêineres se espalham por centenas de
máquinas, o ApplicationMaster reinicia as tarefas de uma máquina que morre, e o custo de iniciar um
contêiner é pequeno perto de uma tarefa que lê um bloco por um minuto. Numa máquina só é tudo custo,
que é a mesma lição da aula 1: a maquinaria de um cluster só se paga quando o trabalho precisa de um
cluster.
