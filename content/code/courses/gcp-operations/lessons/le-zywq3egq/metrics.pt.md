---
title: Uma métrica é um tipo, um recurso e rótulos
version: 1
---

**Todo número no Cloud Monitoring é um ponto numa série temporal, e uma série temporal é nomeada por três
coisas: um tipo de métrica, um recurso monitorado e os valores dos rótulos deles.** O tipo de métrica diz o
que é medido, como `run.googleapis.com/request_count`. O recurso monitorado diz onde foi medido: uma revisão
do Cloud Run, uma instância do Compute Engine, um bucket. Os rótulos estreitam os dois: o nome do serviço, a
classe de status da resposta, a região. Mude qualquer um deles e é outra série, com histórico próprio e linha
própria na fatura. **Nada nesta lição chega ao Cloud Monitoring**, porque nada no seu computador o imita; o
que roda aqui é a aritmética que ele aplica, sobre dados que um programa gera, e um plano do Terraform dos
checks e do painel da loja.

A contagem de requisições da loja no Cloud Run é um tipo de métrica e muitas séries:

| tipo de métrica | recurso | rótulos | uma série |
|---|---|---|---|
| `run.googleapis.com/request_count` | `cloud_run_revision` | `service_name`, `revision_name`, `response_code_class` | a revisão `shop-api-00042` do `shop-api`, respostas `5xx` |

O Google publica as métricas dos próprios serviços sem ninguém escrever código, e elas são gratuitas para
receber: são as "non-chargeable Google Cloud metrics" da página de preços. Uma métrica que o seu programa
escreve, `custom.googleapis.com/...` ou uma enviada por OpenTelemetry (lição 12), é cobrada pelo volume
recebido.

## Três tipos (kinds)

O **kind** de uma métrica diz o que um ponto significa, e errar isso é como um gráfico mostra bobagem:

- **GAUGE**: o valor num instante. Memória em uso, número de instâncias, profundidade de uma fila.
- **DELTA**: quanto aconteceu no intervalo que o ponto cobre. Requisições neste minuto.
- **CUMULATIVE**: quanto aconteceu desde um início, crescendo até o processo reiniciar. A maioria dos
  contadores que um programa exporta é cumulativa, porque um programa consegue contar sem saber quando
  alguém vai ler a contagem.

Ninguém quer olhar uma série cumulativa diretamente: é uma linha subindo, mais íngreme quando há mais
movimento. O que as pessoas querem é a taxa, e transformar uma na outra é o que um **alinhador** (aligner)
faz.

## Os alinhadores, à mão

O programa abaixo gera dez minutos da API da loja, um contador cumulativo de requisições e a latência de
cada requisição, e aplica a aritmética de dois alinhadores e de dois resumos. Escreva-o em `~/gcp/align.py`:

```schooling-example
{"language": "python", "file": "align.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"align.py: what Cloud Monitoring's aligners do to a series, done by hand.\n\nTen minutes of the shop's API, one point a minute. Nothing here talks to\nGoogle: the data is generated, and the arithmetic is the aligners'.\n\"\"\"\n", "note": "A docstring diz o que o programa é e o que não é: dados gerados, e a aritmética que o Cloud Monitoring aplica. Nada nele chama o Google."}, {"code": "import random\nimport statistics\n\n", "note": "Só biblioteca padrão: `random` faz os dados, `statistics` calcula médias e percentis."}, {"code": "rng = random.Random(7)\n# a CUMULATIVE counter: total requests since the process started\ntotal, counter = 0, []\nfor minute in range(11):\n    counter.append((minute, total))\n    total += 600 + rng.randint(-50, 50)\n# each minute's latencies in ms: most fast, a few slow\nlatencies = [[rng.choice([40, 45, 50, 55]) if rng.random() > 0.02 else 2400\n              for _ in range(600)] for _ in range(10)]\n\n\n", "note": "Duas séries, ambas com semente fixa para que toda execução imprima os mesmos números. A primeira é um contador **CUMULATIVE**, do tipo que um processo exporta: o total desde que começou, que só cresce. A segunda é a latência de cada uma das 600 requisições por minuto, 98% delas rápidas e 2% levando 2,4 segundos."}, {"code": "def align_delta(points):\n    return [(t2, v2 - v1) for (t1, v1), (t2, v2) in zip(points, points[1:])]\n\n\ndef align_rate(points):\n    return [(t, d / 60) for t, d in align_delta(points)]\n\n\n", "note": "`ALIGN_DELTA` transforma uma série cumulativa em quanto ela cresceu em cada intervalo, e `ALIGN_RATE` divide isso pela duração do intervalo em segundos. O Cloud Monitoring os aplica a cada série antes de qualquer outra coisa, para que séries amostradas em momentos diferentes possam ser comparadas."}, {"code": "def pct(values, p):\n    return statistics.quantiles(values, n=100)[p - 1]\n\n\n", "note": "Um percentil: o valor abaixo do qual aquela fração das requisições fica. `quantiles(n=100)` devolve os 99 pontos de corte, então o 50º é a mediana e o 99º é aquilo que uma requisição em cem ultrapassa."}, {"code": "print('minute  counter  ALIGN_DELTA  ALIGN_RATE/s  mean_ms  p50_ms  p99_ms')\nfor (t, v), (_, d), (_, r), lat in zip(counter[1:], align_delta(counter),\n                                       align_rate(counter), latencies):\n    print(f'{t:>6}  {v:>7}  {d:>11}  {r:>12.2f}  {statistics.mean(lat):>7.1f}'\n          f'  {pct(lat, 50):>6.0f}  {pct(lat, 99):>6.0f}')\n", "note": "Uma linha por minuto: o contador bruto, o que cada alinhador faz com ele, e três resumos das mesmas 600 latências."}]}
```

```
ana@laptop:~/gcp$ python3 align.py
minute  counter  ALIGN_DELTA  ALIGN_RATE/s  mean_ms  p50_ms  p99_ms
     1      591          591          9.85    110.3      50    2400
     2     1160          569          9.48     86.3      45    2400
     3     1760          600         10.00     86.7      50    2400
     4     2393          633         10.55     90.4      45    2400
     5     2949          556          9.27     67.0      45      55
     6     3508          559          9.32     86.6      45    2400
     7     4126          618         10.30     90.4      50    2400
     8     4688          562          9.37    102.5      50    2400
     9     5284          596          9.93     75.4      50    2400
    10     5908          624         10.40     90.2      45    2400
/home/user/schooling/content/code/courses/gcp-operations/lessons/le-zywq3egq/checks.md: expected one block for tf/monitoring/dashboard.json, found 0
```
