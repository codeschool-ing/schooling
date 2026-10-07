---
title: Prefect: um pipeline é uma função Python
version: 1
---

```
"""The nightly load as a Prefect flow: plain Python functions, called in order."""
import subprocess
import sys

from prefect import flow, task


@task(retries=2, retry_delay_seconds=10)
def load_raw():
    subprocess.run(["python", "load_raw.py"], check=True)


@task
def build_models():
    subprocess.run(["dbt", "build", "--project-dir", "shop", "--quiet"], check=True)


@task
def daily_report(day: str) -> str:
    query = ("COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales "
             f"WHERE order_date = '{day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)")
    csv = subprocess.run(["psql", "-d", "wh", "-c", query], check=True,
                         capture_output=True, text=True).stdout
    path = f"reports/daily_{day}.csv"
    with open(path, "w") as out:
        out.write(csv)
    return path


@flow(log_prints=True)
def nightly(day: str):
    load_raw()
    build_models()
    path = daily_report(day)
    print(f"report written to {path}")


if __name__ == "__main__":
    nightly(sys.argv[1])
```

O pipeline do Prefect é um **flow**, uma função Python com `@flow` em cima, e os passos dele são
**tasks**, funções com `@task`. Não há `>>` nem `requires`: a ordem é a ordem das chamadas, e quando
uma task precisa do resultado de outra ele é simplesmente passado como argumento. O `retries` é uma
configuração da task, como no Airflow. Qualquer coisa que o Python saiba fazer entre as chamadas — um
`if`, um laço pelas lojas — faz parte do flow, que é a principal coisa que o Prefect oferece em
relação a escrever os mesmos passos para o Airflow.

Toda execução é registrada por um servidor do Prefect. Sem nenhum configurado, o Prefect inicia um
temporário durante a execução e o para no fim. Esse servidor também tenta mandar estatísticas de uso
para a internet, que o laboratório não tem; uma configuração desliga isso, e fica salva no profile do
Prefect:

```
ana@vm:~/etl$ prefect config set PREFECT_SERVER_ANALYTICS_ENABLED=false
Set 'PREFECT_SERVER_ANALYTICS_ENABLED' to 'false'.
Updated profile 'ephemeral'.
ana@vm:~/etl$ /opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15
05:49:57.107 | INFO    | prefect - Starting temporary server on http://127.0.0.1:8146
See https://docs.prefect.io/v3/concepts/server#how-to-guides for more information on running a dedicated Prefect server.
05:50:07.106 | INFO    | Flow run 'fiery-sloth' - Beginning flow run 'fiery-sloth' for flow 'nightly'
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5366 rows
raw.orders: 21128 rows
raw.order_lines: 33047 rows
raw.payments: 21128 rows
raw.prices: 0 documents
raw.events: 38837 documents
05:50:07.636 | INFO    | Task run 'load_raw-851' - Finished in state Completed()
05:50:10.976 | INFO    | Task run 'build_models-1e7' - Finished in state Completed()
05:50:10.993 | INFO    | Task run 'daily_report-c31' - Finished in state Completed()
05:50:10.994 | INFO    | Flow run 'fiery-sloth' - report written to reports/daily_2026-03-15.csv
05:50:11.135 | INFO    | Flow run 'fiery-sloth' - Finished in state Completed()
05:50:11.149 | INFO    | prefect - Stopping temporary server on http://127.0.0.1:8146
```

O estado de cada task é registrado quando ela termina, com um nome que o Prefect inventou para a
execução. O `print` dentro do flow também é registrado, por causa do `log_prints=True`. Agora o mesmo
flow, mesmo dia, de novo:

```
ana@vm:~/etl$ /opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15 2>&1 | grep -E "Task run|Flow run"
05:50:18.995 | INFO    | Flow run 'spry-coati' - Beginning flow run 'spry-coati' for flow 'nightly'
05:50:19.520 | INFO    | Task run 'load_raw-64a' - Finished in state Completed()
05:50:23.043 | INFO    | Task run 'build_models-6b4' - Finished in state Completed()
05:50:23.059 | INFO    | Task run 'daily_report-195' - Finished in state Completed()
05:50:23.060 | INFO    | Flow run 'spry-coati' - report written to reports/daily_2026-03-15.csv
05:50:24.023 | INFO    | Flow run 'spry-coati' - Finished in state Completed()
```

**Tudo rodou de novo.** O Prefect não pergunta se o trabalho de uma task já está lá; a execução de um
flow é uma chamada, e chamar uma função duas vezes a roda duas vezes. É a troca oposta à do Luigi:
nenhuma marca pode envelhecer, porque não há nenhuma, e nada é pulado por engano. Mas nada é pulado
de propósito também, e um flow que falhou no último passo repete os primeiros na próxima chamada. O
Prefect consegue fazer **cache** do resultado de uma task sob uma chave, o que traz de volta o pular
quando ele é desejado; esta lição não usa isso.

Agendar um flow — toda noite às 02:00 — é um **deployment**, que precisa de um servidor do Prefect
rodando o tempo todo e de um worker para pegar as execuções. O laboratório não roda nenhum dos dois,
então nenhum é mostrado aqui.
