---
title: As partes do Airflow, e o que o MWAA roda por você
version: 1
---

**O Airflow não é um executor de jobs; é um agendador dos jobs dos outros.** Um pipeline no Airflow
é uma **DAG**, um grafo acíclico dirigido de tarefas escrito como arquivo Python. Uma tarefa costuma ser uma chamada a
outra coisa: ligar um job do Glue, rodar uma consulta no Athena, submeter
um step ao EMR, esperar um arquivo chegar ao S3. O Airflow decide quando cada tarefa pode começar,
começa, acompanha, tenta de novo quando ela falha e lembra o que aconteceu. O trabalho pesado
acontece nos serviços que ele chama, e é por isso que um Airflow pequeno consegue orquestrar uma
plataforma de dados grande.

Cinco partes formam um Airflow, e as cinco precisam estar rodando para qualquer coisa funcionar:

- o **scheduler** lê os arquivos das DAGs, calcula quais tarefas estão na hora e as entrega aos
  workers. É a parte que precisa estar de pé às três da manhã;
- os **workers** rodam as tarefas. Com o executor Celery, que o MWAA usa, eles são máquinas separadas
  que pegam tarefas de uma fila, e a quantidade deles pode crescer e diminuir;
- o **servidor web** é a interface onde as pessoas olham as execuções, leem logs e limpam uma tarefa
  que falhou para rodá-la de novo;
- o **banco de metadados** guarda o estado de toda execução de DAG e de toda instância de tarefa, e é
  o que o scheduler lê para decidir o que está na hora. Perca-o e o Airflow esquece a própria
  história;
- a **pasta de DAGs** é onde ficam os arquivos Python, e todas as partes a leem.

