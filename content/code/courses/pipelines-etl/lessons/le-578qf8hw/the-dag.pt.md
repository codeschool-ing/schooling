---
title: Um DAG que espera falhar
version: 1
---

A busca noturna de preços da Ana é o `prices.py` da lição 3, levado para dentro de uma tarefa, com
cada decisão sobre falha escrita ao lado do código a que se refere:

```schooling-example
{
  "language": "python",
  "file": "dags/prices_daily.py",
  "parts": [
    {
      "code": "\"\"\"The publishers' prices, every night at 03:00, and what to do when the API is down.\"\"\"\nimport datetime as dt\nimport json\nimport os\nimport time\n\n",
      "note": "As partes da biblioteca padrão: `timedelta` para toda duração do arquivo, `json` para gravar os preços, `os` para ler a chave do ambiente e `time` para esperar quando a API pede."
    },
    {
      "code": "import pendulum\nimport requests\nfrom airflow.sdk import AsyncCallback, DeadlineAlert, DeadlineReference, dag, task\nfrom airflow.sdk.exceptions import AirflowFailException\nfrom oncall import failed, late\n\n",
      "note": "As peças do Airflow para um prazo, a exceção que recusa um retry e os dois callbacks do módulo `oncall` da Ana, que fica na pasta de plugins, não aqui. **Este import é a linha que falhou primeiro.**"
    },
    {
      "code": "URL = \"http://127.0.0.1:8081/v1/prices\"\n\n\n",
      "note": "A API da lição 3, que o laboratório serve na mesma máquina."
    },
    {
      "code": "@dag(\n    schedule=\"0 3 * * *\",\n    start_date=pendulum.datetime(2026, 3, 2, tz=\"America/Sao_Paulo\"),\n    catchup=False,\n",
      "note": "Toda noite às 03:00, no horário de São Paulo, e nenhuma execução inventada para as noites antes de hoje."
    },
    {
      "code": "    default_args={\n        \"retries\": 4,\n        \"retry_delay\": dt.timedelta(seconds=15),\n        \"retry_exponential_backoff\": 2.0,              # 15 s, then 30, 60, 120\n        \"execution_timeout\": dt.timedelta(minutes=2),\n        \"on_failure_callback\": failed,\n    },\n",
      "note": "**Os `default_args` valem para toda tarefa do DAG.** Quatro retries depois da primeira tentativa, então cinco tentativas ao todo; a primeira espera é de 15 segundos, cada próxima o dobro; nenhuma tentativa pode passar de dois minutos; e quando uma tarefa falhou de vez, `failed` é chamado."
    },
    {
      "code": "    deadline=DeadlineAlert(\n        reference=DeadlineReference.DAGRUN_QUEUED_AT,\n        interval=dt.timedelta(minutes=2),\n        callback=AsyncCallback(late),\n    ),\n)\n",
      "note": "**Um prazo pertence à execução, não a uma tarefa.** Dois minutos depois de a execução entrar na fila, se ela não terminou, `late` é chamado, no triggerer. Em produção seriam horas; dois minutos é coisa do laboratório."
    },
    {
      "code": "def prices_daily():\n    @task\n    def fetch() -> int:\n        headers = {\"X-Api-Key\": os.environ[\"PRICES_API_KEY\"]}\n        params, rows = {\"page_size\": 200}, []\n",
      "note": "Uma tarefa, escrita como função. A chave vem do ambiente, nunca do arquivo."
    },
    {
      "code": "        while True:\n            r = requests.get(URL, headers=headers, params=params, timeout=10)\n",
      "note": "Cada página é um pedido com o seu próprio timeout de dez segundos, que é o limite da rede; os dois minutos lá de cima são da tarefa inteira."
    },
    {
      "code": "            if r.status_code == 429:                  # too fast: wait as told, ask again\n                time.sleep(float(r.headers.get(\"Retry-After\", \"1\")))\n                continue\n",
      "note": "Um `429` é tratado dentro da tentativa, como a lição 3 fez: a API diz quanto esperar, e a mesma página é pedida de novo. Nenhum retry é gasto com ele."
    },
    {
      "code": "            if r.status_code in (400, 401, 403):      # asking again will not change the answer\n                raise AirflowFailException(f\"the API refused the request: {r.status_code} {r.text}\")\n",
      "note": "**Uma recusa faz a tarefa falhar na hora.** O `AirflowFailException` diz ao Airflow para não tentar de novo, diga o `retries` o que disser."
    },
    {
      "code": "            r.raise_for_status()                      # 5xx: worth another try, later\n",
      "note": "Qualquer outra coisa que não seja sucesso — um `503` acima de tudo — levanta uma exceção comum, e uma exceção comum é tentada de novo."
    },
    {
      "code": "            body = r.json()\n            rows += body[\"data\"]\n            if body[\"next_cursor\"] is None:\n                break\n            params[\"cursor\"] = body[\"next_cursor\"]\n",
      "note": "As páginas, juntadas, como na lição 3."
    },
    {
      "code": "        with open(\"/home/ana/etl/landing/prices.jsonl\", \"w\") as out:\n            out.writelines(json.dumps(row) + \"\\n\" for row in rows)\n        return len(rows)\n\n",
      "note": "**O arquivo inteiro é reescrito, nunca acrescentado**, então uma tentativa que roda de novo depois de uma que chegou à metade deixa o mesmo arquivo. É isso que torna um retry seguro aqui."
    },
    {
      "code": "    fetch()\n\n\nprices_daily()"
    }
  ]
}
```

