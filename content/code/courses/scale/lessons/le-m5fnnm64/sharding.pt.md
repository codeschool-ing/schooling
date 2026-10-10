---
title: Sharding, os dados em vários servidores
version: 1
---

**O sharding divide as linhas dos dados entre vários bancos independentes**, cada um com uma parte e
nenhum com tudo. Cada banco é um **shard**. Diferente de uma réplica, um shard não é uma cópia: um
ingresso mora em exatamente um shard, e os outros nunca ouviram falar dele. Diferente de uma
partição, os pedaços estão em servidores diferentes, então as escritas, o armazenamento e a memória
deles se somam.

É isso que faz dele a resposta para o problema que os outros dois não resolvem. **As escritas
escalam na horizontal**: dois shards aceitam o dobro de vendas, porque cada venda vai para um deles.
O preço é que **alguma coisa precisa saber qual shard tem qual linha**, e essa coisa costuma ser o
seu programa.

## A chave de shard

Todo sistema com sharding escolhe uma **chave de shard**, o valor que decide onde uma linha mora.
Para a bilheteria, a natural é o show: todos os ingressos de um show num shard. Essa escolha torna
três coisas verdadeiras de uma vez:

- **Uma venda toca um shard.** Vender um ingresso do show 42 trava a linha do show 42 e insere o
  ingresso do show 42, os dois no mesmo servidor, numa transação comum.
- **Uma pergunta sobre um show pergunta a um shard**, e recebe uma resposta completa.
- **Uma pergunta sobre muitos shows pergunta a todos os shards**, e o programa precisa combinar as
  respostas. A seção 10 trata disso.

Uma chave ruim é uma que a maioria das consultas não carrega, então toda consulta vai para todo
shard; ou uma com poucos valores que levam a maior parte do tráfego, então um shard fica ocupado e
os outros parados. O show quente da aula 1 é exatamente esse segundo caso: fazer sharding por show
põe toda venda do show popular no mesmo shard, e **o sharding não consegue dividir uma chave
quente**, porque a chave é a unidade pela qual ele divide.

## Dois shards no laboratório

Mais dois servidores PostgreSQL, cada um com uma tabela `tickets` vazia, num arquivo do Compose só
deles, para não se misturarem com a bilheteria:

```sql
-- shard.sql
CREATE TABLE tickets (
  event_id int NOT NULL,
  seat     int NOT NULL,
  PRIMARY KEY (event_id, seat)
);
```

```yaml
# shards.yaml
name: shards

x-shard: &shard
  image: postgres:16.15
  environment:
    POSTGRES_USER: tickets
    POSTGRES_PASSWORD: tickets
    POSTGRES_DB: tickets
  volumes:
    - ./shard.sql:/docker-entrypoint-initdb.d/shard.sql:ro
  healthcheck:
    test: ["CMD", "pg_isready", "-U", "tickets"]
    interval: 2s
    retries: 15

services:
  shard0: *shard
  shard1: *shard

  router:
    build: .
    profiles: [run]
    volumes:
      - ./shards.py:/srv/shards.py:ro
    environment:
      SHARDS: >-
        postgresql://tickets:tickets@shard0/tickets
        postgresql://tickets:tickets@shard1/tickets
    command: ["python", "shards.py"]
    depends_on:
      shard0:
        condition: service_healthy
      shard1:
        condition: service_healthy
```

`x-shard` é uma **âncora do YAML**: o bloco é escrito uma vez sob um nome que o Compose ignora, e
`*shard` o repete nos dois serviços. O `router` roda um programa Python com a imagem da bilheteria,
porque essa imagem já tem o `psycopg`; a linha `profiles` impede que ele suba junto com os shards,
então ele só roda quando chamado.

E o roteador em si:

