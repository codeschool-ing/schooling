---
title: A história de todo job
version: 1
---

**A página do driver e a sua interface REST morrem com a aplicação.** Tudo o que esta aula mediu foi
perguntado a um driver em execução, de dentro do programa. Um job que terminou ontem à noite, ou que
falhou, não pode ser perguntado de nada desse jeito.

O `spark-defaults.conf` da aula 1 vem guardando um registro de toda aplicação desde então, em
`~/spark-events`: o `spark.eventLog.enabled` escreve cada evento de um job, cada estágio e tarefa com
as suas métricas, num arquivo. O *history server* do Spark lê esses arquivos e serve as mesmas
páginas e a mesma interface REST para aplicações que já terminaram. Ele precisa saber onde elas
estão, uma vez, e ser iniciado:

```sh
echo "spark.history.fs.logDirectory file://$HOME/spark-events" >> ~/spark/conf/spark-defaults.conf
start-history-server.sh
```

Ele responde na porta 18080, sob os mesmos caminhos `/api/v1/` de um driver:

```
ana@lab:~/big$ curl -s 'localhost:18080/api/v1/applications?limit=6' | jq -c '.[] | {id, name, duration: .attempts[0].duration}'
{"id":"app-20261016011258-0023","name":"collect all","duration":28581}
{"id":"app-20261016011048-0022","name":"spill","duration":125690}
{"id":"app-20261016011028-0021","name":"memory","duration":16282}
{"id":"app-20261016010937-0020","name":"shuffle files","duration":47188}
{"id":"app-20261016010816-0019","name":"jobs and stages","duration":77115}
{"id":"app-20261016010559-0018","name":"memory","duration":16396}
```

**As aplicações rodadas por último, da mais nova para a mais antiga, com a duração em
milissegundos.** Qualquer uma delas pode ser perguntada sobre estágios, tarefas e planos SQL,
exatamente como um driver em execução. As páginas em `http://localhost:18080` são a interface do
Spark de cada uma, com todas as abas.

**Num cluster de verdade os logs de eventos vão para armazenamento compartilhado**, HDFS ou um object
store, para que qualquer máquina os leia e um driver que morre numa máquina perdida já tenha escrito
o que fez até o momento em que morreu. Um cluster sem history server é um cluster cujos jobs que
falham não deixam nada para ler. A aula 14 lê os estágios de um job terminado a partir daqui.
