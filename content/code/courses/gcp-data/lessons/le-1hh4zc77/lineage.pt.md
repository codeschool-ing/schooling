---
title: A linhagem, e o evento que um job manda
version: 1
---

**Linhagem é o registro de que job fez que dado a partir de que outro dado.** Ela responde às duas
perguntas que vêm depois de todo incidente. A montante: a exportação de finanças de 1º de outubro está
errada, então de onde vieram os números dela? A jusante: o arquivo bruto de pedidos de 1º de outubro
foi carregado duas vezes, então que tabelas e exportações herdaram o dobro? Sem linhagem as duas se
respondem lendo o código de cada job, o que é lento num dia bom e impossível no dia em que importa.

**Um grafo de linhagem tem dois tipos de nó e um tipo de aresta.** Datasets são os substantivos, uma
tabela ou um arquivo; jobs são os verbos, o processo que leu alguns datasets e escreveu outros; e uma
aresta diz que uma execução de um job leu isto e escreveu aquilo. A Data Lineage API do Google guarda
três recursos que correspondem a isso: um **processo** é o job, uma **execução** (run) é uma vez em que
ele rodou, e um **evento de linhagem** registra as ligações de origens para destinos que uma execução
fez.

## De onde vêm os eventos

**Parte do Google Cloud informa a linhagem sozinha.** Com a Data Lineage API ligada num projeto, o
BigQuery registra um evento de linhagem para cada job de consulta que escreve uma tabela, um `CREATE
TABLE … AS SELECT` ou um `INSERT … SELECT`. A documentação lista outros serviços que fazem o mesmo
com seus jobs, entre eles o Dataproc, o Cloud Composer e o Dataflow. Nada no código do job muda. A
página de preços chama isso de **análise automática de linhagem** e cobra como processamento premium,
porque o Google gasta computação lendo os jobs para achar as ligações.

**Todo o resto informa a própria, em OpenLineage.** OpenLineage é um padrão aberto, um projeto da
Linux Foundation, feito exatamente para isso: um evento JSON que um job manda quando começa, termina
ou falha, nomeando o job, a execução, e os datasets de entrada e de saída. A Data Lineage API aceita
esses eventos por um método chamado `ProcessOpenLineageRunEvent`, e a página de preços diz que a
linhagem informada desse jeito, que ela chama de personalizada, é grátis, assim como consultar a
linhagem de volta.

## Os eventos do pipeline noturno da Quitanda

Três jobs rodam toda noite. `load_orders` lê o CSV bruto de `quitanda-raw-prod` para a tabela
`curated.orders` do BigQuery; `daily_revenue` junta `curated.orders` com `curated.customers` em
`curated.daily_revenue`; `export_finance` grava essa tabela como um CSV em `quitanda-curated-prod`
para o time de finanças. Este programa escreve o evento que cada job mandaria ao terminar, como
arquivos, porque aqui não há para onde mandá-los. Salve como `~/gcp/emit.py`:

