---
title: O que um executor faz com a memória
version: 1
---

**Um executor é um processo Java com um heap fixo, e o Spark o divide antes de o seu job ver qualquer
parte dele.** O `spark-defaults.conf` da aula 1 deu a cada executor 768 MB, o
`spark.executor.memory`. Este programa pergunta aos executores quanto disso o Spark pode usar para o
próprio trabalho. Salve como `~/big/memory.py`:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"How much memory each executor has for Spark's own use.\"\"\"\nimport json\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"memory\").getOrCreate()\nsc = spark.sparkContext\n"
    },
    {
      "code": "spark.range(30, numPartitions=3).count()\n",
      "note": "Um job minúsculo antes, para que os três executores tenham iniciado e se registrado antes de serem consultados."
    },
    {
      "code": "url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/executors\"\nfor e in json.load(urllib.request.urlopen(url)):\n    print(e[\"id\"], f\"{e['maxMemory'] / 2**20:.1f} MiB\")\n",
      "note": "O endpoint de executores de novo, desta vez pelo `maxMemory`: os bytes que cada executor pode usar para executar tarefas e guardar dados em cache, juntos."
    },
    {
      "code": "print(\"spark.executor.memory =\", sc.getConf().get(\"spark.executor.memory\"))\n",
      "note": "A configuração com que os executores foram iniciados, do `spark-defaults.conf`."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit memory.py
WARNING: Using incubator modules: jdk.incubator.vector
driver 434.4 MiB
2 280.8 MiB
1 280.8 MiB
0 280.8 MiB
spark.executor.memory = 768m
```

**280,8 MiB de 768.** A conta é o modelo de *memória unificada* do Spark:

| | |
|---|---|
| o heap, `spark.executor.memory` | 768 MiB |
| reservado para os objetos do próprio Spark | 300 MiB |
| sobra | 468 MiB |
| a parte do Spark, `spark.memory.fraction`, 0,6 | **280,8 MiB** |
| o resto, para código do usuário e objetos que o Spark não acompanha | 187,2 MiB |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l07-memory\" aria-label=\"O heap de 768 MiB de um executor como uma barra. 300 MiB são reservados. Dos 468 que sobram, 60 por cento, 280,8 MiB, são a região unificada dividida entre execução e armazenamento; os outros 187,2 MiB são para o código do usuário. A memória de overhead fica fora do heap.\"><rect x=\"30.0\" y=\"60.0\" width=\"218.8\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"139.4\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reservado</text><text x=\"139.4\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 MiB</text><rect x=\"248.8\" y=\"60.0\" width=\"204.8\" height=\"56.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"351.1\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execução + armazenamento</text><text x=\"351.1\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">280,8 MiB</text><rect x=\"453.5\" y=\"60.0\" width=\"136.5\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521.8\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">código do usuário</text><text x=\"521.8\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">187,2 MiB</text><path d=\"M351.1 116.0 L351.1 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"254.8\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">execução</text><text x=\"447.5\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">armazenamento</text><text x=\"310.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">heap de 768 MiB</text><rect x=\"600.0\" y=\"60.0\" width=\"110.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">overhead</text><text x=\"655.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fora do heap</text></svg>", "caption": "O Spark guarda 300 MiB para si e divide 60 por cento do resto entre tarefas em execução e dados em cache.", "same": ["overhead"]}
```

**Os 280,8 MiB são divididos por dois usos**, que é o que *unificada* quer dizer. A memória de
*execução* guarda o que uma tarefa em andamento precisa: a tabela hash de uma agregação, o buffer de
uma ordenação, o lado construído de um join. A memória de *armazenamento* guarda dados em cache,
assunto da aula 9. Cada um pode tomar emprestada a metade do outro quando ela está livre, e a execução
pode expulsar dados em cache quando precisa do espaço. Com um núcleo por executor, uma tarefa por vez
tem quase tudo; com quatro núcleos, quatro tarefas dividem.

Duas partes ficam fora do heap e são fáceis de esquecer:

- **Overhead**, memória de que o processo precisa além do heap Java: pilhas de threads, buffers de
  rede, bibliotecas nativas. O Spark pede ao gerenciador do cluster pelo menos 384 MB, ou um décimo
  da memória do executor, a mais; o YARN e o Kubernetes matam um contêiner que passa do total. Aqui os
  workers standalone não impõem nada, e é por isso que workers de 1 GB do laboratório hospedam
  executores de 768 MB.
- **Python.** Os processos Python que rodam UDFs e funções de RDD ao lado de cada executor são
  processos separados, com memória própria, que os números do heap nem incluem.

A linha do driver diz 434,4 MiB, a partir do seu 1 GB padrão com a mesma regra. A seção 10 o esgota.
