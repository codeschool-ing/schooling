---
title: Um primeiro olhar sobre a série
version: 1
---

Com os dados escritos, uma dúzia de linhas de pandas mostra três dos quatro movimentos antes de
qualquer modelo entrar em cena. Salve isto como `look.py` na pasta do curso e rode com
`.venv/bin/python look.py`:

```schooling-example
{"language": "python", "file": "look.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nprint(orders.head(3).rename_axis(None).to_string())", "note": "Lê o arquivo e fica com uma coluna. O `parse_dates` transforma o texto `2023-01-01` numa data, e o `index_col` faz das datas os rótulos das linhas, que é o que permite ao pandas agrupar por ano, dia da semana ou mês."}, {"code": "print(\"\\norders per year\")\nprint(orders.groupby(orders.index.year).sum().rename_axis(None).to_string())", "note": "Soma cada ano. Um ano contém cada sazonalidade uma vez, então os totais só se mexem com a tendência."}, {"code": "print(\"\\nmean orders per day, by weekday\")\nnames = [\"Mon\", \"Tue\", \"Wed\", \"Thu\", \"Fri\", \"Sat\", \"Sun\"]\nby_day = orders.groupby(orders.index.dayofweek).mean().round(0)\nprint(by_day.set_axis(names).to_string())", "note": "Tira a média de cada dia da semana ao longo dos três anos. O `dayofweek` conta a partir de 0 para a segunda-feira, por isso os nomes vão nessa ordem."}, {"code": "print(\"\\nmean orders per day, by month, 2024\")\nyear = orders[\"2024\"]\nprint(year.groupby(year.index.month).mean().round(0).rename_axis(None).to_string())", "note": "Tira a média de cada mês de um ano. Um texto como `\"2024\"` seleciona todas as linhas daquele ano, porque as datas são o índice."}], "output": "Traceback (most recent call last):\n  File \"/home/ana/bi/look.py\", line 3, in <module>\n    orders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\n             ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 872, in read_csv\n    return _read(filepath_or_buffer, kwds)\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 300, in _read\n    parser = TextFileReader(filepath_or_buffer, **kwds)\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 1643, in __init__\n    self._engine = self._make_engine(f, self.engine)\n                   ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/parsers/readers.py\", line 1907, in _make_engine\n    self.handles = get_handle(\n                   ~~~~~~~~~~^\n        f,\n        ^^\n    ...<6 lines>...\n        storage_options=self.options.get(\"storage_options\", None),\n        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n    )\n    ^\n  File \"/home/ana/bi/.venv/lib/python3.13/site-packages/pandas/io/common.py\", line 930, in get_handle\n    handle = open(\n        handle,\n    ...<3 lines>...\n        newline=\"\",\n    )\nFileNotFoundError: [Errno 2] No such file or directory: 'daily_orders.csv'"}
```

**Cada bloco da saída isola um movimento, anulando os outros na média.**

Os totais anuais são a tendência, porque todo ano contém cada dia da semana cerca de 52 vezes e
cada mês uma vez, então as sazonalidades se anulam. Eles sobem 99.383 e depois 55.091: crescimento,
desacelerando.

As médias por dia da semana são a sazonalidade semanal, porque três anos de segundas-feiras
carregam todos os meses e todas as fases da tendência por igual. A segunda é o dia mais movimentado
e o sábado o mais calmo, por 373 pedidos.

As médias por mês são a sazonalidade anual, e são o primeiro sinal de problema. Janeiro e fevereiro
são calmos, como esperado. Mas os meses de junho a dezembro ficam quase planos, e a segunda metade
do ano fica bem acima da primeira. **É a tendência vazando para dentro da sazonalidade**: um ano de
dados não consegue separar "julho é um mês forte" de "o negócio estava maior em julho". Separar as
duas coisas direito é o assunto da aula 2.

O quarto movimento, o ruído, é o que uma tabela de médias não consegue mostrar, porque tirar a
média é justamente o que o remove. Ele aparece quando os outros três são subtraídos, o que a aula 2
também faz.
