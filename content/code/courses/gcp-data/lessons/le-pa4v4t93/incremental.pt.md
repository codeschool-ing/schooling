---
title: A ideia de um agregado incremental, no DuckDB
version: 1
---

**Esta seção é a ideia da atualização incremental, feita à mão, e não a implementação do BigQuery.** Uma
visão materializada mantém um agregado guardado atualizado agregando só o que é novo e somando ao que já
está lá. O DuckDB não tem visões materializadas do tipo do BigQuery, então um programa curto faz a
contabilidade sozinho: uma pasta do agregado por dia de pedidos, e uma execução que preenche só os dias que
o agregado ainda não tem. O que ele mostra é por que o incremental é barato, medido em linhas lidas. O que
ele não mostra é nada sobre como o BigQuery agenda, guarda ou reescreve, que a seção anterior tirou da
documentação.

## O programa

Salve como `~/gcp/incremental.py`:

```schooling-example
{"language": "python", "file": "incremental.py", "parts": [{"code": "import pathlib\n\nimport duckdb\n\nORDERS, SALES = pathlib.Path('warehouse/orders'), pathlib.Path('warehouse/daily_sales')\n\ncon = duckdb.connect()\ncon.sql(f\"CREATE VIEW orders AS SELECT * FROM read_parquet(\"\n        f\"'{ORDERS}/**/*.parquet', hive_partitioning = true)\")\n\n", "note": "**Duas tabelas na pasta do warehouse**: os pedidos, como a aula 13 os escreveu, e `daily_sales`, o agregado que este programa mantém, uma pasta por dia como os pedidos. Como fica dentro de `warehouse/`, o `ask.py` consegue consultá-lo pelo nome."}, {"code": "done = {p.name for p in SALES.glob('dt=*')}\nnew = sorted(p.name for p in ORDERS.glob('dt=*') if p.name not in done)\n\n", "note": "**O que é novo é o que o agregado ainda não tem**: uma pasta de dia em `orders` sem pasta de mesmo nome em `daily_sales`. É a contabilidade que o BigQuery faz para uma visão materializada, feita comparando nomes."}, {"code": "read = 0\nfor folder in new:\n    day = folder.removeprefix('dt=')\n    (SALES / folder).mkdir(parents=True, exist_ok=True)\n    con.sql(f\"\"\"COPY (SELECT district, count(*) AS orders, sum(total_cents)::BIGINT AS sales\n                      FROM orders WHERE dt = DATE '{day}'\n                      GROUP BY district ORDER BY district)\n                TO '{SALES / folder}/part-000.parquet' (FORMAT parquet)\"\"\")\n    read += con.sql(f\"SELECT count(*) FROM orders WHERE dt = DATE '{day}'\").fetchone()[0]\n\n", "note": "**Cada dia novo é agregado só a partir dos pedidos daquele dia**, e escrito como a partição daquele dia do agregado. Pedidos por bairro, e a soma deles, convertida de volta para `BIGINT` para o dinheiro continuar em centavos inteiros. As linhas lidas são contadas, porque quantas a atualização lê é o ponto inteiro."}, {"code": "print(f'new days aggregated: {len(new)}, order rows read: {read:,}, days in daily_sales: {len(done) + len(new)}')\n", "note": "**Uma linha de contas**, para cada execução dizer o que fez."}]}
```

## Chega um dia

**Para ver um dia chegar, o último é posto de lado primeiro**, como se a carga noturna de 29 de setembro
ainda não tivesse acontecido. Depois o agregado é construído, rodado de novo sem nada novo, e rodado mais
uma vez depois que o dia volta:

```
ana@laptop:~/gcp$ mv warehouse/orders/dt=2026-09-29 day-60
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 59, order rows read: 1,228,759, days in daily_sales: 59
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 0, order rows read: 0, days in daily_sales: 59
ana@laptop:~/gcp$ mv day-60 warehouse/orders/dt=2026-09-29
ana@laptop:~/gcp$ python3 incremental.py
new days aggregated: 1, order rows read: 16,359, days in daily_sales: 60
```

**A primeira execução leu 1.228.759 pedidos para construir 59 dias**: tudo o que havia, que é o que custa
criar uma visão materializada. **A segunda não leu nada**, porque nada era novo; uma atualização sem
mudança na tabela base é gratuita. **A terceira leu 16.359 pedidos, um dia**, e deixou 59 dias do agregado
intocados. Essa razão, as linhas de um dia contra todas, é o que a manutenção incremental economiza a cada
atualização, e ela cresce com o histórico: contra três anos de pedidos, a atualização de uma noite lê
cerca de um milésimo da tabela.

## Está certo?

**Um agregado incremental só vale se bater com uma recomputação inteira**, então pergunte ao DuckDB a
diferença entre os dois, o agregado calculado do zero a partir de todos os pedidos, menos o que o programa
manteve:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT count(*) AS differences FROM (SELECT dt, district, count(*) AS orders, sum(total_cents) AS sales FROM orders GROUP BY ALL EXCEPT SELECT dt, district, orders, sales FROM daily_sales)"
┌─────────────┐
│ differences │
│    int64    │
├─────────────┤
│           0 │
└─────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT district, orders, sales FROM daily_sales WHERE dt = DATE '2026-09-29' ORDER BY district"
┌──────────────┬────────┬──────────┐
│   district   │ orders │  sales   │
│   varchar    │ int64  │  int64   │
├──────────────┼────────┼──────────┤
│ Butantã      │   2132 │ 51441722 │
│ Lapa         │   2018 │ 47482131 │
│ Moema        │   1967 │ 47805392 │
│ Mooca        │   2111 │ 50703844 │
│ Pinheiros    │   2040 │ 48877437 │
│ Santana      │   1975 │ 48953221 │
│ Tatuapé      │   2071 │ 49693044 │
│ Vila Mariana │   2045 │ 48705315 │
└──────────────┴────────┴──────────┘
```

**Nenhuma diferença**, e as oito linhas do último dia estão lá, com os pedidos e as vendas em centavos
inteiros. `EXCEPT` devolve as linhas da primeira consulta que não estão na segunda, então zero quer dizer
que todo dia e bairro que a computação inteira produziu está na incremental, com os mesmos números.

## Uma correção

**Uma mudança num dia já agregado não é algo que o programa percebe**, porque ele só procura dias que nunca
viu. O conserto é jogar fora aquele dia do agregado e rodar de novo, que é o que o BigQuery faz com uma
visão materializada quando uma partição da base muda:

```
ana@laptop:~/gcp$ rm -r 'warehouse/daily_sales/dt=2026-09-15' && python3 incremental.py
new days aggregated: 1, order rows read: 16,279, days in daily_sales: 60
```

**Um dia recalculado, a partir de 16.279 pedidos.** A regra do programa é grosseira, um dia inteiro para
qualquer mudança, e a do BigQuery tem a mesma forma: a unidade de recomputação é a partição. É também o
motivo pelo qual o particionamento de uma view deve seguir o da tabela base: uma correção num dia então
custa um dia, onde uma view particionada de outro jeito, ou sem partição, teria de ser recalculada a partir
de tudo.
