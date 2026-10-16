---
title: O que sobreviveu
version: 1
---

**As ideias do Hadoop sobreviveram melhor que os seus programas.** Cada uma delas está no que o
substituiu:

- **Os blocos, as réplicas e a localidade do HDFS** viraram a durabilidade do object storage e a
  separação entre armazenamento e processamento da nuvem. O custo dessa separação é a localidade que a
  aula 3 mediu, e os formatos colunares com poda, aulas 6 e 10, são como ele é pago de volta.
- **Os contêineres e as filas do YARN** viraram os pods e os namespaces com cotas do Kubernetes, aula
  13, com o Spark pedindo executores do mesmo jeito.
- **O modelo do MapReduce** virou os estágios do Spark: um lado de map, um shuffle por chave, um lado
  de reduce, com os resultados intermediários guardados na memória em vez de gravados no HDFS entre
  jobs.
- **O metastore do Hive** virou o catálogo de todo motor, e as suas partições os diretórios de todo
  lake. O **HiveServer2** é a forma de todo endpoint SQL sobre um lake.
- **O HBase** ainda é o HBase, para as aplicações que precisam dele, ao lado dos seus primos na nuvem
  feitos sobre o mesmo desenho do Bigtable.

O que um engenheiro de dados encontra hoje costuma ser uma mistura: um cluster YARN em servidores
próprios que roda há dez anos e um Kubernetes ou um gerenciado ao lado, um metastore que os dois
dividem, e arquivos Parquet por baixo de tudo. A aula 13 é a outra metade desse quadro.

Antes de sair, pare o que esta aula iniciou; o cluster standalone fica de pé para a próxima:

```sh
stop-hbase.sh
sh hdfs.sh stop
```
