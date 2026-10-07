---
title: Datas em templates, e de quem é o dia do `ds`
version: 1
---

Argumentos com template podem usar as datas da execução diretamente, e é por isso que a maioria dos
exemplos de Airflow carrega "o dia" com `{{ ds }}` e nunca escreve uma função como o `day_to_load`. O
`ds` é a data lógica da execução no formato `YYYY-MM-DD`, e há primos para tudo em volta dela:
`ds_nodash`, `data_interval_start`, `macros.ds_add(ds, -1)` para o dia anterior.

**O `ds` é uma data em UTC.** As execuções da Ana acontecem às 02:00 em São Paulo, que são 05:00 em
UTC, no mesmo dia, então o `ds` e a data de São Paulo concordam e ninguém percebe. Mova uma execução
para o fim da noite e eles deixam de concordar:

```
"""What {{ ds }} says for a run late in the evening, São Paulo time."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def ds_demo():
    BashOperator(task_id="show", bash_command=(
        "echo ds={{ ds }}; "
        "echo logical_date={{ logical_date }}; "
        "echo in_sao_paulo={{ logical_date.in_timezone('America/Sao_Paulo') }}"))


ds_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags test ds_demo 2026-03-02T23:30:00-03:00 2>&1 | grep -oE "(ds|logical_date|in_sao_paulo)=[0-9-]+( [0-9:+-]+)?" | sort -u
ds=2026-03-03
in_sao_paulo=2026-03-02 23:30:00-03:00
logical_date=2026-03-03 02:30:00+00:00
```

Uma execução às 23:30 de 2 de março em São Paulo tem um `ds` de 3 de março, porque em UTC já são
02:30 do dia 3. Um DAG que carregasse `{{ ds }}` a partir de uma execução assim carregaria o dia de
amanhã, ainda sem nada — e daria certo.

É o problema do `::date` da lição 6, chegando de novo por um template. O remédio é o mesmo: **escreva o
fuso horário onde a data é feita**. O DAG da Ana faz isso no `day_to_load`, e o sensor dela na próxima
seção faz isso no próprio template, com `logical_date.in_timezone('America/Sao_Paulo')`. Qualquer um
dos dois serve; o que importa é que o fuso esteja escrito em vez de herdado.
