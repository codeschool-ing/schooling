---
title: Uma camada crua para transformar
version: 1
---

As lições 2 a 5 extraíram os dados da loja de quatro jeitos diferentes. **Esta lição trata do que
vem depois**, então ela parte da camada crua mais simples que guarda tudo: as seis tabelas da loja
copiadas inteiras, os preços das editoras como a API os mandou, e cada arquivo de eventos que caiu.

A Ana toca a primeira semana de março e inicia a API de preços, com
`sudo shop until 2026-03-07` e `sudo shop api`. A Ana busca todos os preços
que a API tem, com o cliente da lição 3, e roda o carregador:

```schooling-example
{
  "language": "python",
  "file": "load_raw.py",
  "parts": [
    {
      "code": "\"\"\"Load the raw layer: the shop's tables copied whole, and the files that\nlanded — the publishers' prices and the website's events — as JSON.\"\"\"\nimport glob\n\nimport psycopg\n\n"
    },
    {
      "code": "TABLES = [\"shops\", \"books\", \"customers\", \"orders\", \"order_lines\", \"payments\"]\nCOLUMNS = \"\"\"SELECT string_agg(format('%%I %%s', attname, format_type(atttypid, atttypmod)),\n                               ', ' ORDER BY attnum)\n               FROM pg_attribute\n              WHERE attrelid = %s::regclass AND attnum > 0 AND NOT attisdropped\"\"\"\n\n",
      "note": "Seis tabelas, e uma consulta que pede à loja para descrever as colunas e os tipos de cada uma. **A tabela crua é declarada a partir da descrição da própria origem**, então uma coluna que a loja acrescentar no mês que vem chega sem ninguém editar este arquivo — e o SQL de staging que a lê vai ser o lugar onde uma decisão é tomada."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"CREATE SCHEMA IF NOT EXISTS raw\")\n    shop.execute(\"SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY\")\n",
      "note": "Um snapshot para as seis tabelas, como a lição 3 exigiu, para nenhuma linha chegar sem o seu pedido."
    },
    {
      "code": "    for table in TABLES:\n        columns = shop.execute(COLUMNS, (table,)).fetchone()[0]\n        wh.execute(f\"DROP TABLE IF EXISTS raw.{table}\")\n        wh.execute(f\"CREATE TABLE raw.{table} ({columns})\")\n",
      "note": "Cada tabela crua é apagada e refeita, depois enchida com `COPY`. Uma carga completa, que é a resposta certa da lição 4 para uma semana de uma loja pequena."
    },
    {
      "code": "        src, dst = shop.cursor(), wh.cursor()\n        with src.copy(f\"COPY {table} TO STDOUT\") as out, \\\n             dst.copy(f\"COPY raw.{table} FROM STDIN\") as into:\n            for chunk in out:\n                into.write(chunk)\n        print(f\"raw.{table}: {src.rowcount} rows\")\n\n",
      "note": "As linhas passam de um banco para o outro no próprio fluxo do `COPY`, um pedaço por vez, e o Python nunca as separa em linhas."
    },
    {
      "code": "    for name, pattern in [(\"prices\", \"landing/prices.jsonl\"),\n                          (\"events\", \"landing/events/*.jsonl\")]:\n        wh.execute(f\"DROP TABLE IF EXISTS raw.{name}\")\n        wh.execute(f\"CREATE TABLE raw.{name} (doc jsonb NOT NULL, file text NOT NULL)\")\n",
      "note": "**JSON chega como JSON.** Cada linha do arquivo de preços e de cada arquivo de eventos vira um valor `jsonb`, intocado, ao lado do nome do arquivo de onde veio. Interpretá-lo é trabalho do staging."
    },
    {
      "code": "        n = 0\n        with wh.cursor().copy(f\"COPY raw.{name} (doc, file) FROM STDIN\") as into:\n            for path in sorted(glob.glob(pattern)):\n                for line in open(path, encoding=\"utf-8\"):\n                    into.write_row((line, path))\n                    n += 1\n        print(f\"raw.{name}: {n} documents\")\n",
      "note": "O `write_row` entrega uma linha por vez ao mesmo `COPY`, então o arquivo inteiro continua viajando num comando só."
    }
  ]
}
```

```
ana@vm:~/etl$ python prices.py 2000-01-01T00:00:00-03:00 landing/prices.jsonl
909 prices in 5 pages, 1 waits for the rate limit
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5221 rows
raw.orders: 18945 rows
raw.order_lines: 29668 rows
raw.payments: 18945 rows
raw.prices: 909 documents
raw.events: 18308 documents
```

A camada crua agora guarda três tipos de coisa, e **cada um vai precisar de uma transformação
diferente**:

- as tabelas da loja, cujas linhas já estão bem formadas — elas precisam de uma data calculada, e
  de algumas colunas derivadas, e de nada limpo;
- os preços, mandados pelos sistemas de várias editoras por uma API só, que discordam entre si sobre
  como escrever um ISBN;
- os eventos, que chegam pelo menos uma vez.

## Onde o SQL mora

Cada transformação desta lição é um arquivo SQL que monta uma tabela, e os arquivos ficam em dois
diretórios que são as duas camadas acima do `raw`:

```
sql/
  staging/   one cleaned table per raw table
  marts/     what people ask about
```

Um arquivo de staging lê só o `raw`; um arquivo de marts lê só o `staging`. **Essa regra é toda a
divisão em camadas da lição 2, garantida pelo lugar onde um arquivo pode ficar.** As próximas seções
escrevem os arquivos um de cada vez; a última monta todos em ordem.
