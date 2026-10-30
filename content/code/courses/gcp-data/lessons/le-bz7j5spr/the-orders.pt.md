---
title: Os pedidos da Quitanda, feitos no seu laptop
version: 1
---

**Os dados que estas seis aulas consultam são dois meses de pedidos da Quitanda, e quem os faz é
você.** Um warehouse de verdade seria carregado com as exportações noturnas da aula 1, e o
laboratório não tem exportações reais para carregar. Então um programa curto as escreve: cada pedido
uma linha, com a loja, o bairro, o número de itens, o total, a forma de pagamento e o momento em que
foi feito. Ele tem semente fixa, então os pedidos no seu disco são os destas transcrições, e todo
número que esta aula imprime você também imprime.

## O gerador

Salve como `~/gcp/make_orders.py`:

```schooling-example
{"language": "python", "file": "make_orders.py", "parts": [{"code": "import datetime as dt\nimport pathlib\nimport random\n\nimport pyarrow as pa\nimport pyarrow.parquet as pq\n\nrng = random.Random(13)\nFIRST_DAY, DAYS = dt.date(2026, 8, 1), 60\nDISTRICTS = ['Pinheiros', 'Moema', 'Vila Mariana', 'Tatuapé',\n             'Santana', 'Butantã', 'Lapa', 'Mooca']\nSTORE_DISTRICT = {store: DISTRICTS[(store - 1) // 2] for store in range(1, 17)}\nWEEKDAY = [0.9, 0.85, 0.9, 0.95, 1.1, 1.3, 1.2]\nSAO_PAULO = dt.timezone(dt.timedelta(hours=-3))\n\n\n", "note": "**O gerador tem semente fixa**, então toda execução escreve os mesmos pedidos, e os seus números vão bater com os desta aula. Sessenta dias a partir de 1º de agosto de 2026, dezesseis lojas, duas em cada um de oito bairros. `WEEKDAY` deixa o sábado 30% mais movimentado que um dia médio e a terça 15% mais calma, porque a segunda é 0 no Python."}, {"code": "SCHEMA = pa.schema([\n    ('order_id', pa.string()),\n    ('customer_id', pa.string()),\n    ('store_id', pa.int64()),\n    ('district', pa.string()),\n    ('items', pa.int64()),\n    ('total_cents', pa.int64()),\n    ('payment', pa.string()),\n    ('created_at', pa.timestamp('us', tz='UTC')),\n])\n\n\n", "note": "**As colunas, com os tipos escritos** em vez de adivinhados pelos valores. Cada tipo do Parquet aqui tem um tipo do BigQuery em que ele é carregado: `string` vira `STRING`, `int64` vira `INT64`, e um timestamp em microssegundos com fuso vira `TIMESTAMP`. Dinheiro é centavo inteiro, nunca float. Não há coluna `dt`: a data está no nome da pasta."}, {"code": "def one_day(day):\n    opens = dt.datetime.combine(day, dt.time(7), SAO_PAULO)\n    count = int(20_000 * WEEKDAY[day.weekday()] * rng.uniform(0.95, 1.05))\n    seconds = sorted(rng.randrange(16 * 3600) for _ in range(count))\n    rows = {name: [] for name in SCHEMA.names}\n    for n, second in enumerate(seconds, start=1):\n        store = rng.randint(1, 16)\n        items = rng.randint(1, 30)\n        rows['order_id'].append(f'o-{day:%y%m%d}-{n:05d}')\n        rows['customer_id'].append(f'c-{rng.randint(1, 40_000):05d}')\n        rows['store_id'].append(store)\n        rows['district'].append(STORE_DISTRICT[store])\n        rows['items'].append(items)\n        rows['total_cents'].append(items * rng.randint(600, 2_500))\n        rows['payment'].append(rng.choices(['pix', 'card', 'cash'], [12, 7, 1])[0])\n        rows['created_at'].append(opens + dt.timedelta(seconds=second))\n    return pa.table(rows, schema=SCHEMA)\n\n\n", "note": "**Um dia de pedidos.** Cerca de vinte mil, entre sete da manhã e onze da noite, hora de São Paulo, na ordem em que foram feitos. Os clientes vêm de um grupo de quarenta mil, então a maioria pede mais de uma vez em dois meses. Pix é doze pedidos em vinte, cartão sete e dinheiro um."}, {"code": "total = 0\nfor i in range(DAYS):\n    day = FIRST_DAY + dt.timedelta(days=i)\n    folder = pathlib.Path('warehouse/orders') / f'dt={day}'\n    folder.mkdir(parents=True, exist_ok=True)\n    table = one_day(day)\n    pq.write_table(table, folder / 'part-000.parquet')\n    total += table.num_rows\nprint(f'{DAYS} days, {total:,} orders, from {FIRST_DAY} to {day}')\n", "note": "**Um arquivo Parquet por dia**, numa pasta chamada `dt=2026-08-01` e assim por diante. Esse jeito de nomear é a convenção chamada particionamento Hive: o nome da coluna, um sinal de igual e o valor. O DuckDB lê a data de volta a partir do caminho, e o BigQuery também, quando carrega esses arquivos ou os lê no lugar (aula 17)."}]}
```

