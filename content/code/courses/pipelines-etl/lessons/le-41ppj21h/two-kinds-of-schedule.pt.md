---
title: Dois tipos de agendamento
version: 1
---

A lição 8 disse que o Airflow 3 mudou o que uma string cron significa. Aqui estão os dois
significados lado a lado, em dois DAGs que só diferem no `schedule`, cada um limitado aos três
primeiros dias de março:

```
"""A cron string: in Airflow 3, a run at each time, for that time."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule="0 0 * * *",
     start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     end_date=pendulum.datetime(2026, 3, 3, tz="America/Sao_Paulo"), catchup=True)
def trigger_demo():
    BashOperator(task_id="show",
                 bash_command="echo {{ data_interval_start }} {{ data_interval_end }}")


trigger_demo()
```

```
"""A schedule with intervals: a run for each day, when the day is over."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag
from airflow.timetables.interval import CronDataIntervalTimetable


@dag(schedule=CronDataIntervalTimetable("0 0 * * *", timezone="America/Sao_Paulo"),
     start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     end_date=pendulum.datetime(2026, 3, 3, tz="America/Sao_Paulo"), catchup=True)
def interval_demo():
    BashOperator(task_id="show",
                 bash_command="echo {{ data_interval_start }} {{ data_interval_end }}")


interval_demo()
```

Sem a pausa, o agendador cria as execuções deles na hora, porque as datas estão no passado e o
`catchup=True` pede cada uma delas:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause trigger_demo; airflow dags unpause interval_demo
dag_id       | is_paused
=============+==========
trigger_demo | True     
                        
dag_id        | is_paused
==============+==========
interval_demo | True     
                         
ana@vm:~/etl$ airflow dags list-runs trigger_demo -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
trigger_demo  scheduled__2026-03-03T03:00:00+00:00  success  2026-03-03T03:00:00+00:00  2026-03-03T03:00:00+00:00  202
trigger_demo  scheduled__2026-03-02T03:00:00+00:00  success  2026-03-02T03:00:00+00:00  2026-03-02T03:00:00+00:00  202
trigger_demo  scheduled__2026-03-01T03:00:00+00:00  success  2026-03-01T03:00:00+00:00  2026-03-01T03:00:00+00:00  202
ana@vm:~/etl$ airflow dags list-runs interval_demo -o plain | cut -c1-118
dag_id         run_id                                state    run_after                  logical_date               st
interval_demo  scheduled__2026-03-04T03:00:00+00:00  success  2026-03-04T03:00:00+00:00  2026-03-03T03:00:00+00:00  20
interval_demo  scheduled__2026-03-03T03:00:00+00:00  success  2026-03-03T03:00:00+00:00  2026-03-02T03:00:00+00:00  20
interval_demo  scheduled__2026-03-02T03:00:00+00:00  success  2026-03-02T03:00:00+00:00  2026-03-01T03:00:00+00:00  20
```

Leia as colunas `run_after` e `logical_date` de cada um:

- `trigger_demo`: a data lógica de cada execução *é* o seu `run_after`. A execução da meia-noite
  de 1º de março é para a meia-noite de 1º de março. O intervalo de dados dela, perguntado à API,
  começa e termina no mesmo momento: ele não cobre nada além de um instante.
- `interval_demo`: cada execução acontece no *fim* de um dia e a sua data lógica é o *começo*
  desse dia. A execução que pode começar à meia-noite de 2 de março é para 1º de março, e o intervalo
  dela vai de meia-noite a meia-noite — o dia 1º de março inteiro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l09-two-schedules\" aria-label=\"Três dias numa linha do tempo, de 1º a 3 de março. Em cima, o agendamento por gatilho: uma execução a cada meia-noite, para aquela meia-noite, cobrindo um instante. Embaixo, o agendamento por intervalo: uma execução no fim de cada dia, para aquele dia, cobrindo-o de meia-noite a meia-noite; a primeira execução acontece à meia-noite de 2 de março e é para 1º de março.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M80.0 235.0 L80.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1º de março</text><path d=\"M270.0 235.0 L270.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 de março</text><path d=\"M460.0 235.0 L460.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"460.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 de março</text><path d=\"M650.0 235.0 L650.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 de março</text><text x=\"40.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">string cron: um gatilho</text><circle cx=\"80.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M80.0 68.0 L80.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"270.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M270.0 68.0 L270.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"460.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M460.0 68.0 L460.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"40.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CronDataIntervalTimetable: um intervalo</text><rect x=\"82.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é para 1º de março</text><circle cx=\"270.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda em 2 de março</text><rect x=\"272.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é para 2 de março</text><circle cx=\"460.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"460.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda em 3 de março</text><rect x=\"462.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é para 3 de março</text><circle cx=\"650.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"650.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda em 4 de março</text></svg>", "caption": "Os mesmos três dias. Um agendamento roda a cada meia-noite para aquele instante; o outro roda quando cada dia acaba, para o dia inteiro."}
```

O segundo é o que o Airflow 2 fazia com toda string cron, e é o formato que um batch diário tem: uma
execução para um período, depois que o período acabou. O primeiro é mais simples de raciocinar —
uma execução numa hora, para aquela hora — e deixa o período para o DAG. **Nenhum dos dois está
errado.** Errado é um DAG que supõe um e recebe o outro, e o sintoma é sempre o mesmo: cada execução
carrega o dia ao lado do que devia.

O DAG da Ana usa o primeiro tipo e diz qual dia carrega no próprio código, no `day_to_load`, então a
pergunta nunca depende de qual versão do Airflow, ou qual configuração, o roda. Se usasse o segundo
tipo, as tarefas dele leriam `data_interval_start` e `data_interval_end`, e esses seriam o dia.
