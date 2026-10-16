---
title: Perdendo um worker
version: 1
---

**Um worker é a oferta de recursos de uma máquina, então matar um é o mais perto que o laboratório
chega de puxar o cabo de força de uma máquina.** O mesmo job e, doze segundos depois, o primeiro
processo worker:

```
ana@lab:~/big$ pgrep -f deploy.worker.Worker | head -n 1
9807
ana@lab:~/big$ kill -9 9807
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {port, state}'
{"port":42487,"state":"DEAD"}
{"port":40871,"state":"ALIVE"}
{"port":42343,"state":"ALIVE"}
```

**O master o marcou como `DEAD` em três segundos**, porque a conexão do worker fechou. Num cluster
de verdade, onde uma máquina que perde energia não fecha nada, o master espera os heartbeats
pararem: `spark.worker.timeout`, sessenta segundos por padrão. O lado do job:

```
ana@lab:~/big$ spark-submit tasks.py 60 1
WARNING: Using incubator modules: jdk.incubator.vector
16:43:06 ERROR TaskSchedulerImpl: Lost executor 2 on 127.0.0.1: worker lost: 127.0.0.1:42487 got disassociated
60 tasks of 1 s: answer 1770, 32.3 s
```

O executor daquele worker caiu junto, e a mensagem do driver diz por quê: `worker lost`. A tarefa
dele rodou de novo em outro lugar e a resposta está certa. **Mas nada substituiu o worker**, porque
não havia outra máquina para isso. O job terminou em dois núcleos e levou 32 segundos em vez
de uns 22, metade a mais: o cluster perdeu um terço da capacidade e o
job pagou por isso inteiro.

Esse é o estado normal de um cluster grande, e é por isso que a capacidade se planeja com folga. Um
cluster dimensionado para os jobs noturnos terminarem bem na hora com toda máquina saudável é um
cluster cujos jobs atrasam sempre que uma máquina não está, e em mil máquinas isso é toda noite.

Para voltar o laboratório a três workers, pare os sobreviventes e inicie os três de novo:

```sh
stop-worker.sh
start-worker.sh spark://localhost:7077
```

## O que uma máquina perdida leva junto

Aqui o worker perdido levou só uma tarefa em andamento. Outras duas coisas podem morar numa
máquina, e as duas aparecem adiante:

- **Resultados de um estágio terminado, guardados no disco daquela máquina para o próximo estágio
  ler.** Se se perdem, as tarefas que os fizeram também precisam rodar de novo. A aula 7 mostra onde
  esses *arquivos de shuffle* moram.
- **Dados que estavam em cache na memória do executor.** Perdidos junto, e recalculados pela
  linhagem da próxima vez que forem necessários. Aula 9.

**E os próprios dados.** Aqui a entrada é um arquivo no único disco que todo processo compartilha.
Num cluster de verdade a entrada mora nos discos dos workers, e uma máquina perdida levaria a sua
parte dos dados junto, a menos que o sistema de arquivos guardasse cópias em outro lugar. Esse é o
assunto inteiro da aula 3.
