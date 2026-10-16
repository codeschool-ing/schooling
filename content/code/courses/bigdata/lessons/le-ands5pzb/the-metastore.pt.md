---
title: O Hive e o seu metastore
version: 1
---

**O Hive foi a resposta do Facebook para "temos analistas que sabem SQL e um cluster que só roda
Java"**: ele transformava uma consulta SQL numa cadeia de jobs MapReduce, a limitação da aula 4
transformada em produto. O motor foi substituído desde então, primeiro pelo Tez e pelo LLAP dentro do
próprio Hive, depois, para a maioria, pelo Spark, pelo Trino e pelos warehouses na nuvem. **O que todos
eles mantiveram é o metastore do Hive**: um banco de dados de nomes de tabela, cada um com o seu local,
formato, esquema, partições e estatísticas. A aula 5 o prometeu, e a aula 6 disse que as melhores
estimativas do planejador precisam dele.

O Spark traz o metastore do Hive dentro de si. Sem um serviço de metastore configurado, uma sessão com
suporte ao Hive inicia um no driver, num banco Derby embutido no diretório de trabalho. Salve como
`~/big/metastore.py`:

```schooling-example
{
  "language": "python",
  "file": "metastore.py",
  "parts": [
    {
      "code": "\"\"\"Tables in Hive's metastore: the silver clicks and books, registered once and found by name.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\n\n"
    },
    {
      "code": "spark = SparkSession.builder.appName(\"metastore\").enableHiveSupport().getOrCreate()\n\n",
      "note": "**O `enableHiveSupport()` dá à sessão um metastore.** Sem um serviço de metastore configurado, o Spark inicia um dentro do driver, num banco Derby embutido no diretório `metastore_db`, e guarda as tabelas gerenciadas em `spark-warehouse`."
    },
    {
      "code": "spark.sql(\"CREATE DATABASE IF NOT EXISTS shop\")\nfor name in (\"clicks\", \"books\"):\n    spark.sql(f\"\"\"CREATE TABLE IF NOT EXISTS shop.{name} USING parquet\n                  LOCATION '{os.path.abspath('data/silver/' + name)}'\"\"\")\n",
      "note": "**Tabelas externas sobre os arquivos que já existem.** Nada é copiado: o metastore registra o local, o formato e o esquema que infere, inclusive a coluna de partição `day` achada nos nomes dos diretórios."
    },
    {
      "code": "spark.sql(\"MSCK REPAIR TABLE shop.clicks\")\nprint(spark.sql(\"SHOW PARTITIONS shop.clicks\").count(), \"partitions of shop.clicks\")\n\n",
      "note": "**As partições não são registradas pelo `CREATE`**: o `MSCK REPAIR TABLE` percorre o diretório e acrescenta uma por diretório `day=` que acha."
    },
    {
      "code": "spark.sql(\"ANALYZE TABLE shop.books COMPUTE STATISTICS FOR ALL COLUMNS\")\ntable = spark.sql(\"DESCRIBE TABLE EXTENDED shop.books\").where(\"col_name = 'Statistics'\")\nprint(\"shop.books:\", table.first().data_type)\nspark.sql(\"DESCRIBE TABLE EXTENDED shop.books book_id\").show()\n",
      "note": "**Estatísticas, guardadas no metastore**: contagens de linhas e, para cada coluna dos livros, os valores distintos, os nulos e o intervalo. O planejador as lê em vez de adivinhar pelo tamanho dos arquivos."
    }
  ]
}
```

Rode-o depois de iniciar de novo o cluster standalone; os avisos sobre a versão do esquema do
metastore são o metastore se criando, e são mandados embora aqui:

```
ana@lab:~/big$ spark-submit metastore.py 2>/dev/null
365 partitions of shop.clicks
shop.books: 17800 bytes, 3000 rows
+--------------+----------+
|     info_name|info_value|
+--------------+----------+
|      col_name|   book_id|
|     data_type|       int|
|       comment|      NULL|
|           min|         1|
|           max|      3000|
|     num_nulls|         0|
|distinct_count|      2963|
|   avg_col_len|         4|
|   max_col_len|         4|
|     histogram|      NULL|
+--------------+----------+
```

**Dois nomes agora valem por dois diretórios**, com 365 partições registradas para os cliques, uma por
diretório `day=`, o sentido que a aula 3 disse que o Hive deu à palavra. As estatísticas dos livros são
as do planejador: 3.000 linhas em 17.800 bytes e, para `book_id`, um intervalo de 1 a 3000 sem nulos.
**O `distinct_count` diz 2.963, não 3.000**: o Spark conta valores distintos com HyperLogLog, um esboço
que erra alguns por cento de propósito e precisa de uma fração da memória de uma contagem exata. Um
otimizador baseado em custo, ligado com `spark.sql.cbo.enabled`, usa esses números para ordenar joins e
estimar as suas saídas em vez dos palpites da aula 6.

Depois, uma segunda aplicação, que conhece as tabelas só pelos nomes. Salve como `~/big/by_name.py`:

```schooling-example
{
  "language": "python",
  "file": "by_name.py",
  "parts": [
    {
      "code": "\"\"\"Another application, which knows the tables only by their names.\"\"\"\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"by name\").enableHiveSupport().getOrCreate()\n"
    },
    {
      "code": "spark.sql(\"\"\"SELECT b.category, count(*) AS purchases\n             FROM shop.clicks c JOIN shop.books b ON c.book_id = b.book_id\n             WHERE c.kind = 'purchase' AND c.day = '2025-03-14'\n             GROUP BY b.category ORDER BY purchases DESC LIMIT 3\"\"\").show()\n",
      "note": "**Nenhum caminho e nenhum esquema neste programa**: o metastore fornece os dois, e o filtro em `day` é podado para uma partição como na aula 6."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit by_name.py 2>/dev/null
+--------+---------+
|category|purchases|
+--------+---------+
|  poetry|      420|
| science|      314|
| cookery|      258|
+--------+---------+
```

**Nenhum caminho, nenhum formato, nenhum esquema no programa**, e a resposta veio dos arquivos de um
dia. É para isso que serve um catálogo: quem escreve consultas para de precisar saber onde estão os
dados, e quem move os dados pode fazê-lo mudando uma linha no metastore.

**O banco Derby embutido admite um processo por vez**, e é por isso que um metastore de verdade roda
como um serviço próprio, o *Hive metastore server*, sobre um banco PostgreSQL ou MySQL, com todo
cliente Spark, Trino e Hive apontado para ele por `hive.metastore.uris`. Os catálogos do Iceberg da
aula 11 e o AWS Glue falam o mesmo protocolo pelo mesmo motivo.
