---
title: Repartition e coalesce
version: 1
---

**Um programa pode definir o número de partições ele mesmo, de dois jeitos que custam muito
diferente.** O `repartition(n)` embaralha todas as linhas em n partições novas. O `coalesce(n)` junta
as partições existentes em n sem shuffle: cada executor combina o que já tem, e nenhuma linha cruza
a rede. A aula 7 citou os dois; esta seção mede o que cada um produz. Salve como
`~/big/repartition.py`:

```schooling-example
{
  "language": "python",
  "file": "repartition.py",
  "parts": [
    {
      "code": "\"\"\"Four ways the same clicks can be cut into partitions, and what each one costs.\"\"\"\nimport contextlib\nimport io\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"repartition\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\n\n\n"
    },
    {
      "code": "def sizes(label, df):\n    rows = [r[\"count\"] for r in df.groupBy(F.spark_partition_id()).count().collect()]\n    plan = io.StringIO()\n    with contextlib.redirect_stdout(plan):\n        df.explain()\n    moved = \"shuffle\" if \"Exchange\" in plan.getvalue() else \"no shuffle\"\n    print(f\"{label:24} {df.rdd.getNumPartitions():4} {len(rows):10}\"\n          f\" {min(rows):12,} {max(rows):12,}   {moved}\")\n\n\nprint(\"                   partitions  non-empty     min rows     max rows\")\nsizes(\"as read\", clicks)\n",
      "note": "**Quantas linhas cada partição tem**: o `spark_partition_id()` é o número da partição em que a linha está, então agrupar por ele conta as linhas de cada partição não vazia."
    },
    {
      "code": "sizes(\"coalesce(4)\", clicks.coalesce(4))\n",
      "note": "**O `coalesce(4)` junta partições vizinhas sem mover uma linha entre executores**, então não custa nada e os pedaços ficam tão desiguais quanto o que foi juntado."
    },
    {
      "code": "sizes(\"repartition(4)\", clicks.repartition(4))\n",
      "note": "**O `repartition(4)` embaralha todas as linhas**, distribuindo-as em rodízio, então os quatro pedaços saem iguais."
    },
    {
      "code": "sizes('repartition(\"device\")', clicks.repartition(\"device\"))\n",
      "note": "**O `repartition(\"device\")` embaralha pelo hash de uma coluna**: todas as linhas de um dispositivo caem na mesma partição, e só existem três dispositivos."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit repartition.py
WARNING: Using incubator modules: jdk.incubator.vector
                   partitions  non-empty     min rows     max rows
as read                    15         15       65,753    1,709,594   no shuffle
coalesce(4)                 4          4    5,128,766    6,838,355   no shuffle
repartition(4)              4          4    5,999,997    6,000,002   shuffle
repartition("device")       3          2    7,921,900   16,078,100   shuffle
```

**Como foram lidas, as partições são desiguais**, de 65.753 linhas a 1,7 milhão. O leitor empacota
arquivos em partições de até 128 MB, e a última fica com o que sobrou.

**O `coalesce(4)` não custou nada e manteve a desigualdade**: quatro partições de 5,1 a 6,8 milhões
de linhas, feitas colando vizinhas. **O `repartition(4)` custou um shuffle de todas as 24 milhões de
linhas e produziu quatro partições a cinco linhas umas das outras**, porque linhas sem chave são
distribuídas em rodízio.

**O `repartition("device")` é o que pede cuidado.** Particionar por uma coluna põe todas as linhas de
um valor na mesma partição, então o número de partições que podem ter alguma coisa é no máximo o
número de valores: três dispositivos, três tarefas ocupadas, seja qual for o tamanho do cluster.
Aqui foi pior. A execução adaptativa juntou as 200 partições do shuffle em 3, e dois dos três
dispositivos caíram pelo hash na mesma, então uma partição ficou vazia e outra ficou com 16 milhões
de linhas. Particionar por uma chave é certo quando o passo seguinte precisa das linhas de cada chave
juntas, e só então.

Qual usar decorre do que o passo seguinte precisa:

- **Menos partições, maiores, antes de uma escrita, sem precisar de equilíbrio:** `coalesce`. É de
  graça. Mas o `coalesce(1)` faz o estágio inteiro antes dele rodar como uma tarefa, porque não há
  shuffle para separá-los; quando se quer mesmo um arquivo, o `repartition(1)` mantém paralelo o
  trabalho antes dele.
- **Partições iguais, ou mais partições:** `repartition(n)`. O `coalesce` só consegue reduzir o
  número.
- **Linhas de uma chave juntas, para uma escrita particionada por essa chave ou um join repetido
  nela:** `repartition(coluna)`. Próxima seção.