```schooling-example
{"language": "python", "file": "emit.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Write the OpenLineage run events of Quitanda's nightly pipeline into ./events, one file each.\n\n    python3 emit.py 2026-10-01\n\nNothing is sent anywhere: these are the events a job would send to a lineage service.\n\"\"\"\nimport json\nimport pathlib\nimport sys\nimport uuid\n\n", "note": "Ele escreve eventos e não manda nada. Um job de verdade mandaria cada um no momento em que terminasse, para um serviço de linhagem."}, {"code": "day = sys.argv[1]\nRAW = ('gs://quitanda-raw-prod', f'raw/orders/dt={day}/orders.csv')\nORDERS = ('bigquery', 'planner-dev.curated.orders')\nCUSTOMERS = ('bigquery', 'planner-dev.curated.customers')\nREVENUE = ('bigquery', 'planner-dev.curated.daily_revenue')\nEXPORT = ('gs://quitanda-curated-prod', f'finance/revenue/dt={day}/revenue.csv')\n", "note": "**Todo dataset é um par, um namespace e um nome**, na convenção do OpenLineage: `bigquery` e o nome completo da tabela, ou um bucket e o caminho de um objeto. O dia faz parte dos nomes dos arquivos, então os arquivos de cada noite são datasets diferentes."}, {"code": "JOBS = [\n    ('load_orders', [RAW], [ORDERS]),\n    ('daily_revenue', [ORDERS, CUSTOMERS], [REVENUE]),\n    ('export_finance', [REVENUE], [EXPORT]),\n]\n\n", "note": "Os três jobs, com o que cada um lê e escreve. O `daily_revenue` lê duas tabelas."}, {"code": "out = pathlib.Path('events')\nout.mkdir(exist_ok=True)\nfor n, (job, inputs, outputs) in enumerate(JOBS, start=1):\n", "note": "Um arquivo por evento, numerados na ordem em que os jobs rodam."}, {"code": "    event = {\n        'eventType': 'COMPLETE',\n        'eventTime': f'{day}T03:{10 * n:02d}:00-03:00',\n        'run': {'runId': str(uuid.uuid5(uuid.NAMESPACE_URL, f'{job}/{day}'))},\n        'job': {'namespace': 'quitanda-nightly', 'name': job},\n        'inputs': [{'namespace': ns, 'name': name} for ns, name in inputs],\n        'outputs': [{'namespace': ns, 'name': name} for ns, name in outputs],\n        'producer': 'https://example.com/quitanda/emit.py',\n        'schemaURL': 'https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent',\n    }\n", "note": "**O evento.** `COMPLETE` é mandado quando uma execução dá certo; um job também manda `START` antes e `FAIL` se falha. O id da execução é derivado do job e do dia, então a mesma noite tem sempre o mesmo id, e `schemaURL` nomeia a versão do padrão que o evento segue."}, {"code": "    path = out / f'{day}-{n}-{job}.json'\n    path.write_text(json.dumps(event, indent=2) + '\\n')\n    print(path)\n", "note": "Cada evento vai para o próprio arquivo, e o programa imprime o nome."}]}
```

```
ana@laptop:~/gcp$ python3 emit.py 2026-10-01
events/2026-10-01-1-load_orders.json
events/2026-10-01-2-daily_revenue.json
events/2026-10-01-3-export_finance.json
ana@laptop:~/gcp$ cat events/2026-10-01-2-daily_revenue.json
{
  "eventType": "COMPLETE",
  "eventTime": "2026-10-01T03:20:00-03:00",
  "run": {
    "runId": "d33d71e8-fc3d-5c58-aaa2-cad1a5d473b0"
  },
  "job": {
    "namespace": "quitanda-nightly",
    "name": "daily_revenue"
  },
  "inputs": [
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.orders"
    },
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.customers"
    }
  ],
  "outputs": [
    {
      "namespace": "bigquery",
      "name": "planner-dev.curated.daily_revenue"
    }
  ],
  "producer": "https://example.com/quitanda/emit.py",
  "schemaURL": "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent"
}
```

**Isso é um evento de execução do OpenLineage, inteiro.** `job` é o processo, `run.runId` a execução,
e `inputs` e `outputs` os datasets, cada um nomeado por um `namespace` e um `name`. O namespace diz em
que tipo de armazenamento o nome mora, e a forma de nomear é a convenção do padrão: `bigquery` com
`projeto.dataset.tabela`, e um bucket como `gs://bucket` com o caminho do objeto como nome. **Os nomes
são a junção inteira.** Dois jobs só concordam que mexeram na mesma tabela se a escrevem igualzinho,
então um job que escrevesse `planner-dev:curated.orders` com dois-pontos começaria um segundo nó,
desconectado, e o grafo teria uma quebra que ninguém vê.

## O grafo, montado a partir dos eventos

