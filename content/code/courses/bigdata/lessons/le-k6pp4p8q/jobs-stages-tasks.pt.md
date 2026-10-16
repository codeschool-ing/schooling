---
title: Jobs, estágios e tarefas
version: 1
---

**Uma ação vira um job, um job é cortado em estágios a cada shuffle, e um estágio é um conjunto de
tarefas, uma por partição.** As aulas 2 e 6 usaram cada uma das três palavras; esta aula as mede, e
precisa de um jeito de ver os números de um estágio depois que ele rodou.

A interface REST do driver os tem, por estágio. Um módulo deste curso imprime os estágios da última
consulta, uma linha cada. Salve como `~/big/stages.py`; esta aula e as aulas 9 e 14 o usam:

```schooling-example
{
  "language": "python",
  "file": "stages.py",
  "parts": [
    {
      "code": "\"\"\"The stages of the last query: tasks, data in and out, spill and time.\"\"\"\nimport json\nimport time\nimport urllib.request\n\n\ndef get(spark, path):\n    sc = spark.sparkContext\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/{path}\"\n    return json.load(urllib.request.urlopen(url))\n\n\ndef mb(n):\n    return f\"{n / 2**20:8.1f}\"\n\n\ndef millions(n):\n    return f\"{n / 1e6:8.1f}\"\n\n\n"
    },
    {
      "code": "def report(spark):\n    time.sleep(1)\n    last = max(get(spark, \"sql?details=false\"), key=lambda q: q[\"id\"])\n    ids = []\n    for job in last[\"successJobIds\"] + last[\"failedJobIds\"]:\n        ids += get(spark, f\"jobs/{job}\")[\"stageIds\"]\n",
      "note": "**A consulta SQL mais nova, e todos os jobs que ela rodou.** Uma consulta pode rodar mais de um job, e a execução adaptativa costuma acrescentar um por shuffle."
    },
    {
      "code": "    print(\"stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task\")\n    print(\"                            MiB            MiB      MiB  seconds\")\n    for sid in sorted(set(ids)):\n        for s in get(spark, f\"stages/{sid}\"):\n            if s[\"status\"] == \"SKIPPED\" or s[\"numCompleteTasks\"] == 0:\n                continue\n            took = s[\"executorRunTime\"] / 1000\n            print(f\"{sid:5} {s['numTasks']:6} {millions(s['inputRecords'])}     \"\n                  f\"{mb(s['shuffleWriteBytes'])}      {mb(s['shuffleReadBytes'])}   \"\n                  f\"{mb(s['diskBytesSpilled'])}   {took:6.1f}\")\n",
      "note": "Uma linha por estágio que rodou: as tarefas, as linhas que leu de arquivos, os bytes que escreveu e leu de shuffles, os bytes que despejou em disco e o tempo das tarefas, somado. Um estágio que o job pôde pular, porque a saída dele já existia, fica de fora."
    }
  ]
}
```

Depois, dois agrupamentos dos cliques da camada silver, um por tipo e outro por visitante. Salve como
`~/big/jobs_stages.py`:

```schooling-example
{
  "language": "python",
  "file": "jobs_stages.py",
  "parts": [
    {
      "code": "\"\"\"Two groupings of the clicks, and the stages each one ran.\"\"\"\nfrom pyspark.sql import SparkSession\n\nfrom stages import report\n\nspark = SparkSession.builder.appName(\"jobs and stages\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\n"
    },
    {
      "code": "print(\"partitions:\", clicks.rdd.getNumPartitions())\n\n",
      "note": "Quantas partições a leitura faz: o número de tarefas do primeiro estágio."
    },
    {
      "code": "print(\"kinds:\", len(clicks.groupBy(\"kind\").count().collect()))\nreport(spark)\n",
      "note": "**Quatro tipos**: as contagens parciais deixam o shuffle minúsculo."
    },
    {
      "code": "print(\"visitors:\", len(clicks.groupBy(\"visitor_id\").count().collect()))\nreport(spark)\n",
      "note": "**1,7 milhão de visitantes**: contagens parciais não encolhem uma chave com tantos valores."
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", False)\nprint(\"visitors:\", len(clicks.groupBy(\"visitor_id\").count().collect()))\nreport(spark)\n",
      "note": "**O mesmo agrupamento com a execução adaptativa desligada**, para a seção 07."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit jobs_stages.py
WARNING: Using incubator modules: jdk.incubator.vector
partitions: 15
kinds: 4
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    2     15     24.0          0.0           0.0        0.0     18.5
    4      1      0.0          0.0           0.0        0.0      0.2
visitors: 1729141
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    5     15     24.0         34.6           0.0        0.0     20.8
    7      3      0.0          0.0          34.6        0.0      5.6
visitors: 1729141
stage  tasks  rows in (M)  shuffle write  shuffle read  spill    task
                            MiB            MiB      MiB  seconds
    8     15     24.0         34.6           0.0        0.0     14.4
    9    200      0.0          0.0          34.6        0.0      8.2
```

**Cada agrupamento rodou dois estágios, um de cada lado do seu shuffle.** O primeiro de cada um leu os
arquivos: 15 tarefas, uma por partição da entrada, 24 milhões de linhas de entrada. O segundo leu o
shuffle e fez a contagem final. O segundo estágio do agrupamento por tipo teve uma tarefa e o do
agrupamento por visitante, três, bem menos que as 200 que o planejador pediu, porque a execução
adaptativa as juntou, como a aula 6 mostrou.

**Os dois primeiros estágios fizeram a mesma leitura e levaram mais ou menos o mesmo tempo; o que
escreveram no shuffle é toda a diferença.** Quatro tipos se comprimem, pela contagem parcial, em
poucos bytes por tarefa. 1,7 milhão de visitantes não: 34,6 MiB passaram pelo shuffle, uma linha por
visitante por tarefa que o viu.

**A última coluna é a soma dos tempos das tarefas do estágio**, não o tempo que o estágio levou.
Quinze tarefas de um segundo ou pouco mais somam uns vinte segundos de tarefa, e com três rodando de
cada vez o estágio leva cerca de um terço disso no relógio.
