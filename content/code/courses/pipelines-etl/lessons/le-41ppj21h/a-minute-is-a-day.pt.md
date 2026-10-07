---
title: Um minuto é um dia: o relógio rápido do laboratório
version: 1
---

Um pipeline noturno só é testado de verdade por noites, e noites são lentas. Tudo até aqui usou um
atalho: o laboratório toca um dia quando pedem, e o Airflow fica sabendo para que data lógica uma
execução existe. O próprio agendador — o processo que decide, sozinho, que uma execução está na hora
— quase não fez nada, porque a próxima decisão dele é às 02:00 de amanhã, e o amanhã da loja está em
março.

**Esse é um problema que nenhum outro curso do catálogo tem**: todo outro curso bloqueado precisa de
uma máquina, e este precisa de um relógio. A resposta do laboratório é fazer do calendário da loja e
do calendário do Airflow duas coisas diferentes, e juntá-las num DAG que diz como:

```
"""The lab's fast clock: every minute, one more day of March, loaded.

Not a pipeline anybody would run. It exists because a nightly schedule needs a
night to pass, and here a minute has to do."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(schedule="* * * * *", start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     catchup=False, max_active_runs=1)
def shop_minute():
    play = BashOperator(task_id="play_a_day",
                        bash_command="bash ~/lab/lab.sh until $(date -d \"$(cat /var/lib/etl-run/clock) + 1 day\" +%F) && cat /var/lib/etl-run/clock")
    load = BashOperator(task_id="nightly",
                        bash_command="sh nightly.sh {{ ti.xcom_pull(task_ids='play_a_day') }} ",
                        cwd=ETL)
    play >> load


shop_minute()
```

A cada minuto, o próprio relógio do Airflow agenda uma execução. A execução pergunta ao laboratório
até que dia a loja viveu, toca o próximo e o carrega com o `nightly.sh` da lição 7. **Um minuto do
tempo da máquina é um dia do tempo da loja**, e quem marca o tempo é o agendador.

A Ana tira a pausa e espera um pouco mais de três minutos:

```
ana@vm:~/etl$ cat /var/lib/etl-run/clock; airflow dags reserialize >/dev/null 2>&1; airflow dags unpause shop_minute
2026-03-09
dag_id      | is_paused
============+==========
shop_minute | True     
                       
ana@vm:~/etl$ airflow dags pause shop_minute; cat /var/lib/etl-run/clock
dag_id      | is_paused
============+==========
shop_minute | False    
                       
2026-03-13
ana@vm:~/etl$ airflow dags list-runs shop_minute -o plain | cut -c1-118
dag_id       run_id                                state    run_after                  logical_date               star
shop_minute  scheduled__2026-10-07T05:25:00+00:00  success  2026-10-07T05:25:00+00:00  2026-10-07T05:25:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:24:00+00:00  success  2026-10-07T05:24:00+00:00  2026-10-07T05:24:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:23:00+00:00  success  2026-10-07T05:23:00+00:00  2026-10-07T05:23:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:22:00+00:00  success  2026-10-07T05:22:00+00:00  2026-10-07T05:22:00+00:00  2026
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales WHERE order_date > '2026-03-08' GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-09 |   431
 2026-03-10 |   368
 2026-03-11 |   416
 2026-03-12 |   419
 2026-03-13 |   448
(5 rows)
```

O relógio da loja foi de 9 a 13 de março enquanto a Ana esperava, um dia por execução, cada execução
agendada pelo agendador no começo de um minuto, e a tabela fato ganhou um dia a cada vez. Nada aqui foi
iniciado à mão.

## Para que serve o relógio rápido, e para que não serve

**Ele serve para ver o agendador fazendo o seu trabalho**: execuções aparecendo na hora, o
`max_active_runs=1` segurando a próxima execução até a última terminar, um sensor esperando, um alerta
disparando no momento errado, de que a lição 10 precisa. Nada disso se vê com o `dags test`.

**Ele não é um modelo de produção.** As datas lógicas dele são de outubro; o dia que ele carrega vem
do relógio do laboratório, não da execução. Um DAG de verdade tira o dia da sua execução, como o
`shop_nightly` faz, e essa é a propriedade de que todo backfill depende. O relógio rápido a quebra de
propósito, num DAG cuja docstring diz isso, e a lição o pausa antes de seguir.