**Vinte mil pedidos por dia é um mercado de tamanho crível**, e em sessenta dias isso dá uma tabela
de pouco mais de um milhão de linhas. É pouco para o BigQuery e o bastante para que uma consulta que
lê as colunas erradas, ou os dias errados, apareça nos números. Rode:

```
ana@laptop:~/gcp$ time python3 make_orders.py
60 days, 1,245,118 orders, from 2026-08-01 to 2026-09-29

real	0m9.559s
user	0m8.931s
sys	0m0.471s
ana@laptop:~/gcp$ ls warehouse/orders | head -3; ls warehouse/orders | wc -l
dt=2026-08-01
dt=2026-08-02
dt=2026-08-03
60
ana@laptop:~/gcp$ du -sh warehouse/orders
32M	warehouse/orders
```

**1.245.118 pedidos em sessenta pastas, 32 MB em disco**, escritos em nove segundos na máquina em que
estas aulas foram gravadas. A contagem é a mesma na sua, porque a semente fixa cada escolha que o
programa faz; o tempo é o que o seu processador levar.

## Os mesmos arquivos, no bucket

**Um warehouse carrega as tabelas a partir do Cloud Storage**, e os pedidos tratados da Quitanda
ficam em `quitanda-curated-prod`, o bucket que o esquema de nomes da aula 1 reservou para dado já
limpo. Com o fake-gcs-server rodando no terminal dele, como na aula 1, crie o bucket e copie a pasta
para cima:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1
Average throughput: 54.3MiB/s
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/orders/ | head -3
gs://quitanda-curated-prod/orders/dt=2026-08-01/
gs://quitanda-curated-prod/orders/dt=2026-08-02/
gs://quitanda-curated-prod/orders/dt=2026-08-03/
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/orders/** | wc -l
60
ana@laptop:~/gcp$ gcloud storage du --summarize gs://quitanda-curated-prod/orders/
32451790     gs://quitanda-curated-prod/orders/
```

**Sessenta objetos, 32.451.790 bytes**, cada um sob uma chave como
`orders/dt=2026-08-01/part-000.parquet`. As pastas que a listagem mostra não são objetos: o Cloud
Storage só tem chaves, e o `gcloud` desenha uma pasta onde a chave tiver uma `/`, como a aula 1
mostrou. O emulador guarda tudo em memória, então se você o parar a cópia some e os arquivos do seu
disco não; a linha do `cp` os põe de volta. A aula 17 lê esses objetos de volta do bucket.

## Carregá-los no BigQuery, o que não rodou

No Google Cloud, os dois passos seguintes criariam um dataset em São Paulo e carregariam os arquivos
numa tabela. Os dois comandos aparecem como você os digitaria, e nenhum rodou aqui:

```sh
bq mk --dataset --location=southamerica-east1 planner-dev:quitanda
bq load --source_format=PARQUET \
  --hive_partitioning_mode=AUTO \
  --hive_partitioning_source_uri_prefix=gs://quitanda-curated-prod/orders/ \
  quitanda.orders 'gs://quitanda-curated-prod/orders/*'
```

**`--hive_partitioning_mode=AUTO` é o que transforma `dt=2026-08-01` numa coluna**, então a tabela
carregada tem nove colunas, as oito dos arquivos e `dt`. **Uma carga em lote não custa nada**: a
página de preços a põe entre as operações gratuitas, feita num grupo compartilhado de slots, e depois
que o dado está no BigQuery você paga para guardá-lo. A carga também deixa os arquivos no bucket:
nada os apaga por você, então os mesmos pedidos passam a ser cobrados duas vezes, uma como objetos no
Cloud Storage e outra como tabela no BigQuery. A aula 17 é a outra escolha, uma tabela que lê os
arquivos onde eles estão.

## Perguntar ao DuckDB

**O `ask.py` dá a cada pasta dentro de `warehouse/` um nome que o DuckDB consegue consultar**, do
jeito que um dataset dá nome a uma tabela. É a única interface com o DuckDB de que estas aulas
precisam, e toda consulta delas passa por ele.

`ask.py`:

```python
import pathlib
import sys

import duckdb

con = duckdb.connect()
for folder in sorted(pathlib.Path('warehouse').iterdir()):
    con.sql(f"CREATE VIEW {folder.name} AS SELECT * FROM read_parquet("
            f"'{folder}/**/*.parquet', hive_partitioning = true)")
