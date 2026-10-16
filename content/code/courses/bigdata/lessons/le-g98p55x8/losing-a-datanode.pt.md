---
title: Perdendo um datanode, e as cópias voltando
version: 1
---

**Mate o segundo datanode**, do jeito que a aula 2 matou um worker. O script guardou o id do
processo num arquivo, o que poupa procurá-lo:

```
ana@lab:~/big$ kill -9 $(cat ~/hdfs/dn2/hadoop-ana-datanode.pid)
```

De início nada acontece, e isso é o projeto. Um datanode que perde um heartbeat pode estar só lento,
e copiar os blocos dele para outro lugar custa disco e rede ao cluster inteiro, então o namenode
espera. Com as configurações do `hdfs.sh` ele espera cerca de um minuto; com os padrões do Hadoop,
dez minutos e meio. Então declara o datanode morto, conta os blocos que perderam uma cópia e pede
aos sobreviventes que façam novas.

Pergunte ao namenode, a cada dez segundos, quantos datanodes ele conta como mortos e quantos blocos
do arquivo estão com menos de três cópias. O `fsck` também imprime, toda vez, uma linha dizendo
aonde está se conectando:

```
ana@lab:~/big$ for i in $(seq 15); do sleep 10; echo "$(date +%T) $(hdfs dfsadmin -report -dead | grep -c '^Name') dead, $(hdfs fsck /raw/clicks-2025.csv | grep 'Under-replicated')"; done
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:29 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:43 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:57 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:11 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:26 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:40 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:55 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:09 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:23 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:38 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:52 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:07 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:21 1 dead,  Under-replicated blocks:	2 (20.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:36 1 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:50 1 dead,  Under-replicated blocks:	0 (0.0 %)
```

**O namenode declarou o datanode morto uns setenta segundos depois do kill, e achou sete dos dez
blocos com uma cópia a menos.** Cerca de dois minutos depois todos tinham três cópias de novo,
feitas pelos datanodes sobreviventes copiando entre si. Ninguém fez nada, e em nenhum momento faltou bloco algum: o arquivo pôde ser lido o
tempo todo. Esse é o propósito das três cópias. A conta da aula 2 diz que algum disco está sempre
falhando; três cópias transformam isso de dado perdido em tráfego de fundo.

Duas coisas que as contagens não mostram:

- **O reparo custa ao cluster.** Cada bloco copiado são 128 MB lidos e escritos de novo por causa
  de uma máquina perdida. Um datanode de verdade guarda terabytes, e a perda dele inicia horas de
  cópia que disputam com os jobs os mesmos discos e a mesma rede. O HDFS limita a velocidade da
  re-replicação por isso.
- **Perder duas cópias de uma vez é sobrevivível; três, não.** Um bloco cujas três cópias estavam em
  três máquinas que falharam juntas se perdeu, e o `fsck` reporta o arquivo como corrompido. Os
  racks estão na regra de posicionamento exatamente por isso: o jeito mais comum de perder três
  máquinas de uma vez é perder o rack que elas dividem.

Inicie o datanode de novo e o namenode passa a ver quatro cópias de alguns blocos, e apaga as que
sobram em segundo plano:

```sh
HADOOP_CONF_DIR=~/hdfs/dn2/conf HADOOP_PID_DIR=~/hdfs/dn2 HADOOP_LOG_DIR=~/hdfs/dn2/logs \
  hdfs --daemon start datanode
```

ou simplesmente `sh hdfs.sh stop` e `sh hdfs.sh start`.
