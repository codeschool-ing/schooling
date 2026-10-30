---
title: Um mês de linhas
version: 1
---

**O laboratório não tem fatura, então faz uma**: um mês de linhas na forma da exportação, escritas por um
programa que o aluno pode ler, e consultadas com o mesmo SQL que uma exportação real aceitaria. Todo número
nesta seção e na próxima é invenção do programa; o que é real é a forma das linhas e o que as consultas fazem
com elas. O motor é o DuckDB, instalado no ambiente virtual do laboratório na lição 1, porque o BigQuery não
tem emulador e o DuckDB lê as mesmas linhas aninhadas.

Crie um diretório e salve isto como `~/gcp/export/make_export.py`:

```sh
mkdir -p ~/gcp/export && cd ~/gcp/export
```

```schooling-example
{"language": "python", "file": "make_export.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Writes one invented month of a Cloud Billing export, in the export's shape.\n\n    python3 make_export.py > october.jsonl\n\nEvery row is made up: the projects are the planner's, the SKU names are\nwritten like Google's, and the prices are examples, not Google's.\n\"\"\"\nimport json\nimport random\nfrom datetime import date, timedelta\n\n", "note": "Para que serve o programa, dito nas primeiras linhas: toda linha que ele escreve é inventada, na forma da exportação real. Nada nele lê uma fatura."}, {"code": "rng = random.Random(14)\nMONTH = date(2026, 10, 1)\n\n", "note": "Um gerador de números aleatórios com semente, para o mês sair igual em toda execução, e o próprio mês: outubro de 2026."}, {"code": "# project, service, SKU, unit, units a day, example price per unit, team label\nLINES = [\n    ('planner-prod', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 96, 0.045, 'planner'),\n    ('planner-prod', 'Compute Engine', 'N2 Instance Ram running in Sao Paulo', 'gibibyte hour', 384, 0.006, 'planner'),\n    ('planner-prod', 'Compute Engine', 'Network Inter Region Data Transfer Out', 'gibibyte', 40, 0.14, 'planner'),\n    ('planner-staging', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 24, 0.045, 'planner'),\n    ('planner-dev', 'Cloud Pub/Sub', 'Message Delivery Basic', 'tebibyte', 0.02, 60.0, 'data'),\n    ('planner-dev', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 12, 0.045, None),\n    ('planner-network', 'Networking', 'Cloud NAT Gateway Uptime', 'hour', 24, 0.0014, 'network'),\n]\n\n", "note": "Sete linhas da fatura do planner, uma por projeto e SKU: quantas unidades por dia cada uma usa, um preço por unidade **de exemplo**, e o rótulo `team` que o recurso leva. A máquina do `planner-dev` não leva nenhum; alguém esqueceu, e a próxima seção a acha."}, {"code": "def credits(service, cost, day):\n    if service == 'Compute Engine' and day > 7:\n        return [{'name': 'Sustained Usage Discount', 'amount': round(-0.2 * cost, 6),\n                 'type': 'SUSTAINED_USAGE_DISCOUNT'}]\n    if service == 'Cloud Pub/Sub' and day == 1:\n        return [{'name': 'Free Tier', 'amount': round(-cost, 6), 'type': 'FREE_TIER'}]\n    return []\n\n", "note": "Créditos, os valores negativos da lição 13. O Compute Engine ganha um crédito de uso contínuo depois que uma máquina rodou uma semana do mês, uma simplificação das faixas; o primeiro dia do Pub/Sub é coberto pelo nível gratuito."}, {"code": "for day in range(1, 32):\n    start = MONTH + timedelta(days=day - 1)\n    for project, service, sku, unit, per_day, price, team in LINES:\n        amount = round(per_day * rng.uniform(0.9, 1.1), 4)\n        cost = round(amount * price, 6)\n        print(json.dumps({\n            'billing_account_id': '012345-6789AB-CDEF01',\n            'service': {'description': service},\n            'sku': {'description': sku},\n            'usage_start_time': f'{start}T00:00:00Z',\n            'project': {'id': project},\n            'labels': [{'key': 'team', 'value': team}] if team else [],\n            'location': {'region': 'southamerica-east1'},\n            'cost': cost,\n            'currency': 'USD',\n            'usage': {'amount': amount, 'unit': unit},\n            'credits': credits(service, cost, day),\n            'invoice': {'month': '202610'},\n            'cost_type': 'regular',\n        }))\n", "note": "Uma linha por dia por item, com o uso variando até um décimo para cima ou para baixo. Os campos da linha são um subconjunto das colunas da exportação padrão, com os mesmos nomes e o mesmo aninhamento: `service.description`, `labels` como lista de chave e valor, `credits` como lista."}]}
```

Depois um programa curto que roda um arquivo SQL contra o mês, chamando as linhas de `export`. Salve como
`ask.py`:

```python
#!/usr/bin/env python3
"""Runs one SQL file against the month in october.jsonl, as a table named export.

    python3 ask.py QUERY.sql
"""
import sys

import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW export AS SELECT * FROM read_json_auto('october.jsonl')")
print(con.sql(open(sys.argv[1]).read()))
```

Escreva o mês, e pergunte quantas linhas ele tem, em que dias, por quanto. Salve a pergunta como `month.sql`:

```sql
SELECT count(*) AS lines,
       min(usage_start_time) AS first_day,
       max(usage_start_time) AS last_day,
       round(sum(cost), 2) AS gross
FROM export
```

