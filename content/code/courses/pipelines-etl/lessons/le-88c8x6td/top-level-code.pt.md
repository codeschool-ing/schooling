---
title: O código que roda quando ninguém pediu
version: 1
---

Um arquivo de DAG é um programa Python, e o processador de DAGs o roda — **o arquivo inteiro, do
começo, toda vez que lê a pasta**. Neste laboratório isso é a cada poucos segundos para um arquivo
novo, e a cada trinta segundos ou algo assim depois disso. As tarefas só rodam quando uma execução é
agendada; tudo fora delas roda em cada passada.

Um colega escreve um DAG que cria uma tarefa por loja, perguntando ao banco da loja quais lojas
existem:

```
"""One task per shop, worked out by asking the shop's database which shops exist."""
import pendulum
import psycopg
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

with psycopg.connect("dbname=shop") as shop:                 # runs on every parse
    SHOPS = shop.execute("SELECT shop_id, name FROM shops ORDER BY shop_id").fetchall()


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def by_shop():
    for shop_id, name in SHOPS:
        BashOperator(task_id=f"report_shop_{shop_id}", bash_command=f"echo '{name}'")


by_shop()
```

Está arrumado, e funciona: sete lojas, sete tarefas. Agora veja quanto custa lê-lo, e o que ele faz
com o banco da loja enquanto o DAG fica parado, sem nunca rodar:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags report
file            | duration       | dag_num | task_num | dags        
================+================+=========+==========+=============
by_shop.py      | 0:00:00.085735 | 1       | 7        | by_shop     
shop_nightly.py | 0:00:00.019797 | 1       | 6        | shop_nightly
                                                                    
ana@vm:~/etl$ psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"; sleep 120; psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"
731
745
```

O `by_shop.py` leva mais de quatro vezes o tempo do `shop_nightly.py` para ser lido, e durante dois
minutos tranquilos o banco da loja confirmou 14 transações, uma delas a consulta que contou as
outras. **Cada leitura de um DAG que nunca rodou é uma conexão com o banco de produção**, a cada trinta
segundos, todo dia, enquanto o arquivo estiver na pasta. Se o banco estiver lento ou fora do ar, o
processador de DAGs espera por ele, e as mudanças de todos os outros DAGs esperam na fila atrás.

## A regra

**No nível de cima de um arquivo de DAG, declare; nunca busque.** Imports, constantes, o DAG e as
tarefas dele — nada que abra uma conexão, leia um arquivo que pode ser grande, ou chame uma API. Se o
formato de um DAG precisa depender de dados, leia os dados dentro de uma tarefa e espalhe em tempo de
execução; o *mapeamento dinâmico de tarefas* do Airflow existe para isso. Ou gere o arquivo do DAG
a partir dos dados, num passo separado que alguém roda de propósito.

A Ana apaga o `by_shop.py`. O DAG dela importa dois módulos e define constantes, e é lido em um
cinquenta avos de segundo.
