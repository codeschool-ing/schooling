---
title: Passar um valor de uma tarefa para outra
version: 1
---

O `day_to_load` devolveu uma string, e o `fact_sales` a usou. **O valor de retorno de uma tarefa é
guardado no banco de metadados do Airflow como uma XCom** — uma *comunicação cruzada* — com a chave
da execução, da tarefa e do nome `return_value`, e qualquer tarefa posterior na mesma execução pode
buscá-la. O pequeno script da Ana pede uma à API do Airflow:

```
#!/bin/sh
# The value a task returned in the latest run of a DAG, asked of Airflow's API.
dag=$1 task=$2
run=$(airflow dags list-runs "$dag" -o json | python -c 'import json, sys; print(json.load(sys.stdin)[0]["run_id"])')
curl -s "http://127.0.0.1:8080/api/v2/dags/$dag/dagRuns/$run/taskInstances/$task/xcomEntries/return_value" |
  python -c 'import json, sys; x = json.load(sys.stdin); print(x["logical_date"], x["task_id"], "returned", repr(x["value"]))'
```

```
ana@vm:~/etl$ sh xcom.sh shop_nightly day_to_load
2026-03-03T03:00:00Z day_to_load returned '2026-03-02'
```

A execução de 3 de março guardou `'2026-03-02'`. Ela fica lá enquanto a execução existir, então uma
semana depois qualquer um pode ver exatamente qual dia aquela execução carregou — o que vale mais do
que parece, na manhã em que alguém pergunta por que um relatório tem um buraco.

## Para que serve uma XCom

**Uma XCom é para um valor pequeno que decide o que a próxima tarefa faz**: uma data, um nome de
arquivo, uma contagem de linhas, o id de algo que a última tarefa criou. Ela vai para uma coluna do
banco de metadados e é lida de volta como JSON, então deve ser medida em bytes, não em megabytes.

O que ela não é, é um meio de levar dados. Uma tarefa que devolve uma lista de um milhão de pedidos
para a próxima carregar pôs um milhão de pedidos dentro do banco do próprio Airflow, entre duas
tarefas que poderiam ter compartilhado uma tabela. **Os dados se movem pelo warehouse; as XComs levam
as etiquetas deles.** As tarefas da Ana nunca passam linhas: o `extract` escreve no `raw`, o
`transform` lê de lá, e a única coisa que passa pelo Airflow é uma data.
