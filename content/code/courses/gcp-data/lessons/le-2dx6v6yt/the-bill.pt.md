---
title: As duas decisões, com preço
version: 1
---

**Particionamento e clustering se multiplicam, e a conta é o produto.** O particionamento decide quais
dias uma consulta lê, o clustering decide quais blocos desses dias, e sob demanda cobra as colunas
citadas no que sobrar. O programa abaixo põe os três layouts desta aula lado a lado para a pergunta que
o painel das lojas da Quitanda faz toda hora, as vendas de uma loja ontem, e precifica cada um com as
regras da aula 14. Salve como `~/gcp/layout_bill.py`:

```schooling-example
{"language": "python", "file": "layout_bill.py", "parts": [{"code": "import math\nimport sys\n\nimport duckdb\n\nSCALE = int(sys.argv[1])\nPRICE_PER_TIB, MB, TIB = 11.25, 2**20, 2**40  # on demand, southamerica-east1, read 2026-10-30\nDAY, STORE = '2026-09-29', 7\n\n", "note": "**A pergunta é a do painel**: as vendas de uma loja num dia. `SCALE` multiplica cada byte, para o mesmo programa precificar a Quitanda como ela é e uma empresa mil vezes maior."}, {"code": "con = duckdb.connect()\nrows = con.sql(\"SELECT count(*) FROM read_parquet('warehouse/orders/*/*.parquet')\").fetchone()[0]\nday = con.sql(f\"SELECT count(*) FROM read_parquet('warehouse/orders/dt={DAY}/*.parquet')\").fetchone()[0]\n", "note": "**Duas medições de linhas**: a tabela inteira, que uma tabela sem partição leria, e o único dia que um filtro de partição deixa."}, {"code": "groups, hit = con.sql(f\"\"\"\n    SELECT count(*), count(*) FILTER (WHERE stats_min_value::INT <= {STORE}\n                                        AND stats_max_value::INT >= {STORE})\n    FROM parquet_metadata('warehouse/orders_by_store/dt={DAY}/*.parquet')\n    WHERE path_in_schema = 'store_id'\"\"\").fetchone()\n\n", "note": "**A medição do clustering** da última seção: dos grupos de linhas do dia, ordenados por loja, quantos podem conter a loja pedida. A fração deles faz o papel dos blocos do BigQuery."}, {"code": "read = 3 * 8  # dt, store_id and total_cents: three 8-byte columns a row\nlayouts = {\n    'no partitions': rows * read,\n    'partitioned by dt': day * read,\n    'partitioned by dt, clustered by store_id': day * read * hit / groups,\n}\n", "note": "**Os bytes lógicos que cada layout lê.** A consulta cita três colunas, todas `INT64` ou `DATE`, então 24 bytes por linha, sobre as linhas que cada layout não consegue evitar."}, {"code": "print(f'sum(total_cents) for store {STORE} on {DAY}, at {SCALE:,} times the data')\nfor name, logical in layouts.items():\n    billed = math.ceil(max(logical * SCALE, 10 * MB) / MB) * MB\n    usd = billed / TIB * PRICE_PER_TIB\n    print(f'  {name:<42}{billed:>16,} bytes {usd:9.4f} USD   hourly for a month {usd * 720:8.2f} USD')\n", "note": "**As regras da aula 14, aplicadas**: o mínimo de 10 MB, o arredondamento para o MB, o preço por TiB, e um mês do painel atualizando de hora em hora, 720 vezes."}]}
```

```
ana@laptop:~/gcp$ python3 layout_bill.py 1
sum(total_cents) for store 7 on 2026-09-29, at 1 times the data
  no partitions                                   30,408,704 bytes    0.0003 USD   hourly for a month     0.22 USD
  partitioned by dt                               10,485,760 bytes    0.0001 USD   hourly for a month     0.08 USD
  partitioned by dt, clustered by store_id        10,485,760 bytes    0.0001 USD   hourly for a month     0.08 USD
ana@laptop:~/gcp$ python3 layout_bill.py 1000
sum(total_cents) for store 7 on 2026-09-29, at 1,000 times the data
  no partitions                               29,883,367,424 bytes    0.3058 USD   hourly for a month   220.15 USD
  partitioned by dt                              393,216,000 bytes    0.0040 USD   hourly for a month     2.90 USD
  partitioned by dt, clustered by store_id        88,080,384 bytes    0.0009 USD   hourly for a month     0.65 USD
```

