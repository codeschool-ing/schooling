---
title: O mesmo job, rodando onde dá para ver
version: 1
---

**A transformação não precisa do Spark para ser entendida, só para ser grande.** Um mês da Quitanda
são 40 MB de CSV, que um notebook lê em segundos. A lógica do job é a mesma em qualquer tamanho: o
que é novo, quais dias isso toca, no que cada dia se transforma, o que o catálogo fica sabendo, o que
é lembrado. Este programa faz as cinco coisas contra o S3 e o catálogo do moto, com o DuckDB fazendo
o trabalho que o Spark faria. Salve como `~/aws/etl.py`:

```schooling-example
{"language": "python", "file": "etl.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"etl.py: the nightly job, raw CSV to curated Parquet, run here instead of on Glue.\n\n    python3 etl.py\n\nGLUE IS NOT RUN HERE. moto marks a Glue job SUCCEEDED and runs nothing, so\nthis program does on your computer what the Glue script of lesson 17 does on\nAWS. It finds the raw files no earlier run has processed, rewrites each day\nthey belong to as one Parquet file with no order in it twice, adds those days\nto the table quitanda.orders in the catalog, and remembers which files it has\ndone in a bookmark it keeps in S3.\n\"\"\"\n", "note": "**O Glue não roda aqui, e a docstring diz isso antes de tudo.** O que o programa faz é a lógica inteira do job, na ordem em que o script do Glue a faz: achar o que é novo, reescrever os dias que isso toca, avisar o catálogo, lembrar."}, {"code": "import json\n\nimport boto3\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.parquet as pq\n\nfrom lake import CURATED, RAW, SCHEMA, filesystem\n\n", "note": "O boto3 fala com o catálogo, como a linha de comando da AWS, e lê `AWS_ENDPOINT_URL` sozinho. O DuckDB tira as duplicatas; o PyArrow lê o CSV e grava o Parquet. O `lake.py` dá os dois prefixos e o esquema, então os arquivos curated ficam exatamente com os tipos dos da lição 15."}, {"code": "BOOKMARK = 'quitanda-glue-prod/bookmarks/orders-etl.json'\n\n\ndef bookmark(s3):\n    try:\n        with s3.open_input_stream(BOOKMARK) as f:\n            return set(json.load(f))\n    except FileNotFoundError:\n        return set()\n\n\n", "note": "**O bookmark é uma lista das chaves raw já processadas**, guardada como um objeto JSON no S3. Bookmark nenhum quer dizer que nada foi feito, que é o estado da primeira execução de um job."}, {"code": "def day_of(path):\n    return path.split('/dt=')[1].split('/')[0]\n\n\n", "note": "O dia a que uma chave raw pertence, lido da parte `dt=` dela."}, {"code": "def rewrite(s3, day, paths):\n    types = csv.ConvertOptions(column_types=SCHEMA)\n    parts = []\n    for path in paths:\n        with s3.open_input_stream(path) as f:\n            parts.append(csv.read_csv(f, convert_options=types))\n    raw = pa.concat_tables(parts)\n    clean = duckdb.sql('SELECT DISTINCT ON (order_id) * FROM raw ORDER BY order_id')\n    clean = clean.to_arrow_table().cast(SCHEMA)\n    out = f'{CURATED}/dt={day}/orders.parquet'\n    pq.write_table(clean, out, filesystem=s3)\n    return raw.num_rows, clean.num_rows, s3.get_file_info(out).size\n\n\n", "note": "**Um dia, reescrito a partir de todo arquivo raw que ele tem, não só do novo.** O CSV é lido com os tipos do esquema, então um total que não é número inteiro falha aqui em vez de numa consulta. `DISTINCT ON (order_id)` guarda uma linha por pedido, e ordenar por `order_id` devolve o dia à ordem em que aconteceu. O Parquet substitui o que o dia tinha antes, e é isso que torna inofensiva uma segunda execução."}, {"code": "def register(days):\n    glue = boto3.client('glue')\n    storage = glue.get_table(DatabaseName='quitanda', Name='orders')['Table']['StorageDescriptor']\n    there = 0\n    for i in range(0, len(days), 100):\n        rows = [{'Values': [d], 'StorageDescriptor': dict(storage, Location=f\"{storage['Location']}dt={d}/\")}\n                for d in days[i:i + 100]]\n        answer = glue.batch_create_partition(DatabaseName='quitanda', TableName='orders',\n                                             PartitionInputList=rows)\n        for e in answer.get('Errors', []):\n            if e['ErrorDetail']['ErrorCode'] != 'AlreadyExistsException':\n                raise RuntimeError(f\"{e['PartitionValues'][0]}: {e['ErrorDetail']['ErrorMessage']}\")\n            there += 1\n    return there\n\n\n", "note": "Os dias entram no catálogo do jeito que a lição 16 os pôs lá, cem por requisição, cada partição uma cópia do storage descriptor da tabela com o próprio local. **Uma partição que já existe é contada, e qualquer outro erro para o job**, que é o conselho da lição 16 sobre a lista `Errors` posto em código."}, {"code": "def main():\n    s3 = filesystem()\n    done = bookmark(s3)\n    found = sorted(f.path for f in s3.get_file_info(fs.FileSelector(RAW, recursive=True))\n                   if f.path.endswith('.csv'))\n    new = [p for p in found if p not in done]\n    if not new:\n        print(f'{len(found)} raw files, none of them new: nothing to do')\n        return\n    days = sorted({day_of(p) for p in new})\n    print(f'{len(new)} new raw file{\"s\" * (len(new) != 1)} in {len(days)} day{\"s\" * (len(days) != 1)}')\n    read = kept = size = 0\n    for day in days:\n        paths = [p for p in found if day_of(p) == day]\n        r, k, b = rewrite(s3, day, paths)\n        read, kept, size = read + r, kept + k, size + b\n        if r != k:\n            print(f'  {day}: {r:,} rows in {len(paths)} files, {r - k:,} of them duplicates')\n    print(f'  {read:,} rows read, {kept:,} kept, {size:,} bytes of Parquet written')\n    there = register(days)\n    print(f'  {len(days) - there} partitions added to quitanda.orders, {there} already there')\n    with s3.open_output_stream(BOOKMARK) as f:\n        f.write(json.dumps(sorted(done | set(new)), indent=1).encode())\n\n\nif __name__ == '__main__':\n    main()\n", "note": "A execução em si. Toda chave raw é listada e comparada com o bookmark; sem nada novo, ele diz isso e para. Senão, cada dia com arquivo novo é reescrito, os dias são registrados, e **o bookmark é gravado por último**, então uma execução que falha no meio deixa o bookmark como estava e a próxima refaz os mesmos dias."}]}
```

