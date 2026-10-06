---
title: Um contrato, conferido por um programa
version: 1
---

Um **contrato de dados** é um acordo entre quem produz um conjunto de dados e quem o consome, escrito de modo que uma
máquina consiga conferi-lo. O núcleo é o esquema: quais colunas, com quais tipos. Em volta disso ele traz o que o
esquema não consegue dizer: o grão, o dono, regras que os dados precisam cumprir. O contrato de Ana para a
`fact_sales` é um arquivo JSON:

```json
{
  "table": "fact_sales",
  "owner": "sales analytics",
  "grain": "one row per line of an order that was not cancelled",
  "columns": {
    "date_key": "INTEGER",
    "shop_key": "BIGINT",
    "book_key": "BIGINT",
    "customer_key": "BIGINT",
    "promotion_key": "BIGINT",
    "order_id": "BIGINT",
    "line_no": "BIGINT",
    "quantity": "BIGINT",
    "gross_cents": "BIGINT",
    "discount_cents": "BIGINT",
    "net_cents": "BIGINT"
  },
  "not_null": ["date_key", "shop_key", "book_key", "customer_key", "net_cents"],
  "unique": ["order_id", "line_no"]
}
```

E o programa que confere o warehouse contra ele, com menos de quarenta linhas de Python:

```python
"""Check a table in the warehouse against its contract; exit 1 on any breach."""
import json
import sys

import duckdb

contract = json.load(open(sys.argv[1]))
table = contract["table"]
con = duckdb.connect("wh.duckdb", read_only=True)
breaches = []

actual = dict(con.execute(
    "SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = ?",
    [table]).fetchall())
for column, wanted in contract["columns"].items():
    if column not in actual:
        breaches.append(f"column {column} is missing")
    elif actual[column] != wanted:
        breaches.append(f"column {column} is {actual[column]}, contract says {wanted}")

for column in contract["not_null"]:
    if column in actual:
        n = con.sql(f"SELECT count(*) FROM {table} WHERE {column} IS NULL").fetchone()[0]
        if n:
            breaches.append(f"{n} rows with no {column}")

key = ", ".join(contract["unique"])
n = con.sql(f"SELECT count(*) FROM (SELECT {key} FROM {table} GROUP BY ALL HAVING count(*) > 1)").fetchone()[0]
if n:
    breaches.append(f"{n} values of ({key}) appear more than once")

for b in breaches:
    print("BREACH:", b)
print(f"{table}: {len(contract['columns'])} columns checked, breaches: {len(breaches)}")
sys.exit(1 if breaches else 0)
```

```
ana@lab:~/wh$ python3 check_contract.py fact_sales.contract.json; echo "exit status $?"
fact_sales: 11 columns checked, breaches: 0
exit status 0
ana@lab:~/wh$ duckdb wh.duckdb -c "ALTER TABLE fact_sales RENAME COLUMN discount_cents TO discount"
ana@lab:~/wh$ python3 check_contract.py fact_sales.contract.json; echo "exit status $?"
BREACH: column discount_cents is missing
fact_sales: 11 columns checked, breaches: 1
exit status 1
```

A primeira execução não encontra nada: onze colunas com os tipos certos, nenhuma chave vazia, nenhuma linha contada
duas vezes. Então alguém renomeia `discount_cents` para `discount`, o tipo de arrumação que parece inofensiva de
dentro do time dono da tabela, e a conferência falha com **uma mensagem que nomeia a coluna e um status de saída 1**.

Esse status de saída é o ponto. Uma conferência que imprime um aviso é lida quando alguém lembra; uma conferência que
sai com 1 barra um deploy. **O contrato pertence ao pipeline de quem produz**, executado antes de uma mudança ser
publicada, para que a renomeação seja recusada do lado de quem a fez e pode desfazê-la, em vez de descoberta por cada
painel que lia `discount_cents`, do jeito que a seção 3 da lição 10 achou tarde demais uma coluna renomeada.

Um contrato escrito à mão em JSON é uma versão didática. Na prática, a mesma ideia aparece como os model contracts do
dbt, como suítes de testes em ferramentas de qualidade de dados, e como o Open Data Contract Standard, um formato YAML
mantido por um projeto aberto sob a Linux Foundation. A lição 16 de `pipelines-etl` os põe dentro de um pipeline. O que
todos têm em comum é o passo que esta seção dá: **a promessa é um arquivo, e o arquivo é executado**.
