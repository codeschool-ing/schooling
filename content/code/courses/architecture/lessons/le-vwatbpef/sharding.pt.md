---
title: Dividindo os pedidos por cliente
version: 1
---

O sharding começa com uma decisão, e é a mais difícil de mudar depois: **a chave de shard**, o valor que
decide em que shard uma linha mora. Toda consulta que inclui a chave vai para um shard. Toda consulta que
não inclui tem de ir para todos.

Para os pedidos da Quitanda os candidatos são o cliente, a data do pedido e o id do pedido. O cliente
costuma ser o certo para pedidos, porque a maioria das perguntas é sobre os pedidos de um cliente: o
histórico, a cesta, a última entrega. A data é tentadora e quase sempre errada para escritas: todo pedido
novo vai para o shard de hoje, então um shard recebe todas as escritas enquanto os outros ficam parados,
o que é um **ponto quente** (*hot spot*).

Há dois jeitos de transformar uma chave num shard:

- **Por faixa**: clientes de A a H no shard 0, de I a Q no shard 1. Faixas mantêm vizinhos juntos, então
  "todo cliente cujo nome começa com B" é um shard só, mas elas precisam ser escolhidas e movidas
  conforme os dados crescem de forma desigual.
- **Por hash**: um hash da chave, módulo o número de shards. Um bom hash espalha as chaves por igual, por
  isso é o padrão, ao custo de espalhar os vizinhos por todos os shards.

## O laboratório: dois bancos e um roteador

Dois servidores PostgreSQL que não sabem nada um do outro, e um programa que decide para onde vai cada
pedido. Sistemas de verdade põem essa lógica numa biblioteca, num proxy ou no próprio banco, mas é a
mesma função. Ele fica em `~/lab/shards`:

```sh
mkdir -p ~/lab/shards && cd ~/lab/shards
```

`schema.sql`:

```schooling-example
{"language": "sql", "file": "schema.sql", "parts": [{"code": "CREATE TABLE orders (\n    id       bigint PRIMARY KEY,\n    customer text NOT NULL,\n    product  text NOT NULL,\n    units    int NOT NULL\n);\nCREATE INDEX ON orders (customer);", "note": "A mesma tabela nos dois shards. Cada shard guarda só os pedidos dos seus clientes, e nenhum sabe que o outro existe."}]}
```

`shard.py`:

