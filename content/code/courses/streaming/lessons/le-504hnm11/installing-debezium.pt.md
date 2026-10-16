---
title: Instalando o PostgreSQL, o Kafka Connect e o Debezium
version: 1
---

São três coisas, e só duas são novas. O **PostgreSQL** é o banco; ele vem do arquivo do Ubuntu. O
**Kafka Connect** já está na sua máquina: é um programa que vem dentro do Kafka, em `~/kafka/bin`,
cujo trabalho é rodar conectores que movem dados entre o Kafka e outros sistemas. O **conector de
PostgreSQL do Debezium** é um desses conectores, um diretório de bibliotecas Java que o Connect
carrega quando sobe.

## PostgreSQL, com um log que carrega linhas

Instale o servidor e diga a ele para gravar WAL lógico. O PostgreSQL do Ubuntu lê todo arquivo de
`conf.d` ao lado da configuração principal, então a opção vai para um arquivo próprio, onde é fácil
de achar e de remover:

```sh
sudo apt-get install -y postgresql
echo "wal_level = logical" | sudo tee /etc/postgresql/16/main/conf.d/cdc.conf
```

O arquivo do Ubuntu 24.04 tem o PostgreSQL 16, e numa máquina virtual a instalação cria um cluster
chamado `main` e o sobe na hora, sob o systemd. O `wal_level` só é lido na inicialização, então
reinicie:

```
$ sudo systemctl restart postgresql
```

**Esse comando não foi executado neste curso.** A máquina em que as transcrições foram gravadas não
tem systemd, então lá o PostgreSQL foi iniciado e reiniciado com `pg_ctlcluster 16 main restart`,
que é o que a unidade do systemd roda por baixo. Na sua máquina virtual use o `systemctl`, e o
PostgreSQL também sobe sozinho toda vez que a máquina liga — diferente do cluster Kafka, que você
sobe com o `cluster.sh`. Depois pergunte ao servidor com o que ele está rodando:

```
ubuntu@stream:~$ sudo -u postgres psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)
```

`sudo -u postgres` roda o `psql` como o usuário de sistema `postgres`, em quem o servidor confia
como administrador sem senha. É só para isso que ele é usado aqui.

## Debezium, como plugin do Connect

O Debezium publica cada conector no Maven Central como um `tar.gz` com um checksum ao lado. A versão
3.7.0.Final é a que este curso gravou:

```sh
cd ~
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz
curl -fsSLO https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.7.0.Final/debezium-connector-postgres-3.7.0.Final-plugin.tar.gz.sha512
```

Confira do jeito que a lição 1 conferiu o Kafka. O arquivo `.sha512` do Maven traz só o hash, sem
nome de arquivo e sem quebra de linha, então o segundo comando acrescenta uma:

```
ubuntu@stream:~$ sha512sum debezium-connector-postgres-3.7.0.Final-plugin.tar.gz | cut -d" " -f1
dc5334e087c7405f5b423e77373c60a89a3d7538ad38016f3959c431ad7078361ab95300a7e926c50621e7aa8375b7f4f3c5ecec4fe04ac484804d325009b6c0
ubuntu@stream:~$ cat debezium-connector-postgres-3.7.0.Final-plugin.tar.gz.sha512; echo
dc5334e087c7405f5b423e77373c60a89a3d7538ad38016f3959c431ad7078361ab95300a7e926c50621e7aa8375b7f4f3c5ecec4fe04ac484804d325009b6c0
```

Depois descompacte num diretório que vai guardar os plugins do Connect. **O Connect carrega todo
plugin que estiver sob os diretórios do `plugin.path`, cada um no seu próprio class loader**, então
dois conectores que trazem versões diferentes da mesma biblioteca não tropeçam um no outro:

```sh
mkdir -p ~/connect-plugins
tar -xzf debezium-connector-postgres-3.7.0.Final-plugin.tar.gz -C ~/connect-plugins
```

```
ubuntu@stream:~$ ls ~/connect-plugins/debezium-connector-postgres/*.jar | xargs -n1 basename
debezium-api-3.7.0.Final.jar
debezium-config-3.7.0.Final.jar
debezium-connect-plugins-3.7.0.Final.jar
debezium-connector-common-3.7.0.Final.jar
debezium-connector-postgres-3.7.0.Final.jar
debezium-openlineage-api-3.7.0.Final.jar
debezium-util-3.7.0.Final.jar
postgresql-42.7.13.jar
protobuf-java-3.25.5.jar
sketches-java-0.8.2.jar
```

O conector em si é o `debezium-connector-postgres-3.7.0.Final.jar`; o resto são bibliotecas do
próprio Debezium e o driver JDBC do PostgreSQL, que o conector usa para tudo menos o fluxo de
replicação. Nada foi iniciado ainda. A próxima seção dá ao Connect os seus dois arquivos de
configuração e o roda.
