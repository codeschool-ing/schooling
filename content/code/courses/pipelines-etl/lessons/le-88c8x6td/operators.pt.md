---
title: Operadores, hooks e conexões
version: 1
---

Cada tarefa é uma instância de um **operador**: uma classe que sabe fazer um tipo de trabalho. O
`BashOperator` roda um comando de shell; o `@task` transforma uma função Python num
`PythonOperator`; e os providers acrescentam centenas de outros — o `SQLExecuteQueryOperator` roda
SQL contra qualquer banco para o qual o Airflow tenha uma conexão, e há operadores para o
armazenamento, o warehouse e a fila de cada nuvem.

**Escolher um operador é escolher onde o trabalho acontece.** As tarefas da Ana são todas
`BashOperator` chamando os scripts dela, de propósito: os scripts rodam do mesmo jeito no terminal
dela, no `nightly.sh` e no Airflow, então uma tarefa que falha pode ser rodada de novo à mão com o
mesmo comando e o mesmo resultado. Um operador que esconde o trabalho dentro do Airflow é mais difícil
de rodar em qualquer outro lugar.

## Templates, e por que `sh run_sql.sh` falhou

Alguns argumentos de um operador são **templates**: antes de a tarefa rodar, o Airflow os interpreta
como templates Jinja, então `{{ ds }}` vira a data da execução e `{{ ti.xcom_pull(...) }}` vira a
resposta de outra tarefa. O `bash_command` é um deles, e tem mais uma regra: **um valor que termina
em `.sh` ou `.bash` é tomado como o nome de um arquivo de template**, que o Airflow carrega da pasta do
DAG e interpreta. Isso existe para scripts longos guardados ao lado do DAG. `sh run_sql.sh` termina
em `.sh`, então o Airflow foi procurar um arquivo chamado `sh run_sql.sh` em `~/etl/dags`, não achou
nenhum, e falhou antes de rodar qualquer coisa.

A correção que a própria documentação do Airflow dá é um espaço no fim, para que o valor deixe de
terminar em `.sh`:

```
"""Ponto Final's nightly load: the shop into raw, staging rebuilt, the marts loaded."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"),
    catchup=False,
    tags=["shop"],
)
def shop_nightly():
    @task
    def day_to_load(logical_date=None) -> str:
        """The run at 02:00 loads the day that has just ended, in São Paulo."""
        return logical_date.in_timezone("America/Sao_Paulo").subtract(days=1).to_date_string()

    day = day_to_load()
    extract = BashOperator(task_id="extract", bash_command="python load_raw.py", cwd=ETL)
    # The space after run_sql.sh is deliberate: a command ending in ".sh" is read
    # as the name of a template file to load, and fails before it runs.
    transform = BashOperator(task_id="transform", bash_command="sh run_sql.sh ", cwd=ETL)
    dim_customer = BashOperator(task_id="dim_customer",
                                bash_command=f"{PSQL} -f load/dim_customer.sql", cwd=ETL)
    dim_book = BashOperator(task_id="dim_book",
                            bash_command=f"{PSQL} -f load/dim_book.sql", cwd=ETL)
    fact_sales = BashOperator(task_id="fact_sales",
                              bash_command=f"{PSQL} -v day={day} -f load/fact_sales.sql",
                              cwd=ETL)

    extract >> transform >> [dim_customer, dim_book]
    [day, dim_customer] >> fact_sales


shop_nightly()
```

O comentário acima da linha faz parte da correção. Um espaço no fim é invisível, e a próxima pessoa
que arrumasse o arquivo o tiraria.

## Conexões

Uma tarefa que conversa com um banco precisa saber onde ele está e como entrar, e **isso pertence à
máquina, não ao DAG**. O Airflow guarda isso numa *conexão* com um id, e um operador ou hook pede pelo
id. O laboratório declara duas, como variáveis de ambiente, que é um dos lugares onde o Airflow
procura:

```
ana@vm:~/etl$ grep "^AIRFLOW_CONN" /etc/etl.env
AIRFLOW_CONN_SHOP=postgresql://ana@%2Frun%2Fetl-pg/shop
AIRFLOW_CONN_WH=postgresql://ana@%2Frun%2Fetl-pg/wh
```

O `AIRFLOW_CONN_WH` é a conexão `wh`: PostgreSQL, como `ana`, pelo socket em `/run/etl-pg`, para o
banco `wh`. Um **hook** é a classe que transforma um id de conexão numa conexão viva —
`PostgresHook("wh")` — e todo operador SQL usa um por dentro. As tarefas da Ana chamam o `psql` em
vez disso, que acha o mesmo banco pelo `PGHOST`; a lição 18 tira as conexões e os segredos do
ambiente e diz por que isso importa quando há mais de um ambiente.
