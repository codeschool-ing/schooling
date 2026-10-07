---
title: Um primeiro DAG
version: 1
---

O DAG da Ana roda os passos do `nightly.sh`, da lição 7, como tarefas:

```schooling-example
{
  "language": "python",
  "file": "dags/shop_nightly.py",
  "parts": [
    {
      "code": "\"\"\"Ponto Final's nightly load: the shop into raw, staging rebuilt, the marts loaded.\"\"\"\nimport pendulum\nfrom airflow.providers.standard.operators.bash import BashOperator\nfrom airflow.sdk import dag, task\n\n",
      "note": "O Airflow 3 escreve DAGs com o `airflow.sdk`; os operadores vêm dos providers, pacotes instalados ao lado do Airflow. O `BashOperator` está no provider padrão."
    },
    {
      "code": "ETL = \"/home/ana/etl\"\nPSQL = \"psql -q -v ON_ERROR_STOP=1 -d wh\"\n\n\n",
      "note": "Constantes para os comandos. Nada aqui toca um banco: este arquivo inteiro roda toda vez que o Airflow o lê, que é o assunto da última seção desta lição."
    },
    {
      "code": "@dag(\n    schedule=\"0 2 * * *\",\n    start_date=pendulum.datetime(2026, 3, 2, tz=\"America/Sao_Paulo\"),\n    catchup=False,\n    tags=[\"shop\"],\n)\ndef shop_nightly():\n",
      "note": "**As configurações do próprio DAG.** Rodar às 02:00 todo dia, no horário de São Paulo; a primeira execução que pode existir é a de 2 de março; `catchup=False` quer dizer não inventar execuções para os dias antes de hoje — a lição 9 trata do que o `True` faria."
    },
    {
      "code": "    @task\n    def day_to_load(logical_date=None) -> str:\n        \"\"\"The run at 02:00 loads the day that has just ended, in São Paulo.\"\"\"\n        return logical_date.in_timezone(\"America/Sao_Paulo\").subtract(days=1).to_date_string()\n\n",
      "note": "Uma tarefa escrita como função Python. Ela pede o `logical_date` pelo nome, e o Airflow o passa. **Ela calcula o dia a carregar a partir da execução, não do relógio** — a seção sobre a data lógica diz por quê."
    },
    {
      "code": "    day = day_to_load()\n",
      "note": "Chamar a função dentro do DAG não a roda; isso acrescenta a tarefa ao DAG e devolve uma referência ao que ela vai devolver."
    },
    {
      "code": "    extract = BashOperator(task_id=\"extract\", bash_command=\"python load_raw.py\", cwd=ETL)\n    # as the name of a template file to load, and fails before it runs.\n    transform = BashOperator(task_id=\"transform\", bash_command=\"sh run_sql.sh\", cwd=ETL)\n    dim_customer = BashOperator(task_id=\"dim_customer\",\n                                bash_command=f\"{PSQL} -f load/dim_customer.sql\", cwd=ETL)\n    dim_book = BashOperator(task_id=\"dim_book\",\n                            bash_command=f\"{PSQL} -f load/dim_book.sql\", cwd=ETL)\n    fact_sales = BashOperator(task_id=\"fact_sales\",\n                              bash_command=f\"{PSQL} -v day={day} -f load/fact_sales.sql\",\n                              cwd=ETL)\n\n",
      "note": "Os scripts da Ana das lições 6 e 7, uma tarefa cada, rodados em `~/etl`. No `fact_sales`, o `{day}` dentro de uma f-string vira um template que busca a resposta de `day_to_load` quando a tarefa roda, então a carga de fatos fica sabendo qual dia."
    },
    {
      "code": "    extract >> transform >> [dim_customer, dim_book]\n    [day, dim_customer] >> fact_sales\n\n\n",
      "note": "**A ordem.** O `>>` quer dizer *roda antes de*. Uma lista de um lado quer dizer cada tarefa dela. Nada roda na ordem em que foi escrito; tudo roda na ordem que estas duas linhas dizem."
    },
    {
      "code": "shop_nightly()"
    }
  ]
}
```

Seis tarefas, e entre elas cinco setas. O `extract` precisa terminar antes do `transform`, que
precisa terminar antes das duas cargas de dimensão; a carga de fatos espera a dimensão de clientes e
o cálculo do dia. **`dim_book` e `dim_customer` não têm seta entre si**, então o Airflow pode rodá-las
ao mesmo tempo, e com o `LocalExecutor` ele roda.

O arquivo vai na pasta de DAGs, `~/etl/dags`. O processador de DAGs o encontra em segundos, e o
`airflow dags test` roda uma execução completa dele no terminal, sem o agendador — que é como um DAG
é testado antes de merecer confiança. Uma execução de teste imprime cada linha do log de cada tarefa,
então a Ana primeiro escreve um filtro que guarda o que rodou, como cada tarefa terminou e qualquer
erro:

```
#!/bin/sh
# airflow dags test prints every line of every task's log. Keep the lines that
# say what ran, how it ended, and any error.
grep -oE "\[DAG TEST\] end task task_id=[a-z_]+|Running command: \[[^]]*\]|Command exited with return code [0-9]+|[A-Za-z0-9.]*(Error|NotFound): .*|DagRun Finished: dag_id=[a-z_]+, logical_date=[^,]+|state=[a-z]+, run_type=[a-z]+"
```

Depois ela pede ao Airflow para ler a pasta agora em vez de na próxima passada, lista os DAGs, conta
as linhas que uma execução de teste imprime, e a roda pelo filtro:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags list
dag_id       | fileloc                            | owners  | is_paused | bundle_name | bundle_version
=============+====================================+=========+===========+=============+===============
shop_nightly | /home/ana/etl/dags/shop_nightly.py | airflow | True      | dags-folder | None          
                                                                                                      
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | wc -l
134
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
Running command: ['/usr/bin/bash', '-c', 'python load_raw.py']
Command exited with return code 0
[DAG TEST] end task task_id=extract
[DAG TEST] end task task_id=day_to_load
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
jinja2.exceptions.TemplateNotFound: 'sh run_sql.sh' not found in search path: '/home/ana/etl/dags'
[DAG TEST] end task task_id=transform
DagRun Finished: dag_id=shop_nightly, logical_date=2026-03-03 03:00:00+00:00
state=failed, run_type=manual
```

O Airflow conhece o DAG, e ele está pausado — todo DAG novo está, até alguém tirar a pausa, para que
um arquivo copiado para a pasta por engano não comece a rodar sozinho. O `dags test` o roda mesmo
assim.

**Falhou**, no meio de 134 linhas, que é por isso que o filtro existe. O erro está na tarefa
`transform`, e o comando dela nunca rodou: `TemplateNotFound: 'sh run_sql.sh'`. O `extract` e o
`day_to_load` deram certo, e nada depois do `transform` foi tentado, porque tudo depois dele espera
por ele. A próxima seção diz por que falhou, e como um espaço resolve.
