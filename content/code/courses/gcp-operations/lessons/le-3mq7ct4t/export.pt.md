---
title: Perguntando à exportação de faturamento quem gastou o quê
version: 1
---

**A exportação de faturamento escreve cada linha da fatura, conforme ela acumula, num dataset do BigQuery, com o
projeto, o serviço, o SKU, o recurso e seus rótulos em cada linha.** É o único lugar onde "quanto o time X gastou em
Cloud Run no mês passado?" é uma consulta só. Exportar exige uma conta de faturamento, e o BigQuery não tem emulador,
então nenhum dos dois está aqui. O que roda é um mês da exportação da loja, gerado numa tabela SQLite que mantém os
nomes de coluna da exportação para as colunas que estas consultas usam, e o mesmo SQL que você rodaria no BigQuery, a
menos do dialeto. A lição 14 de `gcp-foundations` liga a exportação; esta lição a lê.

O programa que gera o mês, em `~/gcp/billing.py`:

```python
# billing.py
"""billing.py: a month of the shop's billing export, flattened, into SQLite.

The real export to BigQuery is nested (labels is an array of key and value,
project and service are records). This table keeps the export's names for the
columns the lesson queries, one row per resource per day. Generated, seeded.
"""
import random
import sqlite3

rng = random.Random(23)
ROWS = [  # project, folder, service, sku, resource, team label, cost a day (USD)
    ("planner-prod", "shop", "Cloud Run", "CPU Allocation Time", "shop-api", "shop", 9.40),
    ("planner-prod", "shop", "Cloud Run", "Memory Allocation Time", "shop-api", "shop", 2.10),
    ("planner-prod", "shop", "Cloud Logging", "Log Storage", "_Default", None, 1.30),
    ("planner-prod", "shop", "Cloud Storage", "Standard Storage", "planner-prod-order-exports", "shop", 0.60),
    ("planner-prod", "shop", "Compute Engine", "E2 Instance Core", "batch-1", "data", 2.90),
    ("planner-prod", "shop", "Compute Engine", "E2 Instance Core", "old-migration", None, 1.45),
    ("planner-prod", "shop", "Compute Engine", "Storage PD Capacity", "disk-restore-test", None, 0.85),
    ("planner-dev", "shop", "Cloud Build", "Build time", "shop-api", "shop", 0.70),
    ("planner-dev", "shop", "Artifact Registry", "Storage", "shop", "shop", 0.25),
    ("planner-dev", "sandbox", "Compute Engine", "E2 Instance Core", "sandbox-ana", None, 1.10),
]

db = sqlite3.connect("billing.db")
db.execute("DROP TABLE IF EXISTS export")
db.execute("""CREATE TABLE export (usage_start_time TEXT, project_id TEXT, folder TEXT,
    service TEXT, sku TEXT, resource_name TEXT, label_team TEXT, cost REAL)""")
for day in range(1, 31):
    for project, folder, service, sku, resource, team, daily in ROWS:
        cost = round(daily * rng.uniform(0.85, 1.15), 2)
        db.execute("INSERT INTO export VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                   (f"2026-09-{day:02d}", project, folder, service, sku, resource, team, cost))
db.commit()
print(db.execute("SELECT count(*), round(sum(cost), 2) FROM export").fetchone())
```

E um programa pequeno que roda uma consulta e imprime as linhas, em `~/gcp/q.py`:

```python
# q.py
"""q.py: run one SQL query against billing.db and print the rows."""
import sqlite3
import sys

for row in sqlite3.connect("billing.db").execute(sys.argv[1]):
    print(*row, sep="\t")
```

```
ana@laptop:~/gcp$ python3 billing.py
(300, 623.07)
```

Trezentas linhas, dez recursos ao longo de trinta dias, 623,07 USD no total.

## Por projeto, e por pasta

```
ana@laptop:~/gcp$ python3 q.py "SELECT project_id, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"
planner-prod	561.62
planner-dev	61.45
ana@laptop:~/gcp$ python3 q.py "SELECT folder, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"
shop	590.13
sandbox	32.94
```

Produção é nove décimos do mês. As pastas cortam diferente: `sandbox-ana` vive em `planner-dev`, mas na pasta
`sandbox`, então o total por pasta a tira da linha da própria loja. No BigQuery a pasta não é uma coluna: a exportação
traz a ancestralidade do projeto, `project.ancestors`, e a consulta a desaninha para achar a pasta.

## Por rótulo

```
ana@laptop:~/gcp$ python3 q.py "SELECT coalesce(label_team, '(no label)'), round(sum(cost), 2), round(100 * sum(cost) / (SELECT sum(cost) FROM export), 1) FROM export GROUP BY 1 ORDER BY 2 DESC"
shop	395.9	63.5
(no label)	139.86	22.4
data	87.31	14.0
```

O time `shop` gastou 63,5% e o time `data` 14,0%. **E 22,4% não é de ninguém**: 139,86 USD por mês sem rótulo `team`.
No BigQuery a mesma pergunta lê o array de rótulos:
`(SELECT value FROM UNNEST(labels) WHERE key = 'team')`. A próxima etapa é sobre esses 22,4%.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Uma barra horizontal para o mês da loja, 623,07 USD, dividida pelo rótulo de time: shop 395,90, ou 63,5%; sem rótulo 139,86, ou 22,4%; data 87,31, ou 14,0%.\"><defs><marker id=\"ah10\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"431.8\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"235.9\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shop</text><text x=\"235.9\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">63.5%</text><text x=\"235.9\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">395.90 USD</text><rect x=\"451.8\" y=\"50\" width=\"152.32\" height=\"50\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"527.96\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\" font-weight=\"600\">sem rótulo</text><text x=\"527.96\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">22.4%</text><text x=\"527.96\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">139.86 USD</text><rect x=\"604.12\" y=\"50\" width=\"95.2\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"651.72\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">data</text><text x=\"651.72\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14.0%</text><text x=\"651.72\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">87.31 USD</text></svg>", "caption": "Mais de um quinto do mês não é de ninguém.", "same": ["data", "shop"]}
```