```
ana@laptop:~/gcp/export$ python3 make_export.py > october.jsonl
ana@laptop:~/gcp/export$ python3 ask.py month.sql
┌───────┬─────────────────────┬─────────────────────┬────────┐
│ lines │      first_day      │      last_day       │ gross  │
│ int64 │      timestamp      │      timestamp      │ double │
├───────┼─────────────────────┼─────────────────────┼────────┤
│   217 │ 2026-10-01 00:00:00 │ 2026-10-31 00:00:00 │ 469.05 │
└───────┴─────────────────────┴─────────────────────┴────────┘
```

Sete linhas por dia durante 31 dias, 469,05 dólares antes dos créditos. **Esse total não é a fatura**: os
créditos ficam numa coluna própria, e a próxima seção os subtrai.

## A forma de uma linha

Pergunte ao DuckDB o que ele fez das colunas. Salve como `columns.sql`:

```sql
SELECT column_name, column_type FROM (DESCRIBE export)
```

```
ana@laptop:~/gcp/export$ python3 ask.py columns.sql
┌────────────────────┬─────────────────────────────────────────────────────────┐
│    column_name     │                       column_type                       │
│      varchar       │                         varchar                         │
├────────────────────┼─────────────────────────────────────────────────────────┤
│ billing_account_id │ VARCHAR                                                 │
│ service            │ STRUCT(description VARCHAR)                             │
│ sku                │ STRUCT(description VARCHAR)                             │
│ usage_start_time   │ TIMESTAMP                                               │
│ project            │ STRUCT(id VARCHAR)                                      │
│ labels             │ STRUCT("key" VARCHAR, "value" VARCHAR)[]                │
│ location           │ STRUCT(region VARCHAR)                                  │
│ cost               │ DOUBLE                                                  │
│ currency           │ VARCHAR                                                 │
│ usage              │ STRUCT(amount DOUBLE, unit VARCHAR)                     │
│ credits            │ STRUCT("name" VARCHAR, amount DOUBLE, "type" VARCHAR)[] │
│ invoice            │ STRUCT("month" VARCHAR)                                 │
│ cost_type          │ VARCHAR                                                 │
└────────────────────┴─────────────────────────────────────────────────────────┘
  13 rows                                                            2 columns
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-row\" aria-label=\"Uma linha da exportação inventada, de 8 de outubro, desenhada como os seus campos. À esquerda, campos simples e grupos de campos lidos com um ponto: service.description é Compute Engine, sku.description é N2 Instance Core running in Sao Paulo, project.id é planner-prod, cost é 3.965359 como número de ponto flutuante. À direita, duas listas que pertencem à mesma linha: labels, com uma entrada de chave team e valor planner, e credits, com uma entrada chamada Sustained Usage Discount e um valor negativo. Uma nota diz que uma lista pode estar vazia, e que um rótulo é achado olhando dentro da lista, não nomeando uma coluna.\"><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma linha</text><text x=\"40.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">service.description</text><text x=\"40.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Compute Engine</text><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sku.description</text><text x=\"40.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">N2 Instance Core running in Sao Paulo</text><text x=\"40.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">project.id</text><text x=\"40.0\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"40.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">usage.amount</text><text x=\"40.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">88.1191 hour</text><text x=\"40.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">cost</text><text x=\"40.0\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.965359</text><text x=\"40.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grupos de campos, lidos com um ponto</text><rect x=\"420.0\" y=\"56.0\" width=\"260.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"432.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">labels: uma lista</text><text x=\"432.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">key team, value planner</text><rect x=\"420.0\" y=\"136.0\" width=\"260.0\" height=\"82.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"432.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">credits: uma lista</text><text x=\"432.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Sustained Usage Discount</text><text x=\"432.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">amount -0.793072</text><text x=\"550.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer lista pode estar vazia</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um rótulo é achado dentro da lista, nunca como coluna</text></svg>", "caption": "Campos se leem com um ponto; rótulos e créditos são listas dentro da linha."}
```

Três coisas nessa forma são as três coisas com que toda consulta à exportação real tem de lidar:

| coluna | no BigQuery | o que significa para uma consulta |
|---|---|---|
| `service`, `sku`, `project`, `location`, `usage` | `STRUCT` | um grupo de campos, lido com um ponto: `project.id`, `sku.description` |
| `labels`, `credits` | `ARRAY` de `STRUCT` | **uma lista por linha**: uma linha tem quantos rótulos e créditos tiver, e nenhum é uma coluna própria |
| `cost` | `FLOAT64` | **um número de ponto flutuante**, não centavos inteiros |

A primeira é questão de sintaxe. A segunda é o porquê de um rótulo não poder ser agrupado diretamente: não há
coluna `labels.team`, só uma lista em que uma entrada `team` pode estar ou não. A terceira é uma escolha do
Google, e é por isso que todo total desta lição é arredondado no fim e nunca no caminho: uma soma de valores de
ponto flutuante pode errar por uma fração de centavo, e arredondar cada linha antes erraria mais.

A exportação real tem muito mais colunas que o programa escreve: os ids do SKU e do serviço, o número do
projeto e os ancestrais dele na árvore, os horários em que a linha foi exportada, o preço e a taxa de conversão
de moeda, entre outras. As de cima são as que as perguntas do planner precisam.