sql = sys.argv[1]
if sql.endswith('.sql'):
    sql = pathlib.Path(sql).read_text()
if sql.lstrip().upper().startswith('EXPLAIN'):
    print(con.sql(sql).fetchall()[0][1])
else:
    con.sql(sql).show(max_width=100)
```

**`hive_partitioning = true` é a versão do DuckDB de `--hive_partitioning_mode=AUTO`**: ele lê `dt`
do nome de cada pasta e o oferece como coluna. A view lê os arquivos toda vez que é consultada, então
uma pasta que você reescreve é o que a próxima consulta vê. A pergunta pode ser uma string ou o nome
de um arquivo `.sql`, e uma pergunta que começa com `EXPLAIN` imprime o plano como texto; as aulas
15 e 16 leem esses planos. Salve como `~/gcp/ask.py` e faça as três primeiras perguntas:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT count(*) AS orders, min(dt) AS first_day, max(dt) AS last_day FROM orders"
┌─────────┬────────────┬────────────┐
│ orders  │ first_day  │  last_day  │
│  int64  │    date    │    date    │
├─────────┼────────────┼────────────┤
│ 1245118 │ 2026-08-01 │ 2026-09-29 │
└─────────┴────────────┴────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT column_name, column_type FROM (DESCRIBE orders)"
┌─────────────┬──────────────────────────┐
│ column_name │       column_type        │
│   varchar   │         varchar          │
├─────────────┼──────────────────────────┤
│ order_id    │ VARCHAR                  │
│ customer_id │ VARCHAR                  │
│ store_id    │ BIGINT                   │
│ district    │ VARCHAR                  │
│ items       │ BIGINT                   │
│ total_cents │ BIGINT                   │
│ payment     │ VARCHAR                  │
│ created_at  │ TIMESTAMP WITH TIME ZONE │
│ dt          │ DATE                     │
└─────────────┴──────────────────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT order_id, customer_id, store_id, total_cents, created_at, dt FROM orders LIMIT 3"
┌────────────────┬─────────────┬──────────┬─────────────┬──────────────────────────┬────────────┐
│    order_id    │ customer_id │ store_id │ total_cents │        created_at        │     dt     │
│    varchar     │   varchar   │  int64   │    int64    │ timestamp with time zone │    date    │
├────────────────┼─────────────┼──────────┼─────────────┼──────────────────────────┼────────────┤
│ o-260801-00001 │ c-19923     │        7 │       13676 │ 2026-08-01 07:00:11-03   │ 2026-08-01 │
│ o-260801-00002 │ c-05602     │        1 │       24565 │ 2026-08-01 07:00:11-03   │ 2026-08-01 │
│ o-260801-00003 │ c-34549     │        6 │        3584 │ 2026-08-01 07:00:12-03   │ 2026-08-01 │
└────────────────┴─────────────┴──────────┴─────────────┴──────────────────────────┴────────────┘
```

**As nove colunas são os nomes do DuckDB para os tipos do BigQuery.** `VARCHAR` é a `STRING` do
BigQuery, `BIGINT` é `INT64`, `TIMESTAMP WITH TIME ZONE` é `TIMESTAMP`, e `DATE` é `DATE`. Essa
correspondência é a próxima seção inteira, porque é o tipo que decide quantos bytes o BigQuery conta
para um valor. A hora `07:00:11-03` é a de São Paulo: o DuckDB mostra um timestamp no fuso da
máquina, e o BigQuery guardaria o mesmo instante e o mostraria em UTC.
