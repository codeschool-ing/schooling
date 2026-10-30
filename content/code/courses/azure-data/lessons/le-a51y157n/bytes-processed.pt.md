---
title: Uma pergunta, quatro quantidades de bytes
version: 1
---

**Um pool serverless cobra pelo que lê, então a mesma pergunta pode custar quantias muito diferentes
conforme os arquivos a que é feita.** Esta seção faz uma pergunta, as vendas de outubro por forma de
pagamento, quatro vezes: ao CSV e ao Parquet, para o mês inteiro e para um dia. O motor é o **DuckDB, não
o Synapse**: ele lê os arquivos no Azurite por um pequeno sistema de arquivos escrito aqui, que conta
cada byte que busca. As contagens são o que um leitor do lago precisa buscar para cada pergunta; o que um
pool serverless cobraria é pelo menos isso, com o mínimo de 10 MB e o arredondamento da seção anterior
aplicados, a um preço ilustrativo.

Salve isto como `ask.py`, ao lado do `gen.py`:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [
{"code": "import io\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.dataset as ds\nimport pyarrow.fs as pafs\nfrom azure.storage.blob import BlobServiceClient\n\nPRICE_PER_TB = 5.00   # USD, ILLUSTRATIVE: run the price sheet of lesson 1 for the real one\n", "note": "O DuckDB responde o SQL, o PyArrow lê os arquivos, e a biblioteca do Azure busca os bytes. O preço é ilustrativo, como todo preço deste curso."},
{"code": "\n\nclass Lake(pafs.FileSystemHandler):\n    \"\"\"The lake container in Azurite, read-only, counting every byte it hands over.\"\"\"\n\n    def __init__(self):\n        service = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\n        self.container = service.get_container_client(\"lake\")\n        self.bytes, self.requests, self.blobs = 0, 0, set()\n", "note": "`Lake` apresenta o contêiner `lake` ao PyArrow como um sistema de arquivos, e conta o que entrega: bytes, requisições de leitura e os blobs abertos."},
{"code": "\n    def get_file_info(self, paths):\n        infos = []\n        for path in paths:\n            blob = self.container.get_blob_client(path)\n            if blob.exists():\n                infos.append(pafs.FileInfo(path, pafs.FileType.File, size=blob.get_blob_properties().size))\n            elif any(True for _ in self.container.list_blobs(name_starts_with=path.rstrip(\"/\") + \"/\")):\n                infos.append(pafs.FileInfo(path, pafs.FileType.Directory))\n            else:\n                infos.append(pafs.FileInfo(path, pafs.FileType.NotFound))\n        return infos\n\n    def get_file_info_selector(self, selector):\n        base = selector.base_dir.rstrip(\"/\") + \"/\"\n        infos, dirs = [], set()\n        for blob in self.container.list_blobs(name_starts_with=base):\n            infos.append(pafs.FileInfo(blob.name, pafs.FileType.File, size=blob.size))\n            parts = blob.name[len(base):].split(\"/\")[:-1]\n            dirs.update(base + \"/\".join(parts[:i + 1]) for i in range(len(parts)))\n        return infos + [pafs.FileInfo(d, pafs.FileType.Directory) for d in sorted(dirs)]\n", "note": "Listagem. O PyArrow pergunta o que há num caminho e o que há sob uma pasta, e as duas respostas vêm de listar blobs por prefixo, o que não lê dado nenhum."},
{"code": "\n    def open_input_file(self, path):\n        return pa.PythonFile(Blob(self, path), mode=\"r\")\n", "note": "Abrir um arquivo devolve um `Blob`, abaixo, embrulhado para o PyArrow poder posicionar e ler nele."},
{"code": "\n    def get_type_name(self):\n        return \"azurite-lake\"\n\n    def normalize_path(self, path):\n        return path\n\n    def _read_only(self, *args, **kwargs):\n        raise NotImplementedError(\"the lake is read-only here\")\n\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = _read_only\n    delete_file = move = copy_file = _read_only\n    open_input_stream = open_output_stream = open_append_stream = _read_only\n", "note": "O resto do que um sistema de arquivos precisa oferecer. Nada aqui grava, move ou apaga, então tudo isso recusa."},
{"code": "\n\nclass Blob(io.RawIOBase):\n    \"\"\"One blob, read in byte ranges: each read is one ranged GET to Azurite.\"\"\"\n\n    def __init__(self, lake, path):\n        self.lake, self.client = lake, lake.container.get_blob_client(path)\n        self.size, self.pos = self.client.get_blob_properties().size, 0\n        lake.blobs.add(path)\n\n    def readable(self):\n        return True\n\n    def seekable(self):\n        return True\n\n    def tell(self):\n        return self.pos\n\n    def seek(self, offset, whence=0):\n        self.pos = [offset, self.pos + offset, self.size + offset][whence]\n        return self.pos\n\n    def readinto(self, buffer):\n        n = min(len(buffer), self.size - self.pos)\n        if n <= 0:\n            return 0\n        buffer[:n] = self.client.download_blob(offset=self.pos, length=n).readall()\n        self.pos += n\n        self.lake.bytes += n\n        self.lake.requests += 1\n        return n\n", "note": "**A contagem está aqui.** Cada `readinto` é uma leitura de faixa do blob, `download_blob` com deslocamento e tamanho, e soma os bytes dela à contagem. Um leitor que pula até uma coluna e lê só ela aparece como um número pequeno."},
{"code": "\n\nlake = Lake()\nfs = pafs.PyFileSystem(lake)\nsql = sys.argv[1]\nif \" orders_csv\" in sql:\n    orders_csv = ds.dataset(\"orders_csv\", filesystem=fs, format=\"csv\", partitioning=\"hive\")\nelse:\n    orders = ds.dataset(\"orders\", filesystem=fs, format=\"parquet\", partitioning=\"hive\")\n", "note": "As duas tabelas. Um dataset é uma pasta de arquivos com as pastas `dt=` lidas como coluna, e só a que a consulta nomeia é aberta, para uma pergunta sobre o Parquet não pagar por olhar o CSV."},
{"code": "\nduckdb.sql(sql).show()\nif len(lake.blobs) < 5:\n    print(\"blobs opened:\", \", \".join(sorted(lake.blobs)))\nmb = max(10, -(-lake.bytes // 1_000_000))\nprint(f\"read from the lake: {lake.bytes:,} bytes in {lake.requests} ranged reads of {len(lake.blobs)} blobs\")\nprint(f\"billed as {mb} MB (whole MB, 10 MB minimum): {mb / 1_000_000 * PRICE_PER_TB:.6f} USD at an illustrative {PRICE_PER_TB:.2f} USD per TB\")\n", "note": "O DuckDB roda a consulta, encontrando `orders` ou `orders_csv` entre as variáveis do programa. Ele empurra para dentro do dataset as colunas de que a consulta precisa e o filtro em `dt`, e é isso que decide o que é lido. Depois a contagem, e a conta que um pool serverless aplicaria a esses bytes."}
]}
```

## O mês inteiro, em CSV e em Parquet

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 307681 │ 63109558.55 │
│ credit       │ 219350 │ 44934884.91 │
│ debit        │  87078 │  17837618.2 │
│ meal-voucher │  53454 │ 10989255.43 │
└──────────────┴────────┴─────────────┘

read from the lake: 34,900,248 bytes in 50 ranged reads of 31 blobs
billed as 35 MB (whole MB, 10 MB minimum): 0.000175 USD at an illustrative 5.00 USD per TB
```

