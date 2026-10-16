---
title: Mandando as leituras para a réplica
version: 1
---

Uma réplica que ninguém lê é só um estepe. Para tirar carga do primário, **o programa precisa
decidir, para cada consulta, para qual servidor mandá-la**. O banco não faz isso por você: uma
conexão vai para um servidor, e esse servidor responde.

A bilheteria tem uma leitura e uma escrita, e a regra é a óbvia: a página de um show vai para a
réplica, uma venda vai para o primário. Aqui está o `app.py` com essa mudança; as notas marcam os
três lugares novos, e todo o resto é o programa da aula 1:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, as small as it can be.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nHOST = socket.gethostname()\nlocal = threading.local()", "note": "Dois endereços agora: `PRIMARY`, para onde vai toda escrita, e `REPLICA`, para onde as leituras podem ir. Sem `REPLICA_URL` os dois são o mesmo banco, e o programa se comporta exatamente como na aula 1."}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.__dict__.setdefault(\"conns\", {})\n    if dsn not in conns:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True)\n    return conns[dsn]", "note": "Cada thread mantém uma conexão por banco que já usou. `db()` sem argumento é o primário, como antes."}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]"}, {"code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)"}, {"code": "\n    def do_GET(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"healthz\"]:\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            row = db(REPLICA).execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})", "note": "**A única linha mudada nos caminhos dos pedidos**: ler um show pergunta à réplica. Comprar um ingresso continua usando `db()`, o primário, porque uma réplica recusa escritas."}, {"code": "\n    def do_POST(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})"}, {"code": "\n    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()"}]}
```

O `compose.yaml` já passa `REPLICA_URL`, então reconstruir e reiniciar o `app` é tudo o que falta,
e `docker compose up -d --build` faz as duas coisas. Para ver as leituras chegarem, o PostgreSQL
conta as transações confirmadas por banco em `pg_stat_database`. A contagem da réplica, depois cinco
segundos de leituras, depois a contagem de novo:

```
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'"
3
ana@lab:~/tickets$ python3 load.py -c 4 -d 5 http://localhost:8080/events/1
requests  9655 in 5.0 s = 1929.8 per second
latency   p50 1.9 ms  p95 3.4 ms  p99 4.6 ms  max 38.7 ms
status    200: 9655
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'"
8027
```

De 3 para 8027: as leituras foram para a réplica, e o primário ficou sozinho com as vendas. O
contador é atualizado em lotes e não a cada transação, então ele fica um pouco atrás dos 9655
pedidos.

## Quais leituras podem ir para lá

Toda leitura mandada a uma réplica é uma leitura que pode ver o passado, e a seção 05 mede quanto.
Então a pergunta útil sobre cada consulta é **o que acontece se a resposta tiver um segundo de
idade**:

- **A página de um show**: "999 999 lugares restantes" com um segundo de atraso não machuca
  ninguém. É o grosso do tráfego e o candidato natural às réplicas.
- **Relatórios e painéis**: vendas por dia, os shows mais procurados. São consultas longas que
  disputariam o primário com as vendas, e ninguém percebe um número com um segundo de idade.
- **O ingresso do próprio comprador, logo depois de comprar**: "seu ingresso não existe" é uma
  ligação para o suporte. Essa leitura precisa ver a escrita que acabou de acontecer.
- **Qualquer coisa de que uma escrita dependa**: verificar que um lugar está livre antes de vendê-lo
  precisa perguntar ao primário, na mesma transação da venda, ou dois compradores levam o mesmo
  lugar.

**Uma leitura que decide uma escrita vai para o primário.** Só essa regra já evita os bugs que as
pessoas culpam as réplicas de causar.

## Quantas réplicas

Cada réplica serve tantas leituras quanto o primário serviria, então em princípio as leituras
escalam na horizontal como as cópias da bilheteria escalaram na aula 1. Dois custos crescem com o
número. O primário manda o log inteiro para cada réplica, então cada uma acrescenta rede e um
pouco de trabalho lá. E **toda réplica recebe toda escrita**: uma réplica não reduz o trabalho de
aplicar escritas, ela o repete. Um sistema cujo problema são as escritas não ganha nada com
réplicas, e é por isso que existem as seções 09 a 11.
