---
title: Luigi: feito quer dizer que a saída existe
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "nightly_luigi.py",
  "parts": [
    {
      "code": "\"\"\"The nightly load as three Luigi tasks. A task is done when its output exists.\"\"\"\nimport subprocess\n\nimport luigi\n\n\n",
      "note": "O Luigi é uma biblioteca: um pipeline é um módulo Python, e cada passo é uma classe."
    },
    {
      "code": "class LoadRaw(luigi.Task):\n    day = luigi.DateParameter()\n\n",
      "note": "Um **parâmetro** faz parte da identidade da tarefa. `LoadRaw` do dia 14 e `LoadRaw` do dia 15 são duas tarefas diferentes."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"marks/raw_{self.day}.done\")\n\n",
      "note": "**O `output` é como o Luigi decide se uma tarefa está feita**: se o alvo existe, a tarefa está completa e nunca roda. Uma carga num banco não deixa arquivo, então as tarefas da Ana gravam um pequeno arquivo de marca para representá-la."
    },
    {
      "code": "    def run(self):\n        subprocess.run([\"python\", \"load_raw.py\"], check=True)\n        with self.output().open(\"w\") as mark:\n            mark.write(\"loaded\\n\")\n\n\n",
      "note": "O trabalho, e depois a marca. Se o trabalho falhar, nenhuma marca é gravada, e a próxima execução tenta de novo."
    },
    {
      "code": "class BuildModels(luigi.Task):\n    day = luigi.DateParameter()\n\n",
      "note": "O segundo passo, com o seu próprio parâmetro."
    },
    {
      "code": "    def requires(self):\n        return LoadRaw(self.day)\n\n",
      "note": "**O `requires` é a dependência**: os modelos de um dia precisam da carga crua daquele dia. O Luigi monta o grafo seguindo essas chamadas de volta a partir da tarefa que lhe pediram."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"marks/models_{self.day}.done\")\n\n    def run(self):\n        subprocess.run([\"dbt\", \"build\", \"--project-dir\", \"shop\", \"--quiet\"], check=True)\n        with self.output().open(\"w\") as mark:\n            mark.write(\"built\\n\")\n\n\n",
      "note": "Outra marca, depois de o `dbt build` construir e testar tudo."
    },
    {
      "code": "class DailyReport(luigi.Task):\n    day = luigi.DateParameter()\n\n    def requires(self):\n        return BuildModels(self.day)\n\n",
      "note": "A última tarefa, e a única cuja saída é o produto de verdade: o arquivo CSV para os gerentes."
    },
    {
      "code": "    def output(self):\n        return luigi.LocalTarget(f\"reports/daily_{self.day}.csv\")\n\n",
      "note": "A saída do próprio relatório."
    },
    {
      "code": "    def run(self):\n        query = (\"COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales \"\n                 f\"WHERE order_date = '{self.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)\")\n        csv = subprocess.run([\"psql\", \"-d\", \"wh\", \"-c\", query], check=True,\n                             capture_output=True, text=True).stdout\n        with self.output().open(\"w\") as out:      # written to a temporary file, renamed at the end\n            out.write(csv)",
      "note": "Um dia do `daily_sales`, copiado para fora pelo `psql`. Gravar pelo `open` do alvo faz o arquivo aparecer inteiro ou não aparecer."
    }
  ]
}
```

Pede-se ao Luigi a tarefa do final, e ele trabalha para trás: o `DailyReport` do dia 14 requer o
`BuildModels` do dia 14, que requer o `LoadRaw` do dia 14. O que não estiver completo é rodado, na
ordem das dependências. O `--local-scheduler` roda tudo neste processo; o Luigi também tem um
agendador central, o `luigid`, que impede duas pessoas de rodarem a mesma tarefa ao mesmo tempo e
desenha o grafo num navegador, e que o laboratório não inicia. O `PYTHONPATH=.` está ali porque o
Luigi importa o módulo pelo nome, e o diretório atual não está no caminho do Python para um comando
instalado.

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 3 ran successfully:
    - 1 BuildModels(day=2026-03-14)
    - 1 DailyReport(day=2026-03-14)
    - 1 LoadRaw(day=2026-03-14)

This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
ana@vm:~/etl$ ls marks reports
marks:
models_2026-03-14.done
raw_2026-03-14.done

reports:
daily_2026-03-14.csv
ana@vm:~/etl$ head -4 reports/daily_2026-03-14.csv
shop_id,category,books,revenue_cents
1,Biography,6,58340
1,Business,7,61430
1,Cooking,9,54810
```

Três tarefas, três saídas: duas marcas e o relatório. Agora o mesmo comando de novo:

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 1 tasks of which:
* 1 complete ones were encountered:
    - 1 DailyReport(day=2026-03-14)

Did not run any tasks
This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
```

**Nada rodou.** O Luigi perguntou ao `DailyReport` do dia 14 se ele estava completo, o arquivo estava
lá, e acabou — ele nem olhou as duas tarefas de antes. Essa é a ideia inteira do Luigi, e é uma boa
ideia: **um pipeline a que se pede para rodar duas vezes faz o trabalho uma vez**, e um pipeline que
falha no meio retoma de onde parou, como a próxima seção mostra.

É também a fraqueza dele, e as marcas mostram onde. Uma marca diz que um passo terminou uma vez. Ela
não diz que o que o passo produziu continua certo. Se o dia 14 da loja mudar amanhã — um reembolso,
como a lição 11 achou —, o `reports/daily_2026-03-14.csv` continua lá, o Luigi continua o chamando de
completo, e nada vai gravá-lo de novo a menos que alguém apague o arquivo. **Completude por
existência é exata para arquivos que nunca mudam, e só aproximada para qualquer coisa num banco.**
