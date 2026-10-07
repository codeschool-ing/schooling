---
title: Catch-up, e as execuções que ninguém pediu
version: 1
---

O `catchup=True` diz ao agendador que cada ponto do agendamento entre a data de início e agora
merece uma execução. Para um DAG escrito semana passada, isso é um punhado de execuções. Para um DAG
com uma data de início antiga, é uma enxurrada, e o laboratório produz uma boa, porque o março da loja
está sete meses atrás do outubro da máquina:

```
"""catchup=True, a start date in the past, and no end date."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule="0 2 * * *",
     start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"), catchup=True)
def catchup_demo():
    BashOperator(task_id="load", bash_command="echo loading the day before {{ ds }}")


catchup_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause catchup_demo
dag_id       | is_paused
=============+==========
catchup_demo | True     
                        
ana@vm:~/etl$ airflow dags list-runs catchup_demo -o plain | tail -n +2 | wc -l
220
ana@vm:~/etl$ airflow dags list-runs catchup_demo -o plain | tail -n +2 | tr -s " " | cut -d" " -f3 | sort | uniq -c
    220 success
ana@vm:~/etl$ airflow dags pause catchup_demo; airflow dags delete -y catchup_demo; rm dags/catchup_demo.py
dag_id       | is_paused
=============+==========
catchup_demo | False    
                        
2026-10-07T08:31:56.949638Z [info     ] Deleting Dag: catchup_demo     [airflow.api.common.delete_dag] loc=delete_dag.py:55
Removed 442 record(s)
```

**Duzentas e vinte execuções**, uma para cada 02:00 de 2 de março até a manhã da gravação,
criadas e rodadas nos vinte segundos depois de o DAG sair da pausa. O segundo comando as conta por
estado, e todas são `success`: cada uma era um `echo`, e o agendador as rodou muitas de uma vez,
dezesseis execuções de um DAG por padrão. A Ana pausa o DAG e o apaga, com as execuções dele.

Para este DAG o custo foram duzentos e vinte `echo`s. Para uma carga de verdade são duzentas e
vinte cargas de dias sem dados, disputando as mesmas tabelas ao mesmo tempo, e cada uma que
sobreviver à disputa um sucesso.

## Quando o catch-up é o certo

- **O histórico do DAG importa, e cada execução é independente.** Uma exportação diária dos eventos
  do dia para um arquivo deveria ter um arquivo por dia, e um dia que falta deveria ser preenchido.
- **A data de início foi escolhida de propósito**, perto de agora, e o catch-up só preenche o vão de
  uma queda.

E quando não é, que é o padrão que este curso adota: **`catchup=False`, e o passado preenchido de
propósito, com um backfill**, para um intervalo que alguém escolheu. Essa é a próxima seção. O Airflow
3 concorda: o `catchup` vale `False` por padrão, a menos que uma configuração diga outra coisa.
