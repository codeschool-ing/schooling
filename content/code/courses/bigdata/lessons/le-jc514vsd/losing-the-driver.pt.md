---
title: Perdendo o driver, e perdendo o master
version: 1
---

**O driver é o único processo cuja perda o job não sobrevive.** Ele guarda o plano, a lista de
tarefas terminadas e os resultados parciais, e nada mais no cluster tem cópia disso. O mesmo job e,
doze segundos depois, o driver:

```
ana@lab:~/big$ pgrep -f deploy.SparkSubmit
15144
ana@lab:~/big$ kill -9 15144
```

O que o primeiro terminal imprimiu:

```
ana@lab:~/big$ spark-submit tasks.py 60 1; echo "exit status $?"
WARNING: Using incubator modules: jdk.incubator.vector
bash: line 1: 15144 Killed                  spark-submit tasks.py 60 1
exit status 137
```

**Nenhum erro do Spark, porque o processo que o reportaria é justamente o que morreu.** O status de
saída 137 é o do sinal 9 de novo, e o trabalho feito até ali se perdeu. Os executores perceberam
que o driver sumiu e saíram. Agora pergunte ao master como a aplicação terminou:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.completedapps[] | select(.name == "tasks 60x1.0") | {name, state, duration}' | tail -n 1
{"name":"tasks 60x1.0","state":"FINISHED","duration":8515}
```

**`FINISHED`.** É a palavra do master para uma aplicação que não está mais rodando, seja qual for o
motivo. Um monitoramento que confiasse no estado do master reportaria este job como sucesso. Se um
job funcionou se responde pelo que ele gravou e pelo código de saída do driver, e nunca pela opinião
do gerenciador do cluster.

## Protegendo o driver

Há dois jeitos, e o laboratório mostra por que um deles não está aberto a você aqui.

**Rodar o driver dentro do cluster.** Por padrão o driver roda onde você digitou `spark-submit`, no
modo *client*: feche o notebook e o job morre. No modo *cluster* o gerenciador inicia o driver num
dos seus workers, e o master standalone, com `--supervise`, o reinicia se ele falhar. Reiniciar
quer dizer recomeçar do início: o trabalho se perde de qualquer jeito, mas ninguém precisa perceber
e submeter de novo. Para um programa Python, o master standalone recusa:

```
ana@lab:~/big$ spark-submit --deploy-mode cluster tasks.py 3 1
WARNING: Using incubator modules: jdk.incubator.vector
Exception in thread "main" org.apache.spark.SparkException: Cluster deploy mode is currently not supported for python applications on standalone clusters.
	at org.apache.spark.deploy.SparkSubmit.error(SparkSubmit.scala:1065)
	at org.apache.spark.deploy.SparkSubmit.prepareSubmitEnvironment(SparkSubmit.scala:300)
	at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:962)
	at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:203)
	at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:226)
	at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:95)
	at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1168)
	at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1177)
	at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
```

O YARN e o Kubernetes rodam drivers Python no modo cluster, e as aulas 12 e 13 fazem isso.

**Tornar o job barato de reiniciar.** Um job que grava a saída em etapas, cada uma confirmada quando
termina, pode recomeçar da última etapa confirmada em vez de do zero. Isso é uma propriedade de como
o job é escrito, e os formatos de tabela abertos da aula 11 existem em parte para facilitar isso.

## O master também é um ponto único

O laboratório tem um master. Mate-o, e as aplicações em andamento seguem com os executores que já
têm, porque o driver fala direto com eles. Mas nenhuma aplicação nova consegue iniciar e nenhum
executor perdido pode ser reposto até ele voltar. O master standalone pode rodar com reservas que
assumem por meio do ZooKeeper, um serviço pequeno para eleger um líder; o ResourceManager do YARN tem
o mesmo arranjo. Este laboratório não roda um, e isso não foi montado para este curso.
