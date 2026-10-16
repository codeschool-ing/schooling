---
title: Perguntando ao lago, e contando o que ele leu
version: 1
---

**A resposta do Athena vem com um número que decide o preço dela**, `DataScannedInBytes`, e o do
moto é sempre 0. Então a pergunta vai para um programa seu que faz duas coisas: responde o SQL com o
DuckDB e conta cada byte que o DuckDB tira do S3 para isso. Essa contagem é a quantidade que o Athena
cobra, medida nos mesmos objetos, e o programa a precifica com a linha que a tabela imprimiu.

Salve como `~/aws/ask.py`, ao lado do `lake.py` e do `prices.py`, que ele importa:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"ask.py: SQL over the lake in S3, and the bytes the query read to answer it.\n\n    python3 ask.py \"SELECT payment, sum(total_cents) FROM orders GROUP BY payment\"\n    python3 ask.py -t daily=quitanda-curated-prod/daily/:parquet \"SELECT ...\"\n\nATHENA IS NOT RUN HERE. moto accepts an Athena query and runs nothing, so the\nengine is DuckDB, inside this program, reading the same objects in S3 that\nAthena would read. What it measures is what Athena bills for: every byte the\nengine pulls out of S3. Two tables are always defined:\n\n    orders       s3://quitanda-curated-prod/orders/    Parquet\n    orders_csv   s3://quitanda-raw-prod/raw/orders/     CSV\n\nBoth are partitioned by dt, which is read from the keys (dt=2026-10-01/).\n\"\"\"\n", "note": "**O Athena não roda aqui, e a docstring diz isso primeiro.** O motor é o DuckDB, dentro deste programa; as tabelas são as duas camadas que o `lake.py` gravou, e o `-t` acrescenta qualquer outro prefixo do S3 como tabela."}, {"code": "import argparse\nimport math\nimport os\nimport sys\n\nimport duckdb\nimport pyarrow as pa\nimport pyarrow.dataset as ds\nimport pyarrow.fs as fs\n\nfrom lake import CURATED, RAW, filesystem\nfrom prices import price\n\n", "note": "O `lake.py` fornece os dois prefixos e a conexão com o S3, e o `prices.py`, da lição 1, fornece o preço de um terabyte lido. Os dois precisam estar no mesmo diretório deste programa."}, {"code": "TABLES = {'orders': f'{CURATED}/:parquet', 'orders_csv': f'{RAW}/:csv'}\nMB, TB = 2 ** 20, 2 ** 40\n\n\n", "note": "As duas tabelas que toda execução tem, e as unidades, que são binárias: um megabyte aqui são 2 elevado a 20 bytes e um terabyte, 2 elevado a 40."}, {"code": "class Counted(fs.FileSystemHandler):\n    \"\"\"S3 as PyArrow sees it, with a counter on every read.\"\"\"\n\n    def __init__(self, inner):\n        self.inner, self.bytes, self.gets, self.objects = inner, 0, 0, set()\n\n    def open_input_file(self, path):\n        self.objects.add(path)\n        inner, count = self.inner.open_input_file(path), self\n\n        class File:\n            closed = False\n\n            def read(self, n=-1):\n                data = inner.read() if n is None or n < 0 else inner.read(n)\n                count.bytes += len(data)\n                count.gets += 1\n                return data\n\n            def seek(self, *where): return inner.seek(*where)\n            def tell(self): return inner.tell()\n            def size(self): return inner.size()\n            def close(self): inner.close()\n            def readable(self): return True\n            def seekable(self): return True\n\n        return pa.PythonFile(File(), mode='r')\n\n", "note": "**A medição inteira é esta classe.** Ela fica entre o PyArrow e o S3, e todo `read` que o motor faz passa por ela: os bytes são somados, cada leitura é uma requisição GET com intervalo ao S3, e o objeto é anotado."}, {"code": "    def open_input_stream(self, path): return self.open_input_file(path)\n    def get_type_name(self): return 'counted'\n    def normalize_path(self, path): return self.inner.normalize_path(path)\n    def get_file_info(self, paths): return self.inner.get_file_info(paths)\n    def get_file_info_selector(self, selector): return self.inner.get_file_info(selector)\n\n    def refuse(self, *args): raise OSError('ask.py only reads')\n    create_dir = delete_dir = delete_dir_contents = delete_root_dir_contents = refuse\n    delete_file = move = copy_file = open_output_stream = open_append_stream = refuse\n\n\n", "note": "O resto do que o PyArrow pede a um sistema de arquivos: listagens e informações de arquivo passam direto para o S3, e qualquer coisa que gravaria é recusada, porque fazer uma pergunta nunca pode mudar o lago."}, {"code": "def main():\n    args = argparse.ArgumentParser()\n    args.add_argument('-t', '--table', action='append', default=[],\n                      help='NAME=BUCKET/PREFIX/:FORMAT, the format parquet, csv, json or orc')\n    args.add_argument('sql')\n    args = args.parse_args()\n    count = Counted(filesystem())\n    s3 = fs.PyFileSystem(count)\n    db = duckdb.connect()\n    tables = dict(TABLES, **dict(t.split('=', 1) for t in args.table))\n    for name, where in tables.items():\n        prefix, kind = where.rsplit(':', 1)\n        db.register(name, ds.dataset(prefix, filesystem=s3, format=kind, partitioning='hive'))\n    count.bytes, count.gets, count.objects = 0, 0, set()\n", "note": "Cada tabela é um dataset do PyArrow sobre um prefixo, registrado no DuckDB pelo nome. `partitioning='hive'` transforma `dt=2026-10-01` numa chave em uma coluna `dt`, e é isso que permite a um filtro em `dt` pular objetos inteiros. Os contadores só zeram depois que as tabelas são encontradas, então a listagem não conta como parte da pergunta."}, {"code": "    try:\n        db.sql(args.sql).show(max_rows=40)\n    except duckdb.Error as e:\n        sys.exit(str(e))\n    billed = max(10 * MB, math.ceil(count.bytes / MB) * MB)\n    usd = price('AmazonAthena', 'DataScannedInTB')\n    objects = len(count.objects)\n    print(f'read from S3: {count.bytes:,} bytes in {count.gets} GET requests '\n          f'to {objects} object{\"s\" * (objects != 1)}')\n    print(f'Athena would bill {billed // MB} MB (whole MB, 10 MB minimum): '\n          f'{billed / TB * usd:.6f} USD at {usd:.2f} USD per TB', flush=True)\n    os._exit(0)\n\n\nif __name__ == '__main__':\n    main()\n", "note": "A pergunta, a resposta e a conta. **O que o Athena cobraria são os bytes lidos, arredondados para cima até o megabyte inteiro, com dez megabytes como o mínimo de uma consulta.** O `os._exit` sai na hora: depois de um `LIMIT`, o PyArrow pode ainda estar lendo adiante em segundo plano, e uma saída normal pararia o interpretador debaixo dele."}]}
```

**A contagem é feita por onde os bytes passam, não estimada a partir do SQL.** O DuckDB não busca
objetos sozinho aqui: ele pede ao PyArrow as linhas de uma tabela, o PyArrow as lê do S3 pelo sistema
de arquivos que recebeu, e o que ele recebe é o `Counted`, que soma o que cada leitura devolveu.
Então uma coluna que a consulta não nomeia é uma coluna que ninguém leu, e um dia que o filtro exclui
é um objeto que ninguém abriu, e os números no fim mostram as duas coisas. São contagens do que este
motor fez, o que é próximo do que o motor do Athena faz com os mesmos arquivos, e não uma cópia
disso: dois motores podem ler o mesmo rodapé com um número diferente de requisições.

## A primeira pergunta

Quanto a Quitanda vendeu em outubro, por forma de pagamento? Feita ao CSV:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 40,641,097 bytes in 93 GET requests to 31 objects
Athena would bill 39 MB (whole MB, 10 MB minimum): 0.000335 USD at 9.00 USD per TB
```