**No tamanho da própria Quitanda, o particionamento economiza 20 MB por consulta e o clustering não
economiza nada.** A tabela sem partições é cobrada por 30.408.704 bytes, as três colunas sobre todas as
linhas. Particionada, um dia de três colunas são 392.616 bytes, muito abaixo do mínimo de 10 MB, então é
cobrada por 10.485.760; o clustering corta ainda mais os bytes lidos e o mínimo engole isso também.
Vinte e dois centavos por mês contra oito não é motivo para fazer nada.

**A mil vezes o tamanho, os layouts são três contas diferentes.** Sem partições, cada atualização de hora
em hora lê a tabela inteira, 0,3058 USD, e o mês dá 220,15 USD. Particionada por dia, ela lê um dia de
sessenta, 2,90 USD por mês. Clusterizada por loja também, ela lê dois nonos desse dia, 0,65 USD por mês:
**cerca de um trezentos e quarenta avos da primeira**, para uma tabela com as mesmas linhas e que
responde com os mesmos números.

**Esses são números calculados, e duas das entradas deles são do DuckDB.** As contagens de linhas são
medidas. A fração do clustering é a fração de grupos de linhas do Parquet da seção anterior, no papel dos
blocos do BigQuery, cuja fração real o BigQuery só informa depois de uma consulta rodar. A multiplicação
por mil trata uma empresa maior como mais dos mesmos pedidos, o que é justo para os bytes de uma coluna e
não diz nada sobre como as lojas e os dias dela se distribuem. É o tamanho de uma conta, não uma fatura.

## A tabela, sessenta dias contra três anos

**A linha sem partições cresce com o histórico e as linhas particionadas não.** Sessenta dias de dados é
o que este laboratório guarda; a Quitanda guarda três anos. Sem partições, o painel de hora em hora lê
três anos de linhas para responder sobre ontem, dezoito vezes os sessenta dias, então os 220,15 USD por
mês viram cerca de dezoito vezes isso conforme o histórico enche, enquanto o painel particionado continua
lendo um dia. **O particionamento transforma um custo que cresce com o tempo num custo estável**, e esse
é o principal motivo para decidi-lo no primeiro dia e não no centésimo.

## Quanto custa mudar de ideia

**As duas decisões são tomadas quando a tabela é criada, e mudar qualquer uma significa escrever a tabela
de novo.** O BigQuery não reparticiona uma tabela no lugar. O jeito de passar para um layout novo é uma
consulta que lê a tabela antiga inteira e escreve uma nova, `CREATE TABLE ... PARTITION BY ... CLUSTER BY
... AS SELECT * FROM` a antiga, e sob demanda essa consulta é cobrada por cada byte de cada coluna que
lê, uma vez. Na tabela da Quitanda hoje isso é um mínimo de 10 MB; em três anos de um fluxo de cliques é
a maior consulta que o warehouse vai rodar na vida. O clustering é o mais brando dos dois: pode ser mudado
numa tabela existente, com `bq update --clustering_fields`, sem uma consulta reescrever tudo.

## Os pedidos da Quitanda, decididos

**Particionada por `dt`, por dia**, porque quase toda pergunta cita um dia, uma semana ou um mês, e um dia
de pedidos é uma partição que vale a pena ter.

**Clusterizada por `store_id`**, o segundo filtro dos painéis, com espaço para uma segunda coluna de
clustering, como `payment`, se as perguntas passarem a pedir isso.

**`require_partition_filter` ligado**, para a consulta que esqueceu a data falhar de graça em vez de ler
três anos.

**`partition_expiration_days` em 1.095**, três anos, se esse é o histórico de que o negócio precisa, para
os dias antigos saírem da tabela, e da conta, sozinhos.

E toda consulta que a lê **cita as colunas de que precisa**, o que nenhum layout faz por ela.
