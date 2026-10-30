---
title: Um mês de pedidos no lago
version: 1
---

**A conta de um pool serverless é decidida pelos arquivos antes de qualquer consulta ser escrita**,
então a prática começa pelos arquivos. Esta seção põe um mês de pedidos da Quitanda no Azurite duas
vezes: uma como CSV, o formato que a loja exporta, e uma como Parquet, o formato que um lago guarda. Tudo
daqui até o fim da próxima seção roda na sua máquina, só com o Azurite:

```sh
docker compose up -d
```

**Nada disso é o Synapse.** O Azurite guarda os arquivos, como o Blob Storage guardaria; ele não tem
endpoint de Data Lake, como mostrou a lição 3, então os arquivos são blobs comuns cujos nomes contêm
barras. O motor que os consulta na próxima seção é o DuckDB. O que vale para o Synapse são os próprios
arquivos, o formato e as pastas deles, porque é isso que um pool serverless também lê.

Salve isto como `gen.py` em `~/azure`:

```schooling-example
{"language": "python", "file": "gen.py", "parts": [
{"code": "import io\nimport os\nimport random\nfrom datetime import date, timedelta\n\nimport pyarrow as pa\nimport pyarrow.csv as csv\nimport pyarrow.parquet as pq\nfrom azure.storage.blob import BlobServiceClient\n\nSTORES = [\"pinheiros\", \"moema\", \"tatuape\", \"santana\", \"lapa\"]\nPAYMENTS = [\"pix\"] * 46 + [\"credit\"] * 33 + [\"debit\"] * 13 + [\"meal-voucher\"] * 8\nservice = BlobServiceClient.from_connection_string(os.environ[\"AZURE_STORAGE_CONNECTION_STRING\"])\nlake = service.get_container_client(\"lake\")\nif not lake.exists():\n    lake.create_container()\n", "note": "Cinco lojas, quatro formas de pagamento nas proporções que um mercado de São Paulo poderia ver, e um contêiner de blobs chamado `lake` no Azurite. A string de conexão é a que todo terminal deste curso exporta."},
{"code": "\nrng = random.Random(2026)\nn = 0\nfor d in range(31):\n    day = date(2026, 10, 1) + timedelta(days=d)\n    rows = {\"order_id\": [], \"hour\": [], \"customer_id\": [], \"store\": [], \"payment\": [],\n            \"items\": [], \"total_cents\": []}\n    for _ in range(rng.randint(18_000, 26_000)):\n        n += 1\n        rows[\"order_id\"].append(f\"o-{n:07d}\")\n        rows[\"hour\"].append(min(23, max(7, int(rng.gauss(18, 3)))))\n        rows[\"customer_id\"].append(f\"c-{rng.randint(1, 60_000):05d}\")\n        rows[\"store\"].append(rng.choice(STORES))\n        rows[\"payment\"].append(rng.choice(PAYMENTS))\n        rows[\"items\"].append(rng.randint(1, 30))\n        rows[\"total_cents\"].append(rng.randint(990, 39_990))\n    table = pa.table(rows)\n", "note": "Um mês de pedidos, inventado mas sempre o mesmo: o gerador tem semente, então toda execução, aqui e na sua máquina, produz os mesmos 667.563 pedidos. Cada dia recebe entre 18.000 e 26.000, a maioria à noite."},
{"code": "\n    for layer, write in ((\"orders\", pq.write_table), (\"orders_csv\", csv.write_csv)):\n        out = io.BytesIO()\n        write(table, out)\n        name = f\"{layer}/dt={day}/part-0.{'parquet' if layer == 'orders' else 'csv'}\"\n        lake.upload_blob(name, out.getvalue(), overwrite=True)\n", "note": "Cada dia é gravado duas vezes, como Parquet em `orders/` e como CSV em `orders_csv/`, numa pasta chamada `dt=` e a data. Esse nome de pasta é o particionamento: um leitor que conhece a convenção sabe que dia um arquivo guarda sem abri-lo."},
{"code": "\nfor layer in (\"orders\", \"orders_csv\"):\n    blobs = list(lake.list_blobs(name_starts_with=layer + \"/\"))\n    print(f\"{layer:11} {len(blobs)} files, {sum(b.size for b in blobs):,} bytes\")\nprint(f\"{n:,} orders in October\")\n", "note": "O que fica no lago depois."}
]}
```

```
ana@laptop:~/azure$ python gen.py
orders      31 files, 13,433,647 bytes
orders_csv  31 files, 33,935,337 bytes
667,563 orders in October
```

**Os mesmos 667.563 pedidos, 13.433.647 bytes em Parquet e 33.935.337 em CSV**: o Parquet é 40% do CSV,
com exatamente as mesmas linhas. Duas coisas fazem a diferença. O Parquet guarda cada coluna junta,
então uma coluna de `pix`, `pix`, `credit` repetida vinte mil vezes comprime para muito pouco, onde o
CSV escreve cada valor por extenso em toda linha. E ele guarda números como números, onde o CSV soletra
`24890` como cinco caracteres e uma vírgula.

**Cada arquivo diz também o que tem dentro.** Um arquivo Parquet termina com um rodapé que lista as
colunas, os tipos delas, e onde no arquivo começam os dados de cada coluna. Esse rodapé é o que deixa um
leitor buscar duas colunas de sete e pular o resto, o que a próxima seção mede. Um arquivo CSV não tem
nada disso: para achar o `payment` de qualquer pedido, um leitor tem de ler todas as linhas desde o
começo.

**E as pastas dizem que dia cada arquivo guarda.** O `orders/dt=2026-10-15/part-0.parquet` guarda o dia
15 de outubro e nada mais, que é a convenção chamada particionamento hive. Um pool serverless a lê pela
função `filepath()`, e o DuckDB e o PyArrow a leem como uma coluna chamada `dt`. Uma consulta que pede um
dia consegue pular os outros trinta arquivos sem abri-los.
