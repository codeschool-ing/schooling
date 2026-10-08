---
title: Uma tarefa que nunca acaba
version: 1
---

Uma falha que levanta exceção é o tipo fácil, porque acaba. O tipo difícil é uma tarefa que espera:
uma conexão que foi aberta e nunca respondeu, uma consulta presa atrás de um lock, um processo
esperando uma entrada que não vai chegar. **Uma tarefa que nunca acaba nunca falha**, então nenhum
retry acontece e nenhum callback roda, e a execução fica em `running` até alguém perceber que os
preços estão com um dia de atraso.

O `execution_timeout` põe um limite numa única tentativa. A Ana o vê funcionando numa tarefa feita
para travar:

```
"""A task that hangs, and the timeout that stops it."""
import datetime as dt

import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def timeout_demo():
    BashOperator(task_id="hangs", bash_command="echo connected; sleep 3600",
                 execution_timeout=dt.timedelta(seconds=20))


timeout_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags test timeout_demo 2>&1 | grep -oE "[0-9:]{8}\.[0-9]+Z.*(connected|Process timed out|Sending SIGTERM[^[]*)|AirflowTaskTimeout: .*|new_state=[a-z_]+" | grep -v "Running command" | sed -E "s/^([0-9:]{8})\.[0-9]+Z *\[[a-z ]*\] */\1 UTC /; s/ +$//"
08:40:07 UTC connected
08:40:27 UTC Process timed out
08:40:27 UTC Sending SIGTERM signal to process group
AirflowTaskTimeout: Timeout, PID: 13654
new_state=failed
ana@vm:~/etl$ rm dags/timeout_demo.py; airflow dags delete -y timeout_demo >/dev/null 2>&1
```

Vinte segundos depois de o comando começar, o Airflow parou de esperar, mandou `SIGTERM` para o
grupo de processos da tarefa — o shell e o `sleep` dentro dele — e fez a tentativa falhar com
`AirflowTaskTimeout`. Se a tarefa tivesse retries, o timeout contaria como uma tentativa falha,
igual a qualquer outra exceção, e a próxima tentativa começaria depois do intervalo.

**Os dois timeouts do `prices_daily` protegem coisas diferentes.** O `timeout=10` de cada pedido é o
limite da rede: um pedido que não ouviu nada por dez segundos é abandonado, e levanta exceção, o que
é uma falha passageira e é tentado de novo. O `execution_timeout` de dois minutos é o limite da
tentativa inteira, esteja ela fazendo o que for — cem páginas lentas, um laço que nunca acha o
último cursor, um `429` que não para de vir. Definir um não define o outro, e uma tarefa só com o
primeiro ainda pode rodar para sempre.

O valor é um julgamento sobre o trabalho. A busca da Ana leva uns poucos segundos numa noite boa,
então dois minutos é folgado e ainda curto o bastante para uma tentativa travada ser notada na mesma
noite. **Um timeout perto demais da duração normal derruba execuções boas numa noite lenta**; um longe
demais dela é timeout só no nome.
