---
title: Ler os arquivos de volta do bucket
version: 1
---

**Uma consulta numa tabela externa lê Parquet do Cloud Storage do jeito que todo bom leitor de Parquet
lê: o rodapé primeiro, e depois só as faixas de bytes das colunas de que precisa.** O BigQuery não pode
rodar aqui, mas isso pode: o fake-gcs-server guarda os mesmos arquivos, responde a pedidos com faixa
como o Cloud Storage responde, e o cliente Python do Google sabe fazê-los. Esta seção constrói um leitor
que faz o que uma tabela externa faz, conta cada pedido e cada byte que busca, e entrega o resultado ao
DuckDB.

## Os arquivos, no bucket de novo

**O fake-gcs-server esquece tudo quando para**, então se ele foi reiniciado desde a aula 13, ponha os
arquivos de volta. No terminal em que você digita, com o emulador rodando no dele:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1
Average throughput: 6.9MiB/s
ana@laptop:~/gcp$ gcloud storage ls -l 'gs://quitanda-curated-prod/orders/dt=2026-09-2*/*' | tail -4
    598978  2026-10-30T19:08:31Z  gs://quitanda-curated-prod/orders/dt=2026-09-27/part-000.parquet
    465485  2026-10-30T19:08:32Z  gs://quitanda-curated-prod/orders/dt=2026-09-28/part-000.parquet
    435738  2026-10-30T19:08:30Z  gs://quitanda-curated-prod/orders/dt=2026-09-29/part-000.parquet
