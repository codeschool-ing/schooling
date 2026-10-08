---
title: What Airflow is, and what it is not
version: 1
---

Ana has a nightly script that works. What it lacks is everything around it: something that starts
it at two in the morning, runs its steps in the right order, retries the one that failed, remembers
which nights succeeded, and shows somebody what happened. **Apache Airflow is that something.** It
does not move data itself. It runs the programs that do, in an order you declare, on a schedule, and
keeps a record of every attempt.

The unit is a **DAG** — a *directed acyclic graph* of **tasks**. Directed, because each arrow says
*this runs before that*. Acyclic, because no task may wait for itself, however indirectly. A DAG is
declared in a Python file, and each task wraps one piece of work: a shell command, a Python
function, a SQL statement.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-components\" aria-label=\"Airflow's parts. The DAG folder is read by the DAG processor, which stores each DAG in the metadata database. The scheduler reads the database, decides what is due, and hands tasks to the executor, which runs them as processes. The triggerer waits on behalf of waiting tasks. The API server serves the web interface and the API, and also reads and writes the metadata database.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">DAG folder</text><text x=\"95.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/etl/dags/*.py</text><rect x=\"220.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">DAG processor</text><rect x=\"220.0\" y=\"130.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">scheduler</text><rect x=\"420.0\" y=\"130.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">executor</text><rect x=\"580.0\" y=\"130.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">task processes</text><rect x=\"220.0\" y=\"230.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">triggerer</text><rect x=\"410.0\" y=\"30.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><rect x=\"560.0\" y=\"30.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">web interface and API</text><rect x=\"20.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"8\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metadata database</text><text x=\"95.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL: airflow</text><path d=\"M170.0 55.0 L218.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M245.0 82.0 L160.0 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M218.0 155.0 L172.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M370.0 155.0 L418.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M540.0 155.0 L578.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M218.0 250.0 L150.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M530.0 55.0 L558.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M410 70 C 330 110, 230 100, 172 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Four processes and a database. The files are only read; everything Airflow knows about runs and states is in the database."}
```

Airflow 3 runs as four processes and a database:

- the **DAG processor** reads the files in the DAG folder, every few seconds, and stores what each
  DAG looks like;
- the **scheduler** decides which runs are due and which of their tasks are ready, and hands those
  to an **executor** — here `LocalExecutor`, which runs them as processes on the same machine;
- the **triggerer** waits on behalf of tasks that are waiting for something outside, so that a
  waiting task does not occupy a worker — lesson 9's sensors use it;
- the **API server** serves the web interface and the API that tasks and tools talk to;
- the **metadata database** — the `airflow` database in Ana's PostgreSQL — holds every DAG, every
  run, every task's state and every value tasks pass to each other.

`shop airflow` starts the four processes:

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

The triggerer appears twice: it starts a second process of its own. And everything Airflow needs to
know about this machine is in its environment:

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

The DAG folder is `~/etl/dags`, the executor is local, the time zone is São Paulo's, and the
metadata lives in PostgreSQL. `SIMPLE_AUTH_MANAGER_ALL_ADMINS` lets anybody on the machine open the
interface at `http://127.0.0.1:8080` without a password — right for a lab that listens only on the
machine itself, and a setting that must never reach a server anybody else can reach.

## What it is not

Airflow is not a data processing engine. **A task that loads a million rows into Airflow's own
memory to transform them is using the wrong tool**: the work belongs in the database, or in a
program the task starts. Airflow's own database holds states and small values, not data. The DAG
Ana is about to write runs her scripts and nothing else.