**34.900.248 bytes: cada byte de cada arquivo CSV**, e um pouco mais que os 33.935.337 guardados, porque
o PyArrow leu primeiro o começo de um arquivo para conhecer as colunas, como as perguntas de um dia
abaixo mostram com mais clareza. A pergunta precisa de duas colunas de sete, e um CSV não dá ao leitor
jeito nenhum de pular as outras cinco.

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 307681 │ 63109558.55 │
│ credit       │ 219350 │ 44934884.91 │
│ debit        │  87078 │  17837618.2 │
│ meal-voucher │  53454 │ 10989255.43 │
└──────────────┴────────┴─────────────┘

read from the lake: 5,600,246 bytes in 94 ranged reads of 31 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**As mesmas quatro linhas a partir de 5.600.246 bytes**, um sexto do CSV. O DuckDB pediu ao PyArrow só
`payment` e `total_cents`, e o PyArrow leu o rodapé de cada arquivo, depois os blocos dessas duas colunas,
e nada mais: 94 leituras de faixa, umas três por arquivo, onde o CSV precisou de menos leituras e
maiores.

## Um dia, em Parquet e em CSV

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │   8415 │ 1720742.02 │
│ credit       │   5928 │ 1219676.93 │
│ debit        │   2357 │  478763.39 │
│ meal-voucher │   1488 │  306383.34 │
└──────────────┴────────┴────────────┘

blobs opened: orders/dt=2026-10-01/part-0.parquet, orders/dt=2026-10-15/part-0.parquet
read from the lake: 228,895 bytes in 4 ranged reads of 2 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**228.895 bytes de dois blobs.** O filtro em `dt` foi resolvido antes de qualquer coisa ser lida: `dt`
está no nome da pasta, então os outros dias nunca foram abertos. O segundo blob é o dia 15; o primeiro,
o dia 1º de outubro, foi aberto quando o dataset foi criado, porque o PyArrow lê um arquivo para
conhecer as colunas da tabela. Um pool serverless tem a mesma necessidade, e o mesmo tipo de custo,
quando ninguém lhe diz o esquema.

```
ana@laptop:~/azure$ python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │   8415 │ 1720742.02 │
│ credit       │   5928 │ 1219676.93 │
│ debit        │   2357 │  478763.39 │
│ meal-voucher │   1488 │  306383.34 │
└──────────────┴────────┴────────────┘

blobs opened: orders_csv/dt=2026-10-01/part-0.csv, orders_csv/dt=2026-10-15/part-0.csv
read from the lake: 1,889,288 bytes in 2 ranged reads of 2 blobs
billed as 10 MB (whole MB, 10 MB minimum): 0.000050 USD at an illustrative 5.00 USD per TB
```

**O CSV leu o dia 15 inteiro, 1.889.288 bytes, cerca de oito vezes o Parquet.** O particionamento
funcionou para os dois formatos: cada um abriu dois arquivos de trinta e um. **As duas decisões são
independentes e se multiplicam**: as pastas decidem quantos arquivos uma pergunta abre, e o formato
decide quanto de cada arquivo ela lê. Juntas, levaram a pergunta de 34.900.248 bytes para 228.895, cerca
de 150 vezes menos.

## O que a conta diria

Neste tamanho toda consulta menos a primeira fica abaixo do mínimo de 10 MB, então num pool serverless
três das quatro custariam o mesmo, e a primeira três vezes e meia isso. Isso é propriedade de um lago
pequeno, não motivo para ignorar o layout: as razões ficam e o mínimo não. Um ano destes pedidos lido em
CSV por um painel que atualiza a cada cinco minutos é o mês em CSV doze vezes, 288 vezes por dia. O mesmo
painel sobre Parquet, particionado por dia e perguntando por hoje, lê um rodapé e duas colunas de um
arquivo. Os dois respondem certo, e só um deles é uma conta que alguém nota.