TOTAL: 10 objects, 5293736 bytes (5.05MiB)
```

**Cada dia é um objeto de cerca de meio megabyte.** O curinga casou com os dez dias de 20 a 29 de
setembro, e a listagem mostra os três últimos com os tamanhos e o momento em que foram escritos, e o total
dos dez. Esses tamanhos são aqueles contra os quais o programa abaixo lê.

## O leitor

Salve isto como `~/gcp/external.py`:

```schooling-example
{"language": "python", "file": "external.py", "parts": [{"code": "import io\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.parquet as pq\nfrom google.cloud import storage\n\nBUCKET, PREFIX = 'quitanda-curated-prod', 'orders/'\nfirst, last, columns = sys.argv[1], sys.argv[2], sys.argv[3].split(',')\n\n\n", "note": "**Uma consulta sobre o bucket, em três argumentos**: o primeiro e o último dia que o filtro de partição mantém, e as colunas a ler. O bucket e o prefixo são onde a aula 13 pôs os arquivos."}, {"code": "class RangeReader(io.RawIOBase):\n    \"\"\"A file that fetches only the byte ranges asked of it, and counts them.\"\"\"\n\n    def __init__(self, blob):\n        self.blob, self.size, self.pos = blob, blob.size, 0\n        self.requests = self.fetched = 0\n\n    def seekable(self):\n        return True\n\n    def readable(self):\n        return True\n\n    def seek(self, offset, whence=io.SEEK_SET):\n        self.pos = {io.SEEK_SET: 0, io.SEEK_CUR: self.pos, io.SEEK_END: self.size}[whence] + offset\n        return self.pos\n\n    def tell(self):\n        return self.pos\n\n    def readinto(self, buffer):\n        end = min(self.pos + len(buffer), self.size)\n        if end <= self.pos:\n            return 0\n        data = self.blob.download_as_bytes(start=self.pos, end=end - 1)\n        buffer[:len(data)] = data\n        self.pos += len(data)\n        self.requests += 1\n        self.fetched += len(data)\n        return len(data)\n\n\n", "note": "**Um arquivo que nunca é baixado inteiro.** O PyArrow pede a um arquivo que faça seek e leia como qualquer outro, e cada leitura aqui vira um pedido de exatamente aquela faixa de bytes do objeto, `download_as_bytes(start=..., end=...)`, que é um pedido HTTP com `Range`. Ele conta os pedidos e os bytes, que é a razão de existir."}, {"code": "client = storage.Client(project='planner-dev')\ntables, listed, requests, fetched, stored = [], 0, 0, 0, 0\nfor blob in client.list_blobs(BUCKET, prefix=PREFIX):\n    listed += 1\n    dt = blob.name.split('dt=')[1].split('/')[0]\n    if not first <= dt <= last:\n        continue\n    reader = RangeReader(blob)\n    table = pq.read_table(reader, columns=columns)\n    tables.append(table.append_column('dt', pa.array([dt] * table.num_rows)))\n    requests, fetched, stored = requests + reader.requests, fetched + reader.fetched, stored + blob.size\n\n", "note": "**Particionamento Hive, feito à mão.** Todo objeto sob o prefixo é listado, a data sai do nome dele, e um objeto fora da faixa é pulado sem um byte dele ser buscado. Para o resto, `read_table` com `columns=` lê o rodapé, acha onde essas colunas estão e busca só elas. `dt` é acrescentada de volta a partir do nome, como o BigQuery a acrescenta a partir do caminho. O cliente acha o fake-gcs-server por `STORAGE_EMULATOR_HOST`, que todo terminal deste curso exporta."}, {"code": "orders = pa.concat_tables(tables)\nprint(f'{listed} objects listed, {len(tables)} read: {requests} range requests, '\n      f'{fetched:,} of their {stored:,} bytes fetched')\nduckdb.sql(\"SELECT district, sum(total_cents) AS sales FROM orders GROUP BY district ORDER BY sales DESC\").show()\n", "note": "**A consulta, sobre o que voltou.** O DuckDB consulta uma tabela Arrow numa variável Python pelo nome dela, então `orders` aqui é o dado buscado do bucket e mais nada."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um objeto Parquet no bucket, desenhado como uma barra comprida: um grupo de linhas com nove pedaços de coluna, de order_id a created_at, com district e total_cents destacados, e no fim do objeto o rodapé. Três pedidos numerados saem do leitor. O pedido 1 busca o fim do objeto, o rodapé, que diz onde começa cada pedaço de coluna. Os pedidos 2 e 3 buscam só os pedaços de district e total_cents. Os outros pedaços de coluna nunca são buscados.\" data-fig=\"l17-ranges\"><defs><marker id=\"l17-ranges-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-ranges-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um objeto: orders/dt=2026-09-29/part-000.parquet</text><rect x=\"20\" y=\"34\" width=\"82\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"61.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"106\" y=\"34\" width=\"66\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"139.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"176\" y=\"34\" width=\"58\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">store_id</text><rect x=\"238\" y=\"34\" width=\"68\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">district</text><rect x=\"310\" y=\"34\" width=\"52\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">items</text><rect x=\"366\" y=\"34\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">total_cents</text><rect x=\"446\" y=\"34\" width=\"56\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"474.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">payment</text><rect x=\"506\" y=\"34\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">created_at</text><rect x=\"580\" y=\"34\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">rodapé</text><rect x=\"300\" y=\"196\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">external.py, ou qualquer leitor de Parquet</text><polyline points=\"500,196 640.0,82\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-0)\"></polyline><text x=\"560\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">1. o rodapé, primeiro</text><polyline points=\"360,196 272.0,82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-1)\"></polyline><polyline points=\"430,196 404.0,82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l17-ranges-ah-1)\"></polyline><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">2. e 3. só os dois pedaços de coluna pedidos</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">nunca buscados: order_id, customer_id, store_id,</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">items, payment, created_at</text></svg>", "caption": "O que um leitor colunar pede a um bucket: o rodapé primeiro, depois só os pedaços de coluna de que precisa. Desenhado para um grupo de linhas; os arquivos desta aula têm um por dia.", "same": ["items, payment, created_at"]}
```

## Três consultas sobre o bucket

As vendas de setembro por bairro, que precisam de duas colunas de 29 arquivos; um dia com todas as
colunas, que precisa de um arquivo inteiro; e as mesmas duas colunas nos sessenta dias:

```
ana@laptop:~/gcp$ python3 external.py 2026-09-01 2026-09-29 district,total_cents
60 objects listed, 29 read: 87 range requests, 4,878,703 of their 15,520,944 bytes fetched
┌──────────────┬────────────┐
│   district   │   sales    │
│   varchar    │   int128   │
├──────────────┼────────────┤
│ Santana      │ 1796352232 │
│ Vila Mariana │ 1794992861 │
│ Tatuapé      │ 1794313101 │
│ Mooca        │ 1787916569 │
│ Pinheiros    │ 1786375693 │
│ Butantã      │ 1778472411 │
│ Lapa         │ 1776954375 │
│ Moema        │ 1773707382 │
└──────────────┴────────────┘

ana@laptop:~/gcp$ python3 external.py 2026-09-29 2026-09-29 order_id,customer_id,store_id,district,items,total_cents,payment,created_at
60 objects listed, 1 read: 2 range requests, 499,423 of their 435,738 bytes fetched
┌──────────────┬──────────┐
│   district   │  sales   │
│   varchar    │  int128  │
├──────────────┼──────────┤
│ Butantã      │ 51441722 │
│ Mooca        │ 50703844 │
│ Tatuapé      │ 49693044 │
│ Santana      │ 48953221 │
│ Pinheiros    │ 48877437 │
│ Vila Mariana │ 48705315 │
│ Moema        │ 47805392 │
│ Lapa         │ 47482131 │
└──────────────┴──────────┘

ana@laptop:~/gcp$ python3 external.py 2026-08-01 2026-09-29 district,total_cents
60 objects listed, 60 read: 180 range requests, 10,152,701 of their 32,451,790 bytes fetched
┌──────────────┬────────────┐
│   district   │   sales    │
│   varchar    │   int128   │
├──────────────┼────────────┤
│ Vila Mariana │ 3758093658 │
│ Santana      │ 3753808833 │
│ Tatuapé      │ 3752619012 │
│ Mooca        │ 3747729248 │
│ Butantã      │ 3736296055 │
│ Lapa         │ 3724394126 │
│ Pinheiros    │ 3720802949 │
│ Moema        │ 3718075370 │
└──────────────┴────────────┘
```

**As duas colunas de setembro buscaram 4.878.703 dos 15.520.944 bytes guardados**, em 87 pedidos, três
para cada um dos 29 arquivos. A aula 16 contou a parte das duas colunas nesses arquivos em 2.978.159
bytes; o resto é o rodapé de cada arquivo, que todo leitor tem de buscar antes de saber onde está
qualquer outra coisa. Os outros 31 objetos foram listados e nunca abertos, porque os nomes diziam agosto.

**Um dia com todas as colunas buscou mais do que o arquivo tem**: 499.423 bytes de um arquivo de 435.738.
O leitor pediu o fim do arquivo primeiro, para achar o rodapé, e depois o arquivo inteiro, então os bytes
do rodapé atravessaram a rede duas vezes. Para uma consulta que quer tudo, um formato colunar não
economiza nada, e as leituras com faixa custam um pouco a mais.

**Duas colunas dos sessenta dias levaram 180 pedidos**, três por arquivo, e buscaram 10.152.701 dos
32.451.790 bytes do bucket: menos de um terço, pelo mesmo motivo de setembro. Uma consulta sobre colunas
paga pelas colunas e pelos rodapés, nunca pelo resto do arquivo.

## O que isto é, e o que não é

**Isto é o que um leitor de tabela externa faz, medido no emulador.** O número de pedidos, a leitura do
rodapé e as faixas das colunas são propriedades do formato Parquet e do leitor, e o leitor do BigQuery
tem de fazer o mesmo trabalho de alguma forma: listar os objetos, ler cada rodapé, buscar os pedaços de
coluna. **Não é o leitor do BigQuery.** O do BigQuery guarda metadados em cache (o assunto da próxima
seção), lê em paralelo por muitos workers, e busca nas faixas que escolher; quantos pedidos ele faz para
uma consulta não é algo que a documentação dele prometa. E não é uma conta: o que o BigQuery cobraria
por estas três consultas é a conta da aula 16, sobre os bytes das colunas, e o que o Cloud Storage
cobraria pelos pedidos é a da última seção.
