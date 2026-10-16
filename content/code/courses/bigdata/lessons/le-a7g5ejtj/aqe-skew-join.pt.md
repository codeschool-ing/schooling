---
title: Deixando a execução adaptativa dividir
version: 1
---

**A execução adaptativa pode fazer o salting sozinha, num sort-merge join.** Depois que o lado de map
do shuffle rodou, o Spark sabe o tamanho de cada partição. Uma partição muito maior que a mediana é
cortada em pedaços, cada um lido pela sua própria tarefa, e a partição correspondente do outro lado é
lida inteira por cada uma dessas tarefas. É o salting com as cópias feitas só para a partição que
precisa delas, e sem mudar o programa.

Uma partição conta como desbalanceada quando é maior que
`spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes`, 256 MB por padrão, e também que
`spark.sql.adaptive.skewJoin.skewedPartitionFactor` vezes a mediana, cinco por padrão. **Nenhuma das
duas vale para a partição quente deste laboratório**: a seção 02 a mediu em 3.236 KiB contra uma
mediana de 760, cerca de quatro vezes a mediana e longe de 256 MB. Esses padrões são para clusters
cujas partições têm centenas de megabytes; este programa os reduz aos dados do laboratório, e diz
isso. Salve como `~/big/aqe_skew.py`:

```schooling-example
{
  "language": "python",
  "file": "aqe_skew.py",
  "parts": [
    {
      "code": "\"\"\"The skewed join once more, left to adaptive execution.\"\"\"\nimport contextlib\nimport io\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom spread import spread\n\nspark = SparkSession.builder.appName(\"aqe skew\").getOrCreate()\nspark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\n"
    },
    {
      "code": "spark.conf.set(\"spark.sql.adaptive.enabled\", True)\nspark.conf.set(\"spark.sql.adaptive.coalescePartitions.enabled\", False)\nspark.conf.set(\"spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes\", \"2MB\")\nspark.conf.set(\"spark.sql.adaptive.skewJoin.skewedPartitionFactor\", 3)\nspark.conf.set(\"spark.sql.adaptive.advisoryPartitionSizeInBytes\", \"1MB\")\n\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\nstart = time.time()\nreturning = (clicks.join(visitors, \"visitor_id\")\n             .where(F.col(\"day\") > F.col(\"first_day\"))\n             .groupBy(\"device\").count())\nprint(sorted(tuple(row) for row in returning.collect()))\nprint(f\"{time.time() - start:.1f} s\")\nspread(spark)\n",
      "note": "**Execução adaptativa ligada, com o tratamento de skew reduzido aos dados deste laboratório**: uma partição conta como desbalanceada acima de 2 MB e de três vezes a mediana, e é cortada em pedaços de cerca de 1 MB. Os padrões são 256 MB e cinco vezes, para clusters cujas partições têm centenas de megabytes. A junção de partições está desligada, para não juntar as pequenas e esconder a grande."
    },
    {
      "code": "plan = io.StringIO()\nwith contextlib.redirect_stdout(plan):\n    returning.explain()\nprint(\"\\n\".join(line.strip() for line in plan.getvalue().splitlines() if \"Join\" in line))\n",
      "note": "**O plano final, e só a linha do join**: o `explain` imprime, então a saída dele é capturada e filtrada em vez de lida inteira."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit aqe_skew.py
WARNING: Using incubator modules: jdk.incubator.vector
[('desktop', 4624211), ('mobile', 8687852), ('tablet', 699799)]
33.2 s
stage  tasks       rows read: min     median        max   KiB read: median    max   seconds: median   max
    7    203              119,806    123,864    317,199                760    994              0.17  2.97
+- *(5) SortMergeJoin(skew=true) [visitor_id#2], [visitor_id#7], Inner, (day#6 > first_day#8)
+- SortMergeJoin [visitor_id#2], [visitor_id#7], Inner, (day#6 > first_day#8)
```

**O `skew=true` no plano é a execução adaptativa dizendo que dividiu uma partição.** O estágio que
leu o shuffle teve 203 tarefas em vez de 200: a partição quente virou quatro pedaços, e a maior
tarefa leu 317.199 linhas em vez de 1.086.798. A resposta é a mesma de antes, que é a propriedade que
torna seguro deixar isso ligado. O join aparece duas vezes porque o `explain`, depois de uma
execução, imprime o plano que rodou e depois o que foi feito primeiro, e só o primeiro traz a divisão.

**A tarefa mais lenta não ficou mais rápida**, com 2,97 segundos contra 1,72. O tempo de uma tarefa
neste laboratório varia meio segundo entre execuções do mesmo programa, e com tarefas tão curtas as
linhas são a medida em que confiar.

**E o job ainda demorou mais que sem cura nenhuma**, 33,2 segundos contra 26,3. Nada neste
laboratório consegue ser mais rápido que um desbalanceamento que custa menos de dois segundos. O que esta
seção mostra é o mecanismo e como vê-lo funcionar: o `skew=true`, as tarefas a mais e a maior tarefa
descendo ao tamanho das outras. Num cluster, com os limites padrão, a mesma coisa acontece com uma
partição de gigabytes sem que ninguém peça.

**Vale conhecer os limites antes de contar com ela.** Ela funciona em sort-merge e shuffle hash
joins, não num `groupBy` desbalanceado; ali, a agregação parcial antes do shuffle já reduz uma chave
quente a uma linha por tarefa, e é por isso que o agrupamento por visitante da aula 7 nunca sofreu
com o robô. Num outer join ela só divide o lado cujas linhas são todas mantidas, porque dividir o
outro lado emitiria cada linha sem par uma vez por pedaço. E ela mede bytes de shuffle comprimidos,
então uma chave cujas linhas comprimem bem parece menor do que é.
