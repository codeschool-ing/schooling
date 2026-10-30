---
title: As partes do Airflow, e o que o Composer roda por você
version: 1
---

**O Airflow não é um executor de jobs; é um agendador dos jobs dos outros.** Um pipeline no Airflow
é um **DAG**, um grafo acíclico dirigido de tarefas escrito como arquivo Python. Uma tarefa
costuma ser uma chamada a outra coisa: submeter um batch Spark ao Dataproc, rodar uma consulta no
BigQuery, esperar um objeto chegar num bucket. O Airflow decide quando cada tarefa pode começar, a
inicia, acompanha, tenta de novo quando ela falha e lembra o que aconteceu. O trabalho pesado
acontece nos serviços que ele chama, e é por isso que um Airflow pequeno orquestra uma plataforma de
dados grande.

Cinco partes fazem um Airflow, e todas precisam estar rodando para qualquer coisa funcionar:

- o **scheduler** descobre quais tarefas estão na hora e as entrega aos workers. É a parte que
  precisa estar acordada às três da manhã;
- o **DAG processor** lê os arquivos de DAG e transforma cada um na estrutura a partir da qual o
  scheduler planeja. O Airflow 3 o roda como processo próprio, onde o Airflow 2 o rodava dentro do
  scheduler;
- os **workers** rodam as tarefas. No executor Celery, que o Composer usa, eles são processos
  separados que pegam tarefas de uma fila, e o número deles pode crescer e diminuir;
- o **servidor web**, que o Airflow 3 chama de API server, é a interface onde as pessoas veem
  execuções, leem logs e limpam uma tarefa que falhou para rodá-la de novo, e o endereço para o qual
  uma tarefa em execução informa o próprio estado;
- o **banco de metadados** guarda o estado de cada execução de DAG e de cada instância de tarefa, e
  é o que o scheduler lê para decidir o que está na hora. Perca-o e o Airflow esquece a própria
  história.

E há a **pasta de DAGs**, onde ficam os arquivos Python, que todas as partes leem.

