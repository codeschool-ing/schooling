---
title: Lendo a tabela como ela era
version: 1
---

Como os arquivos antigos ficam no disco até alguém removê-los, e o log registra quais arquivos formavam cada versão,
qualquer versão anterior da tabela pode ser lida de novo:

```python
"""Read the Delta table as it is now, or as it was at an earlier version."""
import sys

import pyarrow.compute as pc
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
if len(sys.argv) > 1:
    table.load_as_version(int(sys.argv[1]))

data = table.to_pyarrow_table()
print(f"version {table.version()}: {len(table.file_uris())} files, "
      f"{data.num_rows} rows, net_cents {pc.sum(data['net_cents'])}")
```

```python
"""List the table's commits, oldest first."""
from deltalake import DeltaTable

for commit in reversed(DeltaTable("lake/sales").history()):
    print(commit["version"], commit["operation"], commit.get("operationParameters", {}))
```

```
ana@lab:~/wh$ python read_sales.py 1
version 1: 2 files, 887477 rows, net_cents 9574389852
ana@lab:~/wh$ python read_sales.py 0
version 0: 1 files, 404067 rows, net_cents 4172718581
ana@lab:~/wh$ python history.py
0 WRITE {'mode': 'Overwrite', 'partitionBy': '["year"]'}
1 WRITE {'partitionBy': '["year"]', 'mode': 'Append'}
2 UPDATE {'predicate': 'order_id = 112406 AND line_no = 3'}
```

- **Versão 2**, a atual, tem a correção: `net_cents` 9.574.388.852.
- **Versão 1**, antes dela: 9.574.389.852, o número que todas as lições até a correção da lição 6 informavam.
- **Versão 0**: só 2024, um arquivo, 404.067 linhas.

E o histórico diz o que foi cada commit: duas gravações e o update, com seu predicado.

Isso é o que um lake sem formato de tabela não consegue fazer, e responde a perguntas que um warehouse ouve com
frequência:

- **"Por que o relatório do mês passado dizia outra coisa?"** Leia a tabela como estava no dia em que o relatório
  rodou.
- **"O que essa carga ruim mudou?"** Compare a versão de antes com a de depois.
- **"Desfaça."** Restaure a tabela para a versão anterior, o que é mais um commit apontando de volta para os arquivos
  antigos.

## O preço, e a limpeza

Guardar toda versão significa guardar todo arquivo antigo. Uma tabela atualizada toda noite acumula cópias
regravadas, e a conta de armazenamento cresce com elas. O **vacuum** apaga arquivos de dados de que nenhuma versão
dentro de um período de retenção ainda precisa:

```python
"""Which files would vacuum delete: those no current version still needs."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
stale = table.vacuum(retention_hours=0, dry_run=True, enforce_retention_duration=False)
print(len(stale), "file(s) no longer referenced by the current version")
```

```
ana@lab:~/wh$ python vacuum.py
1 file(s) no longer referenced by the current version
ana@lab:~/wh$ find lake/sales -name "*.parquet" | wc -l
4
```

Um arquivo, o 2024 original que o commit 2 substituiu, não é mais referenciado. A execução é um ensaio (dry run),
então só informa; uma de verdade o apagaria, e depois disso **a versão 0 e a versão 1 não poderiam mais ser lidas**. O
período de retenção é a troca: o padrão do Delta guarda sete dias, que é a janela em que a viagem no tempo funciona.

É também a resposta a uma pergunta que a lição 12 levanta sobre dados pessoais. Um cliente que pede para ser esquecido
é apagado numa versão nova, e continua nos arquivos antigos até que um vacuum os remova; um lakehouse que guarda meses
de histórico guarda meses de uma pessoa que prometeu esquecer.
