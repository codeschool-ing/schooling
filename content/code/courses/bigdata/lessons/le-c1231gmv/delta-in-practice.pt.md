---
title: Delta Lake na prática
version: 1
---

**Uma tabela Delta é gravada com `format("delta")` e alterada com SQL**, e toda mudança é um commit.
Este programa monta uma tabela de compras em três commits, um deles rodado duas vezes de propósito.
Salve como `~/big/delta_basics.py`:

```schooling-example
{
  "language": "python",
  "file": "delta_basics.py",
  "parts": [
    {
      "code": "\"\"\"A Delta table of purchases: written, appended to, corrected, and read as it was.\"\"\"\nimport os\nimport subprocess\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "spark = (SparkSession.builder.appName(\"delta basics\")\n         .config(\"spark.sql.extensions\", \"io.delta.sql.DeltaSparkSessionExtension\")\n         .config(\"spark.sql.catalog.spark_catalog\",\n                 \"org.apache.spark.sql.delta.catalog.DeltaCatalog\")\n         .getOrCreate())\nPATH = os.path.abspath(\"data/delta/purchases\")\nTABLE = f\"delta.`{PATH}`\"\npurchases = (spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n             .select(\"event_id\", \"ts\", \"visitor_id\", \"book_id\", \"day\"))\n\n\ndef count(sql_from=TABLE):\n    return spark.sql(f\"SELECT count(*) FROM {sql_from}\").first()[0]\n\n\n",
      "note": "**Duas configurações fazem o Spark falar Delta**: uma extensão que acrescenta os comandos SQL do Delta, e um catálogo que reconhece uma tabela Delta quando a vê. As duas têm de ser definidas antes de a sessão começar."
    },
    {
      "code": "purchases.where(F.col(\"day\") < \"2025-02-01\").write.format(\"delta\").mode(\"overwrite\").save(PATH)\nprint(\"version 0:\", count(), \"purchases\")\n",
      "note": "**Versão 0: janeiro, gravado como Delta.** Os arquivos de dados são Parquet comuns; o que faz disso uma tabela é o diretório `_delta_log` ao lado deles."
    },
    {
      "code": "february = purchases.where((F.col(\"day\") >= \"2025-02-01\") & (F.col(\"day\") < \"2025-03-01\"))\nfor attempt in (1, 2):\n    (february.write.format(\"delta\").mode(\"append\")\n     .option(\"txnAppId\", \"nightly-purchases\").option(\"txnVersion\", 20250228).save(PATH))\n    print(f\"version 1, attempt {attempt}:\", count(), \"purchases\")\n",
      "note": "**Versão 1: fevereiro, acrescentado**, com um id para o job e um número para esta execução dele. O Delta registra o par no log e ignora uma segunda gravação que traga o mesmo par, e é isso que deixa um job seguro de rodar duas vezes."
    },
    {
      "code": "spark.sql(f\"DELETE FROM {TABLE} WHERE visitor_id = 'v0000000'\")\nprint(\"version 2:\", count(), \"purchases\")\n\n",
      "note": "**Versão 2: as compras de um visitante apagadas**, do jeito que um pedido de esquecimento seria atendido. Num lake de Parquet puro isso significa achar e reescrever à mão cada arquivo que as guarda."
    },
    {
      "code": "print(\"as of version 1:\", count(f\"{TABLE} VERSION AS OF 1\"), \"purchases\")\n\n",
      "note": "**Viagem no tempo**: a tabela como era na versão 1, antes do delete, lida do mesmo diretório."
    },
    {
      "code": "for row in spark.sql(f\"DESCRIBE HISTORY {TABLE}\").orderBy(\"version\").collect():\n    m = row.operationMetrics\n    added = m.get(\"numFiles\") or m.get(\"numAddedFiles\")\n    print(f\"version {row.version}: {row.operation:7} {added} files added,\"\n          f\" {m.get('numRemovedFiles', '0')} removed\")\n\n",
      "note": "**O histórico que o log guarda**: uma linha por commit, o que ele fez e, das suas métricas, os arquivos que acrescentou e removeu."
    },
    {
      "code": "print(subprocess.run([\"ls\", f\"{PATH}/_delta_log\"], capture_output=True, text=True).stdout,\n      end=\"\")\n",
      "note": "**E o log em si**: um arquivo JSON por commit, numerado."
    }
  ]
}
```