**O MWAA são as cinco, operadas pela AWS, com a pasta de DAGs no S3.** Você cria um *ambiente*,
entrega a ele um bucket, duas sub-redes privadas da sua VPC e um papel, e a AWS roda o scheduler, o
servidor web, os workers e o banco na conta dela, longe da sua vista. Você nunca vê as máquinas nem o
banco. O que você vê é o bucket, onde põe as DAGs, um `requirements.txt` com os pacotes Python de que
as tarefas precisam, e os logs que ele escreve no CloudWatch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas bordas tracejadas. À esquerda, um ambiente MWAA na conta da AWS tem quatro partes: o scheduler, que decide o que está na hora; o servidor web, para execuções, logs e novas tentativas; os workers, um base e dois extras que vêm e vão com a carga, que rodam as tarefas; e o banco de metadados, que registra cada execução de DAG e cada instância de tarefa. À direita, a sua conta tem o bucket s3://quitanda-airflow-prod com dags/nightly_orders.py e requirements.txt, versionado e não público, e os serviços onde o trabalho roda, Glue, EMR e Athena, cobrados à parte. Uma seta vai do bucket ao scheduler, e outra dos workers ao Glue, EMR e Athena.\" data-fig=\"l25-parts\"><defs><marker id=\"ah-l25-parts\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ambiente MWAA, na conta da AWS</text><rect x=\"230\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">scheduler</text><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decide o que está na hora</text><rect x=\"40\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">servidor web</text><text x=\"125\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">execuções, logs, novas tentativas</text><rect x=\"230\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">workers</text><rect x=\"245\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"295\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"345\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">base</text><text x=\"315\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"365\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"315\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodam as tarefas; os extras</text><text x=\"315\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vêm e vão com a carga</text><rect x=\"40\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">banco de metadados</text><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada execução de DAG e</text><text x=\"125\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada instância de tarefa</text><rect x=\"450\" y=\"20\" width=\"255\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a sua conta</text><rect x=\"465\" y=\"60\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">s3://quitanda-airflow-prod</text><text x=\"577\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dags/nightly_orders.py</text><text x=\"577\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">requirements.txt</text><text x=\"577\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versionado, não público</text><rect x=\"465\" y=\"170\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Glue, EMR, Athena</text><text x=\"577\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">onde o trabalho roda,</text><text x=\"577\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cobrado à parte</text><line x1=\"463\" y1=\"88\" x2=\"402\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25-parts)\"></line><line x1=\"402\" y1=\"215\" x2=\"463\" y2=\"215\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25-parts)\"></line></svg>", "caption": "O MWAA roda as cinco partes do Airflow longe da sua vista; você fica com a pasta de DAGs, e o trabalho acontece nos serviços que as tarefas chamam.", "same": ["Glue, EMR, Athena", "base", "extra", "scheduler", "workers"]}
```

## Uma DAG, como a Quitanda a escreveria

O pipeline noturno da Quitanda são dois jobs do Glue: carregar os pedidos do dia, depois montar a
tabela diária a partir deles. Como DAG do Airflow, é o arquivo abaixo. **Ele não roda neste
laboratório**, que não tem Airflow e, como mostra a próxima seção, também não tem MWAA; ele aparece
porque o arquivo é o que uma equipe escreve, e a seção seguinte escreve o mesmo pipeline para o Step
Functions.

```schooling-example
{"language": "python", "file": "nightly_orders.py", "parts": [{"code": "from datetime import datetime, timedelta\n\nfrom airflow import DAG\nfrom airflow.providers.amazon.aws.operators.glue import GlueJobOperator\n\n", "note": "`GlueJobOperator` vem do provider da Amazon para o Airflow, o pacote de operadores que chamam serviços da AWS. Os ambientes do MWAA já vêm com ele instalado."}, {"code": "with DAG(\n    dag_id='quitanda_nightly',\n    schedule='0 3 * * *',\n    start_date=datetime(2026, 10, 1),\n    catchup=False,\n    default_args={'retries': 2, 'retry_delay': timedelta(minutes=5)},\n) as dag:\n", "note": "**A DAG em si.** Uma expressão cron para as três da manhã, a data a partir da qual o agendamento começa, e `catchup=False`, para que o Airflow não rode todas as noites desde 1º de outubro no momento em que o arquivo aparece. Toda tarefa herda duas novas tentativas, com cinco minutos entre elas."}, {"code": "    load = GlueJobOperator(\n        task_id='load_orders',\n        job_name='load-orders',\n        script_args={'--dt': '{{ ds }}'},\n    )\n    daily = GlueJobOperator(\n        task_id='build_daily',\n        job_name='build-daily',\n        script_args={'--dt': '{{ ds }}'},\n    )\n", "note": "Duas tarefas, cada uma ligando um job do Glue e esperando que ele termine. `{{ ds }}` é preenchido pelo Airflow com a data do intervalo que a execução cobre: a execução das três da manhã do dia 16 cobre o dia 15, que é exatamente a partição que o job deve ler."}, {"code": "    load >> daily\n", "note": "A única dependência: `build_daily` começa quando `load_orders` deu certo, e não antes."}]}
```

**`{{ ds }}` é o detalhe que mostra para que serve o Airflow.** O Airflow pensa em intervalos: toda
execução cobre um trecho de tempo, sabe qual é e pode ser rodada de novo para ele. Limpe a execução
de 12 de outubro no servidor web e ela roda de novo com `ds` igual a `2026-10-12`; ponha
`catchup=True` e uma DAG nova preenche todos os intervalos desde a data de início. Isso se chama
**backfill**, e é a primeira coisa de que as equipes sentem falta quando saem do Airflow, porque
nada mais nesta lição sabe o que quer dizer "a execução do dia 12".

## A pasta de DAGs é um bucket que dá para montar aqui

O bucket é S3 comum, e o moto o guarda fielmente. Com o moto rodando no terminal dele e as quatro
linhas de "Seu laboratório, em resumo" da lição 1 digitadas neste, salve a DAG acima como
`nightly_orders.py` e dê a ela o bucket que o MWAA leria:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-airflow-prod
make_bucket: quitanda-airflow-prod
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-airflow-prod --versioning-configuration Status=Enabled
ana@laptop:~/aws$ aws s3 cp nightly_orders.py s3://quitanda-airflow-prod/dags/nightly_orders.py
upload: ./nightly_orders.py to s3://quitanda-airflow-prod/dags/nightly_orders.py
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-airflow-prod --query "Versions[].[Key,IsLatest]" --output text
dags/nightly_orders.py	True
```

**O MWAA recusa um bucket sem versionamento**, e é por isso que o segundo comando o liga: o ambiente
registra qual versão de cada arquivo carregou, e um bucket que não sabe responder isso não pode ser
a pasta de DAGs dele. Ele também pede Block Public Access no bucket, a configuração de que trata a
lição 4. Na AWS o scheduler pegaria o arquivo novo na próxima passada pela pasta e desenharia a DAG
no servidor web; aqui o arquivo está no bucket e nada o lê.