**O que vem a seguir é um modelo da ideia, não a Data Lineage API**: um programa que lê os arquivos de
eventos, fica com as execuções concluídas, transforma cada par de entrada e saída numa aresta, e
percorre as arestas nos dois sentidos. Salve como `~/gcp/edges.py`:

```schooling-example
{"language": "python", "file": "edges.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read OpenLineage run events and answer two questions a lineage service answers.\n\n    python3 edges.py                      # every edge: input -> output, through which job\n    python3 edges.py upstream DATASET     # everything DATASET was made from\n    python3 edges.py downstream DATASET   # everything made from DATASET\n\nA MODEL OF THE IDEA, NOT THE DATA LINEAGE API: a graph built from files in ./events.\n\"\"\"\nimport json\nimport pathlib\nimport sys\n\n", "note": "**Um modelo do serviço, e a docstring diz isso.** Ele responde às duas buscas de que um incidente precisa, a partir de arquivos de eventos em vez de uma API."}, {"code": "def fqn(dataset):\n    return f\"{dataset['namespace']}/{dataset['name']}\"\n\n", "note": "O nome completo de um dataset é o namespace e o nome juntos, `bigquery/planner-dev.curated.orders`, e é isso que faz dois eventos sobre a mesma tabela se encontrarem."}, {"code": "edges = set()\nfor path in sorted(pathlib.Path('events').glob('*.json')):\n    event = json.loads(path.read_text())\n    if event['eventType'] != 'COMPLETE':\n        continue\n    job = f\"{event['job']['namespace']}.{event['job']['name']}\"\n    for source in event['inputs']:\n        for target in event['outputs']:\n            edges.add((fqn(source), job, fqn(target)))\n\n", "note": "**Toda execução concluída transforma cada par de uma entrada e uma saída numa aresta**, marcada com o job. Uma execução que só começou, ou falhou, não desenha nada."}, {"code": "if len(sys.argv) < 3:\n    for source, job, target in sorted(edges, key=lambda e: e[1]):\n        print(f'{source}\\n    --[{job}]--> {target}')\n    sys.exit()\n\n", "note": "Sem argumentos ele imprime todas as arestas, agrupadas por job."}, {"code": "direction, start = sys.argv[1], sys.argv[2]\nseen, todo = set(), [start]\nwhile todo:\n    here = todo.pop()\n    for source, job, target in sorted(edges):\n        near, far = (target, source) if direction == 'upstream' else (source, target)\n        if near == here and far not in seen:\n            seen.add(far)\n            todo.append(far)\n            print(f'{far}  (via {job})')\n", "note": "**A busca**: a partir de um dataset, seguir as arestas para trás em `upstream` ou para a frente em `downstream`, até não achar nada novo. O `seen` impede que ela ande em círculo, o que um pipeline que lê a própria saída teria."}]}
```

```
ana@laptop:~/gcp$ python3 edges.py
bigquery/planner-dev.curated.customers
    --[quitanda-nightly.daily_revenue]--> bigquery/planner-dev.curated.daily_revenue
bigquery/planner-dev.curated.orders
    --[quitanda-nightly.daily_revenue]--> bigquery/planner-dev.curated.daily_revenue
bigquery/planner-dev.curated.daily_revenue
    --[quitanda-nightly.export_finance]--> gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv
gs://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv
    --[quitanda-nightly.load_orders]--> bigquery/planner-dev.curated.orders
ana@laptop:~/gcp$ python3 edges.py upstream gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv
bigquery/planner-dev.curated.daily_revenue  (via quitanda-nightly.export_finance)
bigquery/planner-dev.curated.customers  (via quitanda-nightly.daily_revenue)
bigquery/planner-dev.curated.orders  (via quitanda-nightly.daily_revenue)
gs://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv  (via quitanda-nightly.load_orders)
ana@laptop:~/gcp$ python3 edges.py downstream bigquery/planner-dev.curated.customers
bigquery/planner-dev.curated.daily_revenue  (via quitanda-nightly.daily_revenue)
gs://quitanda-curated-prod/finance/revenue/dt=2026-10-01/revenue.csv  (via quitanda-nightly.export_finance)
```

