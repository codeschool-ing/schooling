---
title: Rodando, e lendo o que aconteceu
version: 1
---

Com o espaço no lugar, a execução de teste dá certo:

```
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh
Running command: ['/usr/bin/bash', '-c', 'python load_raw.py']
Command exited with return code 0
[DAG TEST] end task task_id=extract
[DAG TEST] end task task_id=day_to_load
Running command: ['/usr/bin/bash', '-c', 'sh run_sql.sh ']
Command exited with return code 0
[DAG TEST] end task task_id=transform
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql']
Command exited with return code 0
[DAG TEST] end task task_id=dim_customer
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_book.sql']
Command exited with return code 0
[DAG TEST] end task task_id=dim_book
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -v day=2026-03-02 -f load/fact_sales.sql']
Command exited with return code 0
[DAG TEST] end task task_id=fact_sales
DagRun Finished: dag_id=shop_nightly, logical_date=2026-03-03 03:00:00+00:00
state=success, run_type=manual
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   415
(1 row)
```

Cada tarefa rodou o comando que recebeu, e cada comando saiu com código 0. A última linha do filtro é
o veredito da execução, `state=success`. A tabela fato tem 415 linhas para 2 de março, o dia que a
execução de 3 de março devia carregar, e o mesmo número que o `nightly.sh` carregou na lição 7.

O `fact_sales` rodou `psql ... -v day=2026-03-02`. **O `{day}` no arquivo do DAG foi interpretado como
`2026-03-02` logo antes de a tarefa rodar**, a partir da resposta do `day_to_load` — então o valor no
comando é o valor desta execução, não um valor fixado quando o arquivo foi escrito.

## O que o `dags test` é, e o que não é

- **É uma execução de verdade.** Ele cria uma execução do DAG no banco de metadados, roda cada tarefa
  e registra os estados delas; a execução aparece no `list-runs` depois, como a última seção mostrou.
- **Ele não precisa do agendador**, e ignora se o DAG está pausado. É como um DAG é testado antes de
  sair da pausa.
- **Ele roda as tarefas no processo do terminal**, uma depois da outra. Duas tarefas sem seta entre
  si rodam em sequência aqui; sob o agendador, com o `LocalExecutor`, elas rodam ao mesmo tempo. Um
  DAG que funciona no `dags test` porque duas tarefas por acaso rodaram numa ordem conveniente pode não
  funcionar sob o agendador — que é a armadilha da dependência que falta, da seção sobre dependências.

O `airflow tasks test DAG TAREFA DATA` roda uma tarefa só do mesmo jeito, sem as tarefas antes dela,
que é o jeito mais rápido de testar uma mudança numa delas.
