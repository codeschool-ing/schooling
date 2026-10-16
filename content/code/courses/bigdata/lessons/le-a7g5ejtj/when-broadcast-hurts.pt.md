---
title: Quando um broadcast machuca
version: 1
---

**Um broadcast é pago duas vezes: uma no driver e uma em cada executor.** O driver roda a consulta do
lado pequeno, coleta as linhas, monta a tabela hash e a envia; cada executor guarda uma cópia
inteira na memória enquanto o join roda. Nada disso vai para o disco. Um lado que afinal não é
pequeno é o jeito de um broadcast dar errado.

O caso mais claro é um hint no lado errado. Salve como `~/big/too_big.py`:

```schooling-example
{
  "language": "python",
  "file": "too_big.py",
  "parts": [
    {
      "code": "\"\"\"A broadcast join asked for on the wrong side.\"\"\"\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nspark = SparkSession.builder.appName(\"too big to broadcast\").getOrCreate()\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\n"
    },
    {
      "code": "print(visitors.join(F.broadcast(clicks), \"visitor_id\").groupBy(\"device\").count().collect())\n",
      "note": "**O hint aponta os cliques, todos os 24 milhões, como o lado a copiar para cada tarefa.** O driver tem de coletá-los primeiro."
    }
  ]
}
```

Rode, com o `grep` guardando a única linha do stack trace que diz o que aconteceu:

```
ana@lab:~/big$ spark-submit too_big.py 2>&1 | grep -E 'WARN|SparkException'
WARNING: Using incubator modules: jdk.incubator.vector
01:47:38 WARN TaskMemoryManager: Failed to allocate a page (1073741824 bytes), try again.
: org.apache.spark.SparkException: Not enough memory to build and broadcast the table to all worker nodes. As a workaround, you can either disable broadcast by setting spark.sql.autoBroadcastJoinThreshold to -1 or increase the spark driver memory by setting spark.driver.memory to a higher value or apply the shuffle sort merge join hint as described in the Spark documentation: https://spark.apache.org/docs/latest/sql-ref-syntax-qry-select-hints.html#join-hints.
```

**O driver recusou, e disse por quê.** Ele tentou reservar um gigabyte de memória para guardar 24
milhões de linhas e não conseguiu, e a mensagem lista as três saídas: desligar o broadcast, dar mais
memória ao driver ou pedir um sort-merge join com um hint. Só a última é uma correção; a primeira
joga fora os broadcasts que estavam ajudando, e a segunda muda a parede de lugar sem tirá-la.

Ninguém escreve esse hint de propósito. **O que acontece na prática é uma estimativa errada:**

- **Estatísticas de antes de um filtro.** O planejador estima um lado pelos arquivos e pelos filtros
  que consegue ver. Uma tabela que era pequena no mês passado e cresceu, ou um filtro escrito como
  UDF Python que o planejador não enxerga, manda um lado grande para o driver.
- **Um hint que sobreviveu ao motivo.** O `F.broadcast(countries)` estava certo quando a tabela tinha
  200 linhas. Dois anos depois alguém a juntou antes com as cidades.
- **Um limite subido para um job e deixado subido** nos padrões do cluster, onde todo outro job o
  herda.

Duas configurações limitam o estrago. O `spark.sql.broadcastTimeout`, 300 segundos por padrão, faz
falhar um broadcast que demora demais para ser montado. E a execução adaptativa, ligada por padrão,
replaneja um join depois do shuffle, quando o tamanho real é conhecido; ela pode transformar um
sort-merge join em broadcast quando um lado saiu pequeno, mas não transforma um broadcast de volta em
sort-merge. Um hint errado é obedecido até falhar.
