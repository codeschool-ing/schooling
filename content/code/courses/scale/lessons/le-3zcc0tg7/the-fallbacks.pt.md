---
title: Os recuos no código
version: 1
---

Aqui está o `app.py` inteiro desta aula em diante. As leituras ganham os seus recuos, e as vendas uma
verificação antes de cobrar:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, now degrading instead of failing.\"\"\"\nimport hashlib\nimport json\nimport math\nimport os\nimport random\nimport socket\nimport threading\nimport time\nimport urllib.error\nimport urllib.request\nimport uuid\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\nimport redis\nfrom opentelemetry import propagate, trace\nfrom prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,\n                               disable_created_metrics, generate_latest)\n\nimport guards\nimport telemetry\n\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nPAYMENTS = os.environ.get(\"PAYMENTS_URL\", \"http://payments:8001\")\nLIMIT = guards.RateLimit(os.environ.get(\"REDIS_URL\", \"redis://redis\"),\n                         rate=float(os.environ.get(\"BUYER_RATE\", \"2\")),\n                         burst=int(os.environ.get(\"BUYER_BURST\", \"5\")))\nSHED = guards.Shed(int(os.environ.get(\"MAX_IN_FLIGHT\", \"32\")))\nBREAKER = guards.Breaker(failures=5, cooldown=10)", "note": "A bilheteria da aula 10, sem mudanças até aqui."}, {"code": "LAST_SEEN = {}  # event id -> (row, when): the last answer read, for when no database answers", "note": "**A última resposta lida para cada evento**, guardada na memória desta cópia, para quando nenhum banco responde."}, {"code": "ATTEMPTS = int(os.environ.get(\"CHARGE_ATTEMPTS\", \"3\"))\nSEND_KEYS = os.environ.get(\"IDEMPOTENCY_KEYS\", \"on\") == \"on\"\nHOST = socket.gethostname()\nlocal = threading.local()\ntracer = telemetry.setup(\"tickets\")\ndisable_created_metrics()\n\nREQUESTS = Counter(\"tickets_requests_total\", \"Requests answered\",\n                   [\"method\", \"route\", \"status\"])\nLATENCY = Histogram(\"tickets_request_seconds\", \"Time to answer a request\",\n                    [\"method\", \"route\"],\n                    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))\nIN_FLIGHT = Gauge(\"tickets_in_flight\", \"Requests being answered now\")\nBREAKER_OPEN = Gauge(\"tickets_breaker_open\", \"1 while the breaker to payments is not closed\")\nBREAKER_OPEN.set_function(lambda: BREAKER.state() != \"closed\")\n\n\ndef log(level, message, **fields):\n    span = trace.get_current_span().get_span_context()\n    if span.is_valid:\n        fields[\"trace_id\"] = format(span.trace_id, \"032x\")\n    record = {\"time\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n              \"level\": level, \"message\": message, \"host\": HOST, **fields}\n    print(json.dumps(record), flush=True)"}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.slot\n    if dsn not in conns or conns[dsn].closed:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True, connect_timeout=1)\n    return conns[dsn]", "note": "Uma conexão que foi fechada é trocada, e uma nova desiste depois de **um segundo** em vez de esperar o sistema operacional."}, {"code": "\n\ndef read_event(event_id):\n    \"\"\"The replica, then the primary, then the last answer this copy saw.\n    Returns the row, where it came from, and how old it is in seconds.\"\"\"\n    for dsn, source in ((REPLICA, \"replica\"), (PRIMARY, \"primary\")):\n        try:\n            with tracer.start_as_current_span(f\"SELECT events ({source})\"):\n                row = db(dsn).execute(\n                    \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                    (event_id,)).fetchone()\n        except psycopg.OperationalError as error:\n            local.slot.pop(dsn, None)\n            log(\"warning\", \"read fell back\", source=source, error=str(error).strip())\n            continue\n        LAST_SEEN[event_id] = (row, time.monotonic())\n        return row, source, 0\n    if event_id in LAST_SEEN:\n        row, at = LAST_SEEN[event_id]\n        return row, \"memory\", round(time.monotonic() - at)\n    raise Unavailable()", "note": "**Três lugares de onde ler, em ordem.** A réplica; se falhar, o primário; se esse falhar também, a última resposta que esta cópia viu, com a idade dela. Uma conexão que falhou sai da vaga, para o próximo pedido abrir uma nova, e todo recuo vai para o log."}, {"code": "\n\nclass Unavailable(Exception):\n    pass"}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]\n\n\ndef charge(event_id):\n    \"\"\"Charge one sale, trying up to ATTEMPTS times. The key is made once, so\n    every attempt is the same charge as far as payments is concerned.\"\"\"\n    key = str(uuid.uuid4()) if SEND_KEYS else None\n    for attempt in range(1, ATTEMPTS + 1):\n        try:\n            return charge_once(event_id, key, attempt)\n        except OSError as error:\n            if attempt == ATTEMPTS or not retryable(error):\n                raise\n            wait = backoff(attempt, error)\n            log(\"warning\", \"charge retry\", attempt=attempt, wait_ms=round(wait * 1000),\n                error=f\"{type(error).__name__}: {error}\")\n            time.sleep(wait)\n\n\ndef charge_once(event_id, key, attempt):\n    with tracer.start_as_current_span(\"charge\", kind=trace.SpanKind.CLIENT) as span:\n        span.set_attribute(\"attempt\", attempt)\n        headers = {\"Content-Type\": \"application/json\"}\n        if key:\n            headers[\"Idempotency-Key\"] = key\n        propagate.inject(headers)\n        body = json.dumps({\"event\": event_id, \"cents\": 18000}).encode()\n        request = urllib.request.Request(f\"{PAYMENTS}/charges\", data=body, headers=headers)\n        with urllib.request.urlopen(request, timeout=1) as answer:\n            return json.load(answer)\n\n\ndef retryable(error):\n    \"\"\"Network errors and timeouts, and the statuses that mean 'not now'.\n    Any other answer from payments would be the same answer next time.\"\"\"\n    if isinstance(error, urllib.error.HTTPError):\n        return error.code in (502, 503, 504)\n    return True\n\n\ndef backoff(attempt, error):\n    \"\"\"Retry-After if payments sent one; otherwise a random wait between zero\n    and an exponential ceiling: 200 ms, then 400 ms, never more than 2 s.\"\"\"\n    if isinstance(error, urllib.error.HTTPError) and error.headers.get(\"Retry-After\"):\n        return float(error.headers[\"Retry-After\"])\n    return random.uniform(0, min(2.0, 0.1 * 2 ** attempt))\n\n\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body, content_type=\"application/json\", wait=None):\n        data = body if isinstance(body, bytes) else json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        if wait is not None:\n            self.send_header(\"Retry-After\", str(max(1, math.ceil(wait))))\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n        self.status = status\n\n    def do_GET(self):\n        self.observe(\"GET\", self.get)\n\n    def do_POST(self):\n        self.observe(\"POST\", self.post)\n\n    def observe(self, method, handler):\n        started = time.monotonic()\n        self.route, self.status = \"unknown\", 500\n        IN_FLIGHT.inc()\n        context = propagate.extract(self.headers)\n        with tracer.start_as_current_span(method, context=context,\n                                          kind=trace.SpanKind.SERVER) as span:\n            try:\n                if self.path in (\"/metrics\", \"/healthz\"):\n                    handler()\n                elif (slot := SHED.enter()) is not None:\n                    local.slot = slot\n                    try:\n                        handler()\n                    finally:\n                        SHED.leave(slot)\n                else:\n                    self.route = \"shed\"\n                    self.reply(503, {\"error\": \"too busy\"}, wait=1)\n            except Exception as error:\n                span.record_exception(error)\n                log(\"error\", \"request failed\", method=method, route=self.route,\n                    error=f\"{type(error).__name__}: {error}\")\n                self.reply(500, {\"error\": \"internal error\"})\n            finally:\n                IN_FLIGHT.dec()\n                seconds = time.monotonic() - started\n                span.update_name(f\"{method} {self.route}\")\n                span.set_attribute(\"http.route\", self.route)\n                span.set_attribute(\"http.response.status_code\", self.status)\n                if self.route != \"/metrics\":\n                    REQUESTS.labels(method, self.route, str(self.status)).inc()\n                    LATENCY.labels(method, self.route).observe(seconds)\n                    log(\"info\", \"request\", method=method, route=self.route,\n                        status=self.status, ms=round(seconds * 1000, 1))\n"}, {"code": "    def get(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"metrics\"]:\n            self.route = \"/metrics\"\n            return self.reply(200, generate_latest(), CONTENT_TYPE_LATEST)\n        if parts == [\"healthz\"]:\n            self.route = \"/healthz\"\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            self.route = \"/events/{id}\"\n            try:\n                row, source, age = read_event(int(parts[1]))\n            except Unavailable:\n                return self.reply(503, {\"error\": \"event unavailable\"}, wait=5)\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            body = {\"name\": row[0], \"left\": row[1], \"host\": HOST, \"source\": source}\n            if age:\n                body[\"seconds_old\"] = age\n            return self.reply(200, body)\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "**Uma leitura diz de onde veio a resposta**, e quantos segundos ela tem quando veio da memória. Sem nada de onde responder, é um `503` que pede a quem chama para voltar em cinco segundos."}, {"code": "    def post(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            self.route = \"/events/{id}/tickets\"\n            event_id = int(parts[1])\n            trace.get_current_span().set_attribute(\"event.id\", event_id)\n            try:\n                wait = LIMIT.take(self.headers.get(\"X-Buyer\", \"anonymous\"))\n            except redis.RedisError as error:\n                log(\"warning\", \"rate limit unavailable\", error=str(error))\n                wait = 0\n            if wait:\n                return self.reply(429, {\"error\": \"too many attempts\"}, wait=wait)"}, {"code": "            try:\n                conn = db()\n                left = conn.execute(\"SELECT capacity - sold FROM events WHERE id = %s\",\n                                    (event_id,)).fetchone()\n            except psycopg.OperationalError as error:\n                local.slot.pop(PRIMARY, None)\n                log(\"warning\", \"sales paused\", error=str(error).strip())\n                return self.reply(503, {\"error\": \"sales paused\"}, wait=5)\n            if left is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            if left[0] <= 0:\n                return self.reply(409, {\"error\": \"sold out\"})", "note": "**Antes de cobrar alguém, a venda pergunta ao primário quantos lugares sobram.** Sem primário: `503`, vendas pausadas, ninguém cobrado. Sem lugares: `409`, ninguém cobrado. A seção 07 explica por que essa verificação existe."}, {"code": "            try:\n                BREAKER.call(charge, event_id)\n            except guards.Open:\n                return self.reply(503, {\"error\": \"payments unavailable\"}, wait=BREAKER.cooldown)\n            except OSError as error:\n                log(\"warning\", \"charge failed\", error=f\"{type(error).__name__}: {error}\")\n                return self.reply(502, {\"error\": \"payment failed\"})\n            with conn.transaction():\n                with tracer.start_as_current_span(\"UPDATE events\"):\n                    row = conn.execute(\n                        \"UPDATE events SET sold = sold + 1\"\n                        \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                        (event_id,)).fetchone()\n                if row is None:\n                    log(\"error\", \"charged but sold out\", event=event_id)\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                with tracer.start_as_current_span(\"sign\"):\n                    code = sign(event_id, seat)\n                with tracer.start_as_current_span(\"INSERT tickets\"):\n                    conn.execute(\n                        \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                        (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "O resto é o da aula 10, com uma linha nova: se o último lugar foi para outra pessoa entre a verificação e o `UPDATE`, a venda registra um erro, porque este comprador foi cobrado por nada."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    log(\"info\", \"listening\", port=8000)\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()"}]}
```

O `compose.yaml` muda num lugar. Desde a aula 2 a réplica copiava o primário com `pg_basebackup`
toda vez que subia, o que funciona num contêiner vazio e fica em laço para sempre num que já tem os
dados, então uma réplica que foi parada nunca mais conseguia subir. Agora ela só copia quando não tem
nada:

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
        if [ ! -s "$$PGDATA/PG_VERSION" ]; then
          until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        fi
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
      OTEL_TRACES_SAMPLER: ${SAMPLER:-parentbased_always_on}
      OTEL_TRACES_SAMPLER_ARG: ${SAMPLER_ARG:-1}
      MAX_IN_FLIGHT: ${MAX_IN_FLIGHT:-32}
      BUYER_RATE: ${BUYER_RATE:-2}
      BUYER_BURST: ${BUYER_BURST:-5}
      CHARGE_ATTEMPTS: ${CHARGE_ATTEMPTS:-3}
      IDEMPOTENCY_KEYS: ${IDEMPOTENCY_KEYS:-on}
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy
      redis:
        condition: service_started

  payments:
    build: .
    command: ["python", "payments.py"]
    environment:
      PAYMENTS_DELAY_MS: ${PAYMENTS_DELAY_MS:-20}
      PAYMENTS_FAIL_PERCENT: ${PAYMENTS_FAIL_PERCENT:-0}
    ports:
      - "127.0.0.1:8001:8001"

  redis:
    image: redis:7.4.11

  collector:
    image: otel/opentelemetry-collector:0.162.0
    volumes:
      - ./collector.yaml:/etc/otelcol/config.yaml:ro

  jaeger:
    image: jaegertracing/jaeger:2.22.0
    ports:
      - "127.0.0.1:16686:16686"

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

Reconstrua e suba:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-app Building 
 Image tickets-payments Building 
 Image tickets-app Built 
 Image tickets-payments Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_replication Creating 
 Network tickets_replication Creating 
 Network tickets_default Creating 
 Network tickets_replication Created 
 Network tickets_replication Created 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-redis-1 Creating 
 Container tickets-db-1 Creating 
 Container tickets-collector-1 Creating 
 Container tickets-prometheus-1 Creating 
 Container tickets-jaeger-1 Creating 
 Container tickets-payments-1 Creating 
 Container tickets-collector-1 Created 
 Container tickets-prometheus-1 Created 
 Container tickets-payments-1 Created 
 Container tickets-jaeger-1 Created 
 Container tickets-redis-1 Created 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-payments-1 Starting 
 Container tickets-prometheus-1 Starting 
 Container tickets-redis-1 Starting 
 Container tickets-collector-1 Starting 
 Container tickets-db-1 Starting 
 Container tickets-jaeger-1 Starting 
 Container tickets-payments-1 Started 
 Container tickets-prometheus-1 Started 
 Container tickets-redis-1 Started 
 Container tickets-collector-1 Started 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-jaeger-1 Started 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE      STATUS
app          Up 10 seconds
collector    Up 16 seconds
db           Up 15 seconds (healthy)
jaeger       Up 15 seconds
lb           Up 10 seconds
payments     Up 16 seconds
prometheus   Up 16 seconds
redis        Up 16 seconds
replica      Up 13 seconds (healthy)
```
