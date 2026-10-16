---
title: SQL pela rede
version: 1
---

**O HiveServer2 é a outra metade do Hive que sobreviveu ao seu motor**: um servidor que recebe SQL de
qualquer cliente por JDBC ou ODBC, como um banco de dados faz, e devolve linhas. Ferramentas de BI,
notebooks e outros programas se conectam a ele sem saber nada de Spark ou HDFS. O Spark traz um
servidor que fala o mesmo protocolo, o *Thrift server*, e o `beeline`, o cliente de linha de comando
do Hive.

O Thrift server é uma aplicação Spark comum que fica de pé e roda qualquer SQL que chegue. Ele leva o
metastore consigo, então as tabelas da seção anterior estão lá pelo nome:

```
ana@lab:~/big$ start-thriftserver.sh
starting org.apache.spark.sql.hive.thriftserver.HiveThriftServer2, logging to /home/ana/spark/logs/spark-ana-org.apache.spark.sql.hive.thriftserver.HiveThriftServer2-1-lab.out
ana@lab:~/big$ beeline -u jdbc:hive2://localhost:10000 -n ana --silent=true -e 'SHOW TABLES IN shop; SELECT kind, count(*) AS events FROM shop.clicks WHERE day = "2025-03-14" GROUP BY kind ORDER BY kind;'
WARNING: Using incubator modules: jdk.incubator.vector
+------------+------------+--------------+
| namespace  | tableName  | isTemporary  |
+------------+------------+--------------+
| shop       | books      | false        |
| shop       | clicks     | false        |
+------------+------------+--------------+
+-----------+---------+
|   kind    | events  |
+-----------+---------+
| cart      | 5203    |
| purchase  | 2588    |
| search    | 5370    |
| view      | 52592   |
+-----------+---------+
```

**As mesmas tabelas, consultadas de outro processo por JDBC**, e a consulta rodou no cluster
standalone como um job da aplicação do Thrift server. 52.592 visualizações em 14 de março, que são os
65.753 eventos daquele dia da aula 6 separados por tipo.

É assim que um cluster vira um banco de dados para pessoas que nunca vão escrever um programa Spark. É
também um único driver atendendo todo usuário, então a consulta enorme de uma pessoa disputa com a de
todo mundo, que é o problema que as filas do YARN resolvem para aplicações e um motivo para existirem
warehouses gerenciados. Pare o servidor ao terminar, já que ele segura cores:

```sh
stop-thriftserver.sh
```
