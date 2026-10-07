---
title: Sensores: esperar pelo mundo
version: 1
---

A distribuidora deixa o arquivo de estoque por volta das seis da manhã — por volta. Uns dias às
05:40, outros às 07:10, de vez em quando não deixa. Uma tarefa agendada para as 06:00 que lê o arquivo
é uma tarefa que falha uma manhã em cada três. **Um sensor é uma tarefa cujo único trabalho é esperar
até algo ser verdade**, e deixar as tarefas depois dele rodarem quando for.

O `FileSensor` do Airflow espera por um arquivo, e o encontra por meio de uma **conexão** do tipo
`fs` cujo `path` é o diretório onde procurar. A Ana acrescenta uma com a CLI, que a guarda no banco
de metadados do Airflow:

```
ana@vm:~/etl$ airflow connections add fs_inbox --conn-type fs --conn-extra '{"path": "/home/ana/etl/inbox"}'
2026-10-07T05:21:32.889266Z [warning  ] ProvidersManager.hooks is deprecated. Use ProvidersManagerTaskRuntime.hooks from task-sdk instead. [py.warnings] category=DeprecatedImportWarning filename=/opt/etl/airflow/lib/python3.13/site-packages/airflow/cli/commands/connection_command.py lineno=240
Successfully added `conn_id`=fs_inbox
conn_id  | conn_type | host | login | port | extra                          
=========+===========+======+=======+======+================================
fs_inbox | fs        | None | None  | None | {'path': '/home/ana/etl/inbox'}
```

Depois, um DAG que espera o arquivo de estoque do dia e o carrega com o carregador da lição 3:

```
"""Load the distributor's stock file for a day, once it has arrived."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.sensors.filesystem import FileSensor
from airflow.sdk import dag

DAY = "{{ logical_date.in_timezone('America/Sao_Paulo').strftime('%Y-%m-%d') }}"


@dag(schedule="0 6 * * *",
     start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"), catchup=False)
def stock_file():
    arrived = FileSensor(
        task_id="arrived",
        fs_conn_id="fs_inbox",
        filepath=f"stock_{DAY}.csv",
        poke_interval=5,            # look every five seconds
        timeout=2 * 60 * 60,        # give up after two hours
        mode="poke",
    )
    load = BashOperator(task_id="load",
                        bash_command=f"python load_stock.py inbox/stock_{DAY}.csv",
                        cwd="/home/ana/etl")
    arrived >> load


stock_file()
```

A Ana o testa para 8 de março antes de o laboratório ter tocado esse dia. O arquivo não está lá;
doze segundos depois o laboratório toca o dia, e o arquivo da distribuidora chega:

```
ana@vm:~/etl$ airflow dags test stock_file 2026-03-08 2>&1 | grep -oE "Poking for file [^ ]*|Success criteria met|[0-9]+ rows loaded|[A-Za-z]*(Error|NotFound): .*|state=[a-z]+, run_type=[a-z]+" | uniq -c
      3 Poking for file /home/ana/etl/inbox/stock_2026-03-08.csv
      1 Success criteria met
      1 Poking for file /home/ana/etl/inbox/stock_2026-03-08.csv
      1 1200 rows loaded
      1 state=success, run_type=manual
```

Três olhadas, com cinco segundos entre elas, não acharam nada. Depois o arquivo estava lá, o sensor
deu certo, e a carga rodou: 1.200 linhas. Nada foi agendado num momento de sorte. **O DAG roda às
06:00 e os dados chegam quando chegam**, e o sensor é o que junta as duas coisas.

## Três jeitos de esperar

Um sensor que espera é uma tarefa que roda, e uma tarefa rodando ocupa um worker. Isso decide como ele
deve esperar:

| modo | enquanto espera | certo para |
|---|---|---|
| `poke` | segura o seu worker, olha a cada `poke_interval` | esperas curtas, de segundos a poucos minutos |
| `reschedule` | solta o worker entre as olhadas; o agendador o inicia de novo | esperas de minutos a horas |
| `deferrable=True` | entrega a espera ao triggerer, que vigia milhares de condições num processo só | muitos sensores, esperas longas |

O teste acima usou `poke`, porque o `dags test` roda num processo só. **Um DAG noturno que espera até
duas horas não deve segurar um worker por duas horas**: com `poke` e dezesseis DAGs assim, todo worker
estaria dormindo à espera de arquivos e nada mais rodaria. `reschedule` ou um sensor adiável é o que a
produção quer.

## O timeout é o ponto

O `timeout=2 * 60 * 60` diz: desista depois de duas horas. Sem ele, um sensor espera para sempre por
um arquivo que nunca vai chegar, e a execução nunca termina — **não falhou, só está rodando**, que é
algo que o alerta de ninguém procura. Com ele, o sensor falha às 08:00 e os alertas da lição 10 podem
avisar. Todo sensor precisa de um timeout escolhido por alguém que sabe quão tarde é "tarde".