Rode com os dois jars do Delta:

```
ana@lab:~/big$ spark-submit --jars $HOME/jars/delta-spark_2.13-4.3.1.jar,$HOME/jars/delta-storage-4.3.1.jar delta_basics.py
WARNING: Using incubator modules: jdk.incubator.vector
03:34:50 WARN SparkStringUtils: Truncated the string representation of a plan since it was too large. This behavior can be adjusted by setting 'spark.sql.debug.maxToStringFields'.
version 0: 80988 purchases
version 1, attempt 1: 154822 purchases
version 1, attempt 2: 154822 purchases
03:35:29 WARN DeleteCommand: Could not validate number of records due to missing statistics.
version 2: 148537 purchases
as of version 1: 154822 purchases
version 0: WRITE   3 files added, 0 removed
version 1: WRITE   3 files added, 0 removed
version 2: DELETE  3 files added, 6 removed
00000000000000000000.crc
00000000000000000000.json
00000000000000000001.crc
00000000000000000001.json
00000000000000000002.crc
00000000000000000002.json
_staged_commits
```

**A segunda tentativa de fevereiro não mudou nada.** A gravação levava um id de job e um número de
execução, o `txnAppId` e o `txnVersion`; a primeira tentativa registrou o par no log, e a segunda o
achou lá e não gravou nada. É assim que um job Delta fica seguro de repetir, e é a correção para a
primeira seção desta aula, desde que cada execução do job traga o seu próprio número, sendo a data a
que ela se refere a escolha de costume. O log em si são os arquivos JSON numerados com um checksum ao lado de cada
um; o `_staged_commits` é para tabelas cujos commits passam por um serviço de catálogo, e aqui está
vazio.

**O delete reescreveu seis arquivos em três.** Arquivos Parquet não podem ser editados, então o
`DELETE` leu cada arquivo que tinha uma linha do `v0000000`, gravou arquivos novos sem essas linhas e
fez o commit das duas listas: os seis removidos e os três acrescentados. O aviso diz que o Delta não
conseguiu conferir o número de linhas que apagou contra as estatísticas do seu log; a contagem do
próprio programa depois do delete é a checagem que importa aqui. O commit do delete:

```
ana@lab:~/big$ jq -c 'keys[0]' data/delta/purchases/_delta_log/00000000000000000002.json | sort | uniq -c
      3 "add"
      1 "commitInfo"
      6 "remove"
ana@lab:~/big$ jq -c 'select(.add) | .add | {path, size, rows: (.stats | fromjson | .numRecords)}' data/delta/purchases/_delta_log/00000000000000000002.json
{"path":"part-00000-3e3734cc-4c96-4088-ab55-3150e6b5afe2-c000.snappy.parquet","size":1168116,"rows":55171}
{"path":"part-00001-32805b50-e127-4f0a-a4af-7de42ace70b4-c000.snappy.parquet","size":1072544,"rows":50636}
{"path":"part-00002-f9e0992f-fc98-49a3-9084-ba7f3b7933d9-c000.snappy.parquet","size":908023,"rows":42730}
```

**Um commit é uma lista de ações, um objeto JSON por linha**: um `commitInfo` dizendo quem fez o quê,
seis `remove` e três `add`, cada `add` com o tamanho do arquivo e a sua contagem de linhas. Os
arquivos removidos ainda estão no disco, e é isso que deixa o `VERSION AS OF 1` ler a tabela como era
antes do delete: o log na versão 1 os cita.

O Delta tem o resto das mudanças do SQL também. O `UPDATE` reescreve os arquivos com as linhas que
muda, e o `MERGE INTO` pega um lote de linhas e, linha a linha, atualiza as que têm a chave igual e
insere as outras: o upsert, que a seção 07 faz com o Hudi.
