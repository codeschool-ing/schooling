---
title: A mesma noite, escrita como código
version: 1
---

**Nem um mapping data flow nem um notebook Spark rodam num laptop sem o Azure, e esta seção não roda
nenhum dos dois.** O que ela roda é a própria transformação: o export da noite como a loja o escreve,
limpo, deduplicado e resumido, por um programa do tipo que um notebook guarda, com o DuckDB fazendo o
trabalho que o Spark faria num cluster e o Azurite guardando os arquivos. A lógica é a mesma em
qualquer tamanho; o que um cluster acrescenta é o tamanho, e é isso que as próximas seções põem
preço.

## O export, como a loja o escreve

**Um export cru nunca é a tabela limpa que a lição 17 gerou.** A loja da Quitanda escreve o export
com três hábitos que toda carga precisa desfazer: um pedido enviado duas vezes quando o próprio
upload da loja é repetido, uma forma de pagamento escrita com qualquer caixa e com espaços em volta, e
um total em reais com vírgula, `42,87`, porque é assim que uma tela brasileira o mostra. Este programa
escreve uma noite assim, a partir dos mesmos pedidos do `orders.py`:

`export.py`:

```python
"""export.py: one night's export, written the way Quitanda's shop really writes it."""
import csv
import random
import sys

from orders import october

day = october(days=1).to_pylist()
rnd = random.Random(29)
rows = []
for o in day:
    total = f"{o['total_cents'] // 100},{o['total_cents'] % 100:02d}"
    payment = rnd.choice([o["payment"], o["payment"].upper(), f" {o['payment']} "])
    rows.append([o["order_id"], f"{o['dt']} {o['hour']:02d}:{rnd.randint(0, 59):02d}",
                 o["customer_id"], o["neighbourhood"], payment, total])
    if rnd.random() < 0.02:
        rows.append(rows[-1])

with open(sys.argv[1], "w", newline="") as f:
    out = csv.writer(f, lineterminator="\n")
    out.writerow(["order_id", "created_at", "customer_id", "neighbourhood", "payment", "total"])
    out.writerows(rows)
print(f"{len(rows):,} rows written to {sys.argv[1]}")
```

## A transformação

O programa que um notebook guardaria tem três partes: uma função que limpa, uma função que resume e o
código que lê do armazenamento e grava de volta. Separadas, as duas primeiras podem ser testadas sem
armazenamento nenhum, que é a próxima seção.

```schooling-example
{"language": "python", "file": "clean.py", "parts": [
{"code": "\"\"\"clean.py: the night's transformation, written as a notebook would hold it, run over Azurite.\n\n    python clean.py 2026-10-01\n\"\"\"\nimport io\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.parquet as pq\nfrom azure.storage.blob import BlobServiceClient\n\n", "note": "O SDK do Azure para Blob Storage lê e grava os arquivos; o PyArrow lê o CSV e grava o Parquet; o DuckDB faz a transformação em SQL, como o Spark SQL faria num notebook."},
{"code": "COLUMNS = [\"order_id\", \"created_at\", \"customer_id\", \"neighbourhood\", \"payment\", \"total\"]\n\n\n", "note": "**Toda coluna é lida como texto.** O total do export é `42,87`, que nenhum leitor de números entende, e adivinhar tipos por amostra é como uma carga falha na primeira noite em que uma coluna vem diferente."},
{"code": "def clean(raw):\n    return duckdb.sql(\"\"\"\n        SELECT DISTINCT ON (order_id)\n               order_id,\n               strftime(CAST(created_at AS TIMESTAMP), '%Y-%m-%d') AS dt,\n               hour(CAST(created_at AS TIMESTAMP)) AS hour,\n               customer_id,\n               neighbourhood,\n               lower(trim(payment)) AS payment,\n               CAST(round(CAST(replace(total, ',', '.') AS DECIMAL(12, 2)) * 100) AS BIGINT) AS total_cents\n        FROM raw\n        ORDER BY order_id\n    \"\"\").to_arrow_table()\n\n\n", "note": "**As regras da noite, numa consulta.** `DISTINCT ON (order_id)` mantém uma linha por pedido, seja o que for que a loja reenviou. O horário vira um dia e uma hora. A forma de pagamento perde os espaços e as maiúsculas. O total troca a vírgula por ponto, vira decimal e é guardado em centavos, como inteiro, o único jeito seguro de guardar dinheiro."},
{"code": "def summary(orders):\n    return duckdb.sql(\"\"\"\n        SELECT neighbourhood, count(*) AS orders, sum(total_cents) / 100 AS reais\n        FROM orders GROUP BY neighbourhood ORDER BY reais DESC LIMIT 5\n    \"\"\")\n\n\n", "note": "Um resumo para quem espera a noite: os cinco bairros que mais venderam. Num pipeline isso seria uma tabela própria; aqui é impresso."},
{"code": "def main(day):\n    lake = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\n    data = lake.get_blob_client(\"raw\", f\"orders/{day}.csv\").download_blob().readall()\n    types = csv.ConvertOptions(column_types=dict.fromkeys(COLUMNS, pa.string()))\n    raw = csv.read_csv(io.BytesIO(data), convert_options=types)\n    orders = clean(raw)\n    out = io.BytesIO()\n    pq.write_table(orders, out, compression=\"zstd\")\n    lake.get_blob_client(\"curated\", f\"orders/dt={day}/orders.parquet\").upload_blob(\n        out.getvalue(), overwrite=True)\n    print(f\"{raw.num_rows:,} rows read, {raw.num_rows - orders.num_rows} duplicates dropped, \"\n          f\"{orders.num_rows:,} orders written as {out.tell():,} bytes of Parquet\")\n    summary(orders).show()\n\n\n", "note": "**Ler, limpar, gravar, nessa ordem, e a gravação substitui.** O arquivo cru vem de `raw/orders/<dia>.csv` e o resultado vai para `curated/orders/dt=<dia>/orders.parquet` com `overwrite=True`, então rodar a noite duas vezes deixa uma cópia do dia, que é o que a lição 19 pediu de toda carga."},
{"code": "if __name__ == \"__main__\":\n    main(sys.argv[1])\n"}
]}
```

