---
title: Medindo o que uma consulta leu
version: 1
---

**Um plano diz o que o Spark pretende ler. As métricas do driver dizem o que ele leu.** A aula 3 leu
a localidade das tarefas na interface REST do driver; a mesma interface guarda, para cada consulta
SQL, as métricas de cada nó do plano. Um módulo pequeno lê as do scan. Salve como
`~/big/lastscan.py`:

```schooling-example
{
  "language": "python",
  "file": "lastscan.py",
  "parts": [
    {
      "code": "\"\"\"What the last query's file scans did, from the driver's REST interface.\"\"\"\nimport json\nimport time\nimport urllib.request\n\n\n"
    },
    {
      "code": "def scans(spark):\n    sc = spark.sparkContext\n    url = (f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}\"\n           \"/sql?details=true&planDescription=false\")\n",
      "note": "**O driver guarda, para cada consulta SQL que rodou, o plano e as métricas que cada passo dele reportou.** Isto pede a consulta mais nova e imprime três números de cada scan de arquivo dela."
    },
    {
      "code": "    time.sleep(1)\n    last = max(json.load(urllib.request.urlopen(url)), key=lambda q: q[\"id\"])\n    for node in last[\"nodes\"]:\n        if node[\"nodeName\"].startswith(\"Scan\"):\n            m = {x[\"name\"]: x[\"value\"] for x in node[\"metrics\"]}\n",
      "note": "As métricas chegam um instante depois do fim da consulta, então a função espera um segundo antes."
    },
    {
      "code": "            print(f\"  {m.get('number of files read')} files of \"\n                  f\"{m.get('size of files read')}, {m.get('number of output rows')} rows\")\n",
      "note": "Quantos arquivos o scan abriu, o tamanho total deles em disco, e quantas linhas entregou ao resto do plano."
    }
  ]
}
```

E quatro perguntas sobre compras que diferem no que precisam dos arquivos. Salve como
`~/big/pruning.py`; ele importa o módulo acima do mesmo diretório:

```schooling-example
{
  "language": "python",
  "file": "pruning.py",
  "parts": [
    {
      "code": "\"\"\"Four questions about purchases, and what each one read.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom lastscan import scans\n\nspark = SparkSession.builder.appName(\"pruning\").getOrCreate()\n"
    },
    {
      "code": "def run(label, make):\n    make().collect()\n    start = time.time()\n    answer = make().collect()[0][0]\n    print(label, answer, f\"in {time.time() - start:.1f} s\")\n    scans(spark)\n\n\ndef purchases():\n    return spark.read.parquet(\"data/silver/clicks\").where(F.col(\"kind\") == \"purchase\")\n\n\n",
      "note": "Um auxiliar que monta uma consulta duas vezes e roda cada uma, ficando com o segundo tempo, para não contar o aquecimento, e depois imprime o que o scan dela fez. A consulta é montada de novo a cada vez porque o Spark reaproveita os arquivos intermediários de uma consulta que já rodou, o que a aula 9 explica, e isso não cronometraria nada."
    },
    {
      "code": "run(\"every column:\", lambda: purchases().agg(\n    F.max(F.length(F.concat_ws(\"|\", *purchases().columns)))))\n",
      "note": "**Todas as colunas**: a compra mais longa escrita como texto, todas as colunas unidas por `|`, o que precisa de todas as colunas de todas as compras."
    },
    {
      "code": "run(\"one column:  \", lambda: purchases().agg(F.countDistinct(\"book_id\")))\n",
      "note": "**Uma coluna**: uma contagem de livros distintos lê o `book_id`, e o `kind` para o filtro."
    },
    {
      "code": "run(\"one day:     \", lambda: purchases().where(F.col(\"day\") == \"2025-03-14\")\n                                        .agg(F.countDistinct(\"book_id\")))\n\n",
      "note": "**Um dia**: a mesma contagem para 14 de março. O `day` é a coluna de partição."
    },
    {
      "code": "is_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, \"boolean\")\nrun(\"one day, udf:\", lambda: purchases().where(is_pi_day(\"day\"))\n                                        .agg(F.countDistinct(\"book_id\")))\n",
      "note": "**O mesmo dia, escolhido por uma função Python** que faz exatamente o que o `== \"2025-03-14\"` faz."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit pruning.py
WARNING: Using incubator modules: jdk.incubator.vector
every column: 70 in 14.9 s
  365 files of 388.8 MiB, 24,000,000 rows
one column:   3000 in 6.5 s
  365 files of 388.8 MiB, 24,000,000 rows
one day:      1304 in 3.1 s
  1 files of 1098.7 KiB, 65,753 rows
one day, udf: 1304 in 6.7 s
  365 files of 388.8 MiB, 24,000,000 rows
```

Quatro respostas, e quatro scans bem diferentes:

- **Todas as colunas** abriu os 365 arquivos e levou mais tempo.
- **Uma coluna** abriu os 365 arquivos, os mesmos 388,8 MiB pela métrica, e levou cerca de metade do
  tempo.
- **Um dia** abriu um arquivo de 1 MiB e entregou 65.753 linhas em vez de 24 milhões.
- **Um dia, escolhido por uma função Python**, abriu os 365 arquivos de novo, para a mesma resposta
  da linha de cima.

**Um aviso sobre o nome da métrica.** *Size of files read* é o tamanho dos arquivos que o scan abriu,
não os bytes que ele leu deles. Um arquivo Parquet pode ser aberto e lido em parte, que é justamente
o assunto da próxima seção, e esse número não enxerga isso; o tempo enxerga. As seções 06, 07 e 08
explicam as três diferenças.
