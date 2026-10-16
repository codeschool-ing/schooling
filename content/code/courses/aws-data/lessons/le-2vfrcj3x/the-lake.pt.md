---
title: Um mês de pedidos no lago
version: 1
---

**Uma pergunta sobre bytes precisa de bytes bastantes para importar**, então esta seção enche o
lago. Os três arquivos CSV de dois pedidos cada da lição 1 são pequenos demais para o formato fazer diferença. Um mês de pedidos da Quitanda são três quartos de um milhão de linhas, e nisso a
diferença entre um jeito de guardá-las e outro é um fator que dá para ver. Ninguém tem os pedidos
reais da Quitanda, então um programa os inventa, os mesmos toda vez.

Copie com o botão do bloco e salve como `~/aws/lake.py`, do jeito que a lição 1 salvou o
`prices.py`. Ele precisa do PyArrow, que a lição 1 instalou com o DuckDB no ambiente virtual.

```schooling-example
{"language": "python", "file": "lake.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"lake.py: Quitanda's orders for October 2026, written into the lake in S3.\n\n    python3 lake.py                 # both layers, all 31 days\n    python3 lake.py --layer raw     # only the CSV the shop exports\n    python3 lake.py --days 3        # only the first three days\n\nThe orders are invented, and they are the same on every run: the generator is\nseeded, so two runs write the same bytes. Each day goes to two places:\n\n    s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv\n    s3://quitanda-curated-prod/orders/dt=2026-10-01/orders.parquet\n\nBoth buckets must exist already. The S3 it writes to is AWS_ENDPOINT_URL when\nthat is set, which in this course is moto.\n\"\"\"\n", "note": "A docstring é o manual: como rodar, o que grava e onde. **Os pedidos são inventados e têm semente fixa**, então o seu lago guarda os mesmos bytes que o desta lição, e todo número abaixo pode ser conferido na sua máquina."}, {"code": "import argparse\nimport datetime\nimport os\nimport random\nimport urllib.parse\n\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.parquet as pq\n\n", "note": "A biblioteca padrão do Python e depois o PyArrow: o gravador de CSV, o de Parquet e o `pyarrow.fs`, que fala S3 sozinho."}, {"code": "RAW = 'quitanda-raw-prod/raw/orders'\nCURATED = 'quitanda-curated-prod/orders'\nSCHEMA = pa.schema([('order_id', pa.string()), ('customer_id', pa.string()),\n                    ('hour', pa.int8()), ('items', pa.int16()),\n                    ('total_cents', pa.int64()), ('payment', pa.string()),\n                    ('neighbourhood', pa.string())])\nPAYMENTS, PAYMENT_SHARE = ['pix', 'credit', 'debit', 'meal-voucher'], [46, 33, 13, 8]\nHOURS = list(range(7, 24))\nHOUR_SHARE = [1, 2, 3, 3, 4, 5, 4, 3, 3, 3, 4, 6, 8, 9, 7, 4, 2]\nNEIGHBOURHOODS = ['Pinheiros', 'Moema', 'Vila Mariana', 'Perdizes', 'Mooca', 'Lapa',\n                  'Santana', 'Itaim Bibi', 'Bela Vista', 'Liberdade', 'Ipiranga',\n                  'Brooklin', 'Vila Madalena', 'Santo Amaro', 'Penha', 'Jabaquara']\nCUSTOMERS = 40_000\n\n\n", "note": "Onde ficam as duas camadas, as colunas e seus tipos, e o formato da invenção: como se repartem pagamentos, horários e bairros. **O `SCHEMA` é escrito uma vez e usado nos dois arquivos**, então o CSV e o Parquet têm as mesmas sete colunas."}, {"code": "def filesystem():\n    url = os.environ.get('AWS_ENDPOINT_URL')\n    region = os.environ.get('AWS_DEFAULT_REGION', 'sa-east-1')\n    if not url:\n        return fs.S3FileSystem(region=region)\n    u = urllib.parse.urlparse(url)\n    return fs.S3FileSystem(endpoint_override=u.netloc, scheme=u.scheme, region=region)\n\n\n", "note": "**O PyArrow não lê `AWS_ENDPOINT_URL`**, então o programa a lê e repassa o endereço. Sem a variável ele fala com o S3 de verdade, na região que o terminal indica."}, {"code": "def orders(rng, day, weights):\n    n = 20_000 + rng.randint(0, 4_000) + (8_000 if day.weekday() >= 5 else 0)\n    items = [min(40, 1 + int(rng.expovariate(1 / 8))) for _ in range(n)]\n    customers = rng.choices(range(1, CUSTOMERS + 1), cum_weights=weights, k=n)\n    return pa.table({\n        'order_id': [f'o-{day:%m%d}-{i:05d}' for i in range(1, n + 1)],\n        'customer_id': [f'c-{c}' for c in customers],\n        'hour': sorted(rng.choices(HOURS, HOUR_SHARE, k=n)),\n        'items': items,\n        'total_cents': [990 + i * rng.randint(390, 2190) for i in items],\n        'payment': rng.choices(PAYMENTS, PAYMENT_SHARE, k=n),\n        'neighbourhood': rng.choices(NEIGHBOURHOODS, k=n),\n    }, schema=SCHEMA)\n\n\n", "note": "Um dia de pedidos como tabela. Dias úteis têm de 20.000 a 24.000 e fins de semana 8.000 a mais, as horas vêm ordenadas para que o arquivo siga a ordem do dia, e o total é uma taxa de entrega de 9,90 mais um preço por item."}, {"code": "def regulars():\n    weights, total = [], 0.0\n    for rank in range(1, CUSTOMERS + 1):\n        total += rank ** -0.7\n        weights.append(total)\n    return weights\n\n\ndef main():\n    args = argparse.ArgumentParser()\n    args.add_argument('--layer', choices=['raw', 'curated', 'both'], default='both')\n    args.add_argument('--days', type=int, default=31)\n    args = args.parse_args()\n    s3, rng, weights = filesystem(), random.Random(2026), regulars()\n", "note": "`regulars` dá os pesos que fazem alguns clientes pedirem muito mais vezes que o resto, como os clientes de uma loja de verdade. Depois os argumentos e o gerador com semente 2026, para que toda execução sorteie os mesmos pedidos."}, {"code": "    count, size = 0, {RAW: 0, CURATED: 0}\n    for d in range(args.days):\n        day = datetime.date(2026, 10, 1) + datetime.timedelta(days=d)\n        table = orders(rng, day, weights)\n        count += table.num_rows\n        if args.layer in ('raw', 'both'):\n            path = f'{RAW}/dt={day}/orders.csv'\n            with s3.open_output_stream(path) as out:\n                csv.write_csv(table, out, csv.WriteOptions(quoting_style='needed'))\n            size[RAW] += s3.get_file_info(path).size\n        if args.layer in ('curated', 'both'):\n            path = f'{CURATED}/dt={day}/orders.parquet'\n            pq.write_table(table, path, filesystem=s3)\n            size[CURATED] += s3.get_file_info(path).size\n    print(f'{count:,} orders in {args.days} days')\n    for prefix, total in size.items():\n        if total:\n            print(f'  s3://{prefix}/  {args.days} objects  {total:>12,} bytes')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "**Cada dia é gravado duas vezes**: como o CSV que a loja exporta, no bucket raw, e como Parquet no curated, numa chave que nomeia o dia como `dt=2026-10-01`. Depois os totais: pedidos, objetos e bytes por camada."}]}
```

