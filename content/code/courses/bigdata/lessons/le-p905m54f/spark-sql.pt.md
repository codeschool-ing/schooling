---
title: Spark SQL
version: 1
---

**O Spark fala SQL, e para a maioria das perguntas sobre tabelas o SQL é o jeito mais curto de
perguntar.** Não é um motor separado: uma consulta SQL e o código DataFrame que diz a mesma coisa
compilam para o mesmo plano, e a próxima seção mostra que custam o mesmo.

O Spark vem com um shell SQL, o `spark-sql`, que roda uma consulta com `-e` e imprime o resultado.
Um diretório Parquet pode ser consultado direto, pondo o formato antes do caminho:

```
ana@lab:~/big$ time spark-sql -e 'SELECT b.category, count(*) AS purchases FROM parquet.`data/silver/clicks` c JOIN parquet.`data/silver/books` b ON c.book_id = b.book_id WHERE c.kind = "purchase" GROUP BY b.category ORDER BY purchases DESC LIMIT 3'
WARNING: Using incubator modules: jdk.incubator.vector
22:29:26 WARN ObjectStore: Version information not found in metastore. hive.metastore.schema.verification is not enabled so recording the schema version 2.3.0
22:29:26 WARN ObjectStore: setMetaStoreSchemaVersion called but recording version is disabled: version = 2.3.0, comment = Set by MetaStore ana@127.0.1.1
Spark Web UI available at http://localhost:4040
Spark master: spark://localhost:7077, Application Id: app-20261015222916-0019
22:29:28 WARN ObjectStore: Failed to get database parquet, returning NoSuchObjectException
22:29:28 WARN ObjectStore: Failed to get database parquet, returning NoSuchObjectException
poetry	154689
science	115387
cookery	94744
Time taken: 25.506 seconds, Fetched 3 row(s)

real	0m42.590s
user	0m48.194s
sys	0m2.381s
```

**Compras por categoria, juntando os cliques aos livros**, a partir de arquivos e mais nada: nenhum
banco, nenhuma definição de tabela. O SQL é comum, e `parquet.` seguido de um caminho entre crases é
o jeito do Spark de nomear arquivos onde iria o nome de uma tabela. O Spark contou 25 segundos para a consulta e o comando inteiro levou 43; a
diferença é iniciar uma aplicação e, na primeira vez, um pequeno banco que o `spark-sql` cria em
`~/big/metastore_db` para guardar definições de tabelas. Os avisos `ObjectStore` do topo vêm desse
banco, que é o metastore do Hive, e a aula 12 trata dele.

Dentro de um programa, um DataFrame passa a ser consultável quando recebe um nome:

```python
clicks.createOrReplaceTempView("clicks")
spark.sql("SELECT device, count(*) FROM clicks GROUP BY device").show()
```

**Uma view temporária vive enquanto vive a sessão que a criou** e não é vista por mais ninguém. Para
nomes que sobrevivam a um programa, com esquema e localização registrados num lugar que todo programa
encontre, o Spark precisa de um *catálogo*. Esse é o metastore do Hive da aula 12, e os formatos de
tabela da aula 11 trazem catálogos próprios.
