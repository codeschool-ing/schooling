---
title: HDFS na sua máquina, com quatro datanodes
version: 1
---

**O HDFS vem com o Hadoop, e o Hadoop se instala do jeito que o Spark se instalou**: uma versão da
Apache Software Foundation, conferida, descompactada e ligada por um link. No shell da máquina, a
partir do seu diretório pessoal:

```sh
curl -O https://downloads.apache.org/hadoop/common/hadoop-3.5.0/hadoop-3.5.0.tar.gz
curl -O https://downloads.apache.org/hadoop/common/hadoop-3.5.0/hadoop-3.5.0.tar.gz.sha512
sha512sum -c hadoop-3.5.0.tar.gz.sha512
tar -xzf hadoop-3.5.0.tar.gz
ln -s hadoop-3.5.0 hadoop
cat >> ~/.sparkrc <<'END'
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_HOME=~/hadoop
export PATH=$HADOOP_HOME/bin:$PATH
END
. ~/.sparkrc
cd ~/big
```

A versão tem 581 MB. Os scripts do Hadoop precisam do `JAVA_HOME` definido, enquanto os do Spark
acharam o Java no path sozinhos. Só o `bin` do Hadoop entra no path, e não o `sbin`, porque os dois
projetos têm um `start-all.sh` ali e o segundo no path ganharia calado.

```
ana@lab:~$ sha512sum -c hadoop-3.5.0.tar.gz.sha512
hadoop-3.5.0.tar.gz: OK
ana@lab:~$ hadoop version | head -n 1
Hadoop 3.5.0
```

## Um namenode e quatro datanodes

Um HDFS de verdade tem um datanode por máquina. Aqui os quatro dividem uma máquina, então cada um
precisa do próprio diretório, das próprias portas e da própria cópia da configuração. Um script
escreve tudo isso e inicia e para os cinco processos. Salve como `~/big/hdfs.sh`:

```schooling-example
{
  "language": "sh",
  "file": "hdfs.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# One namenode and four datanodes on this machine, each datanode with its\n# own directory, its own ports and its own copy of the configuration.\n#   sh hdfs.sh setup    write the configuration and format the namenode (once)\n#   sh hdfs.sh start    start the five processes\n#   sh hdfs.sh stop     stop them\nset -e\nH=$HOME/hdfs\nCONF=$HADOOP_HOME/etc/hadoop\n\n"
    },
    {
      "code": "shared() {\n  cat <<END\n  <property><name>dfs.replication</name><value>3</value></property>\n  <property><name>dfs.namenode.name.dir</name><value>file://$H/name</value></property>\n  <property><name>dfs.heartbeat.interval</name><value>3</value></property>\n  <property><name>dfs.namenode.heartbeat.recheck-interval</name><value>15000</value></property>\nEND\n}\n\n",
      "note": "As configurações que todo processo compartilha. O `dfs.replication` guarda três cópias de cada bloco. As duas de heartbeat fazem o namenode declarar morto um datanode calado depois de cerca de um minuto, em vez dos dez minutos e meio padrão, para que a seção 06 não leve um quarto de hora."
    },
    {
      "code": "datanode_conf() {\n  n=$1\n  mkdir -p $H/dn$n/conf\n  cp -r $CONF/* $H/dn$n/conf/\n  {\n    echo '<configuration>'\n    shared\n    echo \"  <property><name>dfs.datanode.data.dir</name><value>file://$H/dn$n/data</value></property>\"\n    echo \"  <property><name>dfs.datanode.address</name><value>127.0.0.1:9${n}66</value></property>\"\n    echo \"  <property><name>dfs.datanode.http.address</name><value>127.0.0.1:9${n}64</value></property>\"\n    echo \"  <property><name>dfs.datanode.ipc.address</name><value>127.0.0.1:9${n}67</value></property>\"\n    echo \"  <property><name>dfs.datanode.hostname</name><value>127.0.0.1</value></property>\"\n    echo '</configuration>'\n  } > $H/dn$n/conf/hdfs-site.xml\n}\n\n",
      "note": "O datanode `n` ganha o próprio diretório de dados e três portas com `n` dentro: 9166, 9164 e 9167 para o primeiro, 9466, 9464 e 9467 para o quarto. Dois processos não escutam na mesma porta, e é só por isso que uma máquina precisa disso. A última linha faz cada datanode se chamar `127.0.0.1`, o nome que os executores do Spark usam; a seção 08 diz o que acontece sem ela."
    },
    {
      "code": "datanode() {\n  HADOOP_CONF_DIR=$H/dn$2/conf HADOOP_PID_DIR=$H/dn$2 HADOOP_LOG_DIR=$H/dn$2/logs \\\n    hdfs --daemon $1 datanode\n}\n\n",
      "note": "Cada datanode inicia com o próprio diretório de configuração, e com o próprio lugar para o arquivo do id do processo e para os logs."
    },
    {
      "code": "case \"$1\" in\n  setup)\n    cat > $CONF/core-site.xml <<END\n<configuration>\n  <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>\n</configuration>\nEND\n    { echo '<configuration>'; shared; echo '</configuration>'; } > $CONF/hdfs-site.xml\n    for n in 1 2 3 4; do datanode_conf $n; done\n    hdfs namenode -format -nonInteractive 2>&1 | grep -o 'Storage directory .* has been successfully formatted.' ;;\n  start)\n    hdfs --daemon start namenode\n    for n in 1 2 3 4; do datanode start $n; done ;;\n  stop)\n    for n in 1 2 3 4; do datanode stop $n; done\n    hdfs --daemon stop namenode ;;\nesac\n",
      "note": "O `setup` escreve o `core-site.xml`, que diz a todo cliente onde o namenode escuta, e o `hdfs-site.xml` do próprio namenode, e então formata o namenode: um sistema de arquivos vazio, ainda sem arquivo nenhum."
    }
  ]
}
```

