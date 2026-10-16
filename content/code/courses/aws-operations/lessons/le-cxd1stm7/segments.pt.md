---
title: Segmentos, escritos à mão e lidos de volta
version: 1
---

Um serviço instrumentado para o X-Ray manda um **segmento** para cada requisição que trata: um
documento JSON com o id do trace, o id próprio, um nome, um início e um fim, e **subsegmentos** para o
trabalho que esperou. Não há serviços neste laboratório, então o programa abaixo escreve os dois
segmentos que o checkout da loja produziria, o da API e o do serviço de pagamentos, e os manda como o
SDK do X-Ray ou um coletor mandaria. As durações dele são fixas; a estrutura é a real.

```schooling-example
{"language": "python", "file": "trace.py", "parts": [{"code": "# trace.py: one checkout, traced across two services, sent to X-Ray\nimport json\nimport random\nimport time\n\nimport boto3\n\nrng = random.Random(11)\nstart = time.time()\ntrace_id = f\"1-{int(start):08x}-{rng.getrandbits(96):024x}\"\n\n\ndef new_id():\n    return f\"{rng.getrandbits(64):016x}\"\n\n\napi_id, call_id = new_id(), new_id()\n", "note": "**Um id de trace tem três partes**: a versão `1`, o instante de início em segundos como oito dígitos hexadecimais, e 96 bits aleatórios. O tempo dentro do id é o que permite ao X-Ray achar um trace por tempo sem índice. Cada trecho ganha um id próprio, de 64 bits aleatórios."}, {"code": "api = {\n    \"trace_id\": trace_id, \"id\": api_id, \"name\": \"shop-api\",\n    \"start_time\": start, \"end_time\": start + 0.512,\n    \"http\": {\"request\": {\"method\": \"POST\", \"url\": \"/checkout\"}, \"response\": {\"status\": 200}},\n    \"subsegments\": [\n        {\"id\": new_id(), \"name\": \"orders-db\",\n         \"start_time\": start + 0.004, \"end_time\": start + 0.031},\n        {\"id\": call_id, \"name\": \"payments\", \"namespace\": \"remote\",\n         \"start_time\": start + 0.035, \"end_time\": start + 0.505},\n    ],\n}\n", "note": "O **segmento** da API: o trabalho dela do início ao fim, 512 ms, com dois **subsegmentos** para o que ela esperou. `namespace: remote` marca a chamada a outro serviço, e o id dela, `call_id`, é o que o outro serviço vai nomear como pai."}, {"code": "payments = {\n    \"trace_id\": trace_id, \"id\": new_id(), \"parent_id\": call_id, \"name\": \"payments\",\n    \"start_time\": start + 0.041, \"end_time\": start + 0.498,\n    \"subsegments\": [\n        {\"id\": new_id(), \"name\": \"card-network\", \"namespace\": \"remote\",\n         \"start_time\": start + 0.050, \"end_time\": start + 0.470},\n    ],\n}\n", "note": "O serviço de pagamentos escreve **o próprio segmento**, no próprio processo, com o mesmo `trace_id` e o `parent_id` apontando para o subsegmento da API. Num sistema real os dois valores chegam no cabeçalho `X-Amzn-Trace-Id` da requisição; aqui são variáveis compartilhadas."}, {"code": "xray = boto3.client(\"xray\")\nxray.put_trace_segments(TraceSegmentDocuments=[json.dumps(api), json.dumps(payments)])\nprint(trace_id)\n", "note": "Os dois documentos vão para o X-Ray numa chamada, como strings JSON. Serviços reais mandam os seus separadamente, por um daemon ou um coletor, e o X-Ray os junta pelo id do trace."}]}
```

```
ana@laptop:~/aws/traces$ TRACE=$(python3 trace.py); echo "$TRACE"
1-6ad25577-8f4d3e27dda1494c73cf256d
```

O id do trace começa com `1-`, depois a hora da execução em hexadecimal, depois a parte aleatória. O
X-Ray aceita os dois documentos e lista o trace:

```
ana@laptop:~/aws/traces$ aws xray get-trace-summaries --start-time $(date -d '-5 min' +%s) --end-time $(date -d '+1 min' +%s) --query 'TraceSummaries[].[Id,Duration,ResponseTime]' --output text
1-6ad25577-8f4d3e27dda1494c73cf256d	0.0	1.0
```

Uma duração de 0.0 e um tempo de resposta de 1.0 segundo, para uma requisição que levou 512
milissegundos. **O moto guarda os documentos e inventa o resumo**; o X-Ray calcula os dois a partir dos
segmentos. O que ele guarda basta para ler o trace de volta, e um segundo programa curto desenha para
onde foi o tempo:

```python
# waterfall.py TRACE_ID: where the time of one trace went
import json
import sys

import boto3

trace = boto3.client("xray").batch_get_traces(TraceIds=[sys.argv[1]])["Traces"][0]
docs = [json.loads(s["Document"]) for s in trace["Segments"]]
t0 = min(d["start_time"] for d in docs)


def ms(t):
    return round((t - t0) * 1000)


def show(span, depth):
    took = ms(span["end_time"]) - ms(span["start_time"])
    print(f'{"  " * depth}{span["name"]:<{18 - 2 * depth}} at {ms(span["start_time"]):>4} ms  took {took:>4} ms')
    for sub in span.get("subsegments", []):
        show(sub, depth + 1)
        for child in docs:
            if child.get("parent_id") == sub["id"]:
                show(child, depth + 2)


for d in docs:
    if "parent_id" not in d:
        show(d, 0)
```

```
ana@laptop:~/aws/traces$ python3 waterfall.py 1-6ad25577-8f4d3e27dda1494c73cf256d
shop-api           at    0 ms  took  512 ms
  orders-db        at    4 ms  took   27 ms
  payments         at   35 ms  took  470 ms
    payments       at   41 ms  took  457 ms
      card-network at   50 ms  took  420 ms
```

Leia de baixo para cima. O checkout levou 512 ms; o banco respondeu em 27; **a rede de cartões levou
420 dos 512**. Nada nas métricas da própria API diz isso: a latência dela está alta e a CPU, ociosa. O
trace diz que o tempo foi gasto esperando dois serviços adiante, o que é outra conversa, com outra
equipe. Na AWS, o console desenha exatamente esta cascata para qualquer trace, e um **mapa de
serviços** a partir de todos eles: uma caixa por serviço, uma linha por chamada, colorida pelos erros. O
moto não desenha nenhum dos dois.

## O que a instrumentação faz por você

Ninguém escreve segmentos à mão. Um SDK ou um agente em cada serviço cria o segmento quando uma
requisição chega, um subsegmento em volta de cada chamada que ele faz por um cliente instrumentado
(HTTP, o SDK da AWS, um driver de banco), e **propaga o contexto**: acrescenta o id do trace e o id do
trecho atual ao cabeçalho da requisição de saída, e o SDK do próximo serviço os lê e escreve o segmento
dele como filho. As duas variáveis compartilhadas em `trace.py` representam esse cabeçalho.
