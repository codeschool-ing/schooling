---
title: Onde um shuffle mora
version: 1
---

**Os dados de um shuffle são arquivos nos discos locais dos executores**, não no HDFS e não na
memória. Cada tarefa de map escreve um arquivo de dados com todas as suas linhas, ordenadas pela
partição de destino, e um arquivo de índice dizendo onde começa cada partição; as tarefas de reduce
leem as suas faixas do arquivo de cada tarefa de map. Numa máquina só, o driver enxerga os discos dos
três executores, então um programa consegue listá-los. Salve como `~/big/shuffle_files.py`:

```schooling-example
{
  "language": "python",
  "file": "shuffle_files.py",
  "parts": [
    {
      "code": "\"\"\"Where a shuffle's files are, while the application that wrote them is alive.\"\"\"\nimport glob\nimport os\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"shuffle files\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nclicks.groupBy(\"visitor_id\").count().collect()\n\n"
    },
    {
      "code": "files = sorted(glob.glob(\"/tmp/spark-*/executor-*/blockmgr-*/*/shuffle_*\"))\ndata = [f for f in files if f.endswith(\".data\")]\nprint(len(files), \"files,\", len(data), \"of them data\")\nfor f in data[:3]:\n    print(os.path.getsize(f), \"bytes\", f.split(\"/\")[-1])\nprint(sum(os.path.getsize(f) for f in data), \"bytes of shuffle data in all\")\n",
      "note": "**Cada executor guarda os arquivos de shuffle sob `/tmp`**, num diretório com o nome dele, até a aplicação terminar. Num cluster de verdade os de cada executor ficam na própria máquina; aqui os três estão nesta, então o driver consegue listá-los."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit shuffle_files.py
WARNING: Using incubator modules: jdk.incubator.vector
45 files, 15 of them data
2581806 bytes shuffle_0_379_0.data
2581506 bytes shuffle_0_377_0.data
2584079 bytes shuffle_0_371_0.data
36268702 bytes of shuffle data in all
```

**Quarenta e cinco arquivos para um shuffle de 15 tarefas de map: para cada tarefa, um `.data`, um
`.index` e um checksum.** Os arquivos de dados somam os 34,6 MiB que o estágio reportou, cerca de 2,5 MB para
cada um dos três primeiros listados.

Três consequências de os arquivos morarem onde moram:

- **Eles sobrevivem ao estágio, e isso é útil.** Um job posterior que precisa do mesmo shuffle lê os
  arquivos de novo em vez de rodar de novo os estágios anteriores. O `pruning.py` da aula 6 precisou
  montar cada consulta de novo para cronometrá-la exatamente por isso.
- **Eles morrem com o executor.** Quando a aula 2 matou um worker, os arquivos de shuffle que ele
  tivesse se foram, e as tarefas de map que os escreveram teriam de rodar de novo antes que o estágio
  seguinte pudesse ler. Num cluster isso é a parte de uma máquina no lado do map, recalculada pela
  linhagem.
- **Eles precisam de espaço em disco.** Um shuffle de 35 GB precisa de 35 GB livres nos discos dos
  executores, espalhados por quantos forem, e um job que fica sem espaço falha com `No space left on
  device` no meio de um estágio. O `spark.local.dir` diz para onde eles vão; o padrão, `/tmp`, muitas
  vezes é o menor disco de uma máquina.

Os arquivos são apagados quando a aplicação termina. Clusters que acrescentam e retiram executores
enquanto um job roda, assunto da aula 13, precisam que eles sobrevivam à saída de um executor, e é
para isso que serve um *shuffle service* externo.