## Duas camadas, as mesmas linhas

**A camada raw é o que chega e a camada curated é o que se lê.** A loja exporta CSV, porque todo
programa sabe escrever e uma pessoa consegue abrir; ele cai no `quitanda-raw-prod` exatamente como
veio. A camada curated guarda os mesmos pedidos em Parquet, um formato colunar que as próximas seções
desmontam, no `quitanda-curated-prod`. A lição 17 é o job que transforma um no outro na AWS; aqui o
`lake.py` grava os dois de uma vez, para que guardem as mesmas linhas e só o formato mude.

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu laboratório,
em resumo" da lição 1 digitadas neste. O moto começa vazio, então os buckets vêm primeiro:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

**755.511 pedidos, e os mesmos pedidos ocupam 40.641.097 bytes em CSV e 12.703.975 em Parquet**,
cerca de um terço. Nada se perdeu no caminho: os arquivos Parquet guardam todo valor que os CSV
guardam, com seus tipos, e a próxima seção conta os dois e chega à mesma resposta. A economia vem de
guardar cada coluna separada, onde a coluna de horas de um dia, cada uma um número entre 7 e 23, é
uma sequência de valores pequenos que comprime até quase nada, e do Snappy, a compressão que o
PyArrow aplica ao Parquet quando ninguém pede outra. A lição 19 mede os formatos e os codecs uns
contra os outros.

## Como isso aparece no S3

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/ | head -3
                           PRE dt=2026-10-01/
                           PRE dt=2026-10-02/
                           PRE dt=2026-10-03/
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-10-01/
2026-10-16 13:12:12     351356 orders.parquet
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/
2026-10-16 13:12:12    1101292 orders.csv
ana@laptop:~/aws$ aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv day.csv && head -4 day.csv
download: s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv to ./day.csv
"order_id","customer_id","hour","items","total_cents","payment","neighbourhood"
"o-1001-00001","c-151",7,4,8958,"pix","Ipiranga"
"o-1001-00002","c-22",7,25,44390,"pix","Santana"
"o-1001-00003","c-337",7,9,16407,"pix","Itaim Bibi"
```

**Cada dia é um prefixo, e cada prefixo guarda um objeto.** O `aws s3 ls` agrupa as chaves na barra
depois de `dt=…`, que é a pasta que não existe da lição 1, e dentro de `dt=2026-10-01/` há um arquivo
por camada: 351.356 bytes de Parquet contra 1.101.292 de CSV para o mesmo 1º de outubro. O CSV é
texto, como a loja escreveu. O Parquet não se lê com `head`, e esse é o preço dele: uma pessoa não
consegue mais olhar o arquivo, e um programa precisa conhecer o formato para ler um único valor.

Os nomes são o esquema que a lição 1 montou, `raw/orders/dt=2026-10-01/orders.csv`, com a data
escrita com o ano primeiro para que a ordem da listagem seja a ordem do tempo. Também são os nomes
que a tabela do Athena lê: o `LOCATION` em `orders.sql` é o prefixo curated, e `PARTITIONED BY (dt
string)` é o `dt=` de toda chave.
