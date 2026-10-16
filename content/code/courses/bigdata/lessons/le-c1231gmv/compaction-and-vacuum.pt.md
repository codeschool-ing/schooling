---
title: Compactação e vacuum
version: 1
---

**Todo commit acrescenta arquivos, e uma tabela gravada em commits pequenos se enche de arquivos
pequenos**, o problema da aula 3 de novo com um log por cima. Dois comandos lidam com isso, e o
segundo tem um preço. Salve como `~/big/delta_maintenance.py`:

```schooling-example
{
  "language": "python",
  "file": "delta_maintenance.py",
  "parts": [
    {
      "code": "\"\"\"A Delta table written one day at a time, then compacted and vacuumed.\"\"\"\nimport os\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = (SparkSession.builder.appName(\"delta maintenance\")\n         .config(\"spark.sql.extensions\", \"io.delta.sql.DeltaSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.delta.catalog.DeltaCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/delta/daily\")\nTABLE = f\"delta.`{PATH}`\"\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n\ndef files():\n    on_disk = len([f for f in os.listdir(PATH) if f.endswith(\".parquet\")])\n    live = spark.sql(f\"DESCRIBE DETAIL {TABLE}\").first().numFiles\n    return f\"{live} files in the table, {on_disk} on disk\"\n\n\n"
    },
    {
      "code": "for d in range(1, 32):\n    (clicks.where(F.col(\"day\") == f\"2025-01-{d:02}\")\n     .write.format(\"delta\").mode(\"overwrite\" if d == 1 else \"append\").save(PATH))\nprint(\"after 31 appends:\", files())\n\n",
      "note": "**Os cliques de janeiro, acrescentados um dia por vez**, como um job diário faria: 31 commits, cada um acrescentando os arquivos que as suas tarefas gravaram."
    },
    {
      "code": "spark.sql(f\"OPTIMIZE {TABLE}\").select(\"metrics.numFilesAdded\", \"metrics.numFilesRemoved\").show()\nprint(\"after OPTIMIZE:  \", files())\n\n",
      "note": "**O `OPTIMIZE` reescreve os arquivos pequenos em grandes**, num commit próprio. Quem lê a tabela vê os arquivos novos a partir desse commit; os antigos deixam de fazer parte dela mas ficam no disco, porque versões mais antigas ainda apontam para eles."
    },
    {
      "code": "spark.conf.set(\"spark.databricks.delta.retentionDurationCheck.enabled\", False)\nspark.sql(f\"VACUUM {TABLE} RETAIN 0 HOURS\")\nprint(\"after VACUUM:    \", files())\n\n",
      "note": "**O `VACUUM` apaga os arquivos de que nenhuma versão atual precisa.** Ele se recusa a olhar menos de sete dias para trás a menos que uma checagem de segurança seja desligada, porque um leitor ainda rodando numa versão antiga perderia os seus arquivos no meio da consulta. Desligada aqui, para que o efeito apareça na hora."
    },
    {
      "code": "try:\n    spark.sql(f\"SELECT count(DISTINCT visitor_id) FROM {TABLE} VERSION AS OF 0\").show()\nexcept Exception as e:\n    cause = [line for line in str(e).splitlines() if \"FileNotFoundException\" in line][0]\n    print(\"version 0:\", cause.strip()[:150])\n",
      "note": "**E o preço**: a versão 0 ainda está no log, e os seus arquivos se foram. A consulta conta visitantes distintos porque um `count(*)` simples é respondido pelas contagens de linhas do log, sem abrir arquivo nenhum."
    }
  ]
}
```

Os avisos que este programa imprime são longos e não dizem nada novo, então esta execução os manda
embora:

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/delta-spark_2.13-4.3.1.jar,$HOME/jars/delta-storage-4.3.1.jar delta_maintenance.py 2>/dev/null
after 31 appends: 31 files in the table, 31 on disk
+-------------+---------------+
|numFilesAdded|numFilesRemoved|
+-------------+---------------+
|            1|             31|
+-------------+---------------+

after OPTIMIZE:   1 files in the table, 32 on disk
Deleted 31 files and directories in a total of 1 directories.
after VACUUM:     1 files in the table, 1 on disk
version 0: Caused by: java.io.FileNotFoundException: File file:/home/ana/big/data/delta/daily/part-00000-dea0fa9c-6734-480a-9d56-91c9e7b603ec-c000.snappy.parquet
```

**31 commits diários deixaram 31 arquivos**, e o log acrescenta mais um arquivo JSON por commit. O
`OPTIMIZE` os reescreveu em um, num commit próprio: dali em diante a tabela é um arquivo, e leitores
que começaram antes continuam com os 31 que receberam. **Os dois conjuntos ficaram no disco**, 32
arquivos, porque as versões anteriores do log ainda citam os antigos.

**O `VACUUM` apagou os arquivos de que nenhuma versão precisava dentro da retenção**, aqui zero horas,
e deixou um arquivo. Depois disso a versão 0, ainda listada no log, não pôde ser lida: o seu arquivo
se foi. Essa é a troca que todo formato de tabela faz. Histórico custa armazenamento enquanto é
guardado, e o `VACUUM` decide por quanto tempo. A retenção padrão é de sete dias, e a checagem que
recusou algo mais curto existe porque uma consulta longa numa versão antiga, ou um job que lê a
versão de ontem, perde os seus arquivos quando a retenção é mais curta que o job.

Mais duas coisas que o `OPTIMIZE` faz: o `ZORDER BY (visitor_id)` ordena os arquivos reescritos para
que linhas com valores próximos nas colunas citadas fiquem nos mesmos arquivos, a ordenação da aula 10
com mais de uma coluna ao mesmo tempo. E tabelas Delta podem ser configuradas para compactar
gravações pequenas na hora, o que troca uma gravação mais lenta por nunca acumular os arquivos.
