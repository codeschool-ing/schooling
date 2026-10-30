---
title: Uma tabela de lakehouse, gravada num contêiner que você pode abrir
version: 1
---

**O Fabric não está no seu computador, e nada nesta seção é o Fabric.** O que está aqui é a coisa
que o Fabric guarda: uma tabela Delta, que é uma pasta de arquivos Parquet com um log ao lado,
gravada num contêiner de blobs no lugar em que um lakehouse guarda suas tabelas. O programa que a
grava é o `deltalake`, a biblioteca Delta de código aberto, e o contêiner é do Azurite. Cada byte
dela é um byte que o Spark do Fabric, o warehouse dele e o Power BI leriam do mesmo jeito, porque
todos leem o formato aberto e nada privado.

## Um mês de pedidos

Todo programa daqui até a lição 20 lê o mesmo mês: o outubro de 2026 da Quitanda, uns cem mil
pedidos, gerados por um programa para que todo computador tenha exatamente as mesmas linhas. Salve-o
em `~/azure`:

`orders.py`:

```python
"""orders.py: Quitanda's October 2026, one row per order, the same on every computer."""
import random
from datetime import date, timedelta

import pyarrow as pa

PLACES = ["Pinheiros", "Vila Madalena", "Moema", "Tatuapé", "Santana", "Mooca", "Butantã", "Lapa",
          "Perdizes", "Itaim Bibi", "Bela Vista", "Liberdade", "Ipiranga", "Saúde", "Vila Mariana", "Penha"]
PAYMENTS = ["pix"] * 9 + ["credit"] * 7 + ["debit"] * 3 + ["meal-voucher"] * 2


def october(days=31, seed=2026):
    rnd = random.Random(seed)
    cols = {c: [] for c in ("order_id", "dt", "hour", "customer_id", "neighbourhood", "payment", "total_cents")}
    for d in range(days):
        day = date(2026, 10, 1) + timedelta(days=d)
        hours = sorted(rnd.choices(range(7, 24), k=rnd.randint(2800, 3600)))
        for n, hour in enumerate(hours, 1):
            cols["order_id"].append(f"{day:%m%d}-{n:05d}")
            cols["dt"].append(day.isoformat())
            cols["hour"].append(hour)
            cols["customer_id"].append(f"c-{rnd.randint(1, 9000)}")
            cols["neighbourhood"].append(rnd.choice(PLACES))
            cols["payment"].append(rnd.choice(PAYMENTS))
            cols["total_cents"].append(rnd.randint(900, 32000))
    return pa.table(cols)
```

**A semente é o que o torna igual em todo lugar.** `random.Random(2026)` sorteia os mesmos números na
mesma ordem em qualquer máquina com Python 3, então os totais impressos abaixo são os que você vai
obter. Os pedidos de cada dia vêm ordenados por hora, como viriam no export de uma loja.

## Gravando a tabela

O próximo programa grava o mês como uma tabela Delta, onde um lakehouse chamado `sales`, num
workspace chamado `quitanda-analytics`, guardaria uma tabela chamada `orders`:

```schooling-example
{"language": "python", "file": "onelake.py", "parts": [
{"code": "\"\"\"onelake.py: October's orders as a Delta table, where a lakehouse keeps its tables.\"\"\"\nfrom deltalake import DeltaTable, write_deltalake\n\nfrom orders import october\n\n", "note": "O `deltalake` é a biblioteca Delta escrita em Rust, com uma cara em Python. Ela não precisa de Spark nem de Java, e é por isso que cabe no laboratório de um laptop."},
{"code": "AZURITE = {\"account_name\": \"devstoreaccount1\", \"use_emulator\": \"true\"}\nTABLE = \"az://quitanda-analytics/sales.Lakehouse/Tables/orders\"\n\n", "note": "**`use_emulator` aponta a biblioteca para o Azurite** em `127.0.0.1:10000`, com a conta e a chave publicadas. O caminho é o contêiner, depois a pasta do lakehouse, depois `Tables`, depois a tabela: o mesmo formato de um caminho do OneLake, com o contêiner do Azurite no lugar do workspace."},
{"code": "if __name__ == \"__main__\":\n    write_deltalake(TABLE, october(), storage_options=AZURITE)\n    table = DeltaTable(TABLE, storage_options=AZURITE)\n    print(f\"version {table.version()}, {len(table.file_uris())} data file, {table.count():,} rows\")\n", "note": "Uma chamada grava o Parquet e depois a entrada do log que o torna uma tabela. Em seguida a tabela é aberta de novo a partir do contêiner, então o que se imprime é o que um segundo leitor encontraria, não o que quem escreveu lembra."}
]}
```

E um terceiro, que faz uma pergunta à tabela com o DuckDB, um motor SQL que roda dentro do programa
Python:

`ask.py`:

```python
import sys

import duckdb
from deltalake import DeltaTable

from onelake import AZURITE, TABLE

orders = DeltaTable(TABLE, storage_options=AZURITE).to_pyarrow_dataset()
duckdb.sql(sys.argv[1]).show()
```

Com o Azurite rodando e as quatro linhas de "Every time you open a terminal" da lição 1 digitadas,
crie o contêiner, grave a tabela e ponha o export cru da noite ao lado dela, na outra metade do
lakehouse:

