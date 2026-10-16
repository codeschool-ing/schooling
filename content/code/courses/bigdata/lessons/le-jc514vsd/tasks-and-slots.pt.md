---
title: Tarefas, núcleos e ondas
version: 1
---

**Um job é cortado em tarefas, e a tarefa é a unidade que o agendador distribui.** Cada tarefa
trabalha numa fatia dos dados, e cada núcleo de um executor roda uma tarefa por vez. Então a conta
da duração de um job começa com dois números: quantas tarefas existem, e quantos núcleos há para
rodá-las.

O programa que esta aula usa deixa os dois números fáceis de ver. Ele roda quantas tarefas você
pedir, e cada uma só dorme pelo tempo que você disser, então o tempo do job é obra do agendador e
não dos dados. Salve como `~/big/tasks.py`:

```schooling-example
{
  "language": "python",
  "file": "tasks.py",
  "parts": [
    {
      "code": "\"\"\"Run N tasks that each take S seconds, and say how long the whole job took.\"\"\"\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession\n\n"
    },
    {
      "code": "N, S = int(sys.argv[1]), float(sys.argv[2])\nspark = SparkSession.builder.appName(f\"tasks {N}x{S}\").getOrCreate()\n\n\n",
      "note": "Dois números da linha de comando: quantas tarefas, e quanto tempo cada uma trabalha."
    },
    {
      "code": "def work(slice_):\n    time.sleep(S)\n    return sum(slice_)\n\n\n",
      "note": "**Esta função é a tarefa.** O Spark a envia a um executor, que a roda sobre uma fatia dos dados e devolve o resultado."
    },
    {
      "code": "start = time.time()\ntotal = (spark.sparkContext.parallelize(range(N), N)\n         .glom().map(work).sum())\nprint(f\"{N} tasks of {S:g} s: answer {total}, {time.time() - start:.1f} s\")\n",
      "note": "O `parallelize` corta os números de 0 a N-1 em N fatias, uma por tarefa, e o `map` com o `sum` roda o `work` em cada uma e soma as respostas. A aula 5 explica a API."
    }
  ]
}
```

Trinta tarefas de dois segundos, depois trinta e uma, depois três:

```
ana@lab:~/big$ spark-submit tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 22.0 s
ana@lab:~/big$ spark-submit tasks.py 31 2
WARNING: Using incubator modules: jdk.incubator.vector
31 tasks of 2 s: answer 465, 23.9 s
ana@lab:~/big$ spark-submit tasks.py 3 2
WARNING: Using incubator modules: jdk.incubator.vector
3 tasks of 2 s: answer 3, 3.8 s
```

**Trinta tarefas em três núcleos rodam em dez *ondas*** de três, e dez ondas de dois segundos são
vinte segundos. A execução levou uns dois a mais, que é o preço de iniciar uma aplicação: pedir
executores ao master, esperar três processos Java subirem e mandar o programa para eles. **Trinta e
uma tarefas precisam de uma décima primeira onda** para uma tarefa só, e o job levou dois segundos a
mais com dois dos três núcleos parados. Três tarefas cabem numa onda, e o job é quase todo custo
fixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l02-waves\" aria-label=\"Três núcleos ao longo do tempo. Trinta tarefas de dois segundos enchem dez ondas de três e terminam em vinte segundos. Uma trigésima primeira tarefa precisa de uma décima primeira onda, em que um núcleo trabalha e dois ficam parados, e o job termina em vinte e dois segundos.\"><text x=\"70.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">núcleo 1</text><rect x=\"81.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">tarefa 31</text><text x=\"70.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">núcleo 2</text><rect x=\"81.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"626.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">parado</text><text x=\"70.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">núcleo 3</text><rect x=\"81.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"626.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">parado</text><path d=\"M80.0 160.0 L662.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 160.0 L80.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M132.0 160.0 L132.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"132.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M184.0 160.0 L184.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"184.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M236.0 160.0 L236.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"236.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M288.0 160.0 L288.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"288.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M340.0 160.0 L340.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"340.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M392.0 160.0 L392.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M444.0 160.0 L444.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"444.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M496.0 160.0 L496.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"496.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M548.0 160.0 L548.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"548.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M600.0 160.0 L600.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"600.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M652.0 160.0 L652.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"652.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22</text><text x=\"366.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">segundos</text></svg>", "caption": "Trinta e uma tarefas em três núcleos: a última onda tem uma tarefa e dois núcleos parados, e custa uma onda inteira de tempo."}
```

Duas regras saem daqui, e a aula 7 se apoia nas duas:

- **A onda mais lenta decide o tempo, e a última onda costuma estar meio vazia.** Um job com tantas
  tarefas quanto núcleos não tem o que redistribuir se uma tarefa for lenta; um job com algumas
  vezes mais tarefas que núcleos espalha o trabalho de forma mais uniforme.
- **Uma tarefa tem um custo fixo**, agendar, iniciar e reportar, de alguns milissegundos aqui e mais
  num cluster ocupado. Tarefas de um segundo o tornam invisível; dezenas de milhares de tarefas de
  poucos milissegundos gastam a maior parte do job nesse custo.

**Onde uma tarefa roda é decisão do driver**, e quando os dados moram em máquinas específicas, como
no HDFS da aula 3, o driver prefere um executor na máquina que guarda a fatia da tarefa. O Spark
chama isso de *data locality*, e espera alguns segundos por um núcleo local livre antes de se
contentar com um remoto. Numa máquina só, todo executor é local para tudo, então o laboratório
nunca mostra a espera.
