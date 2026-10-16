---
title: Instrumentando a bilheteria
version: 1
---

**Instrumentar** um programa é acrescentar o código que registra os sinais dele. A maior parte
fica num lugar só, o código por onde todo pedido passa, e é por isso que dá muito menos trabalho do
que parece.

A biblioteca é a `prometheus_client`, o cliente do próprio Prometheus para Python. Ela guarda cada
métrica na memória do programa e, quando pedida, imprime todas num formato de texto que o
Prometheus lê. Toda linguagem tem um equivalente, e a aula 8 mostra uma biblioteca que funciona do
mesmo jeito em todas.

Aqui está o `app.py` inteiro como fica desta aula em diante. As rotas e o banco são os da aula 2; o
que é novo está nas notas:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, now saying what it does.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nimport time\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\nfrom prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,\n                               disable_created_metrics, generate_latest)\n\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nHOST = socket.gethostname()\nlocal = threading.local()\ndisable_created_metrics()", "note": "Duas importações novas: `time`, para medir cada pedido, e `prometheus_client`, a biblioteca que guarda métricas na memória e as imprime no formato que o Prometheus lê. `disable_created_metrics()` desliga uma série extra por métrica que esta aula não usa."}, {"code": "\nREQUESTS = Counter(\"tickets_requests_total\", \"Requests answered\",\n                   [\"method\", \"route\", \"status\"])\nLATENCY = Histogram(\"tickets_request_seconds\", \"Time to answer a request\",\n                    [\"method\", \"route\"],\n                    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))\nIN_FLIGHT = Gauge(\"tickets_in_flight\", \"Requests being answered now\")", "note": "**As três métricas.** Um **contador** de pedidos respondidos, por método, rota e status; um **histograma** de quanto cada um levou, separado em faixas de 5 ms a 5 s; e um **medidor** de pedidos em andamento. Os rótulos são o modelo da rota, `/events/{id}`, nunca o caminho em si: a seção 09 explica por quê."}, {"code": "\n\ndef log(level, message, **fields):\n    record = {\"time\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n              \"level\": level, \"message\": message, \"host\": HOST, **fields}\n    print(json.dumps(record), flush=True)", "note": "**Uma linha de log é um objeto JSON** na saída padrão: uma hora em UTC, um nível, uma mensagem, o nome da cópia e os campos que quem chama acrescentar. O Docker recolhe a saída padrão, então o `docker compose logs` as lê."}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.__dict__.setdefault(\"conns\", {})\n    if dsn not in conns:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True)\n    return conns[dsn]\n\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]\n"}, {"code": "\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body, content_type=\"application/json\"):\n        data = body if isinstance(body, bytes) else json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n        self.status = status\n", "note": "`reply` agora aceita bytes além de JSON, para a página de métricas, e lembra o status que mandou."}, {"code": "    def do_GET(self):\n        self.observe(\"GET\", self.get)\n\n    def do_POST(self):\n        self.observe(\"POST\", self.post)\n", "note": "Os dois métodos passam por `observe`, que faz a medição."}, {"code": "    def observe(self, method, handler):\n        started = time.monotonic()\n        self.route, self.status = \"unknown\", 500\n        IN_FLIGHT.inc()\n        try:\n            handler()\n        except Exception as error:\n            log(\"error\", \"request failed\", method=method, route=self.route,\n                error=f\"{type(error).__name__}: {error}\")\n            self.reply(500, {\"error\": \"internal error\"})\n        finally:\n            IN_FLIGHT.dec()\n            seconds = time.monotonic() - started\n            if self.route != \"/metrics\":\n                REQUESTS.labels(method, self.route, str(self.status)).inc()\n                LATENCY.labels(method, self.route).observe(seconds)\n                log(\"info\", \"request\", method=method, route=self.route,\n                    status=self.status, ms=round(seconds * 1000, 1))\n", "note": "**Todo pedido é medido num lugar só.** O relógio começa, o medidor sobe, o tratador roda. Uma exceção vira um 500 e uma linha de log de erro com o tipo e a mensagem, em vez de uma conexão derrubada. Aconteça o que acontecer, o medidor desce e, a não ser na própria página de métricas, o pedido é contado, cronometrado e registrado."}, {"code": "    def get(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"metrics\"]:\n            self.route = \"/metrics\"\n            return self.reply(200, generate_latest(), CONTENT_TYPE_LATEST)\n        if parts == [\"healthz\"]:\n            self.route = \"/healthz\"\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            self.route = \"/events/{id}\"\n            row = db(REPLICA).execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "As leituras da aula 2, com dois acréscimos: `/metrics`, a página que o Prometheus busca, e uma `route` definida assim que o tratador sabe qual é."}, {"code": "    def post(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            self.route = \"/events/{id}/tickets\"\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "A venda, sem mudança além de nomear a rota."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    log(\"info\", \"listening\", port=8000)\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()", "note": "Uma primeira linha de log diz que a cópia está escutando, para a subida dela aparecer nos logs."}]}
```

Mais dois arquivos mudam. O `requirements.txt` ganha a biblioteca:

```
# requirements.txt
psycopg[binary]==3.2.10
prometheus-client==0.26.0
```

E o `compose.yaml` ganha um quinto serviço, o próprio Prometheus, que recolhe as métricas e responde
perguntas sobre elas. Ele é publicado na porta 9090 do laboratório, para o navegador se você quiser:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16.15
    environment:
      POSTGRES_USER: tickets
      POSTGRES_PASSWORD: tickets
      POSTGRES_DB: tickets
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro
      - ./replication.sh:/docker-entrypoint-initdb.d/2-replication.sh:ro
    networks:
      default:
      replication:
        aliases: [primary]
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  replica:
    image: postgres:16.15
    user: postgres
    environment:
      PGPASSWORD: replicator
      PGDATA: /var/lib/postgresql/replica
      DELAY: ${DELAY:-0}
    command:
      - bash
      - -c
      - |
        until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    networks:
      - default
      - replication
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15
    depends_on:
      db:
        condition: service_healthy

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
      REPLICA_URL: postgresql://tickets:tickets@replica/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy

  prometheus:
    image: prom/prometheus:v3.15.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "127.0.0.1:9090:9090"

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app

networks:
  replication:
```

## Três tipos de métrica

- **Um contador** (*counter*) só sobe, e volta a zero quando o programa reinicia. Pedidos
  respondidos, erros, ingressos vendidos. O valor dele sozinho diz pouco; **a velocidade com que ele
  cresce é a informação**, e a seção 06 pede exatamente isso.
- **Um medidor** (*gauge*) sobe e desce, e o valor de agora é a informação: pedidos em andamento,
  conexões abertas, itens numa fila.
- **Um histograma** conta observações em **faixas** (*buckets*) por tamanho: quantos pedidos levaram
  até 5 ms, até 10 ms, até 25 ms, e assim por diante. É como uma distribuição de latências é guardada
  como um punhado de contadores, e a seção 07 trata de lê-lo.

Cada métrica leva **rótulos** (*labels*), aqui `method`, `route` e `status`, e cada combinação de
valores de rótulos é um contador separado, chamado **série**. É isso que deixa uma pergunta pedir
os erros de uma rota só, e é também o único jeito de as métricas ficarem caras, que é a seção 09.

O coletor padrão da biblioteca acrescenta de graça algumas métricas sobre o processo, entre elas
`process_cpu_seconds_total`, o tempo de processador que o programa usou desde que começou.
