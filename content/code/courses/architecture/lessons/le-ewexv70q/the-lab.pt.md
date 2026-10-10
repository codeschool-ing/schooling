---
title: O laboratório: um banco a um milissegundo
version: 1
---

O PostgreSQL, o proxy de latência na frente dele, e o código de acesso a dados da loja, com cada página
escrita dos dois jeitos. Ele fica em `~/lab/perf`:

```sh
mkdir -p ~/lab/perf && cd ~/lab/perf
```

`latency.py`, o proxy:

```schooling-example
{"language": "python", "file": "latency.py", "parts": [{"code": "\"\"\"Forward TCP to the database, one millisecond late each way.\"\"\"\nimport asyncio\n\nDELAY = 0.001\n\n\nasync def pipe(reader, writer):\n    try:\n        while data := await reader.read(65536):\n            await asyncio.sleep(DELAY)\n            writer.write(data)\n            await writer.drain()\n    finally:\n        writer.close()\n\n\nasync def handle(client_reader, client_writer):\n    db_reader, db_writer = await asyncio.open_connection(\"db\", 5432)\n    await asyncio.gather(pipe(client_reader, db_writer), pipe(db_reader, client_writer))\n\n\nasync def main():\n    server = await asyncio.start_server(handle, \"\", 5432)\n    await server.serve_forever()\n\n\nasyncio.run(main())", "note": "Um proxy TCP que segura cada pedaço de dados por um milissegundo antes de repassá-lo, nas duas direções. Entre a loja e o banco ele transforma uma ida e volta numa máquina só, uma fração de milissegundo, em umas duas, que é o que custa um banco na zona de disponibilidade vizinha."}]}
```

`shop.py`, as páginas:

