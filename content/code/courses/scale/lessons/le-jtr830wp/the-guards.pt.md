---
title: Três guardas no código
version: 1
---

Cada guarda desta aula responde uma pergunta diferente:

- **um limite de taxa** (*rate limit*): com que frequência *quem chama* pode pedir? Seção 04.
- **descarte de carga** (*load shedding*): quanto trabalho a bilheteria aceita *ao mesmo tempo*, de
  todo mundo junto? Seção 05.
- **um disjuntor** (*circuit breaker*): a bilheteria ainda deve chamar *uma dependência* que não para
  de falhar? Seções 08 e 09.

As três moram num arquivo novo. Salve-o como `guards.py`:

```schooling-example
{"language": "python", "file": "guards.py", "parts": [{"code": "# guards.py\n\"\"\"What stands between the box office and more work than it can do.\"\"\"\nimport queue\nimport threading\nimport time\n", "note": "Três guardas num arquivo, cada uma com poucas linhas. A bilheteria usa as três; as seções 04 a 09 as pegam uma de cada vez."}, {"code": "import redis"}, {"code": "\n# A token bucket per key, kept in Redis so that every copy shares it.\n# The script runs inside Redis, all at once, so two copies can never\n# both take the last token. It reads Redis's own clock, not the caller's.\nBUCKET = \"\"\"\nlocal rate, burst = tonumber(ARGV[1]), tonumber(ARGV[2])\nlocal t = redis.call('TIME')\nlocal now = t[1] * 1000 + t[2] / 1000\nlocal b = redis.call('HMGET', KEYS[1], 'tokens', 'at')\nlocal tokens, at = tonumber(b[1]) or burst, tonumber(b[2]) or now\ntokens = math.min(burst, tokens + (now - at) * rate / 1000)\nlocal allowed = 0\nif tokens >= 1 then\n  tokens = tokens - 1\n  allowed = 1\nend\nredis.call('HSET', KEYS[1], 'tokens', tokens, 'at', now)\nredis.call('PEXPIRE', KEYS[1], math.ceil(burst / rate * 1000))\nreturn {allowed, tostring(tokens)}\n\"\"\"", "note": "**Um balde de fichas, escrito em Lua e rodado dentro do Redis.** As fichas pingam a `rate` por segundo até `burst`; um pedido pega uma, ou é recusado quando não sobra nenhuma. O Redis roda um script inteiro, sem nada no meio, então duas cópias da bilheteria pedindo no mesmo instante não conseguem as duas pegar a última ficha. A hora vem do `TIME` do Redis, então os relógios das cópias não precisam concordar."}, {"code": "\n\nclass RateLimit:\n    def __init__(self, url, rate, burst):\n        self.redis = redis.Redis.from_url(url)\n        self.script = self.redis.register_script(BUCKET)\n        self.rate, self.burst = rate, burst\n\n    def take(self, key):\n        \"\"\"Returns 0 if the request may go ahead, or the seconds to wait.\"\"\"\n        allowed, tokens = self.script(keys=[f\"bucket:{key}\"],\n                                      args=[self.rate, self.burst])\n        if allowed:\n            return 0\n        return (1 - float(tokens)) / self.rate", "note": "O `take` responde quanto quem chamou deve esperar: zero para seguir, ou o tempo até a próxima ficha, que vira o cabeçalho `Retry-After`. A chave no Redis é por comprador, e o Redis a apaga quando o balde já estaria cheio de novo de qualquer jeito."}, {"code": "\n\nclass Shed:\n    \"\"\"At most `limit` requests at once. Each one holds a slot, and a slot\n    keeps its own database connections, so the slots bound the connections\n    too. A request that finds no free slot is refused, not queued.\"\"\"\n\n    def __init__(self, limit):\n        self.free = queue.LifoQueue()\n        for _ in range(limit):\n            self.free.put({})\n\n    def enter(self):\n        try:\n            return self.free.get_nowait()\n        except queue.Empty:\n            return None\n\n    def leave(self, slot):\n        self.free.put(slot)", "note": "**Descarte de carga.** Um número fixo de vagas, cada uma com as próprias conexões ao banco. Um pedido pega uma vaga livre ou é recusado na hora. A `LifoQueue` entrega a vaga devolvida por último, cujas conexões estão mais quentes."}, {"code": "\n\nclass Open(Exception):\n    pass"}, {"code": "\n\nclass Breaker:\n    \"\"\"Closed: calls go through. After `failures` failures in a row it opens,\n    and calls fail at once for `cooldown` seconds. Then one call is let\n    through (half-open): if it works the breaker closes, if not it opens again.\"\"\"\n\n    def __init__(self, failures, cooldown):\n        self.failures, self.cooldown = failures, cooldown\n        self.lock = threading.Lock()\n        self.failed, self.opened, self.trying = 0, None, False\n", "note": "**O disjuntor** (*circuit breaker*) guarda três fatos: quantas chamadas falharam seguidas, quando ele abriu, e se há uma chamada de teste em andamento."}, {"code": "    def state(self):\n        if self.opened is None:\n            return \"closed\"\n        if time.monotonic() - self.opened < self.cooldown:\n            return \"open\"\n        return \"half-open\"\n", "note": "O estado dele é calculado a partir deles em vez de guardado: aberto por `cooldown` segundos depois de abrir, e então meio aberto."}, {"code": "    def call(self, function, *args):\n        with self.lock:\n            state = self.state()\n            if state == \"open\" or (state == \"half-open\" and self.trying):\n                raise Open()\n            self.trying = state == \"half-open\"\n        try:\n            result = function(*args)\n        except Exception:\n            with self.lock:\n                self.failed += 1\n                self.trying = False\n                if self.opened is not None or self.failed >= self.failures:\n                    self.opened = time.monotonic()\n            raise\n        with self.lock:\n            self.failed, self.opened, self.trying = 0, None, False\n        return result", "note": "O `call` recusa na hora enquanto aberto, e deixa passar exatamente uma chamada quando meio aberto. Uma falha conta para abrir, ou reabre um disjuntor que estava testando; um sucesso o fecha e zera a contagem. A função roda fora da trava, então uma chamada lenta nunca bloqueia as decisões das outras."}]}
```