## Uma primeira noite

O programa precisa de uma camada raw para ler e de uma tabela em que registrar os dias. A tabela é o
`orders-table.json` da lição 16, que você salvou lá; se não salvou, ele aparece inteiro na lição 16,
em "O catálogo, e do que uma tabela é feita". E o `lake.py --layer raw` grava o CSV de outubro e
nenhum Parquet, para que todo arquivo curated abaixo seja do job:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws glue create-database --database-input '{"Name": "quitanda"}' && aws glue create-table --database-name quitanda --table-input file://orders-table.json
ana@laptop:~/aws$ python3 lake.py --layer raw
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
```

```
ana@laptop:~/aws$ python3 etl.py
31 new raw files in 31 days
  755,511 rows read, 755,511 kept, 12,703,975 bytes of Parquet written
  31 partitions added to quitanda.orders, 0 already there
```

**31 arquivos, 755.511 linhas na entrada e as mesmas na saída, 12.703.975 bytes de Parquet.** É o
tamanho que o `lake.py` imprimiu para a própria camada curated na lição 15, até o byte, e não é
sorte: as mesmas linhas, na mesma ordem, com os mesmos tipos, gravadas pela mesma biblioteca, são o
mesmo arquivo. Nada veio duplicado na exportação de outubro, então nada foi descartado, e o catálogo
ganhou as 31 partições que a lição 16 acrescentou à mão.

## Está certo?

A pergunta que a lição 15 fez, feita de novo ao que o job gravou:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'
31
```

**As mesmas quatro linhas, até o centavo, a partir dos mesmos 5.102.048 bytes**, e 31 partições no
catálogo. Um job que produz exatamente o que um processo sabidamente certo produziu é o teste mais
barato que um pipeline tem, e vale guardá-lo: uma mudança no job que mexa em qualquer um desses
números mudou o que o lago diz sobre outubro.

O que esta execução não consegue mostrar é qualquer coisa sobre o Glue: quanto os workers demoram a
ligar, como o trabalho se divide entre dez deles, o que acontece quando um falha. Essas são
propriedades de uma execução real na AWS, e são descritas, não mostradas, neste curso.
