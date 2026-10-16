---
title: Sete arranjos de um mês
version: 1
---

**Duas decisões são tomadas quando um arquivo é gravado, e toda consulta paga por elas depois**: o
formato, que arranja os bytes dentro de cada arquivo, e o particionamento, que arranja os arquivos
pelas chaves. A lição 15 encontrou as duas com um arranjo de cada. Esta lição pega os mesmos 755.511
pedidos, grava-os de mais sete jeitos e faz a cada arranjo as mesmas perguntas, para que a única coisa
que muda entre dois números seja o arranjo.

## Um arranjo por linhas e um por colunas

**Um arquivo CSV é gravado uma linha por vez, e por isso só pode ser lido uma linha por vez.** Para
achar o pagamento de cada pedido, um leitor passa por todas as linhas, porque nada diz onde começa o
quinto campo da próxima linha. Foi isso que fez a pergunta ao CSV da lição 15 ler 40.641.097 bytes
para duas colunas.

**Parquet e ORC são gravados uma coluna por vez, em blocos.** O Parquet corta um arquivo em *row
groups*, grupos de linhas, cada um com alguns milhares ou milhões de linhas, e dentro de cada grupo
guarda toda coluna como um *column chunk* próprio, comprimido sozinho. O ORC faz o mesmo com outros
nomes: *stripes* em vez de grupos de linhas, *streams* em vez de chunks. Os dois terminam com um
rodapé que diz onde começa cada bloco e que faixa de valores ele guarda, que é como um leitor lê duas
colunas de sete, e os dois carregam o esquema e os tipos no próprio arquivo. O `footer.py` da lição 15
imprimiu um desses rodapés; esta lição lê mais deles.

## O programa

Salve como `~/aws/layouts.py`. Ele lê a camada curated que o `lake.py` grava e não precisa de mais
nada:

```schooling-example
{"language": "python", "file": "layouts.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"layouts.py: the curated month written seven more ways, to compare their bills.\n\n    python3 layouts.py\n\nReads s3://quitanda-curated-prod/orders/, which lake.py wrote, and writes each\nlayout under s3://quitanda-curated-prod/layouts/NAME/dt=2026-10-01/... with the\nsame rows. Then it prints how many objects and bytes each layout came to.\n\"\"\"\n", "note": "Sete arranjos dos mesmos 755.511 pedidos, todos derivados da camada curated, então a única coisa que muda entre eles é como os bytes estão dispostos."}, {"code": "import random\n\nimport pyarrow.csv as csv\nimport pyarrow.fs as fs\nimport pyarrow.orc as orc\nimport pyarrow.parquet as pq\n\nfrom lake import CURATED, filesystem\n\n", "note": "O PyArrow grava os quatro formatos aqui: CSV, Parquet e ORC pelo `pyarrow.orc`."}, {"code": "OUT = 'quitanda-curated-prod/layouts'\n\n\n", "note": "Cada arranjo mora sob o próprio nome em `layouts/`, particionado por `dt` como o original, então o `ask.py -t` pode apontar para qualquer um deles."}, {"code": "def write_day(s3, day, table):\n    base = f'dt={day}'\n    with s3.open_output_stream(f'{OUT}/csv-gzip/{base}/orders.csv.gz', compression='gzip') as f:\n        csv.write_csv(table, f, csv.WriteOptions(quoting_style='needed'))\n    pq.write_table(table, f'{OUT}/parquet-none/{base}/orders.parquet', filesystem=s3,\n                   compression='none')\n    pq.write_table(table, f'{OUT}/parquet-zstd/{base}/orders.parquet', filesystem=s3,\n                   compression='zstd')\n    with s3.open_output_stream(f'{OUT}/orc-zstd/{base}/orders.orc') as f:\n        orc.write_table(table, f, compression='zstd')\n", "note": "**O formato e o codec, um dia por vez.** O CSV é o da camada raw, comprimido com gzip a caminho do S3. O Parquet é gravado sem compressão e com zstd, ao lado do Snappy da camada curated. O ORC é o outro formato colunar, comprimido com zstd."}, {"code": "    pq.write_table(table, f'{OUT}/groups/{base}/orders.parquet', filesystem=s3,\n                   row_group_size=2_000)\n    shuffled = list(range(table.num_rows))\n    random.Random(day).shuffle(shuffled)\n    pq.write_table(table.take(shuffled), f'{OUT}/groups-shuffled/{base}/orders.parquet',\n                   filesystem=s3, row_group_size=2_000)\n", "note": "**Grupos de linhas de 2.000 linhas**, duas vezes: uma na ordem do dia, ordenada por hora, e outra embaralhada, com as mesmas linhas. A diferença é só a ordem, e ela decide o que o mínimo e o máximo de cada grupo dizem."}, {"code": "    step = -(-table.num_rows // 96)\n    for k in range(96):\n        pq.write_table(table.slice(k * step, step), f'{OUT}/small-files/{base}/part-{k:02d}.parquet',\n                       filesystem=s3)\n\n\n", "note": "**Arquivos pequenos**: cada dia cortado em 96 arquivos Parquet do mesmo tamanho, mais ou menos o que um gravador que descarrega a cada quarto de hora deixa para trás."}, {"code": "def main():\n    s3 = filesystem()\n    for d in range(1, 32):\n        day = f'2026-10-{d:02d}'\n        write_day(s3, day, pq.read_table(f'{CURATED}/dt={day}/orders.parquet', filesystem=s3))\n    totals = {}\n    for f in s3.get_file_info(fs.FileSelector(OUT, recursive=True)):\n        if f.is_file:\n            name = f.path.split('/')[2]\n            objects, size = totals.get(name, (0, 0))\n            totals[name] = (objects + 1, size + f.size)\n    for name, (objects, size) in totals.items():\n        print(f'  {name:<16}{objects:>6} objects {size:>13,} bytes')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Os 31 dias, depois uma listagem de `layouts/` somada por arranjo: quantos objetos, quantos bytes."}]}
```

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu
laboratório, em resumo" da lição 1 digitadas neste. O moto começa vazio, então o lago vem primeiro. Depois vêm os sete arranjos, o comando mais lento deste curso, porque só o último arranjo tem 2.976 objetos:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

