---
title: Níveis de armazenamento
version: 1
---

**O `cache()` é o `persist()` com o nível de armazenamento padrão, e o nível diz onde a cópia fica e
em que forma.** Os que vale conhecer:

| nível | onde | quando uma partição não cabe na memória |
|---|---|---|
| `MEMORY_AND_DISK` | memória, depois o disco local do executor | vai para o disco; o padrão para um DataFrame |
| `MEMORY_ONLY` | memória | não é guardada, e é recalculada toda vez que é preciso |
| `DISK_ONLY` | o disco local do executor | não se aplica |
| `MEMORY_AND_DISK_2` e os outros níveis `_2` | como acima, em dois executores | como acima |
| `OFF_HEAP` | memória fora do heap Java | precisa de `spark.memory.offHeap.enabled` e de um tamanho |

Para um DataFrame, a cópia não é uma lista de objetos Python. O Spark guarda as linhas em cache no
seu próprio formato colunar comprimido, então um DataFrame em cache costuma ser menor que as mesmas
linhas como objetos, e é lido coluna a coluna como um arquivo Parquet. A interface REST do driver
informa o que cada cache ocupa, em `storage/rdd`. Salve como `~/big/storage.py`:

```schooling-example
{
  "language": "python",
  "file": "storage.py",
  "parts": [
    {
      "code": "\"\"\"What a cache holds, at three storage levels and with fewer columns.\"\"\"\nimport json\nimport time\nimport urllib.request\n\nfrom pyspark import StorageLevel\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"storage\").getOrCreate()\nsc = spark.sparkContext\n\n\n"
    },
    {
      "code": "def stored(label, df, level):\n    df.persist(level)\n    start = time.time()\n    df.count()\n    took = time.time() - start\n    time.sleep(1)\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/storage/rdd\"\n    for r in json.load(urllib.request.urlopen(url)):\n        print(f\"{label:22} {r['numCachedPartitions']:3} of {r['numPartitions']:2}\"\n              f\" {r['memoryUsed'] / 2**20:8.1f} {r['diskUsed'] / 2**20:8.1f} {took:7.1f}\")\n    start = time.time()\n    df.count()\n    print(f\"{'':22} counted again in {time.time() - start:.1f} s\")\n    df.unpersist(blocking=True)\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\nprint(\"                       partitions   memory     disk   filled\")\nprint(\"                           cached      MiB      MiB  seconds\")\n",
      "note": "**A página `storage/rdd` do driver lista cada conjunto em cache**: quantas partições dele estão em cache, e os bytes que ocupam na memória e em disco, somados entre os executores."
    },
    {
      "code": "stored(\"all 7 columns\", clicks, StorageLevel.MEMORY_AND_DISK)\n",
      "note": "**O padrão para um DataFrame**: memória primeiro, e as partições que não cabem vão para os discos locais dos executores."
    },
    {
      "code": "stored(\"3 columns\", clicks.select(\"visitor_id\", \"kind\", \"day\"), StorageLevel.MEMORY_AND_DISK)\n",
      "note": "**O mesmo, para as três colunas de que um relatório precisa** em vez das sete."
    },
    {
      "code": "tripled = clicks.unionByName(clicks).unionByName(clicks)\nstored(\"3 copies, memory+disk\", tripled, StorageLevel.MEMORY_AND_DISK)\nstored(\"3 copies, memory only\", tripled, StorageLevel.MEMORY_ONLY)\n",
      "note": "**Três cópias dos cliques, 72 milhões de linhas**, mais do que a memória de armazenamento dos três executores comporta, no nível padrão e depois só em memória. Uma partição que não cabe só em memória não é guardada, e é lida de novo dos arquivos toda vez que é preciso."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit storage.py
WARNING: Using incubator modules: jdk.incubator.vector
                       partitions   memory     disk   filled
                           cached      MiB      MiB  seconds
all 7 columns           15 of 15    284.7      0.0    41.9
                       counted again in 1.1 s
3 columns               15 of 15     51.4      0.0    13.3
                       counted again in 0.7 s
3 copies, memory+disk   45 of 45    793.3     60.9    87.8
                       counted again in 1.6 s
3 copies, memory only   42 of 45    793.4      0.0    90.1
                       counted again in 8.7 s
```

**As sete colunas dos cliques ocuparam 284,7 MiB de memória**, menos que os 396 MB de arquivos
Parquet de onde vieram. Os três executores oferecem cerca de 840 MiB de armazenamento juntos, os
280,8 MiB de cada um da aula 7, então a tabela inteira coube, e contá-la de novo levou cerca de um
segundo onde lê-la tinha levado cerca de quarenta.

**Três colunas ocuparam 51,4 MiB**, um quinto do espaço, porque as colunas deixadas de fora incluem
`event_id` e `ts`, que são diferentes em quase toda linha e deixam pouco para a compressão
trabalhar.

**Três cópias dos cliques não couberam, e as duas últimas linhas são a diferença entre os dois
níveis.** Em `MEMORY_AND_DISK`, 793,3 MiB ficaram na memória e 60,9 MiB foram para os discos dos
executores: todas as partições em cache, e contar de novo levou 1,6 segundo. Em `MEMORY_ONLY`, três
das 45 partições não acharam lugar e não foram guardadas. Contar de novo precisou ler essas três dos
arquivos Parquet, e levou 8,7 segundos: um cache que não cabe custa recalcular a parte que falta,
toda vez.
