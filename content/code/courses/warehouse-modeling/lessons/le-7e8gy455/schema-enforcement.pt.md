---
title: Recusando o formato errado
version: 1
---

A seção 3 viu um lake aceitar um arquivo com uma coluna renomeada sem um pio. Uma tabela Delta registra seu esquema no
log e confere toda escrita contra ele. Este programa acrescenta uma linha com uma coluna a mais, `shipping_cents`:

```python
"""Append a row whose shape does not match the table: one column too many."""
import sys

import pyarrow as pa
from deltalake import DeltaTable, write_deltalake

table = DeltaTable("lake/sales")
row = table.to_pyarrow_table().slice(0, 1)
row = row.append_column("shipping_cents", pa.array([1490], pa.int64()))

if len(sys.argv) > 1 and sys.argv[1] == "merge":
    write_deltalake("lake/sales", row, mode="append", schema_mode="merge")
    print("appended, and the table now has", len(DeltaTable("lake/sales").schema().fields), "columns")
else:
    write_deltalake("lake/sales", row, mode="append")
```

```
ana@lab:~/wh$ python bad_append.py 2>&1 | tail -1
_internal.SchemaMismatchError: Cannot cast schema, number of fields does not match: 13 vs 12
ana@lab:~/wh$ python history.py | tail -1
2 UPDATE {'predicate': 'order_id = 112406 AND line_no = 3'}
ana@lab:~/wh$ python bad_append.py merge
appended, and the table now has 13 columns
```

- **O append simples é recusado**: treze colunas oferecidas, doze na tabela. O histórico depois disso ainda termina no
  commit 2, então nada foi gravado; a recusa aconteceu antes do commit, que é o único lugar em que uma recusa vale
  alguma coisa.
- **Com `schema_mode="merge"` o mesmo append funciona** e a tabela ganha a coluna. Toda linha anterior a lê como vazia.

Essa é a diferença entre um lake e uma tabela, numa decisão só. **Evoluir o esquema é um ato deliberado que alguém
escreve**, e não algo que acontece com a tabela porque um arquivo veio diferente. A coluna renomeada pelo time do site
na seção 3 teria sido barrada na porta com um erro que a nomeia, e as pessoas capazes de corrigi-la seriam as que o
veriam.

O que a imposição de esquema não faz é conferir significado. Uma coluna renomeada na origem e gravada com o nome certo
na tabela passa; um preço em reais onde se queria centavos também. Isso pede o tipo de conferência que a lição 5 fez
numa dimensão tipo 2, e que `pipelines-etl` torna parte de toda carga.
