---
title: Assets: rodar quando os dados mudam
version: 1
---

O relatório de vendas deve rodar depois de a tabela fato ser carregada. Agendá-lo para as 04:00,
duas horas depois de a carga noturna começar, funciona até a noite em que a carga leva três horas — e
então o relatório roda sobre a tabela de ontem e dá certo. **Aquilo de que o relatório depende não é
um horário, é um acontecimento: a tabela fato tem dados novos.**

O Airflow 3 deixa um DAG dizer isso. Uma tarefa declara que produz um **asset** — um nome para um
pedaço de dados, escrito como URI — e outro DAG declara que roda sempre que esse asset é atualizado. A
Ana marca o `fact_sales` como produtor da tabela fato:

```
ana@vm:~/etl$ sed -i 's|^from airflow.sdk import dag, task|from airflow.sdk import Asset, dag, task|' dags/shop_nightly.py
ana@vm:~/etl$ sed -i 's|-f load/fact_sales.sql",|-f load/fact_sales.sql",\n                              outlets=[Asset("postgres://localhost:5432/wh/marts/fact_sales")],|' dags/shop_nightly.py
ana@vm:~/etl$ grep -n -A3 "fact_sales = " dags/shop_nightly.py
32:    fact_sales = BashOperator(task_id="fact_sales",
33-                              bash_command=f"{PSQL} -v day={day} -f load/fact_sales.sql",
34-                              outlets=[Asset("postgres://localhost:5432/wh/marts/fact_sales")],
35-                              cwd=ETL)
```

e escreve um relatório agendado pelo asset em vez de por um relógio:

```
"""A report that runs whenever the fact table has been loaded, whoever loaded it."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import Asset, dag

FACT_SALES = Asset("postgres://localhost:5432/wh/marts/fact_sales")


@dag(schedule=[FACT_SALES], start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def sales_report():
    BashOperator(task_id="report", bash_command=(
        "psql -d wh -Atc \"SELECT max(order_date), sum(line_cents) FROM marts.fact_sales\""))


sales_report()
```

O Airflow agora conhece o asset, e o relatório o espera:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause sales_report; airflow assets list
dag_id       | is_paused
=============+==========
sales_report | True     
                        
name                                          | uri                                           | group | extra
==============================================+===============================================+=======+======
postgres://localhost:5432/wh/marts/fact_sales | postgres://localhost:5432/wh/marts/fact_sales | asset | {}   
                                                                                                             
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-09
ana@vm:~/etl$ airflow backfill create --dag-id shop_nightly --from-date 2026-03-10 --to-date 2026-03-10T12:00:00-03:00 2>&1 | grep -c "Created backfill Dag run"
1
ana@vm:~/etl$ airflow dags list-runs sales_report -o plain | cut -c1-118
dag_id        run_id                                                      state    run_after                         l
sales_report  asset_triggered__2026-10-07T05:22:11.720065+00:00_gDgSDCof  success  2026-10-07T05:22:11.720065+00:00   
ana@vm:~/etl$ f=$(ls -d ~/airflow/logs/dag_id=sales_report/run_id=*/task_id=report | head -1); grep -oE "\"event\":\"[0-9-]+\|[0-9]+\"" $f/attempt=1.log
"event":"2026-03-09|23133780"
```

O `shop day` toca o dia 9 de março, e um backfill o carrega. Quando o `fact_sales` deu certo, o
Airflow registrou um evento no asset, e o agendador iniciou o `sales_report` — `asset_triggered`, no
momento em que a carga terminou, sem horário escrito em lugar nenhum. O relatório viu o dia 9 de
março, e o total de tudo o que foi carregado até ali.

## O que um asset é, e o que não é

**Um asset é uma promessa, não uma verificação.** O Airflow registra que o `fact_sales` *disse* que
atualizou a tabela; ele não olha a tabela. Uma tarefa que declara um outlet e não escreve nada ainda
dispara o relatório. A URI é um nome com que dois DAGs concordam — o provider de PostgreSQL do Airflow
exige que ela tenha host, porta, banco, schema e tabela, e é por isso que ela diz `localhost:5432`
embora nada se conecte ali.

**E ele junta DAGs de donos diferentes.** Quem escreve o relatório não precisa saber quando, como ou
por qual DAG a tabela fato é carregada — só o nome dela. É a mesma separação que a lição 2 traçou
entre camadas, traçada entre equipes.
