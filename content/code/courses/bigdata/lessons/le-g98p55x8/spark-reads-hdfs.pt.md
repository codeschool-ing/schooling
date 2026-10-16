---
title: O Spark lendo do HDFS, e as tarefas indo até os dados
version: 1
---

**Um programa Spark lê o HDFS recebendo um endereço que começa com `hdfs://`.** Nada mais muda. O que
muda por baixo é que o Spark agora sabe onde mora cada pedaço do arquivo, e pode mandar cada tarefa
até ele. Salve como `~/big/hdfs_count.py`:

```schooling-example
{
  "language": "python",
  "file": "hdfs_count.py",
  "parts": [
    {
      "code": "\"\"\"Count the events of each kind in the year's file on HDFS, then ask the\ndriver's own REST interface where the reading tasks ran.\"\"\"\nimport collections\nimport json\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"hdfs count\").getOrCreate()\n"
    },
    {
      "code": "clicks = (spark.read.csv(\"hdfs://localhost:9000/raw/clicks-2025.csv\")\n          .toDF(\"event_id\", \"ts\", \"visitor_id\", \"kind\", \"book_id\", \"device\"))\n",
      "note": "**A única mudança em relação a um arquivo local é o endereço.** `hdfs://localhost:9000` é o namenode que o `core-site.xml` nomeou. O arquivo não tem cabeçalho, então as colunas são nomeadas aqui."
    },
    {
      "code": "print(\"partitions:\", clicks.rdd.getNumPartitions())\nclicks.groupBy(\"kind\").count().orderBy(\"kind\").show()\n\n",
      "note": "Uma partição por bloco do HDFS: o Spark perguntou ao namenode onde estão os blocos e fez uma tarefa para cada um."
    },
    {
      "code": "sc = spark.sparkContext\nbase = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/stages\"\nfor stage in json.load(urllib.request.urlopen(base)):\n    tasks = json.load(urllib.request.urlopen(\n        f\"{base}/{stage['stageId']}/{stage['attemptId']}/taskList?length=1000\"))\n    where = collections.Counter(t[\"taskLocality\"] for t in tasks)\n    print(f\"stage {stage['stageId']}: {stage['numTasks']} tasks\", dict(where))\n",
      "note": "A página do driver, a mesma que a aula 2 leu com `curl`, consultada de dentro do programa antes que ele termine: para cada estágio, quantas tarefas rodaram em cada *localidade*. A seção 08 lê a resposta."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit hdfs_count.py
WARNING: Using incubator modules: jdk.incubator.vector
partitions: 10
+--------+--------+
|    kind|   count|
+--------+--------+
|    cart| 1920654|
|purchase|  959814|
|  search| 1920318|
|    view|19199214|
+--------+--------+

stage 3: 1 tasks {'NODE_LOCAL': 1}
stage 2: 10 tasks {}
stage 1: 10 tasks {'NODE_LOCAL': 10}
stage 0: 1 tasks {'NODE_LOCAL': 1}
```

**Dez partições, uma por bloco**, e as contagens de cada tipo de evento: 24 milhões no total, quatro
em cada cinco visualizações, como o `generate.py` sorteou. As linhas do fim são o programa
perguntando ao próprio driver onde as tarefas rodaram:

- **O estágio 1 leu o arquivo: dez tarefas, todas `NODE_LOCAL`.** Cada uma rodou numa máquina que
  guardava uma cópia do seu bloco, então leu de um disco local e não pela rede.
- **O estágio 0 leu uma linha para saber quantas colunas existem**, e o estágio 3 leu o pequeno
  resultado intermediário do estágio 1. O estágio 2 não tem tarefas listadas: o Spark o planejou e
  depois viu que não precisava dele, o que a aula 6 explica.

Os níveis que o Spark usa, do melhor para o pior, são `PROCESS_LOCAL` (os dados já estão na memória
do executor, aula 9), `NODE_LOCAL` (na mesma máquina), `RACK_LOCAL` (no mesmo rack) e `ANY`. Num
cluster grande, a diferença entre `NODE_LOCAL` e `ANY` é a diferença entre ler um bloco de um disco
dentro da máquina e puxá-lo pela rede, para cada bloco.

**Este laboratório registrou primeiro cada uma dessas tarefas como `ANY`**, e a correção é a última
linha das configurações de datanode do `hdfs.sh`. Sem ela, cada datanode se registra com o nome
`localhost`, enquanto os executores do Spark são conhecidos como `127.0.0.1`: a mesma máquina, com
dois nomes. O Spark compara nomes, não achou executor chamado `localhost` e mandou toda tarefa para
`ANY`. Nada falhou e nada avisou; o job simplesmente leu tudo como se viesse de longe. **A localidade
funciona comparando nomes**, e num cluster de verdade uma divergência entre os nomes que o HDFS e o
gerenciador do cluster usam para uma máquina a desliga do mesmo jeito silencioso. A lista de tarefas
é onde conferir.

Note o que ainda falta: a localidade de dados só economiza rede onde os dados e o processamento são
as mesmas máquinas. Com um object store, assunto da próxima seção, nunca são.