```
ana@laptop:~/aws$ python3 layouts.py
  csv-gzip            31 objects     8,421,323 bytes
  groups-shuffled     31 objects    16,278,695 bytes
  groups              31 objects    15,063,805 bytes
  orc-zstd            31 objects     6,871,300 bytes
  parquet-none        31 objects    24,667,617 bytes
  parquet-zstd        31 objects     7,433,857 bytes
  small-files       2976 objects    22,068,273 bytes
```

**Os mesmos pedidos ocupam de 40.641.097 bytes a 6.871.300.** Três coisas definem o tamanho, e a lista
acima as separa:

- **o arranjo**: Parquet sem compressão nenhuma, 24.667.617 bytes, já é menor que o CSV, porque um
  número é guardado como número e não como seus dígitos, e uma coluna de quatro formas de pagamento é
  guardada como um dicionário de quatro palavras e um código pequeno por linha;
- **o codec**: o mesmo Parquet tem 12.703.975 bytes com Snappy, o da camada curated, e 7.433.857 com
  zstd. O gzip leva o CSV a 8.421.323, que é o assunto da próxima seção;
- **o corte**: os grupos de linhas e os 96 arquivos pequenos por dia acrescentam rodapés, dicionários
  e estatísticas a cada pedaço, e 2.976 arquivos pequenos somam 22.068.273 bytes, 1,74 vez o arquivo
  por dia que eles guardam.

**O ORC saiu o menor, 6.871.300 bytes contra os 7.433.857 do Parquet com o mesmo codec.** É uma
diferença entre dois bons formatos com estes dados, e não um motivo para escolher um deles. Athena,
Spark, Glue e Redshift Spectrum leem os dois; PyArrow, DuckDB e a maioria das ferramentas fora do
mundo Hadoop usam Parquet por padrão, e o ORC é mais forte onde o Hive está. Um lago escolhe um e fica
com ele, porque a decisão que importa foi a anterior: colunas em vez de linhas.