```schooling-example
{"language": "python", "file": "shop.py", "parts": [{"code": "\"\"\"Quitanda's pages, each written the easy way and the fast way, measured.\"\"\"\nimport random, sys, time\nimport psycopg\n\ndb = psycopg.connect(\"host=latency user=postgres password=quitanda\", autocommit=True)\nstats = {\"queries\": 0, \"rows\": 0, \"bytes\": 0}\n\n\ndef q(sql, *args):\n    cur = db.execute(sql, args)\n    rows = cur.fetchall() if cur.description else []\n    stats[\"queries\"] += 1\n    stats[\"rows\"] += len(rows)\n    stats[\"bytes\"] += sum(len(str(v)) for r in rows for v in r)\n    return rows\n\n", "note": "O código de acesso a dados da Quitanda, escrito de jeitos diferentes para cada página: o jeito fácil de escrever, e o jeito rápido. Todo comando imprime quantas consultas mandou, quantas linhas e bytes voltaram, e quanto tempo levou. Ele se conecta ao banco pelo proxy de latência, como a loja faria através de uma rede."}, {"code": "def seed():\n    rng = random.Random(16)\n    db.execute(\"\"\"\n        CREATE EXTENSION pg_stat_statements;\n        CREATE TABLE products (id int PRIMARY KEY, name text, cents int, description text);\n        CREATE TABLE orders (id int PRIMARY KEY, customer text, placed date);\n        CREATE TABLE items (order_id int, product_id int, units int);\n    \"\"\")\n    with db.cursor() as cur:\n        cur.executemany(\"INSERT INTO products VALUES (%s, %s, %s, %s)\",\n                        [(p, f\"product {p}\", rng.randint(500, 5000), \"x\" * 20000) for p in range(1, 51)])\n        cur.executemany(\"INSERT INTO orders VALUES (%s, %s, date '2026-01-01' + %s)\",\n                        [(o, f\"c-{rng.randint(1, 200)}\", rng.randint(0, 270)) for o in range(1, 2001)])\n        cur.executemany(\"INSERT INTO items VALUES (%s, %s, %s)\",\n                        [(o, rng.randint(1, 50), rng.randint(1, 3)) for o in range(1, 2001) for _ in range(4)])\n    print(\"seeded\")\n\n", "note": "`seed` enche o banco uma vez: 200 clientes, 2.000 pedidos de quatro itens cada, e 50 produtos, cada um com uma descrição de 20 KB, que é o tamanho do texto de uma página de produto e dos metadados de algumas imagens pequenas."}, {"code": "def history_n1(customer):\n    for (order,) in q(\"SELECT id FROM orders WHERE customer = %s\", customer):\n        q(\"SELECT product_id, units FROM items WHERE order_id = %s\", order)\n\n\ndef history_join(customer):\n    q(\"SELECT o.id, i.product_id, i.units FROM orders o JOIN items i ON i.order_id = o.id \"\n      \"WHERE o.customer = %s\", customer)\n\n", "note": "O histórico de pedidos, do jeito fácil: uma consulta para os pedidos do cliente, depois uma por pedido para os itens. Esse é o padrão **N+1**, e o carregamento preguiçoso de um ORM o escreve por você sem nenhuma linha que pareça um laço sobre o banco."}, {"code": "def catalogue_star():\n    q(\"SELECT * FROM products ORDER BY id\")\n\n\ndef catalogue_columns():\n    q(\"SELECT id, name, cents FROM products ORDER BY id\")\n\n", "note": "A lista do catálogo, que mostra um nome e um preço. `SELECT *` traz junto a descrição inteira de cada produto."}, {"code": "def best_sellers():\n    q(\"SELECT i.product_id, sum(i.units) FROM items i JOIN orders o ON o.id = i.order_id \"\n      \"WHERE o.placed > date '2026-09-28' - 30 GROUP BY 1 ORDER BY 2 DESC LIMIT 5\")\n\n", "note": "Os mais vendidos dos últimos 30 dias, que a página inicial da loja mostra a todo visitante. A consulta está certa; o que importa é com que frequência roda e o que lê a cada vez."}, {"code": "cache = {}\n\n\ndef front_page(*flags):\n    for _ in range(100):\n        if \"--cached\" in flags and time.time() - cache.get(\"at\", 0) < 60:\n            continue\n        best_sellers()\n        cache[\"at\"] = time.time()\n\n\nPAGES = {\"history-n1\": history_n1, \"history-join\": history_join, \"catalogue-star\": catalogue_star,\n         \"catalogue-columns\": catalogue_columns, \"best-sellers\": best_sellers, \"front-page\": front_page}\nname, *args = sys.argv[1:]\nif name == \"seed\":\n    seed()\nelse:\n    start = time.time()\n    PAGES[name](*args)\n    print(f\"{name}: {stats['queries']} queries, {stats['rows']} rows, {stats['bytes']:,} bytes, \"\n          f\"{(time.time() - start) * 1000:.0f} ms\")", "note": "Cem visitantes abrem a página inicial. Sem `--cached`, cada um roda a consulta dos mais vendidos; com ela, a resposta é guardada por um minuto e o banco é consultado uma vez."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir \"psycopg[binary]==3.3.6\"\nWORKDIR /app\nCOPY *.py .", "note": "Python e psycopg, como nas aulas 10 e 13."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  db:\n    image: postgres:17\n    command: postgres -c shared_preload_libraries=pg_stat_statements\n    environment:\n      POSTGRES_PASSWORD: quitanda\n  latency:\n    build: .\n    command: python latency.py\n    depends_on:\n      - db\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"shop.py\"]\n    depends_on:\n      - latency", "note": "O PostgreSQL, iniciado com o `pg_stat_statements`, a extensão que conta quanto cada consulta custa ao banco; o proxy de latência na frente dele; e a imagem que roda as páginas da loja."}]}
```

Suba o banco e o proxy, dê dez segundos, guarde numa variável o comando das páginas, e encha o banco:

```sh
docker compose up -d
P="docker compose --progress quiet run --rm tools"
```

```
ana@vm:~/lab/perf$ $P seed
seeded
```

Os números que cada página imprime são as medições da aula: consultas mandadas, linhas e bytes recebidos,
e o tempo da primeira consulta à última resposta, como o código da loja viu.