**Quatro arestas a partir de três eventos**, porque `daily_revenue` leu duas tabelas e por isso
desenhou duas. A busca a montante a partir da exportação de finanças voltou por todos os jobs até o
CSV bruto e até a tabela de clientes, que é a primeira pergunta do incidente respondida numa linha. A
busca a jusante a partir de `curated.customers` achou as duas coisas que uma tabela de clientes ruim
estragaria. O serviço de verdade desenha o mesmo grafo no console, para tabelas e, a partir do
BigQuery, também para algumas colunas, e a API dele responde às mesmas duas buscas com uma pesquisa
pelas ligações que entram num dataset ou saem dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Linhagem do pipeline noturno. O CSV bruto de pedidos em quitanda-raw-prod alimenta o job load_orders, que escreve curated.orders. curated.orders e curated.customers alimentam o job daily_revenue, que escreve curated.daily_revenue. Ele alimenta o job export_finance, que escreve o CSV de finanças em quitanda-curated-prod.\" data-fig=\"g26-graph\"><defs><marker id=\"g26-graph-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"16\" y=\"40\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">gs://quitanda-raw-prod</text><text x=\"26\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">raw/orders/…/orders.csv</text><rect x=\"16\" y=\"110\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"76\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">load_orders</text><line x1=\"76\" y1=\"80\" x2=\"76\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"16\" y=\"160\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"26\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.orders</text><line x1=\"76\" y1=\"136\" x2=\"76\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"16\" y=\"230\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"26\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"26\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.customers</text><rect x=\"290\" y=\"190\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"350\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">daily_revenue</text><line x1=\"216\" y1=\"180\" x2=\"288\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><line x1=\"216\" y1=\"250\" x2=\"288\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"260\" y=\"260\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"270\" y=\"273\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bigquery</text><text x=\"270\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curated.daily_revenue</text><line x1=\"350\" y1=\"216\" x2=\"350\" y2=\"258\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"500\" y=\"190\" width=\"120\" height=\"26\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"560\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">export_finance</text><line x1=\"440\" y1=\"280\" x2=\"498\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><rect x=\"484\" y=\"110\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"494\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">gs://quitanda-curated-prod</text><text x=\"494\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">finance/revenue/…/revenue.csv</text><line x1=\"560\" y1=\"188\" x2=\"560\" y2=\"152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#g26-graph-ah)\"/><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a linhagem do pipeline noturno, a partir de três eventos</text><rect x=\"484\" y=\"260\" width=\"10\" height=\"10\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"500\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dataset</text><rect x=\"484\" y=\"282\" width=\"10\" height=\"10\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"500\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">job</text></svg>", "caption": "O grafo que o edges.py monta, desenhado: datasets como caixas, jobs entre eles. O serviço de verdade desenha a mesma forma a partir dos mesmos eventos.", "same": ["dataset", "job"]}
```

**Mandar um evento para o Google é uma requisição**, mostrada e não executada; ela precisaria de um
projeto de verdade, da API ligada e de credenciais que este curso nunca tem:

```sh
curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @events/2026-10-01-2-daily_revenue.json \
  "https://datalineage.googleapis.com/v1/projects/planner-dev/locations/southamerica-east1:processOpenLineageRunEvent"
```

**A linhagem só é tão completa quanto os jobs que a informam.** Um script que alguém roda à mão num
laptop, ou um job escrito antes de alguém pensar em linhagem, não desenha aresta nenhuma, e o grafo
mostra uma tabela surgindo do nada. A busca a montante então para cedo e parece terminada. A regra que
mantém o grafo honesto é a mesma que este curso mantém para todo o resto: todo job que escreve dados
diz o que leu.