```schooling-example
{"language": "python", "file": "shards.py", "parts": [{"code": "# shards.py\n\"\"\"Sell tickets on two shards, then ask a question that needs both.\"\"\"\nimport os\n\nimport psycopg\n\nSHARDS = [psycopg.connect(url, autocommit=True) for url in os.environ[\"SHARDS\"].split()]", "note": "Uma conexão por shard, numa ordem fixa. A ordem faz parte do desenho: o shard 0 precisa ser sempre o mesmo banco, ou um ingresso é procurado onde nunca foi gravado."}, {"code": "\n\ndef shard_for(event_id):\n    return SHARDS[event_id % len(SHARDS)]", "note": "**O roteador**, inteiro. O id do show é a **chave de shard**: shows pares moram no shard 0, ímpares no shard 1. Toda parte do programa que toca um ingresso precisa passar por esta função."}, {"code": "\n\nfor event_id in range(1, 101):\n    with shard_for(event_id).transaction():\n        for seat in range(1, event_id + 1):\n            shard_for(event_id).execute(\n                \"INSERT INTO tickets (event_id, seat) VALUES (%s, %s)\", (event_id, seat))", "note": "O show *n* vende *n* ingressos, então os shows têm tamanhos diferentes de propósito. Os ingressos de cada show são gravados numa transação, num shard, que é o caso que o sharding trata bem."}, {"code": "\nfor number, shard in enumerate(SHARDS):\n    count, = shard.execute(\"SELECT count(*) FROM tickets\").fetchone()\n    print(f\"shard {number}: {count} tickets\")\n\nprint(\"show 42:\", shard_for(42).execute(\n    \"SELECT count(*) FROM tickets WHERE event_id = 42\").fetchone()[0], \"tickets, from one shard\")", "note": "Como os ingressos se distribuíram, e uma pergunta sobre um show, que o roteador manda para um shard."}, {"code": "\ntop = []\nfor shard in SHARDS:\n    top += shard.execute(\n        \"SELECT event_id, count(*) FROM tickets GROUP BY event_id ORDER BY 2 DESC LIMIT 3\").fetchall()\nprint(\"top three, from every shard:\", sorted(top, key=lambda row: -row[1])[:3])", "note": "Uma pergunta sobre **todos** os shows não pode ser roteada: cada shard é perguntado sobre o seu próprio top três e o programa junta as seis linhas. A seção 10 trata do que isso custa."}]}
```

Suba os shards, rode o roteador uma vez, e remova tudo depois com
`docker compose -f shards.yaml down`. O progresso do próprio Compose vai para a saída de erro, que
o `2>/dev/null` esconde, para que só a resposta do programa seja impressa:

```
ana@lab:~/tickets$ docker compose -f shards.yaml up -d
 Network shards_default Creating 
 Network shards_default Creating 
 Network shards_default Created 
 Network shards_default Created 
 Container shards-shard0-1 Creating 
 Container shards-shard1-1 Creating 
 Container shards-shard0-1 Created 
 Container shards-shard1-1 Created 
 Container shards-shard1-1 Starting 
 Container shards-shard0-1 Starting 
 Container shards-shard1-1 Started 
 Container shards-shard0-1 Started 
ana@lab:~/tickets$ docker compose -f shards.yaml run --rm router 2>/dev/null
shard 0: 2550 tickets
shard 1: 2500 tickets
show 42: 42 tickets, from one shard
top three, from every shard: [(100, 100), (99, 99), (98, 98)]
```

**O shard 0 tem 2550 ingressos e o shard 1 tem 2500**: os shows pares, 2 + 4 + … + 100, e os
ímpares, 1 + 3 + … + 99. O show 42 foi respondido por um shard. O top três precisou dos dois: cada
shard devolveu o próprio top três, e o programa ficou com os três melhores das seis linhas.

Repare no que mudou no programa em comparação com a bilheteria. **Toda consulta agora começa
escolhendo uma conexão**, e toda consulta que não consegue escolher precisa perguntar a todas. Esse
é o custo permanente do sharding, e é por isso que ele vem por último nesta aula.