**A resposta são quatro linhas, e a leitura foi cada byte de cada arquivo**: 40.641.097 bytes, o
total que o `lake.py` imprimiu para a camada raw, até o byte. Um arquivo CSV não tem como dizer onde
começa uma coluna, então o motor leu cada linha inteira para achar dois valores em cada uma, o
pagamento e o total, e jogou fora os outros cinco. Os 31 objetos são os 31 dias, e as 93 requisições
GET são o PyArrow lendo cada um em três pedaços.

A conta embaixo é a aritmética das regras de "O Athena lê os arquivos onde eles estão": 40.641.097 bytes são 38,8 megabytes, arredondados
para 39, e 39 megabytes a 9 dólares o terabyte dão 0,000335 dólar. Um número pequeno, porque um mês
de uma loja é um lago pequeno; a próxima seção é sobre a razão, que não encolhe quando o lago cresce.

## Quando a pergunta está errada

Uma coluna que não existe é o erro mais comum, e o DuckDB diz quais poderiam ter sido:

```
ana@laptop:~/aws$ python3 ask.py "SELECT sum(total) FROM orders"
Binder Error: Referenced column "total" not found in FROM clause!
Candidate bindings: "total_cents", "dt", "customer_id"
```

Nenhuma contagem de bytes aparece, porque nada foi lido: o erro veio enquanto a consulta era
planejada, antes de um único objeto ser aberto. O Athena falha a mesma consulta na mesma etapa, com
um erro escrito do jeito dele, e uma consulta que falha também não custa nada lá.

**Uma diferença para ter em mente em toda pergunta deste curso.** O `ask.py` lista o prefixo toda vez
que roda, então um dia gravado um segundo atrás já está na próxima resposta. O Athena lê a lista de
partições do catálogo, e um dia que ninguém registrou nem aparece na resposta dele, que é a surpresa que "O Athena lê os arquivos onde eles estão" descreve. Um lago consultado pelos dois, que é o caso comum, pode dar duas
respostas ao mesmo SQL exatamente por isso.