Quatro datanodes, e não três, para que o cluster possa perder um e ainda ter três lugares para
guardar três cópias; a seção 06 precisa disso. Cada datanode ocupa uns 200 MB de memória, e o
namenode uns 300.

```
ana@lab:~/big$ sh hdfs.sh setup
Storage directory /home/ana/hdfs/name has been successfully formatted.
```

O namenode é formatado uma vez. Formatar de novo dá um sistema de arquivos vazio com outra
identidade, e datanodes que se lembram da antiga se recusam a entrar; a lista no fim desta seção
diz como se recuperar. Agora inicie os cinco processos e pergunte ao namenode quem entrou:

```
ana@lab:~/big$ sh hdfs.sh start
WARNING: /home/ana/hdfs/dn1/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn2/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn3/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn4/logs does not exist. Creating.
ana@lab:~/big$ hdfs dfsadmin -report | grep -E '^(Live|Name)'
Live datanodes (4):
Name: 127.0.0.1:9166 (localhost)
Name: 127.0.0.1:9266 (localhost)
Name: 127.0.0.1:9366 (localhost)
Name: 127.0.0.1:9466 (localhost)
```

**Quatro datanodes vivos**, cada um nomeado pelo endereço e pela porta de dados que o script deu a
ele. A primeira inicialização cria os diretórios de log, e avisa.

O namenode tem uma página própria na porta 9870, acessível do jeito que a aula 1 acessou a do Spark.
Os comandos desta aula fazem as mesmas perguntas a ele pelo shell.

### Quando não inicia

- **`Incompatible clusterIDs` no log de um datanode**, em `~/hdfs/dn1/logs`: o namenode foi
  formatado de novo depois que os datanodes entraram pela primeira vez. `sh hdfs.sh stop`,
  `rm -rf ~/hdfs`, depois `setup` e `start` de novo. Os dados no HDFS se perdem, e neste curso
  todos podem ser postos de volta a partir de `~/big/data`.
- **`JAVA_HOME is not set and could not be found`**: o `~/.sparkrc` não foi lido neste terminal.
- **`Live datanodes (0)`** logo depois do `start`: eles levam alguns segundos para se registrar.
  Pergunte de novo.
- **`Call From lab/127.0.1.1 to localhost:9000 failed on connection exception`**: o namenode não
  está rodando. O log dele fica em `~/hadoop/logs`.
