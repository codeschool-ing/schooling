---
title: Executores que vêm e vão
version: 1
---

**Num cluster compartilhado uma aplicação deveria segurar executores só enquanto tem trabalho para
eles.** O Kubernetes e o YARN cobram, em dinheiro ou na espera dos outros, por cada pod e contêiner
segurado, ocupado ou não. A *alocação dinâmica* deixa o Spark pedir executores quando há tarefas
esperando e devolvê-los quando ficam ociosos por um tempo. Ela roda também no cluster standalone, e é
lá que esta seção a mede. Salve como `~/big/dynamic.py`:

```schooling-example
{
  "language": "python",
  "file": "dynamic.py",
  "parts": [
    {
      "code": "\"\"\"An application that asks for executors when it has work and gives them back when it has none.\"\"\"\nimport json\nimport sys\nimport threading\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "builder = (SparkSession.builder.appName(\"dynamic\")\n           .config(\"spark.dynamicAllocation.enabled\", True)\n           .config(\"spark.dynamicAllocation.shuffleTracking.enabled\", True)\n           .config(\"spark.dynamicAllocation.minExecutors\", 0)\n           .config(\"spark.dynamicAllocation.maxExecutors\", 3)\n           .config(\"spark.dynamicAllocation.executorIdleTimeout\", \"15s\"))\nif len(sys.argv) > 1:\n    builder = builder.config(\"spark.dynamicAllocation.shuffleTracking.timeout\", sys.argv[1])\nspark = builder.getOrCreate()\nsc = spark.sparkContext\nstart = time.time()\n\n\n",
      "note": "**Alocação dinâmica**, de nenhum executor até três. Um executor ocioso por 15 segundos é devolvido. O *shuffle tracking* mantém um executor que guarda arquivos de shuffle que um estágio posterior ainda pode ler, que é o que um serviço externo de shuffle faz nos clusters que têm um. Por quanto tempo ele o mantém é o argumento do programa, para sempre se não for dado."
    },
    {
      "code": "def watch():\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/executors\"\n    held = None\n    while True:\n        executors = [e for e in json.load(urllib.request.urlopen(url)) if e[\"id\"] != \"driver\"]\n        if len(executors) != held:\n            held = len(executors)\n            print(f\"{time.time() - start:5.0f} s: {held} executors\", flush=True)\n        time.sleep(1)\n\n\nthreading.Thread(target=watch, daemon=True).start()\n\n",
      "note": "**Um observador numa thread própria**, conferindo a cada segundo quantos executores a aplicação tem, pela interface REST do driver, e imprimindo quando o número muda."
    },
    {
      "code": "clicks = spark.read.parquet(\"data/silver/clicks\")\nfor round in (1, 2):\n    n = clicks.groupBy(\"visitor_id\").count().where(F.col(\"count\") > 100).count()\n    print(f\"{time.time() - start:5.0f} s: round {round} done, {n} visitors with more than 100 events\",\n          flush=True)\n    time.sleep(35)\n",
      "note": "**Trabalho, depois nada, depois trabalho de novo**: um agrupamento do ano, meio minuto de ociosidade, e o agrupamento de novo."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit dynamic.py 2>/dev/null
    2 s: 0 executors
    9 s: 1 executors
   10 s: 2 executors
   11 s: 3 executors
   42 s: round 1 done, 1 visitors with more than 100 events
   87 s: round 2 done, 1 visitors with more than 100 events
```

**A aplicação começou sem executores e tinha três uns dez segundos depois**, assim que as tarefas do
primeiro estágio ficaram esperando. **Depois nunca os devolveu**, em duas rodadas e no meio minuto
ocioso depois de cada uma. O shuffle tracking é o motivo. Um executor que gravou arquivos de shuffle é
o único lugar em que esses arquivos existem, o ponto da aula 7, e um estágio posterior, ou uma consulta
posterior que reaproveite o mesmo shuffle como as da aula 9, pode precisar deles. O Spark não tem como
saber que ninguém vai, então por padrão mantém esse executor enquanto a aplicação viver.

Com um limite de quanto tempo os arquivos de shuffle ficam protegidos, 20 segundos aqui:

```
ana@lab:~/big$ spark-submit dynamic.py 20s 2>/dev/null
    2 s: 0 executors
    8 s: 1 executors
   11 s: 3 executors
   39 s: round 1 done, 1 visitors with more than 100 events
   65 s: 0 executors
   81 s: 1 executors
   83 s: 3 executors
  100 s: round 2 done, 1 visitors with more than 100 events
  125 s: 0 executors
```

**Agora os executores voltaram a zero cerca de meio minuto depois de cada rodada**, e voltaram para a
seguinte. O preço apareceu na segunda rodada: ela levou cerca de 26 segundos desde o fim da pausa, contra
10 na primeira execução, em que os seus executores e os seus arquivos de shuffle ainda estavam lá. Em
troca, o cluster teve esses três cores livres por meio minuto.

**Num cluster de verdade a resposta de costume é um serviço externo de shuffle**: um processo em cada
máquina, fora dos executores, que serve os arquivos de shuffle deles depois que se foram, para que um
executor possa ser liberado assim que fica ocioso. O YARN pode rodar um dentro de cada NodeManager; no
Kubernetes, em que pods não dividem discos, o Spark conta com o shuffle tracking, com migrar os
arquivos de shuffle para outros executores quando um é avisado de que vai sair, ou com um serviço de
shuffle remoto, um sistema à parte que guarda dados de shuffle para o cluster inteiro.
