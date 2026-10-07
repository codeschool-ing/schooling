---
title: O que o Airflow é, e o que não é
version: 1
---

A Ana tem um script noturno que funciona. O que falta a ele é tudo o que fica em volta: algo que o
inicie às duas da manhã, rode os seus passos na ordem certa, tente de novo o que falhou, lembre quais
noites deram certo e mostre a alguém o que aconteceu. **O Apache Airflow é esse algo.** Ele não move
dados sozinho. Ele roda os programas que movem, numa ordem que você declara, num horário, e guarda um
registro de cada tentativa.

A unidade é um **DAG** — um *grafo acíclico dirigido* de **tarefas**. Dirigido, porque cada seta diz
*isto roda antes daquilo*. Acíclico, porque nenhuma tarefa pode esperar por si mesma, nem de forma
indireta. Um DAG é declarado num arquivo Python, e cada tarefa embrulha um pedaço de trabalho: um
comando de shell, uma função Python, um comando SQL.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-components\" aria-label=\"As partes do Airflow. A pasta de DAGs é lida pelo processador de DAGs, que guarda cada DAG no banco de metadados. O agendador lê o banco, decide o que está na hora e entrega as tarefas ao executor, que as roda como processos. O triggerer espera em nome das tarefas que esperam. O servidor da API serve a interface web e a API, e também lê e escreve no banco de metadados.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">pasta de DAGs</text><text x=\"95.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/etl/dags/*.py</text><rect x=\"220.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">processador de DAGs</text><rect x=\"220.0\" y=\"130.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">agendador</text><rect x=\"420.0\" y=\"130.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">executor</text><rect x=\"580.0\" y=\"130.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">processos de tarefa</text><rect x=\"220.0\" y=\"230.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">triggerer</text><rect x=\"410.0\" y=\"30.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">servidor da API</text><rect x=\"560.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">interface web e API</text><rect x=\"20.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"8\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco de metadados</text><text x=\"95.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL: airflow</text><path d=\"M170.0 55.0 L218.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M245.0 82.0 L160.0 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M218.0 155.0 L172.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 155.0 L418.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M540.0 155.0 L578.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M218.0 250.0 L150.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M530.0 55.0 L558.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M410 70 C 330 110, 230 100, 172 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Quatro processos e um banco. Os arquivos são só lidos; tudo o que o Airflow sabe sobre execuções e estados está no banco.", "same": ["executor", "triggerer"]}
```

O Airflow 3 roda como quatro processos e um banco:

- o **processador de DAGs** lê os arquivos da pasta de DAGs, a cada poucos segundos, e guarda o
  formato de cada DAG;
- o **agendador** decide quais execuções estão na hora e quais tarefas delas estão prontas, e as
  entrega a um **executor** — aqui o `LocalExecutor`, que as roda como processos na mesma máquina;
- o **triggerer** espera em nome de tarefas que estão esperando algo de fora, para que uma tarefa em
  espera não ocupe um worker — os sensores da lição 9 o usam;
- o **servidor da API** serve a interface web e a API com que as tarefas e as ferramentas conversam;
- o **banco de metadados** — o banco `airflow` no PostgreSQL da Ana — guarda cada DAG, cada execução,
  o estado de cada tarefa e cada valor que as tarefas passam umas às outras.

O `shop airflow` inicia os quatro processos:

```
ana@vm:~/etl$ sudo shop airflow
ana@vm:~/etl$ pgrep -u ana -fa "bin/airflow [a-z-]*$|airflow api_server"
7622 /opt/etl/airflow/bin/python3 /opt/etl/bin/airflow scheduler
7629 /opt/etl/airflow/bin/python3 /opt/etl/bin/airflow dag-processor
7636 /opt/etl/airflow/bin/python3 /opt/etl/bin/airflow triggerer
7643 airflow api_server -- host:127.0.0.1 port:8080
7702 /opt/etl/airflow/bin/python3 /opt/etl/bin/airflow triggerer
ana@vm:~/etl$ curl -s http://127.0.0.1:8080/api/v2/version; echo
{"version":"3.3.2","git_version":".release:aa19d2dbb9ed187ec01957a92848d9b005e9ba9d"}
```

O triggerer aparece duas vezes: ele inicia um segundo processo próprio. E tudo o que o Airflow
precisa saber sobre esta máquina está no ambiente dele:

```
ana@vm:~/etl$ grep "^AIRFLOW" /etc/etl.env | grep -v -e JWT -e CONN
AIRFLOW_HOME=/home/ana/airflow
AIRFLOW__CORE__DAGS_FOLDER=/home/ana/etl/dags
AIRFLOW__CORE__LOAD_EXAMPLES=False
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__CORE__DEFAULT_TIMEZONE=America/Sao_Paulo
AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=True
AIRFLOW__DAG_PROCESSOR__REFRESH_INTERVAL=10
AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=False
AIRFLOW__API__PORT=8080
AIRFLOW__API__HOST=127.0.0.1
AIRFLOW__LOGGING__COLORED_CONSOLE_LOG=False
```

A pasta de DAGs é `~/etl/dags`, o executor é local, o fuso horário é o de São Paulo, e os metadados
moram no PostgreSQL. O `SIMPLE_AUTH_MANAGER_ALL_ADMINS` deixa qualquer um na máquina abrir a
interface em `http://127.0.0.1:8080` sem senha — certo para um laboratório que só escuta na própria
máquina, e uma configuração que nunca pode chegar a um servidor que outras pessoas alcancem.

## O que ele não é

O Airflow não é um motor de processamento de dados. **Uma tarefa que carrega um milhão de linhas na
memória do próprio Airflow para transformá-las está usando a ferramenta errada**: o trabalho pertence
ao banco, ou a um programa que a tarefa inicia. O banco do próprio Airflow guarda estados e valores
pequenos, não dados. O DAG que a Ana vai escrever roda os scripts dela e nada mais.
