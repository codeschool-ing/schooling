---
title: Um cluster de três workers, numa máquina só
version: 1
---

**Um cluster Spark é um conjunto de processos, e nada exige que eles estejam em computadores
diferentes.** Um *master* guarda a lista de workers e entrega os núcleos deles a quem pede. Cada
*worker* oferece alguns núcleos e um pouco de memória, e inicia os processos que fazem o trabalho
de fato quando um job recebe esses recursos. A aula 2 separa esses papéis; esta seção os inicia.

Num cluster de verdade, cada worker é uma máquina própria. Aqui os três dividem a sua, e essa é a
única coisa deste laboratório que não é o que finge ser. Os processos são reais e separados: um
worker que morre leva os seus dados junto, e dados passando de um worker para outro são
serializados, gravados e lidos de volta exatamente como seriam através de uma rede. O que falta é a
lentidão da rede, e a aula 7 põe números no que isso esconde.

## Três arquivos de configuração

O Spark lê as configurações de `~/spark/conf`. No shell da máquina:

```sh
cd ~/spark/conf
cat > spark-env.sh <<'END'
SPARK_LOCAL_IP=127.0.0.1
SPARK_MASTER_HOST=localhost
SPARK_WORKER_INSTANCES=3
SPARK_WORKER_CORES=1
SPARK_WORKER_MEMORY=1g
END
cat > spark-defaults.conf <<END
spark.master            spark://localhost:7077
spark.executor.memory   768m
spark.eventLog.enabled  true
spark.eventLog.dir      file://$HOME/spark-events
END
cat > log4j2.properties <<'END'
rootLogger.level = warn
rootLogger.appenderRef.stderr.ref = console
appender.console.type = Console
appender.console.name = console
appender.console.target = SYSTEM_ERR
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{HH:mm:ss} %p %c{1}: %m%n
logger.native.name = org.apache.hadoop.util.NativeCodeLoader
logger.native.level = error
END
mkdir -p ~/spark-events
cd ~/big
```

O **`spark-env.sh`** é lido pelos scripts que iniciam o master e os workers. As duas primeiras
linhas mantêm todo processo no endereço de loopback da própria máquina, então nada escuta na rede e
nenhum outro computador alcança o seu cluster. As três últimas pedem três workers de um núcleo e
1 GB cada.

O **`spark-defaults.conf`** é lido por todo programa que você submete. O `spark.master` diz onde
está o master, para você nunca precisar digitá-lo. O `spark.executor.memory` é quanto do gigabyte
de um worker o processo de cada job pode usar, e a aula 7 explica por que é menos que o total. As
duas últimas linhas guardam um registro de cada job em `~/spark-events`, que a aula 7 lê de volta.
Esse heredoc não tem aspas, então `$HOME` vira o seu diretório pessoal quando o arquivo é escrito;
um caminho neste arquivo precisa ser absoluto.

O **`log4j2.properties`** define o quanto o Spark fala enquanto roda. O padrão do próprio Spark
imprime uma linha para quase tudo o que ele faz, e isso soterra o que você veio ler. Este arquivo
mantém avisos e erros, manda-os para a saída de erro e cala um aviso sobre uma biblioteca nativa de
que o Spark não precisa.

## Iniciando

```sh
start-master.sh
start-worker.sh spark://localhost:7077
```

```
ana@lab:~/big$ start-master.sh
starting org.apache.spark.deploy.master.Master, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.master.Master-1-lab.out
ana@lab:~/big$ start-worker.sh spark://localhost:7077
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-1-lab.out
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-2-lab.out
starting org.apache.spark.deploy.worker.Worker, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.deploy.worker.Worker-3-lab.out
```

Agora há quatro processos Java rodando: um master e três workers. Cada script imprimiu onde o seu
processo grava o log, que é o primeiro lugar a olhar quando um deles não sobe.

O master responde na porta 8080 com uma página para navegador e, em `/json/`, os mesmos fatos como
dados. O `curl` busca a página, e o `jq` guarda os campos que importam:

```
ana@lab:~/big$ curl -s localhost:8080/json/ | jq -c '.workers[] | {host, port, cores, memory, state}'
{"host":"127.0.0.1","port":45749,"cores":1,"memory":1024,"state":"ALIVE"}
{"host":"127.0.0.1","port":46219,"cores":1,"memory":1024,"state":"ALIVE"}
{"host":"127.0.0.1","port":41191,"cores":1,"memory":1024,"state":"ALIVE"}
```

Três workers, cada um com um núcleo e 1024 MB, todos `ALIVE`. Toda porta depois de `127.0.0.1:` é
escolhida ao acaso quando um worker inicia, então as suas vão ser outras.

**Para ver as páginas num navegador**, o navegador precisa alcançar a porta 8080 da máquina.
Instalado no Ubuntu ou no WSL 2, `http://localhost:8080` funciona como está. Numa máquina virtual,
o cluster só escuta dentro da máquina, que é o propósito do `SPARK_LOCAL_IP`; um túnel SSH traz uma
porta até o seu computador, `ssh -L 8080:localhost:8080 voce@a-maquina`. O curso lê as mesmas
páginas como JSON com `curl` do começo ao fim, então o navegador é uma comodidade e nunca uma
exigência.

## Parando, e iniciando de novo

O cluster não inicia com a máquina. Depois de reiniciar, ou quando você quiser a memória de volta:

```sh
stop-worker.sh
stop-master.sh
```

e `start-master.sh` com `start-worker.sh spark://localhost:7077` o trazem de volta. Um job
submetido com o cluster parado falha em menos de um minuto, e a seção 06 mostra o que ele diz.
