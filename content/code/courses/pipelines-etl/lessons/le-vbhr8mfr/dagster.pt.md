---
title: Dagster: o pipeline são os dados que ele faz
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "nightly_dagster.py",
  "parts": [
    {
      "code": "\"\"\"The nightly load as three Dagster assets: what should exist, and what it is made from.\"\"\"\nimport subprocess\n\nimport dagster as dg\n\n\n",
      "note": "O Dagster também é uma biblioteca, e a unidade dele não é uma tarefa."
    },
    {
      "code": "class Day(dg.Config):\n    day: str\n\n\n",
      "note": "Configuração para uma execução, declarada como classe: o dia do relatório, passado na linha de comando."
    },
    {
      "code": "@dg.asset\ndef raw_tables():\n    \"\"\"The shop's tables, copied into raw by load_raw.py.\"\"\"\n    subprocess.run([\"python\", \"load_raw.py\"], check=True)\n\n\n",
      "note": "**Um asset é algo que deve existir** — aqui, as tabelas cruas — e a função é como fazê-lo. Rodar a função é *materializar* o asset."
    },
    {
      "code": "@dg.asset(deps=[raw_tables])\ndef dbt_models():\n    \"\"\"Every model of the dbt project, built and tested.\"\"\"\n    subprocess.run([\"dbt\", \"build\", \"--project-dir\", \"shop\", \"--quiet\"], check=True)\n\n\n",
      "note": "O `deps` nomeia os assets a partir dos quais este é feito. Mesma ideia do `ref` do dbt e dos assets do Airflow: a dependência é entre coisas, não entre passos."
    },
    {
      "code": "@dg.asset(deps=[dbt_models])\ndef daily_report(config: Day) -> dg.MaterializeResult:\n    \"\"\"One day of daily_sales as a CSV file, for the managers.\"\"\"\n",
      "note": "O relatório pega o dia da sua configuração."
    },
    {
      "code": "    query = (\"COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales \"\n             f\"WHERE order_date = '{config.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)\")\n    csv = subprocess.run([\"psql\", \"-d\", \"wh\", \"-c\", query], check=True,\n                         capture_output=True, text=True).stdout\n    path = f\"reports/daily_{config.day}.csv\"\n    with open(path, \"w\") as out:\n        out.write(csv)\n",
      "note": "A mesma cópia das outras duas ferramentas."
    },
    {
      "code": "    return dg.MaterializeResult(metadata={\"path\": path, \"rows\": csv.count(\"\\n\") - 1})\n\n\n",
      "note": "**Metadados vão junto com a materialização** e o Dagster os guarda: onde está o arquivo e quantas linhas ele tem. A próxima seção os lê de volta."
    },
    {
      "code": "defs = dg.Definitions(assets=[raw_tables, dbt_models, daily_report])",
      "note": "As definições que o Dagster carrega do módulo: os três assets."
    }
  ]
}
```

O Luigi e o Prefect descrevem **passos**. O Dagster descreve **assets**: as tabelas cruas, os modelos
do dbt, o relatório — coisas que devem existir —, cada uma com a função que a faz e os assets a partir
dos quais ela é feita. Rodar as funções é *materializar* os assets, e a ordem vem do `deps`. É a ideia
que o Airflow acrescentou na lição 9 e sobre a qual o dbt foi construído na lição 11, tomada como
ponto de partida em vez de acrescentada depois.

O Dagster guarda os seus registros num diretório nomeado por `DAGSTER_HOME`, e a Ana desliga ali as
estatísticas de uso antes da primeira execução, pelo mesmo motivo do Prefect. Depois ela materializa
tudo, dando ao relatório o seu dia:

```
ana@vm:~/etl$ mkdir -p ~/dagster && printf "telemetry:\n  enabled: false\n" > ~/dagster/dagster.yaml
ana@vm:~/etl$ export DAGSTER_HOME=~/dagster; dagster asset materialize -m nightly_dagster --select "*" --config-json "{\"ops\": {\"daily_report\": {\"config\": {\"day\": \"2026-03-15\"}}}}" 2>&1 | grep -oE "(STEP_SUCCESS|STEP_FAILURE|RUN_SUCCESS|RUN_FAILURE) - .*"
STEP_SUCCESS - Finished execution of step "raw_tables" in 641ms.
STEP_SUCCESS - Finished execution of step "dbt_models" in 3.45s.
STEP_SUCCESS - Finished execution of step "daily_report" in 70ms.
RUN_SUCCESS - Finished execution of run for "__ASSET_JOB".
```

Uma linha por asset e uma para a execução, filtradas de muito mais: o Dagster registra cada evento de
cada passo, cada um no seu próprio processo. O que o Dagster **guarda** depois é a parte interessante.
Ele registra cada materialização de cada asset, com a hora e os metadados, e um script curto consegue
perguntar:

```
"""What Dagster remembers: the last time each asset was materialized, and what it said."""
import datetime as dt

import dagster as dg

instance = dg.DagsterInstance.get()
for name in ["raw_tables", "dbt_models", "daily_report"]:
    event = instance.get_latest_materialization_event(dg.AssetKey(name))
    when = dt.datetime.fromtimestamp(event.timestamp).strftime("%H:%M:%S")
    meta = event.asset_materialization.metadata
    print(f"{name:<13}{when}  " + "  ".join(f"{k}={v.value}" for k, v in meta.items()))
ana@vm:~/etl$ DAGSTER_HOME=~/dagster /opt/etl/dagster/bin/python latest.py
raw_tables   05:50:28  
dbt_models   05:50:33  
daily_report 05:50:35  path=reports/daily_2026-03-15.csv  rows=86
```

A resposta é o estado dos dados, não de uma execução: quando cada coisa foi feita pela última vez, e
o que ela disse sobre si mesma. Os metadados do relatório — o caminho e as 86 linhas — foram
devolvidos pela função e guardados com o evento. Na interface web do Dagster, o `dagster dev`, os
mesmos registros alimentam o grafo de assets, e um asset cujo antecessor foi materializado mais
recentemente que ele aparece marcado como desatualizado. O laboratório não roda a interface; os
registros são os mesmos que o script leu.

Agendar é um **schedule** ou um **sensor** ligado a uma seleção de assets, rodado pelo
`dagster-daemon`, que o laboratório também não inicia.