Crie os dois contêineres, escreva o export, ponha-o onde a loja o poria e rode a noite:

```
ana@laptop:~/azure$ az storage container create -n raw -o none && az storage container create -n curated -o none
ana@laptop:~/azure$ python export.py export.csv
2,972 rows written to export.csv
ana@laptop:~/azure$ head -4 export.csv
order_id,created_at,customer_id,neighbourhood,payment,total
1001-00001,2026-10-01 07:04,c-6292,Moema, pix ,"42,87"
1001-00002,2026-10-01 07:18,c-7914,Bela Vista, meal-voucher ,"168,21"
1001-00003,2026-10-01 07:25,c-1255,Vila Madalena,PIX,"64,11"
ana@laptop:~/azure$ wc -c export.csv
176106 export.csv
ana@laptop:~/azure$ az storage blob upload -c raw -n orders/2026-10-01.csv -f export.csv -o none
Finished[#############################################################]  100.0000%
ana@laptop:~/azure$ python clean.py 2026-10-01
2,972 rows read, 51 duplicates dropped, 2,921 orders written as 31,810 bytes of Parquet
┌───────────────┬────────┬──────────┐
│ neighbourhood │ orders │  reais   │
│    varchar    │ int64  │  double  │
├───────────────┼────────┼──────────┤
│ Butantã       │    204 │ 34759.67 │
│ Tatuapé       │    197 │ 32242.19 │
│ Mooca         │    184 │ 31313.87 │
│ Ipiranga      │    183 │ 31133.88 │
│ Liberdade     │    190 │ 31070.65 │
└───────────────┴────────┴──────────┘
```

**2.972 linhas entram, 51 delas uma segunda cópia de um pedido, 2.921 pedidos saem**, como 31.810
bytes de Parquet comprimido com zstd, contra os 176.106 bytes do CSV. O resumo é a primeira coisa que
uma analista pediria da noite, e é calculado a partir dos pedidos limpos, então nenhum pedido
reenviado conta duas vezes nos 34.759,67 reais do Butantã.

A noite precisa ser segura para rodar de novo, porque os gatilhos da lição 19 e as pessoas reexecutam
noites:

```
ana@laptop:~/azure$ az storage blob list -c curated --query '[].{name:name, bytes:properties.contentLength}' -o table
Name                                 Bytes
-----------------------------------  -------
orders/dt=2026-10-01/orders.parquet  31810
ana@laptop:~/azure$ python clean.py 2026-10-01 | head -1
2,972 rows read, 51 duplicates dropped, 2,921 orders written as 31,810 bytes of Parquet
ana@laptop:~/azure$ az storage blob list -c curated --query 'length(@)'
1
```

**Um arquivo para o dia, do mesmo tamanho, depois de duas execuções.** A gravação substituiu o
Parquet do dia, então a segunda execução deixou exatamente o que a primeira deixou. Se o `clean.py`
gravasse um nome de arquivo novo a cada vez, a segunda execução teria deixado o dia duas vezes em
`curated`, e todo leitor da pasta o contaria duas vezes.

## O que um cluster mudaria

**No Spark, as mesmas regras seriam o mesmo SQL, ou as mesmas poucas linhas de PySpark**, rodadas
por um cluster sobre milhares de arquivos em vez de um processo sobre um. Um notebook no Fabric, no
Synapse ou no Databricks com este código leria caminhos `abfss://` em vez de chamar o SDK de blob, e
gravaria uma tabela Delta em vez de um arquivo Parquet, com a substituição de uma partição da lição
18 fazendo o que o `overwrite=True` faz aqui. Um mapping data flow desenharia as mesmas regras como
caixas: uma source, uma derived column para a forma de pagamento e o total, um aggregate para os
duplicados, um sink. As duas próximas seções tratam do que muda entre os dois quando as regras são as
mesmas.
