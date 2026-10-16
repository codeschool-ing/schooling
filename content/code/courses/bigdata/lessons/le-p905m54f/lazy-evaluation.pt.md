---
title: Nada acontece até você pedir uma resposta
version: 1
---

**As operações do Spark são de dois tipos, e só um deles trabalha.** Uma *transformação*, como
`filter`, `map` ou `groupBy`, devolve um novo conjunto de dados e não calcula nada: acrescenta um
passo à linhagem. Uma *ação*, como `count`, `collect`, `show` ou uma escrita, precisa de um
resultado, então transforma a linhagem num job e o roda. Salve como `~/big/lazy.py`:

```schooling-example
{
  "language": "python",
  "file": "lazy.py",
  "parts": [
    {
      "code": "\"\"\"Transformations cost nothing until an action asks for a result.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"lazy\").getOrCreate()\nsc = spark.sparkContext\n\n"
    },
    {
      "code": "t = time.time()\nlines = sc.textFile(\"data/raw/clicks/*/*.csv.gz\")\nviews = lines.filter(lambda line: \",view,\" in line)\npairs = views.map(lambda line: (line.split(\",\")[4], 1))\nprint(f\"three transformations: {time.time() - t:.3f} s\")\n\n",
      "note": "Três transformações, cronometradas. Elas só registram o que fazer."
    },
    {
      "code": "t = time.time()\nprint(\"views:\", views.count(), f\"{time.time() - t:.1f} s\")\n",
      "note": "O `count` é uma ação: ele roda um job que lê todo arquivo e filtra toda linha."
    },
    {
      "code": "t = time.time()\nprint(\"views again:\", views.count(), f\"{time.time() - t:.1f} s\")\n",
      "note": "**A mesma ação de novo roda o mesmo job de novo**, a partir dos arquivos. Nada foi guardado da primeira vez; a aula 9 trata de guardar."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lazy.py
WARNING: Using incubator modules: jdk.incubator.vector
three transformations: 0.559 s
views: 19199214 26.3 s
views again: 19199214 17.8 s
```

**Três transformações em meio segundo, e quase tudo isso foi preparar o leitor**; nenhuma linha de
arquivo foi lida. O primeiro `count` leu todos os arquivos. O segundo `count` leu todos os arquivos
de novo, porque o `views` é uma receita e não um resultado: duas ações, dois jobs, o mesmo trabalho
duas vezes. Foi mais rápido na segunda vez porque o sistema operacional tinha os arquivos em cache e
os processos Python dos executores já estavam rodando, e não porque o Spark guardou alguma coisa.

**A preguiça é o que deixa o Spark planejar.** Quando a ação chega, o Spark vê todos os passos de uma
vez, dos arquivos ao resultado, e pode escolher como rodá-los. Pode fundir o `filter` e o `map` numa
passada só, como a linhagem da seção anterior mostrou, ou, com um DataFrame, ler só as colunas de que
o resultado precisa. Um programa que rodasse cada linha na hora em que foi escrita teria de ler tudo
na primeira linha, antes de saber o que a última ia pedir.

O custo é um hábito a desaprender. **Uma linha que parece cara pode não custar nada, e um `count` de
aparência barata no fim pode rodar tudo o que está acima dele**, de novo, toda vez. Duas ações sobre
os mesmos dados transformados são dois jobs, a menos que você peça ao Spark para guardar os dados
entre elas, e a aula 9 trata de quando fazer isso.
