---
title: Perdendo uma partição em cache
version: 1
---

**Uma partição em cache mora na memória de um executor, e vai embora quando o executor vai.** A aula
2 disse isso e deixou a demonstração para aqui. Nada se perde para sempre: a linhagem da partição, os
passos que a fizeram, continua conhecida pelo driver, e a próxima ação que precisar dela roda esses
passos de novo. Salve como `~/big/lost.py`:

```schooling-example
{
  "language": "python",
  "file": "lost.py",
  "parts": [
    {
      "code": "\"\"\"A cached DataFrame loses an executor, and the next action rebuilds what was lost.\"\"\"\nimport getpass\nimport json\nimport subprocess\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"lost\").getOrCreate()\nsc = spark.sparkContext\n\n\ndef cached():\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/storage/rdd\"\n    r = json.load(urllib.request.urlopen(url))[0]\n    return f\"{r['numCachedPartitions']} of {r['numPartitions']} partitions cached\"\n\n\ndef timed_count(df):\n    start = time.time()\n    df.count()\n    return f\"count in {time.time() - start:4.1f} s\"\n\n\nclicks = spark.read.parquet(\"data/silver/clicks\").cache()\nprint(\"first count: \", timed_count(clicks), \"|\", cached())\nprint(\"second count:\", timed_count(clicks), \"|\", cached())\n"
    },
    {
      "code": "subprocess.run([\"pkill\", \"-9\", \"-o\", \"-u\", getpass.getuser(), \"-f\", \"CoarseGrainedExecutorBackend\"],\n               check=True)\ntime.sleep(10)\nprint(\"after the kill:              |\", cached())\n",
      "note": "**Um executor é morto**, o mais antigo dos três: o `pkill -o` escolhe o processo que começou primeiro, e o `-u` o limita aos seus próprios processos. As partições em cache dele estavam na sua memória e vão junto."
    },
    {
      "code": "print(\"third count: \", timed_count(clicks), \"|\", cached())\nprint(\"fourth count:\", timed_count(clicks), \"|\", cached())\n",
      "note": "**A ação seguinte encontra partições faltando no cache** e as recalcula pela linhagem, que aqui é uma leitura dos arquivos Parquet, e as põe em cache de novo."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit lost.py
WARNING: Using incubator modules: jdk.incubator.vector
first count:  count in 37.6 s | 15 of 15 partitions cached
second count: count in  0.6 s | 15 of 15 partitions cached
02:27:54 ERROR TaskSchedulerImpl: Lost executor 0 on 127.0.0.1: Command exited with code 137
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_8!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_13!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_2!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_5!
02:27:54 WARN BlockManagerMasterEndpoint: No more replicas available for rdd_8_11!
after the kill:              | 10 of 15 partitions cached
third count:  count in 14.6 s | 15 of 15 partitions cached
fourth count: count in  0.5 s | 15 of 15 partitions cached
```

**O executor morto tinha cinco das quinze partições**, e o driver nomeou cada uma ao perceber:
`rdd_8_2` é a partição 2 do conjunto em cache, e o `No more replicas available` diz que nenhum outro
executor tinha uma cópia. O worker iniciou um executor novo no lugar, como a aula 2 mostrou.

**A terceira contagem achou dez partições no cache e cinco faltando**, leu essas cinco dos arquivos
Parquet, guardou-as de novo e levou 14,6 segundos, bem menos da metade do primeiro preenchimento, porque
faltava um terço dos dados. A quarta voltou a meio segundo. A resposta esteve certa todas as vezes; o que o
executor perdido custou foi tempo, uma vez.

Essa é a troca que um cache faz, e quase sempre é a certa. **Quando recalcular é caro o bastante para
importar**, um join de uma hora atrás do cache, os níveis `_2` guardam cada partição em dois
executores, ao dobro da memória, para que perder um não custe nada além de uma consulta. E quando a
própria linhagem é o problema, valem as duas próximas seções.