```
ana@laptop:~/azure$ az storage container create -n quitanda-analytics
{
  "created": true
}
ana@laptop:~/azure$ python onelake.py
version 0, 1 data file, 98,727 rows
ana@laptop:~/azure$ python -c "import orders, pyarrow.csv as c; c.write_csv(orders.october(days=1), 'export.csv')"
ana@laptop:~/azure$ az storage blob upload -c quitanda-analytics -f export.csv -n sales.Lakehouse/Files/exports/2026-10-01.csv -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ az storage blob list -c quitanda-analytics --query '[].{name:name, bytes:properties.contentLength}' -o table
Name                                                                                               Bytes
-------------------------------------------------------------------------------------------------  -------
sales.Lakehouse/Files/exports/2026-10-01.csv                                                       182294
sales.Lakehouse/Tables/orders/_delta_log/00000000000000000000.json                                 1949
sales.Lakehouse/Tables/orders/part-00000-f29949c4-d009-44ee-9f5e-a1b643a5e98d-c000.snappy.parquet  1205188
```

**Três blobs, e só dois deles são a tabela.** Em `Files` está um CSV como qualquer outro blob, que
nada vai consultar até alguém carregá-lo. Em `Tables/orders` estão o arquivo Parquet, com um nome
aleatório, e o log, numerado a partir de zero. Os 98.727 pedidos ocupam 1.205.188 bytes em Parquet
comprimido com Snappy; só o primeiro dia, em CSV, tem 182.294.

## O log é a tabela

**Um leitor não lista a pasta para achar as linhas de uma tabela Delta; ele lê o log.** Cada arquivo
em `_delta_log` é um commit, e cada linha dele é uma ação. Baixe o primeiro e olhe as linhas:

```
ana@laptop:~/azure$ az storage blob download -c quitanda-analytics -n sales.Lakehouse/Tables/orders/_delta_log/00000000000000000000.json -f v0.json -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ jq -c keys v0.json
["commitInfo"]
["protocol"]
["metaData"]
["add"]
ana@laptop:~/azure$ jq -c '.protocol // empty' v0.json
{"minReaderVersion":1,"minWriterVersion":2}
ana@laptop:~/azure$ jq -r '.metaData // empty | .schemaString | fromjson | .fields[] | "\(.name) \(.type)"' v0.json
order_id string
dt string
hour long
customer_id string
neighbourhood string
payment string
total_cents long
ana@laptop:~/azure$ jq -c '.add // empty | .stats | fromjson | {numRecords, minValues: {dt: .minValues.dt}, maxValues: {dt: .maxValues.dt}}' v0.json
{"numRecords":98727,"minValues":{"dt":"2026-10-01"},"maxValues":{"dt":"2026-10-31"}}
```

Quatro ações, e cada uma é uma promessa a qualquer leitor:

- **`protocol`** diz que recursos do formato um leitor precisa entender para ler a tabela. A versão
  de leitura 1 e a de escrita 2 não pedem nada além do básico; uma tabela que usa um recurso mais
  novo, como deletion vectors, aumenta esses números, e um leitor velho demais para o recurso precisa
  recusar a tabela em vez de lê-la errado.
- **`metaData`** traz o schema, as colunas de partição (nenhuma aqui) e as configurações da tabela.
- **`add`** nomeia um arquivo Parquet como parte da tabela, com o tamanho e as **estatísticas**:
  quantas linhas, e o menor e o maior valor de cada coluna. Um leitor que procura um dia pode pular
  sem abrir um arquivo cuja faixa de `dt` não inclui aquele dia.
- **`commitInfo`** registra quem fez o quê e quando, o que a lição 18 usa para viajar no tempo.

**Qualquer coisa na pasta que nenhum `add` nomeie não está na tabela**, e um arquivo que um commit
posterior remove fica no disco até alguém limpar. A lição 18 mostra as duas coisas, porque é ali que
a conta de uma tabela Delta se esconde.

## Fazendo uma pergunta

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  42487 │ 6989795.82 │
│ credit       │  32725 │ 5364244.14 │
│ debit        │  14202 │  2317012.7 │
│ meal-voucher │   9313 │ 1538313.03 │
└──────────────┴────────┴────────────┘

```

**O DuckDB não sabia que a tabela era Delta**: o `deltalake` leu o log, descobriu quais arquivos
Parquet são a tabela e os entregou ao DuckDB como um dataset só. Essa divisão de trabalho, uma
biblioteca para o log e qualquer motor para os arquivos, é o motivo de uma tabela escrita por um
motor do Fabric ser legível pelos outros, e pelo Databricks na lição 21, sem export nenhum no meio.

## O que o Azurite não consegue substituir

**O OneLake responde ao endpoint de Data Lake, `dfs`, e o Azurite não tem um**, como a lição 3
mostrou. O `deltalake` gravou aqui pela interface comum de blob, que o Azure Blob Storage, o ADLS
Gen2 e o OneLake também respondem. No Fabric a mesma tabela estaria em:

```
abfss://quitanda-analytics@onelake.dfs.fabric.microsoft.com/sales.Lakehouse/Tables/orders
```

Esse caminho não foi usado neste curso, porque exige um tenant do Fabric e um login. O que muda entre
os dois é o endereço e as credenciais; a pasta, o log e os arquivos são os mesmos.