E a bilheteria as usa. Aqui está o `app.py` inteiro desta aula em diante, com notas sobre o que mudou
desde a aula 8:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, now guarded against overload.\"\"\"\nimport hashlib\nimport json\nimport math\nimport os\nimport socket\nimport threading\nimport time\nimport urllib.request\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\nimport redis\nfrom opentelemetry import propagate, trace\nfrom prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,\n                               disable_created_metrics, generate_latest)\n\nimport guards\nimport telemetry", "note": "Importações novas: `math` para arredondar uma espera para cima, o cliente do Redis e o `guards.py`."}, {"code": "\nPRIMARY = os.environ[\"DATABASE_URL\"]\nREPLICA = os.environ.get(\"REPLICA_URL\", PRIMARY)\nPAYMENTS = os.environ.get(\"PAYMENTS_URL\", \"http://payments:8001\")\nLIMIT = guards.RateLimit(os.environ.get(\"REDIS_URL\", \"redis://redis\"),\n                         rate=float(os.environ.get(\"BUYER_RATE\", \"2\")),\n                         burst=int(os.environ.get(\"BUYER_BURST\", \"5\")))\nSHED = guards.Shed(int(os.environ.get(\"MAX_IN_FLIGHT\", \"32\")))\nBREAKER = guards.Breaker(failures=5, cooldown=10)", "note": "**As três guardas, configuradas pelo ambiente.** Um comprador pode tentar duas compras por segundo, cinco de uma vez; no máximo 32 pedidos são atendidos ao mesmo tempo; cinco cobranças falhas seguidas abrem o disjuntor por dez segundos."}, {"code": "HOST = socket.gethostname()\nlocal = threading.local()\ntracer = telemetry.setup(\"tickets\")\ndisable_created_metrics()\n\nREQUESTS = Counter(\"tickets_requests_total\", \"Requests answered\",\n                   [\"method\", \"route\", \"status\"])\nLATENCY = Histogram(\"tickets_request_seconds\", \"Time to answer a request\",\n                    [\"method\", \"route\"],\n                    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))\nIN_FLIGHT = Gauge(\"tickets_in_flight\", \"Requests being answered now\")\nBREAKER_OPEN = Gauge(\"tickets_breaker_open\", \"1 while the breaker to payments is not closed\")\nBREAKER_OPEN.set_function(lambda: BREAKER.state() != \"closed\")", "note": "Mais um medidor: 1 enquanto o disjuntor está aberto ou meio aberto, para que um painel mostre quando a bilheteria parou de chamar o payments."}, {"code": "\n\ndef log(level, message, **fields):\n    span = trace.get_current_span().get_span_context()\n    if span.is_valid:\n        fields[\"trace_id\"] = format(span.trace_id, \"032x\")\n    record = {\"time\": datetime.now(timezone.utc).isoformat(timespec=\"milliseconds\"),\n              \"level\": level, \"message\": message, \"host\": HOST, **fields}\n    print(json.dumps(record), flush=True)"}, {"code": "\n\ndef db(dsn=PRIMARY):\n    conns = local.slot\n    if dsn not in conns:\n        conns[dsn] = psycopg.connect(dsn, autocommit=True)\n    return conns[dsn]", "note": "**As conexões agora pertencem à vaga**, não à thread. A seção 02 mostra por quê: uma thread por conexão, cada uma com a própria conexão ao banco, é um número que nada limita."}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]\n\n\ndef charge(event_id):\n    with tracer.start_as_current_span(\"charge\", kind=trace.SpanKind.CLIENT):\n        headers = {\"Content-Type\": \"application/json\"}\n        propagate.inject(headers)\n        body = json.dumps({\"event\": event_id, \"cents\": 18000}).encode()\n        request = urllib.request.Request(f\"{PAYMENTS}/charges\", data=body, headers=headers)\n        with urllib.request.urlopen(request, timeout=1) as answer:\n            return json.load(answer)\n", "note": "A chamada ao payments desiste depois de **um segundo** em vez de cinco."}, {"code": "\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body, content_type=\"application/json\", wait=None):\n        data = body if isinstance(body, bytes) else json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        if wait is not None:\n            self.send_header(\"Retry-After\", str(max(1, math.ceil(wait))))\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n        self.status = status\n", "note": "O `reply` agora pode mandar `Retry-After`: quantos segundos inteiros quem chamou deve esperar antes de tentar de novo."}, {"code": "    def do_GET(self):\n        self.observe(\"GET\", self.get)\n\n    def do_POST(self):\n        self.observe(\"POST\", self.post)\n\n    def observe(self, method, handler):\n        started = time.monotonic()\n        self.route, self.status = \"unknown\", 500\n        IN_FLIGHT.inc()\n        context = propagate.extract(self.headers)\n        with tracer.start_as_current_span(method, context=context,\n                                          kind=trace.SpanKind.SERVER) as span:\n            try:\n                if self.path in (\"/metrics\", \"/healthz\"):\n                    handler()\n                elif (slot := SHED.enter()) is not None:\n                    local.slot = slot\n                    try:\n                        handler()\n                    finally:\n                        SHED.leave(slot)\n                else:\n                    self.route = \"shed\"\n                    self.reply(503, {\"error\": \"too busy\"}, wait=1)\n            except Exception as error:\n                span.record_exception(error)\n                log(\"error\", \"request failed\", method=method, route=self.route,\n                    error=f\"{type(error).__name__}: {error}\")\n                self.reply(500, {\"error\": \"internal error\"})\n            finally:\n                IN_FLIGHT.dec()\n                seconds = time.monotonic() - started\n                span.update_name(f\"{method} {self.route}\")\n                span.set_attribute(\"http.route\", self.route)\n                span.set_attribute(\"http.response.status_code\", self.status)\n                if self.route != \"/metrics\":\n                    REQUESTS.labels(method, self.route, str(self.status)).inc()\n                    LATENCY.labels(method, self.route).observe(seconds)\n                    log(\"info\", \"request\", method=method, route=self.route,\n                        status=self.status, ms=round(seconds * 1000, 1))\n", "note": "**Todo pedido, menos os dois que o monitoramento usa, precisa achar uma vaga livre**, ou é respondido com `503` e `Retry-After: 1` na hora, sem tocar no banco. Uma recusa é contada e registrada como qualquer outra resposta, na rota `shed`."}, {"code": "    def get(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"metrics\"]:\n            self.route = \"/metrics\"\n            return self.reply(200, generate_latest(), CONTENT_TYPE_LATEST)\n        if parts == [\"healthz\"]:\n            self.route = \"/healthz\"\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            self.route = \"/events/{id}\"\n            with tracer.start_as_current_span(\"SELECT events\"):\n                row = db(REPLICA).execute(\n                    \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                    (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})\n"}, {"code": "    def post(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            self.route = \"/events/{id}/tickets\"\n            event_id = int(parts[1])\n            trace.get_current_span().set_attribute(\"event.id\", event_id)\n            try:\n                wait = LIMIT.take(self.headers.get(\"X-Buyer\", \"anonymous\"))\n            except redis.RedisError as error:\n                log(\"warning\", \"rate limit unavailable\", error=str(error))\n                wait = 0\n            if wait:\n                return self.reply(429, {\"error\": \"too many attempts\"}, wait=wait)\n            try:\n                BREAKER.call(charge, event_id)\n            except guards.Open:\n                return self.reply(503, {\"error\": \"payments unavailable\"}, wait=BREAKER.cooldown)\n            except OSError as error:\n                log(\"warning\", \"charge failed\", error=f\"{type(error).__name__}: {error}\")\n                return self.reply(502, {\"error\": \"payment failed\"})\n            conn = db()\n            with conn.transaction():\n                with tracer.start_as_current_span(\"UPDATE events\"):\n                    row = conn.execute(\n                        \"UPDATE events SET sold = sold + 1\"\n                        \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                        (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                with tracer.start_as_current_span(\"sign\"):\n                    code = sign(event_id, seat)\n                with tracer.start_as_current_span(\"INSERT tickets\"):\n                    conn.execute(\n                        \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                        (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})\n", "note": "**Uma venda passa por mais duas guardas antes de cobrar alguém.** O balde do comprador, pela chave do cabeçalho `X-Buyer`: se o Redis não puder responder, a venda segue e o log diz isso. Depois o disjuntor em volta da cobrança: aberto quer dizer `503` na hora, uma cobrança que falhou quer dizer `502`."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    log(\"info\", \"listening\", port=8000)\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()"}]}
```

O limite de taxa precisa de um lugar que toda cópia enxergue, e esse lugar é um servidor Redis, a
mesma imagem da aula 4. O cliente Python dele entra nos requisitos fixados:

```
# requirements.txt
psycopg[binary]==3.2.10
prometheus-client==0.26.0
opentelemetry-sdk==1.45.1
opentelemetry-exporter-otlp-proto-http==1.45.1
redis==7.4.0
```

A imagem agora também leva o `guards.py`:

```dockerfile
# Dockerfile
FROM python:3.12.15-slim
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py guards.py payments.py telemetry.py .
CMD ["python", "app.py"]
```

E o `compose.yaml` ganha o servidor Redis, os limites da bilheteria como variáveis com os seus
padrões, e o atraso do payments como variável, que a seção 07 aumenta:

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
      OTEL_TRACES_SAMPLER: ${SAMPLER:-parentbased_always_on}
      OTEL_TRACES_SAMPLER_ARG: ${SAMPLER_ARG:-1}
      MAX_IN_FLIGHT: ${MAX_IN_FLIGHT:-32}
      BUYER_RATE: ${BUYER_RATE:-2}
      BUYER_BURST: ${BUYER_BURST:-5}
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
 Image tickets-payments Building 
 Image tickets-app Building 
 Image tickets-payments Built 
 Image tickets-app Built 
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
 Container tickets-jaeger-1 Creating 
 Container tickets-db-1 Creating 
 Container tickets-collector-1 Creating 
 Container tickets-prometheus-1 Creating 
 Container tickets-payments-1 Creating 
 Container tickets-collector-1 Created 
 Container tickets-jaeger-1 Created 
 Container tickets-payments-1 Created 
 Container tickets-prometheus-1 Created 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-redis-1 Created 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-payments-1 Starting 
 Container tickets-redis-1 Starting 
 Container tickets-jaeger-1 Starting 
 Container tickets-db-1 Starting 
 Container tickets-prometheus-1 Starting 
 Container tickets-collector-1 Starting 
 Container tickets-payments-1 Started 
 Container tickets-redis-1 Started 
 Container tickets-jaeger-1 Started 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-prometheus-1 Started 
 Container tickets-collector-1 Started 
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
collector    Up 15 seconds
db           Up 15 seconds (healthy)
jaeger       Up 16 seconds
lb           Up 10 seconds
payments     Up 16 seconds
prometheus   Up 15 seconds
redis        Up 16 seconds
replica      Up 13 seconds (healthy)
```

Nove serviços agora, com o `redis` entre eles. Nada numa venda isolada mudou: as guardas só agem
quando algo passa de um limite, e as próximas seções empurram cada uma além do seu.
