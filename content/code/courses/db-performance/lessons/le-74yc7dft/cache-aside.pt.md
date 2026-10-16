---
title: Cache-aside, o padrão que quase todo mundo usa
version: 1
---

Um **cache** guarda a resposta a uma pergunta num lugar mais rápido de alcançar do que aquele que a
calcula, para que a próxima pessoa que perguntar receba a resposta guardada em vez do trabalho. Para
um banco de dados esse "lugar" costuma ser um armazenamento separado em memória, e o mais comum é o
**Redis**: um servidor que guarda chaves e valores em memória e responde uma consulta em uma fração
de milissegundo.

A crença errada a desfazer primeiro é a de que um cache deixa o banco mais rápido. Ele não toca no
banco. Ele faz **algumas respostas** chegarem sem que o banco seja consultado, e cada uma dessas
respostas é uma cópia que pode estar desatualizada. O resto desta aula trata dessa cópia: quão velha
ela pode estar (seção 03), como jogá-la fora quando o dado muda (seção 04) e o que acontece no
momento em que ela falta (seção 05). As aulas 3 a 11 deixaram a pergunta mais barata de responder; um
cache evita fazê-la, o que só vale a pena para perguntas feitas muito mais vezes do que as respostas
mudam.

## O Redis e um cliente Python

Instale o servidor e as duas bibliotecas Python que o programa usa, tudo do repositório do Ubuntu:

```sh
sudo apt install -y redis-server python3-redis python3-psycopg
```

O `apt` liga o Redis e o habilita no boot. Ele escuta só na própria máquina, porta 6379. Confira que
ele responde:

```
ana@vm:~$ systemctl is-active redis-server
active
ana@vm:~$ redis-cli ping
PONG
```

O `psycopg` é o driver do PostgreSQL para Python, e o `redis` o do Redis. O programa abaixo fala com
os dois, como faria uma aplicação.

## O programa

O painel do vendedor da aula 2 é um bom candidato. Os vendedores o deixam aberto e o recarregam, os
números de dezembro mudam algumas vezes por hora para cada vendedor, e cada recarga roda a mesma
consulta. Salve isto como `dashboard.py` no seu diretório pessoal; o botão de copiar leva o arquivo
inteiro sem as notas:

```schooling-example
{"language": "python", "file": "dashboard.py", "parts": [{"code": "# dashboard.py: a seller's December dashboard, read through a cache.\nimport json, random, sys, time\nimport psycopg, redis\n\ndb = psycopg.connect(\"dbname=market\", autocommit=True)\ncache = redis.Redis()\nTTL = 60\nseen = {\"cache\": 0, \"database\": 0}\n", "note": "Uma conexão com o banco e uma com o Redis, abertas uma vez só, como uma aplicação as mantém. `TTL` é quanto tempo uma resposta guardada vive, sessenta segundos aqui; a seção 03 trata de escolher esse número. `seen` conta de onde vieram as respostas."}, {"code": "QUERY = \"\"\"\n    SELECT date_trunc('day', placed_at)::date, count(*), sum(total_cents)::bigint\n    FROM orders\n    WHERE seller_id = %s AND placed_at >= '2025-12-01'\n    GROUP BY 1 ORDER BY 1\"\"\"\n\ndef from_database(seller):\n    rows = db.execute(QUERY, (seller,)).fetchall()\n    return [[str(day), n, total] for day, n, total in rows]\n", "note": "A consulta do painel da aula 2, sem mudança além de dois casts. As linhas viram listas simples para poderem ser guardadas como JSON, e o `::bigint` mantém a soma inteira: o `sum` de inteiros no PostgreSQL é um `numeric`, que chega ao Python como um `Decimal` que o JSON não guarda."}, {"code": "def dashboard(seller):\n    key = f\"dashboard:{seller}\"\n    cached = cache.get(key)\n    if cached is not None:\n        seen[\"cache\"] += 1\n        return json.loads(cached), \"cache\"\n    rows = from_database(seller)\n    cache.set(key, json.dumps(rows), ex=TTL)\n    seen[\"database\"] += 1\n    return rows, \"database\"\n", "note": "**Cache-aside** em oito linhas. Procure no cache sob uma chave que dá nome à pergunta; num acerto, devolva o que está lá; numa falta, pergunte ao banco, guarde a resposta com o seu TTL e devolva. O banco nunca sabe que o cache existe, e isso é a força do padrão e, na seção 04, a fraqueza dele."}, {"code": "def run(label, read, requests=5000):\n    random.seed(21)\n    start = time.perf_counter()\n    for _ in range(requests):\n        read(random.randint(2, 201))\n    ms = 1000 * (time.perf_counter() - start) / requests\n    print(f\"{label:<12} {requests} requests, {ms:.3f} ms each\")\n", "note": "Os mesmos 5000 pedidos, para os vendedores 2 a 201 na mesma ordem toda vez (`random.seed`), cronometrados uma vez direto do banco e outra pelo cache. Duzentos vendedores fazem o papel dos que deixam o painel aberto."}, {"code": "if __name__ == \"__main__\":\n    if len(sys.argv) > 1:\n        seller = int(sys.argv[1])\n        rows, source = dashboard(seller)\n        orders = sum(n for _, n, _ in rows)\n        print(f\"seller {seller}: {orders} orders since 2025-12-01, \"\n              f\"from the {source}; expires in {cache.ttl(f'dashboard:{seller}')} s\")\n    else:\n        cache.flushdb()  # start cold; this Redis holds nothing else\n        run(\"database\", from_database)\n        run(\"cache-aside\", dashboard)\n        print(f\"cache-aside: {seen['cache']} hits, {seen['database']} misses\")", "note": "Com o número de um vendedor, lê aquele painel e diz de onde veio a resposta e quanto tempo ainda resta a ela. Sem número, esvazia o cache, que neste laboratório não guarda mais nada, e roda as duas medições."}]}
```