Duas coisas nele nem estão no arquivo do DAG. `failed` e `late`, as funções que avisam uma pessoa,
moram num módulo próprio, porque mais de um DAG vai querer usá-las:

```schooling-example
{
  "language": "python",
  "file": "~/airflow/plugins/oncall.py",
  "parts": [
    {
      "code": "\"\"\"Ponto Final's on-call helpers, imported by the DAGs.\n\nIn Airflow's plugins folder rather than in dags/, because a deadline's callback\nruns in the triggerer, and the triggerer can import from here and not from dags/.\"\"\"\n",
      "note": "Um módulo da própria Ana, na pasta de plugins do Airflow, `~/airflow/plugins`. A docstring diz por que ele está lá, e a seção abaixo mostra o que aconteceu antes de estar."
    },
    {
      "code": "import pendulum\n\nALERTS = \"/home/ana/etl/alerts.log\"\n\n\n",
      "note": "Todo alerta é uma linha acrescentada a um arquivo. Em produção esta função postaria num canal de chat ou chamaria quem está de plantão; a linha é a mesma de um jeito ou de outro."
    },
    {
      "code": "def note(text):\n    now = pendulum.now(\"America/Sao_Paulo\").strftime(\"%Y-%m-%d %H:%M:%S\")\n    with open(ALERTS, \"a\") as f:\n        f.write(f\"{now} {text}\\n\")\n\n\n",
      "note": "**Um callback de falha recebe o contexto da tarefa**: qual DAG, qual tarefa, qual execução, qual tentativa e a exceção que a encerrou."
    },
    {
      "code": "def failed(context):\n    \"\"\"A task has failed for good: no tries left, or none allowed.\"\"\"\n    ti = context[\"ti\"]\n    note(f\"FAILED {ti.dag_id}.{ti.task_id} run={ti.run_id} try={ti.try_number} \"\n         f\"error={context.get('exception')!r}\")\n\n\n",
      "note": "**Um callback de prazo precisa ser `async`**, porque quem o roda é o triggerer, e recebe a execução em vez de uma tarefa: o prazo é sobre a execução."
    }
  ]
}
```

## A primeira falha: um DAG que o Airflow não enxerga

Ela salvou os dois arquivos com o Airflow já rodando, e perguntou se o DAG tinha carregado:

```
ana@vm:~/etl$ airflow dags list-import-errors -o plain | grep -oE "Error: .*"
Error: No module named 'oncall'
ana@vm:~/etl$ sudo shop airflow-down
ana@vm:~/etl$ sudo shop airflow
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags list-import-errors
No data found
```

**`No module named 'oncall'`.** O arquivo do DAG importa um módulo que o Airflow em execução não
encontra, então o arquivo não carrega, e um DAG cujo arquivo não carrega não existe para o
agendador: nada de execuções, nada de tentativas e nada de alerta. O `airflow dags
list-import-errors` é o único lugar em que isso aparece, o que o torna **o primeiro comando a digitar
quando um DAG parece não ter feito nada**.

A pasta de plugins entra no caminho do Python quando cada processo do Airflow começa, e a pasta não
existia quando este Airflow começou. Reiniciá-lo foi a correção, e a lista vazia depois do reinício é
o DAG carregando. O mesmo vale para qualquer mudança posterior no `oncall.py`: **um processo que já
importou um módulo fica com a cópia que importou**, então editar um plugin pede um reinício, e editar
um arquivo de DAG não.

Por que não deixar o `oncall.py` em `dags/`, onde um DAG o teria achado na hora? Porque uma das duas
funções dele não é rodada por uma tarefa. O callback de um prazo roda no **triggerer**, o processo da
lição 8 que espera em nome das tarefas, e o triggerer não importa da pasta de DAGs. A primeira versão
do módulo ficava, sim, ao lado do DAG; o prazo disparou na hora certa, e o log do triggerer disse
`No module named 'oncall'` onde devia estar o alerta.
