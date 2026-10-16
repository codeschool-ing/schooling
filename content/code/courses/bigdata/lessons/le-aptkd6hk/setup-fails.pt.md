---
title: Quando a instalação falha
version: 1
---

**A maioria das instalações falha num passo pulado ou feito duas vezes**, e cada falha diz isso com
as próprias palavras. Estas são as que uma primeira execução encontra. Cada uma foi obtida na
máquina de gravação pulando ou quebrando de propósito aquele passo, então as mensagens são as que
você vai ver.

## O download veio danificado

```
ana@lab:~$ sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
spark-4.1.3-bin-hadoop3.tgz: FAILED
sha512sum: WARNING: 1 computed checksum did NOT match
```

`FAILED` quer dizer que o arquivo no seu disco não é o arquivo que a Apache Software Foundation
publicou: em geral, um download interrompido. Apague o `.tgz` e rode de novo a linha `curl -O`. Se
o segundo download falhar do mesmo jeito, o espelho pode já ter passado para uma versão mais nova.
O `downloads.apache.org` guarda só as versões atuais; toda versão antiga fica em
`https://archive.apache.org/dist/spark/spark-4.1.3/`, com os mesmos nomes de arquivo.

## O comando não é encontrado

```
ana@lab:~/big$ spark-submit generate.py
bash: line 1: spark-submit: command not found
```

O shell não sabe onde está o Spark, porque o `~/.sparkrc` não foi lido neste terminal. Um terminal
aberto antes de a linha entrar no `~/.bashrc` é a causa de costume. O `. ~/.sparkrc` resolve este,
e todo terminal novo o lê sozinho.

## O cluster não está rodando

Um job submetido com o master parado tenta três vezes, com vinte segundos de intervalo, e desiste.
A saída completa são cinquenta linhas de stack trace Java; estas são as que importam:

```
ana@lab:~/big$ spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'
WARNING: Using incubator modules: jdk.incubator.vector
04:25:15 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:25:35 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:25:55 WARN StandaloneAppClient$ClientEndpoint: Failed to connect to master localhost:7077
04:26:15 WARN StandaloneSchedulerBackend: Application ID is not initialized yet.
04:26:15 ERROR StandaloneSchedulerBackend: Application has been killed. Reason: All masters are unresponsive! Giving up.
04:26:15 WARN StandaloneAppClient$ClientEndpoint: Drop UnregisterApplication(null) because has not yet connected to master
```

`Failed to connect to master` e `All masters are unresponsive` querem dizer que nada escuta na
porta 7077. `start-master.sh` e `start-worker.sh spark://localhost:7077`, como na seção 04.

## O master está de pé e nenhum worker está

```
ana@lab:~/big$ timeout 40 spark-submit visitors_spark.py 2>&1 | grep -E 'WARN|ERROR'
WARNING: Using incubator modules: jdk.incubator.vector
04:26:49 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
04:27:04 WARN TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
```

Este nunca desiste. O master aceitou o job e não tem nada para dar a ele, então o job espera e
avisa a cada quinze segundos até você pará-lo com Ctrl-C. Ou os workers não estão rodando, ou
nenhum deles tem a memória que o job pede: um worker de 512 MB não hospeda um executor de 768 MB.
`curl -s localhost:8080/json/ | jq '.workers'` mostra o que o master tem.

## A máquina tem menos de 8 GB

Dois workers em vez de três: ponha `SPARK_WORKER_INSTANCES=2` em `~/spark/conf/spark-env.sh`, depois
pare e inicie o cluster. Tudo no curso roda, um pouco mais devagar, e onde uma aula conta tarefas
ou workers você vai contar dois. Se o próprio gerador ficar sem memória, peça menos eventos,
`spark-submit generate.py 6000000`, e espere que todo número do curso seja cerca de um quarto do
número nas transcrições.

## Qualquer outra coisa

- **Uma porta já está em uso.** Outra coisa na máquina ocupa a 8080 ou a 7077. O master então pega
  a próxima porta livre para a página e diz qual no log, o arquivo que o `start-master.sh` citou. A
  porta 7077 não tem alternativa, então pare o que a ocupa.
- **`No space left on device`.** A versão e a cópia descompactada somam 1,2 GB, os dados são
  250 MB, e aulas adiante escrevem cópias deles em outros formatos. `df -h ~` diz quanto resta;
  `rm ~/spark-4.1.3-bin-hadoop3.tgz` devolve 573 MB depois que o Spark está descompactado.
- **Um worker morre quando um job começa.** O log dele, em `~/spark/logs`, termina com o motivo, e
  numa máquina pequena o motivo costuma ser memória tomada pelo sistema operacional antes do Spark.