O formato de `dashboard()` é o **cache-aside**, também chamado de carga preguiçosa: a aplicação olha
para o lado, para o cache, antes de ir ao banco, e só enche o cache com respostas que alguém de fato
pediu. O cache não guarda regra nenhuma sobre os dados. Guarda o que a última falta pôs lá, sob uma
chave que a aplicação escolheu, pelo tempo que o TTL disser.

## Medido

Rode-o sem argumentos. Ele cronometra 5000 pedidos de painel direto do banco, e depois os mesmos 5000
pelo cache:

```
ana@vm:~$ python3 dashboard.py
database     5000 requests, 3.757 ms each
cache-aside  5000 requests, 0.281 ms each
cache-aside: 4800 hits, 200 misses
```

**3,757 milissegundos por pedido vindo do banco, e 0,281 pelo cache**, cerca de treze vezes menos. O
cache respondeu **4800** dos 5000 pedidos e o banco respondeu as **200** faltas, uma para cada
vendedor na primeira vez que foi pedido. Visto do banco, a carga do painel caiu 96%: de 5000 pedidos,
ele rodou a consulta 200 vezes.

Dois detalhes mantêm isto honesto. Os dois tempos incluem o Python e uma ida e volta a um servidor na
mesma máquina, então o número do cache é quase todo o custo de perguntar qualquer coisa ao Redis. E
o lado do banco já era rápido, porque a aula 2 deu a `orders` o índice em `seller_id`; um cache na
frente de uma consulta lenta por falta de índice esconde o problema em vez de consertá-lo, e ele
volta a cada falta.

## O que vale a pena pôr em cache

- **Lido muito, mudado pouco.** A proporção é o que os 4800 contra 200 acima medem. Um valor lido
  uma vez por mudança é um cache que está sempre faltando.
- **A mesma pergunta, feita por muitos.** Uma chave por vendedor funciona porque cada vendedor
  pergunta de novo e de novo. Uma chave por texto de busca qualquer guarda quase só respostas que
  ninguém pede outra vez.
- **Caro o bastante para valer um segundo sistema.** O Redis é mais um servidor para rodar, vigiar e
  reiniciar. Economizar 3,5 milissegundos numa página que ninguém espera não compensa isso.
- **Pode estar um pouco velho.** Todo o resto desta aula decorre deste item.
