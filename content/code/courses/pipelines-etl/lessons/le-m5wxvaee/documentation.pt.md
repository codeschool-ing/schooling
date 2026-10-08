---
title: Documentação que é construída, não escrita à parte
version: 1
---

As perguntas que as pessoas fazem sobre um mart são sempre as mesmas: o que uma linha quer dizer, que
dia é o `order_date`, os pedidos cancelados estão nele, de onde ele vem. Respostas guardadas numa wiki
envelhecem na primeira vez que o modelo muda e ninguém se lembra da wiki. **O dbt as guarda no
projeto**, ao lado dos testes, no mesmo YAML:

```
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    columns:
      - name: order_date
        description: The day of the sale in São Paulo, not in UTC.
        data_tests: [not_null]
      - name: revenue_cents
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the newest day it
      has and every day after it, so changes to older days need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
```

Uma `description` é texto simples, no modelo ou em qualquer coluna, e o YAML também é lugar de
testes: o `order_date` ganha um `not_null` enquanto está ali. Depois o dbt constrói a documentação,
e a Ana a lê de volta com um pequeno script dela, que o resto desta seção explica:

```
"""What dbt docs knows about one model: its description from the project,
its columns' types from the database, and what it depends on."""
import json
import sys

model = f"model.shop.{sys.argv[1]}"
manifest = json.load(open("shop/target/manifest.json"))
catalog = json.load(open("shop/target/catalog.json"))
node, table = manifest["nodes"][model], catalog["nodes"][model]
print(node["description"].strip())
for name, col in table["columns"].items():
    said = node["columns"].get(name, {}).get("description", "")
    print(f"  {name:<14}{col['type']:<10}{said}")
print("depends on:", ", ".join(manifest["parent_map"][model]))
print("used by:   ", ", ".join(manifest["child_map"][model]))
```

```
ana@vm:~/etl/shop$ dbt docs generate 2>&1 | tail -n 2
08:49:16  Building catalog
08:49:16  Catalog written to /home/ana/etl/shop/target/catalog.json
ana@vm:~/etl/shop$ ls target
catalog.json
compiled
graph.gpickle
graph_summary.json
index.html
manifest.json
osi_document.json
partial_parse.msgpack
run
run_results.json
semantic_manifest.json
ana@vm:~/etl$ python docs.py daily_sales
Books and revenue by day, shop and category, counting completed sales only. One row per combination that sold anything. Read by the morning report.
  order_date    date      The day of the sale in São Paulo, not in UTC.
  shop_id       integer   
  category      text      
  books         integer   
  revenue_cents bigint    Sum of quantity times unit price, in cents of a real.
depends on: model.shop.int_sales, model.shop.stg_books
used by:    exposure.shop.morning_report, test.shop.not_null_daily_sales_order_date.eadffc112b
```

O `dbt docs generate` grava dois arquivos que importam. O `manifest.json` é tudo o que o dbt sabe do
projeto: cada modelo, teste, fonte e exposure, a sua descrição, o seu SQL compilado e o grafo. O
`catalog.json` é o que o **banco** diz: cada coluna de cada relação que o dbt construiu, com o seu
tipo. O `index.html` é um site de uma página que lê os dois, e o `dbt docs serve` o serve numa porta
local; ele tem uma página por modelo e desenha o grafo.

O site é o jeito comum de ler. Os arquivos são o jeito útil de usar, porque são JSON: o `docs.py` da
Ana junta as duas metades para um modelo, na linha de comando. Repare no que veio de onde. A descrição do modelo e a de duas colunas vieram do YAML dela; os tipos
vieram do PostgreSQL; as dependências vieram dos `ref`s. `shop_id`, `category` e `books` não têm
descrição, e a saída mostra isso com clareza — **as lacunas da documentação ficam tão visíveis quanto
o resto dela**, que é o primeiro passo para preenchê-las.

Nem toda coluna precisa de uma frase. As que precisam são aquelas em que uma pessoa sensata
adivinharia errado: uma data no horário de São Paulo onde UTC era possível, dinheiro em centavos, um
nulo que quer dizer alguma coisa.
