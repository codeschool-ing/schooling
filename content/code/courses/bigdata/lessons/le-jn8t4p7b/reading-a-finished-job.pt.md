---
title: Lendo um job terminado
version: 1
---

**Um job lento é achado depois de terminar, pelo que deixou para trás.** O driver que rodou o
relatório se foi; o seu log de eventos está em `~/spark-events`, e o history server da aula 7 o lê.
Este programa pede ao history server os estágios da aplicação mais recente com um dado nome, o mais
lento primeiro. Salve como `~/big/history.py`:

```schooling-example
{
  "language": "python",
  "file": "history.py",
  "parts": [
    {
      "code": "\"\"\"The stages of a finished application, read back from the history server.\"\"\"\nimport json\nfrom datetime import datetime\nimport sys\nimport urllib.request\n\nHISTORY = \"http://localhost:18080/api/v1\"\n\n\ndef get(path):\n    return json.load(urllib.request.urlopen(f\"{HISTORY}/{path}\"))\n\n\n"
    },
    {
      "code": "app = next(a for a in get(\"applications?status=completed&limit=50\") if a[\"name\"] == sys.argv[1])\nprint(app[\"id\"], f\"{app['attempts'][0]['duration'] / 1000:.1f} s\")\n\n",
      "note": "**A aplicação terminada mais recente com o nome dado**, pelo history server da aula 7: o driver já se foi faz tempo, e o seu log de eventos é tudo o que sobra."
    },
    {
      "code": "print(\"stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name\")\nstages = [s for s in get(f\"applications/{app['id']}/stages\") if s[\"status\"] == \"COMPLETE\"]\nfor s in sorted(stages, key=lambda s: -s[\"executorRunTime\"])[:6]:\n    first, last = (datetime.strptime(s[k][:23], \"%Y-%m-%dT%H:%M:%S.%f\")\n                   for k in (\"firstTaskLaunchedTime\", \"completionTime\"))\n    wall = (last - first).total_seconds()\n    print(f\"{s['stageId']:5} {s['numTasks']:6} {wall:7.1f} {s['executorRunTime'] / 1000:7.1f}\"\n          f\" {s['inputBytes'] / 2**20:10.1f} {s['shuffleReadBytes'] / 2**20:12.1f}\"\n          f\" {s['diskBytesSpilled'] / 2**20:10.1f}  {s['name'][:28]}\")\n",
      "note": "**Uma linha por estágio que rodou**, o mais lento primeiro: as tarefas, o tempo de relógio do início da primeira tarefa ao fim da última, o tempo de tarefa somado, e os bytes que leu, embaralhou e despejou."
    }
  ]
}
```

Ele não precisa de Spark, então roda com o `python3` comum:

```
ana@lab:~/big$ python3 history.py report
app-20261016061511-0013 156.0 s
stage  tasks  wall s  task s  input MiB  shuffle MiB  spill MiB  name
    4   2000    73.4   172.6        0.0          9.8        0.0  collect at /home/ana/big/rep
    3     14    23.3    57.0      239.3          0.0        0.0  collect at /home/ana/big/rep
    5   2000    15.8    11.3        0.0          2.9        0.0  collect at /home/ana/big/rep
    9   2000    14.1    10.0        0.0          2.9        0.0  collect at /home/ana/big/rep
    2      1     5.3     4.0        0.0          0.0        0.0  collect at /home/ana/big/rep
    0    365     9.8     3.5        0.0          0.0        0.0  csv at NativeMethodAccessorI
```

**Leia de cima para baixo.** O estágio mais lento tem 2.000 tarefas que, somadas, leem menos de 10 MiB
de shuffle: é o sort-merge join, cortado nas 2.000 partições fixas, e é também onde a função Python
rodou em cada compra antes das contagens. São 172,6 segundos de tarefa, o maior de todos os estágios,
e a segunda, a terceira e a quarta correções tratam todas dele. O seguinte leu o CSV cru, os 239 MiB de texto com gzip em 14
tarefas, por 57 segundos de tarefa: a primeira correção. Mais dois estágios de 2.000 tarefas cada
vêm depois, o agrupamento final e a ordenação do resultado, cada tarefa lendo quase nada.

As colunas são as da aula 7, lidas de outro lugar. **Tempo de relógio contra tempo de tarefa** diz o
quanto um estágio foi paralelo: três executores rodando o tempo todo fariam o tempo de tarefa três
vezes o de relógio. **Entrada** diz o que foi lido de arquivos, **shuffle** o que foi movido entre
estágios, e **spill** o que não coube na memória. Um estágio com muito tempo de tarefa e nada notável
nas outras colunas está fazendo trabalho lento por linha, que é como uma função Python e a
interpretação de texto parecem vistas de fora.