```schooling-example
{"language": "python", "file": "shard.py", "parts": [{"code": "\"\"\"Quitanda's orders, split across two databases by customer.\"\"\"\nimport random, sys, zlib\nimport psycopg\n\nSHARDS = [psycopg.connect(f\"host=shard-{i} user=postgres password=quitanda\", autocommit=True)\n          for i in range(2)]\nPRODUCTS = [\"coffee\", \"tea\", \"rice\", \"beans\", \"flour\", \"sugar\", \"oil\", \"salt\"]\n\n\ndef shard_of(customer, count=len(SHARDS)):\n    return zlib.crc32(customer.encode()) % count\n\n", "note": "O roteador. Todo pedido pertence a um cliente, e o cliente decide o shard: um hash do id do cliente, módulo o número de shards. Essa função é tudo o que faz dois bancos parecerem um."}, {"code": "def load():\n    rng = random.Random(59)\n    for n in range(1, 2001):\n        c = rng.randint(1, 40)\n        product = rng.choice(PRODUCTS[c % 5:c % 5 + 4])\n        SHARDS[shard_of(f\"c-{c}\")].execute(\n            \"INSERT INTO orders VALUES (%s, %s, %s, %s)\", (n, f\"c-{c}\", product, rng.randint(1, 4)))\n    for i, db in enumerate(SHARDS):\n        print(f\"shard-{i}: {db.execute('SELECT count(*) FROM orders').fetchone()[0]} orders\")\n\n", "note": "Os mesmos 2.000 pedidos toda vez, de um gerador aleatório com semente fixa: 40 clientes, e cada cliente compra quatro dos oito produtos."}, {"code": "def customer(c):\n    i = shard_of(c)\n    n, units = SHARDS[i].execute(\n        \"SELECT count(*), sum(units) FROM orders WHERE customer = %s\", (c,)).fetchone()\n    print(f\"{c} is on shard-{i}: {n} orders, {units} units\")\n\n", "note": "Uma pergunta sobre um cliente vai para um shard, e o shard responde sozinho, com o seu índice."}, {"code": "def order(n):\n    for i, db in enumerate(SHARDS):\n        row = db.execute(\"SELECT customer, product, units FROM orders WHERE id = %s\", (n,)).fetchone()\n        print(f\"asked shard-{i}: {row or 'not here'}\")\n\n", "note": "Uma pergunta sobre um pedido pelo id não tem cliente, então todo shard tem de ser perguntado."}, {"code": "def top(naive):\n    limit = \"LIMIT 3\" if naive else \"\"\n    totals = {}\n    for db in SHARDS:\n        for product, units in db.execute(\n                f\"SELECT product, sum(units) FROM orders GROUP BY product ORDER BY 2 DESC {limit}\"):\n            totals[product] = totals.get(product, 0) + units\n    for product, units in sorted(totals.items(), key=lambda kv: -kv[1])[:3]:\n        print(f\"{product:8} {units}\")\n\n", "note": "Os produtos mais vendidos precisam de todo shard. `--naive` pede a cada shard o seu próprio top três e junta esses; o padrão pede a cada um o total de todos os produtos e soma aqui."}, {"code": "def moves(count):\n    moved = sum(shard_of(f\"c-{c}\") != shard_of(f\"c-{c}\", count) for c in range(1, 41))\n    print(f\"{moved} of 40 customers change shard going from 2 shards to {count}\")\n\n\ncmd, *args = sys.argv[1:]\nif cmd == \"load\":\n    load()\nelif cmd == \"customer\":\n    customer(args[0])\nelif cmd == \"order\":\n    order(int(args[0]))\nelif cmd == \"top\":\n    top(\"--naive\" in args)\nelif cmd == \"moves\":\n    moves(int(args[0]))", "note": "Quantos dos 40 clientes morariam num shard diferente se houvesse três shards em vez de dois."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir \"psycopg[binary]==3.3.6\"\nWORKDIR /app\nCOPY shard.py .", "note": "Python e psycopg, o driver do PostgreSQL."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-shard: &shard\n  image: postgres:17\n  environment:\n    POSTGRES_PASSWORD: quitanda\n  volumes:\n    - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro\nservices:\n  shard-0:\n    <<: *shard\n  shard-1:\n    <<: *shard\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    depends_on:\n      - shard-0\n      - shard-1", "note": "Dois servidores PostgreSQL que não sabem nada um do outro, cada um criando a tabela `orders` na primeira partida, e a imagem que roda o `shard.py` contra eles."}]}
```

Suba os dois shards, dê uns dez segundos, e economize digitação com uma variável para o roteador:

```sh
docker compose up -d
R="docker compose --progress quiet run --rm tools python shard.py"
```

Carregue os pedidos, e pergunte sobre um cliente:

```
ana@vm:~/lab/shards$ $R load
shard-0: 1054 orders
shard-1: 946 orders
ana@vm:~/lab/shards$ $R customer c-7
c-7 is on shard-1: 55 orders, 147 units
```

O hash pôs 21 clientes no shard 0 e 19 no shard 1, então os pedidos se dividiram mais ou menos ao meio:
1.054 e 946. Uma pergunta sobre `c-7` foi só para o shard 1, que a respondeu com o próprio índice,
exatamente como um banco único teria feito. **É o caso para o qual o sharding é projetado**, e com a
chave certa é a maior parte do tráfego.

Agora procure um pedido pelo id, que não é a chave de shard:

```
ana@vm:~/lab/shards$ $R order 1234
asked shard-0: ('c-1', 'flour', 4)
asked shard-1: not here
```

O roteador não tem como saber onde mora o pedido 1234, então perguntou aos dois shards. Com dois shards
é uma consulta desperdiçada. Com quarenta, toda busca por id são quarenta consultas, e a mais lenta das
quarenta decide quanto a página demora. É o primeiro sinal de uma consulta que não cabe mais.