**O Cloud Composer é todas elas, operadas pelo Google, com a pasta de DAGs num bucket.** Você cria
um *ambiente* numa região, e o Google roda o scheduler, o DAG processor, o triggerer, o servidor web
e os workers num cluster Kubernetes, e o banco de metadados no Cloud SQL. No Composer 3, a geração
atual, os dois ficam num projeto do Google, longe da sua vista. O que você vê é um bucket do Cloud
Storage que o ambiente cria para si, com uma pasta `dags/` para os arquivos de DAG, uma pasta
`data/` e uma pasta `logs/` onde cai o log de cada tarefa, além da lista de pacotes Python de que as
tarefas precisam, que você define no ambiente. A página de preços do Google, lida em 2026-10-30,
chama o produto de *Managed Service for Apache Airflow*; a linha de comando continua dizendo
`gcloud composer`, e esta aula também.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas bordas tracejadas. À esquerda, um ambiente Composer 3 no projeto do Google tem quatro partes: o scheduler, que decide o que está na hora; o API server, para execuções, logs e novas tentativas; os workers, um mínimo e dois extras que vêm e vão com a carga, que rodam as tarefas; e o banco de metadados no Cloud SQL, que registra cada execução de DAG e de tarefa. À direita, o seu projeto tem o bucket do ambiente, criado com ele, com dags/quitanda_nightly.py e logs/, e os serviços onde o trabalho roda, Dataproc e BigQuery, cobrados à parte. Uma seta vai do bucket ao scheduler, e outra dos workers ao Dataproc e ao BigQuery.\" data-fig=\"l24-parts\"><defs><marker id=\"ah-l24-parts\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ambiente Composer 3, no projeto do Google</text><rect x=\"230\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">scheduler</text><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decide o que está na hora</text><rect x=\"40\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">API server</text><text x=\"125\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">execuções, logs, novas tentativas</text><rect x=\"230\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">workers</text><rect x=\"245\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"295\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"345\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">mín.</text><text x=\"315\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"365\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"315\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodam as tarefas; os extras</text><text x=\"315\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vêm e vão com a carga</text><rect x=\"40\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">banco de metadados</text><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud SQL: cada execução</text><text x=\"125\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de DAG e de tarefa</text><rect x=\"450\" y=\"20\" width=\"255\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o seu projeto</text><rect x=\"465\" y=\"60\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o bucket do ambiente</text><text x=\"577\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dags/quitanda_nightly.py</text><text x=\"577\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">logs/</text><text x=\"577\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">criado com o ambiente</text><rect x=\"465\" y=\"170\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Dataproc, BigQuery</text><text x=\"577\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">onde o trabalho roda,</text><text x=\"577\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cobrado à parte</text><line x1=\"463\" y1=\"88\" x2=\"402\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-parts)\"></line><line x1=\"402\" y1=\"215\" x2=\"463\" y2=\"215\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-parts)\"></line></svg>", "caption": "O Composer roda as partes do Airflow longe da vista; você fica com o bucket, e o trabalho acontece nos serviços que as tarefas chamam.", "same": ["scheduler", "workers", "extra", "API server", "Dataproc, BigQuery"]}
```

## Um DAG, como a Quitanda o escreveria

O pipeline noturno da Quitanda é o trabalho da aula 23, em ordem: gerar a exportação de pedidos da
noite, rodar o job Spark sobre ela, conferir o resultado e publicá-lo no bucket curated. Como DAG do
Airflow ele é o arquivo abaixo. **Ele roda no seu notebook na próxima seção**, com cada tarefa sendo
um comando que a aula 23 já rodou, para que o Airflow seja de verdade e nada nele precise do Google.
Salve-o como `quitanda_nightly.py`:

```schooling-example
{"language": "python", "file": "quitanda_nightly.py", "parts": [{"code": "from pathlib import Path\n\nimport pendulum\nfrom airflow.providers.standard.operators.bash import BashOperator\nfrom airflow.sdk import DAG\n\n", "note": "O `DAG` vem de `airflow.sdk`, o módulo contra o qual o Airflow 3 escreve DAGs. O `BashOperator` vem do provider standard, que vem instalado com o próprio Airflow."}, {"code": "DAY = '{{ macros.ds_add(ds, -1) }}'\n\n", "note": "**O dia sobre o qual a execução trabalha: o dia anterior àquele em que ela roda.** `ds` é a data da logical date da execução, e no agendamento cron padrão do Airflow 3 essa é a noite em que a execução acontece, então a execução das 3 da manhã do dia 30 tem `ds` 2026-10-30 e precisa processar o 29. A seção sobre agendamento mostra isso."}, {"code": "with DAG(\n    dag_id='quitanda_nightly',\n    schedule='0 3 * * *',\n    start_date=pendulum.datetime(2026, 10, 26, tz='America/Sao_Paulo'),\n    catchup=False,\n    default_args={'retries': 2, 'retry_delay': pendulum.duration(minutes=5),\n                  'cwd': str(Path.home() / 'gcp')},\n) as dag:\n", "note": "**O DAG em si.** Uma expressão cron para as três da manhã, no horário de São Paulo porque a data de início carrega esse fuso, e `catchup=False`, para que o Airflow não rode todas as noites desde 26 de outubro assim que o arquivo aparece. Toda tarefa herda duas novas tentativas com cinco minutos de intervalo, e roda em `~/gcp`."}, {"code": "    export = BashOperator(task_id='export_orders',\n                          bash_command=f'python3 make_orders.py {DAY}')\n    daily = BashOperator(task_id='daily_orders',\n                         bash_command=f\"spark-submit --master 'local[2]' daily_orders.py --dt {DAY} 2> spark.log\")\n    check = BashOperator(task_id='check',\n                         bash_command=f'python3 check_daily.py {DAY}')\n    publish = BashOperator(task_id='publish',\n                           bash_command=f'gcloud storage cp curated/daily_orders/dt={DAY}/* '\n                                        f'gs://quitanda-curated-prod/daily_orders/dt={DAY}/')\n", "note": "Quatro tarefas, cada uma um comando da aula 23: gerar a exportação do dia, rodar o job Spark sobre ela, conferir o resultado com o DuckDB e copiá-lo para o bucket curated. O Airflow preenche o `{DAY}` quando a tarefa roda, porque ele é um template."}, {"code": "    export >> daily >> check >> publish\n", "note": "As dependências: cada tarefa começa quando a anterior deu certo, e não antes. Uma checagem que falha impede a publicação, e é para isso que ela existe."}]}
```

**Leia o arquivo como uma descrição, não como um programa que faz o trabalho.** Rodá-lo cria quatro operadores e três setas, e nada mais. O scheduler lê essa descrição da pasta de DAGs e, às três da
manhã, cria uma *execução de DAG* para a noite e *instâncias de tarefa* para as quatro tarefas, cada
uma rodada por um worker quando as setas permitem. O `{DAY}` de cada comando é renderizado só para
aquela execução, e é isso que deixa o mesmo arquivo rodar toda noite, e rodar de novo qualquer noite
do passado, com a data certa.

## O mesmo DAG, no Composer

No Composer, as tarefas não seriam comandos de shell num notebook. **A exportação é um objeto que
chega num bucket, e o job Spark é um batch do Dataproc Serverless**, e o provider do Google para o
Airflow tem um operador ou um sensor para cada um. As duas tarefas que mudariam, **não rodadas
aqui**, porque o provider é um pacote grande e não tem Google para chamar:

```python
from airflow.providers.google.cloud.operators.dataproc import DataprocCreateBatchOperator
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor

export = GCSObjectExistenceSensor(
    task_id='export_orders',
    bucket='quitanda-raw-prod',
    object=f'raw/orders/dt={DAY}/orders.csv',
)
daily = DataprocCreateBatchOperator(
    task_id='daily_orders',
    project_id='planner-dev',
    region='southamerica-east1',
    batch_id=f'daily-orders-{DAY}',
    batch={'pyspark_batch': {
        'main_python_file_uri': 'gs://quitanda-raw-prod/jobs/daily_orders.py',
        'args': ['--dt', DAY, '--src', 'gs://quitanda-raw-prod/raw',
                 '--dst', 'gs://quitanda-curated-prod'],
    }},
)
```

**O sensor espera; o operador submete e espera.** O `GCSObjectExistenceSensor` procura o arquivo da
noite até ele aparecer, então o pipeline começa quando a exportação da loja chegou, e não num horário
em que alguém torcia para ela ter chegado. O `DataprocCreateBatchOperator` submete o batch da aula 23
e espera ele terminar, falhando a tarefa se o batch falhar. As setas, as novas tentativas e o `{DAY}`
são os mesmos do arquivo acima, e esse é o motivo de escrever o pipeline assim: o grafo e as datas
são do Airflow, e o trabalho é de outro.
