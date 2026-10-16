---
title: Instalando o Flink
version: 1
---

O Kafka Streams não precisou de nada novo: os jars dele vieram com o Kafka na lição 1. **O Flink é
um cluster próprio**, um JobManager que planeja e coordena os jobs e um ou mais TaskManagers que os
executam, e chega do mesmo jeito que o Kafka, como um arquivo compactado da Apache Software
Foundation. O Flink 2.2.1 roda no Java 21 que a máquina já tem.

Baixe o arquivo e o checksum dele para o seu diretório pessoal. É um arquivo grande, cerca de 570
MB:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz
curl -fsSLO https://archive.apache.org/dist/flink/flink-2.2.1/flink-2.2.1-bin-scala_2.12.tgz.sha512
```

Compare as duas strings, como fez com o Kafka:

```
ubuntu@stream:~$ sha512sum flink-2.2.1-bin-scala_2.12.tgz | cut -d" " -f1
9beb619520a9b9a94d71e165f51c2c2bf67d180fee2a6f88a85b05f23b513efd12897669b6b8b000a7f16c8c8835c3bdb1e7b83133ef63056dc98a2a67105f60
```

```
ubuntu@stream:~$ cut -d" " -f1 flink-2.2.1-bin-scala_2.12.tgz.sha512
9beb619520a9b9a94d71e165f51c2c2bf67d180fee2a6f88a85b05f23b513efd12897669b6b8b000a7f16c8c8835c3bdb1e7b83133ef63056dc98a2a67105f60
```

O `scala_2.12` no nome é a versão do Scala com que as partes internas do Flink foram compiladas, e,
como o `2.13` do Kafka, não importa para você.

## O conector do Kafka

O arquivo do Flink sabe ler arquivos, mas não o Kafka. **O conector é um jar à parte, com versão
própria**: `5.0.0-2.2` é a versão 5.0.0 do conector, compilada para o Flink 2.2. Um jar no
diretório `lib` do Flink é carregado por todo job, então descompacte o Flink e ponha o conector lá:

```sh
tar -xzf flink-2.2.1-bin-scala_2.12.tgz
mv flink-2.2.1 ~/flink
curl -fsSL -o ~/flink/lib/flink-sql-connector-kafka-5.0.0-2.2.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.2/flink-sql-connector-kafka-5.0.0-2.2.jar
```

O `sql` no nome indica a versão gorda do conector, com o cliente do próprio Kafka empacotado dentro,
que é a que o SQL do Flink quer.

## Duas mudanças na configuração

As configurações do Flink ficam em `~/flink/conf/config.yaml`. De fábrica elas dão ao JobManager
1,6 GB de memória e ao TaskManager 1,7 GB, o que é quase toda a máquina virtual antes de o Kafka
ocupar qualquer coisa. **Um gigabyte para cada um basta para esta lição.** E a página web que o
Flink serve na porta 8081 escuta em todos os endereços da máquina, a não ser que alguém diga outra
coisa. Diga `localhost`, como todo o resto deste curso:

```sh
cd ~/flink/conf
sed -i -e 's/size: 1600m/size: 1024m/' -e 's/size: 1728m/size: 1024m/' config.yaml
sed -i 's/^rest:$/rest:\n  bind-address: localhost/' config.yaml
```

A primeira linha muda os dois tamanhos de memória, e a segunda acrescenta uma linha sob o título
`rest:`. Confira que as duas pegaram:

```
ubuntu@stream:~$ grep -n -E "size: |bind-address: localhost" ~/flink/conf/config.yaml
60:      size: 1024m
95:      size: 1024m
173:  bind-address: localhost
182:  # bind-address: localhost
```

As linhas 60 e 95 são os dois tamanhos e a linha 173 é a nova. A última linha já estava no
arquivo, atrás de um `#`: um comentário, que o Flink ignora.

## Subindo o cluster

```
ubuntu@stream:~$ ~/flink/bin/start-cluster.sh
Starting cluster.
Starting standalonesession daemon on host stream.
Starting taskexecutor daemon on host stream.
```

São dois daemons, uma "standalone session", que é o JobManager, e um "task executor", o
TaskManager. Eles levam alguns segundos para abrir as portas:

```
ubuntu@stream:~$ ss -ltn | grep -E ":8081|:6123"
LISTEN 0      4096       127.0.0.1:6123       0.0.0.0:*          
LISTEN 0      4096       127.0.0.1:8081       0.0.0.0:*          
```

A porta 6123 é por onde o TaskManager fala com o JobManager, e a 8081 é a página web e a interface
REST que o comando `flink` usa. As duas estão em `127.0.0.1`. **Como o cluster Kafka, o Flink não
sobe sozinho** quando a máquina virtual liga; `~/flink/bin/start-cluster.sh` o traz de volta e
`~/flink/bin/stop-cluster.sh` o para.
