---
title: A bilheteria que você vai escalar
version: 1
---

**Toda aula deste curso mede um programa pequeno**: a bilheteria da Sabiá Ingressos, uma empresa
inventada que vende ingressos para shows em São Paulo. Ele é pequeno de propósito, sete arquivos
que se leem de uma vez, porque um sistema que você leu inteiro é um sistema cujos números você
consegue explicar. Cada aula seguinte muda ou acrescenta um arquivo, e o mostra inteiro quando faz
isso.

Ele tem três partes, cada uma no seu contêiner:

- **`db`**, um banco PostgreSQL 16 com duas tabelas: os shows, e os ingressos vendidos para eles;
- **`app`**, a bilheteria em si, um programa em Python que responde HTTP;
- **`lb`**, um nginx na frente do `app` que passa cada pedido para uma das suas cópias. Com uma
  cópia ele ainda não faz nada útil; a seção 08 lhe dá mais.

Um quarto arquivo, `load.py`, roda fora dos contêineres, no próprio laboratório, e manda para a
bilheteria quantos pedidos você pedir.

## Os arquivos

Crie um diretório para o projeto e trabalhe dentro dele pelo resto do curso:

```sh
mkdir -p ~/tickets
cd ~/tickets
```

Depois crie cada arquivo abaixo com o nome que está na primeira linha dele. Um editor de texto no
terminal serve, `nano compose.yaml` por exemplo, e o botão de copiar de cada bloco também.

Primeiro o banco. Duas tabelas, e cem shows de um milhão de lugares cada, para que nenhum teste
deste curso esgote um por acidente:

```sql
-- schema.sql
CREATE TABLE events (
  id       int  PRIMARY KEY,
  name     text NOT NULL,
  capacity int  NOT NULL,
  sold     int  NOT NULL DEFAULT 0 CHECK (sold <= capacity)
);

CREATE TABLE tickets (
  id       bigserial   PRIMARY KEY,
  event_id int         NOT NULL REFERENCES events,
  seat     int         NOT NULL,
  code     text        NOT NULL,
  sold_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_id, seat)
);

INSERT INTO events (id, name, capacity)
SELECT n, 'Show ' || n, 1000000
FROM generate_series(1, 100) AS n;
```

A imagem do PostgreSQL roda qualquer arquivo `.sql` que encontrar em `/docker-entrypoint-initdb.d`
na primeira vez que sobe com o diretório de dados vazio, e só nessa vez. O `compose.yaml` coloca
este ali.

O programa, cortado nas suas partes:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\n\"\"\"tickets: the box office of Sabiá Ingressos, as small as it can be.\"\"\"\nimport hashlib\nimport json\nimport os\nimport socket\nimport threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nDSN = os.environ[\"DATABASE_URL\"]\nHOST = socket.gethostname()\nlocal = threading.local()", "note": "O servidor HTTP do próprio Python e uma biblioteca, `psycopg`, que conversa com o PostgreSQL. `HOST` é o nome que o contêiner dá a si mesmo, e toda resposta o leva, para você ver qual cópia respondeu."}, {"code": "\n\ndef db():\n    if not hasattr(local, \"conn\"):\n        local.conn = psycopg.connect(DSN, autocommit=True)\n    return local.conn", "note": "Uma conexão com o banco por thread, aberta na primeira vez que aquela thread precisa e mantida depois. Abrir uma conexão custa mais do que a maioria das consultas."}, {"code": "\n\ndef sign(event_id, seat):\n    data = f\"{event_id}:{seat}\".encode()\n    return hashlib.pbkdf2_hmac(\"sha256\", data, b\"sabia\", 10_000).hex()[:16]", "note": "O código impresso no ingresso, que o leitor da portaria confere. Ele é **caro de propósito**: dez mil rodadas de um hash, cerca de 7 ms de processador, no lugar do trabalho real que uma venda faz. O `hashlib` deixa as outras threads rodarem enquanto calcula, então mais processadores ajudam."}, {"code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n\n    def reply(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "HTTP/1.1 mantém a conexão aberta entre pedidos. Sem a segunda linha, cabeçalhos e corpo saem em dois pacotes pequenos e o segundo espera uns 40 ms pela confirmação do primeiro, o que seria a maior parte de toda medida deste curso."}, {"code": "\n    def do_GET(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if parts == [\"healthz\"]:\n            return self.reply(200, {\"host\": HOST})\n        if len(parts) == 2 and parts[0] == \"events\":\n            row = db().execute(\n                \"SELECT name, capacity - sold FROM events WHERE id = %s\",\n                (int(parts[1]),)).fetchone()\n            if row is None:\n                return self.reply(404, {\"error\": \"no such event\"})\n            return self.reply(200, {\"name\": row[0], \"left\": row[1], \"host\": HOST})\n        self.reply(404, {\"error\": \"not found\"})", "note": "`GET /events/1` lê uma linha: o nome do show e quantos lugares restam. É o caminho barato, uma busca pela chave."}, {"code": "\n    def do_POST(self):\n        parts = self.path.strip(\"/\").split(\"/\")\n        if len(parts) == 3 and parts[0] == \"events\" and parts[2] == \"tickets\":\n            event_id = int(parts[1])\n            conn = db()\n            with conn.transaction():\n                row = conn.execute(\n                    \"UPDATE events SET sold = sold + 1\"\n                    \" WHERE id = %s AND sold < capacity RETURNING sold\",\n                    (event_id,)).fetchone()\n                if row is None:\n                    return self.reply(409, {\"error\": \"sold out\"})\n                seat = row[0]\n                code = sign(event_id, seat)\n                conn.execute(\n                    \"INSERT INTO tickets (event_id, seat, code) VALUES (%s, %s, %s)\",\n                    (event_id, seat, code))\n            return self.reply(201, {\"event\": event_id, \"seat\": seat, \"code\": code})\n        self.reply(404, {\"error\": \"not found\"})", "note": "`POST /events/1/tickets` vende um lugar, numa transação: soma um a `sold` se o show não estiver lotado, assina o ingresso, registra. O `UPDATE` trava a linha do show até a transação terminar, e a assinatura acontece **com essa trava segura**. Guarde isso; a seção 09 mede quanto custa."}, {"code": "\n    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8000), Handler).serve_forever()", "note": "O servidor do Python imprime uma linha a cada pedido por padrão; isto o silencia, e a aula 7 o troca por logs que valem a leitura. Uma thread por conexão, e espaço para 128 conexões esperando para serem aceitas: o padrão do Python é 5, e a sexta seria descartada e tentada de novo pelo cliente um segundo depois."}]}
```

A biblioteca de que ele precisa, fixada na versão com que as transcrições foram gravadas:

```
# requirements.txt
psycopg[binary]==3.2.10
```

A imagem que o roda. `python:3.12.15-slim` é um Debian com Python e pouco mais; a forma `[binary]`
do psycopg traz a sua própria cópia da biblioteca cliente do PostgreSQL, então nada precisa ser
compilado:

```dockerfile
# Dockerfile
FROM python:3.12.15-slim
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```

A configuração do balanceador de carga. `upstream app` nomeia as cópias da bilheteria pelo nome que
o Docker dá ao serviço, e `keepalive 64` mantém as conexões com elas abertas entre um pedido e
outro, em vez de abrir uma nova a cada vez:

```conf
# nginx.conf
events {}

http {
  upstream app {
    server app:8000;
    keepalive 64;
  }

  server {
    listen 80;
    location / {
      proxy_pass http://app;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
    }
  }
}
```

Os três serviços juntos. Duas linhas importam para esta aula: **`cpus: 1`** limita cada cópia do
`app` ao tempo de um processador, que é o que as seções 07 e 08 mudam, e a porta é publicada só em
`127.0.0.1`, então nada fora do laboratório a alcança:

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
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app
```

A senha é `tickets` e está escrita no arquivo. Isso é aceitável num laboratório que ninguém mais
alcança e em nenhum outro lugar. Uma implantação de verdade entrega a senha ao contêiner a partir
de um cofre de segredos, e nunca a escreve num arquivo que vai para o git.

Por último, o gerador de carga, que as próximas seções usam para medir tudo:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py\n\"\"\"A closed-loop load generator: each worker sends a request, waits, sends the next.\"\"\"\nimport argparse\nimport http.client\nimport threading\nimport time\nfrom collections import Counter\nfrom urllib.parse import urlsplit\n\np = argparse.ArgumentParser()\np.add_argument(\"url\")\np.add_argument(\"-c\", \"--workers\", type=int, default=4)\np.add_argument(\"-d\", \"--seconds\", type=float, default=10)\np.add_argument(\"-m\", \"--method\", default=\"GET\")\np.add_argument(\"--events\", type=int, default=1)\nargs = p.parse_args()", "note": "Cinco opções: o endereço, quantos trabalhadores (`-c`), por quanto tempo (`-d`), qual método (`-m`) e por quantos shows espalhar os pedidos (`--events`), que substitui `{event}` no endereço."}, {"code": "\nu = urlsplit(args.url)\nlatencies, statuses, lock = [], Counter(), threading.Lock()\ndeadline = time.monotonic() + args.seconds\n\n\ndef worker(n):\n    conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n    mine, seen, i = [], Counter(), n\n    while time.monotonic() < deadline:\n        path = u.path.replace(\"{event}\", str(i % args.events + 1))\n        i += args.workers\n        start = time.monotonic()\n        try:\n            conn.request(args.method, path, headers={\"Content-Length\": \"0\"})\n            r = conn.getresponse()\n            r.read()\n            seen[r.status] += 1\n        except OSError as e:\n            seen[type(e).__name__] += 1\n            conn.close()\n            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=10)\n            continue\n        mine.append(time.monotonic() - start)\n    with lock:\n        latencies.extend(mine)\n        statuses.update(seen)", "note": "Cada trabalhador mantém uma conexão e repete até o prazo: envia, espera a resposta inteira, anota quanto demorou e qual status voltou. **Ele nunca envia o próximo pedido antes de o último responder**, e é isso que faz disto um laço fechado. A aula 12 mostra o que isso esconde."}, {"code": "\n\nstarted = time.monotonic()\nthreads = [threading.Thread(target=worker, args=(n,)) for n in range(args.workers)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nelapsed = time.monotonic() - started\n\nlatencies.sort()\n\n\ndef pct(q):\n    return latencies[min(len(latencies) - 1, int(q * len(latencies)))] * 1000", "note": "Todos os trabalhadores começam juntos e a rodada acaba quando o último para. Um percentil é lido da lista ordenada: o p95 é o tempo abaixo do qual 95% dos pedidos terminaram."}, {"code": "\n\ntotal = sum(statuses.values())\nprint(f\"requests  {total} in {elapsed:.1f} s = {total / elapsed:.1f} per second\")\nif latencies:\n    print(f\"latency   p50 {pct(0.50):.1f} ms  p95 {pct(0.95):.1f} ms\"\n          f\"  p99 {pct(0.99):.1f} ms  max {latencies[-1] * 1000:.1f} ms\")\nprint(\"status    \" + \"  \".join(f\"{k}: {v}\" for k, v in sorted(statuses.items(), key=str)))", "note": "Três linhas: quantos pedidos por segundo, quatro pontos da distribuição de latência e uma contagem por status, porque uma rodada rápida cheia de erros não é uma rodada rápida."}]}
```

## Subindo

`docker compose up` constrói a imagem, baixa as outras duas e sobe os três contêineres. Na primeira
vez leva um ou dois minutos, a maior parte baixando:

```
ana@lab:~/tickets$ docker compose up -d --build
 Image tickets-app Building 
#1 [internal] load local bake definitions
#1 reading from stdin 474B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile
#2 transferring dockerfile: 204B done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/python:3.12.15-slim
#3 DONE 0.0s

#4 [internal] load .dockerignore
#4 transferring context: 2B done
#4 DONE 0.0s

#5 [internal] load build context
#5 transferring context: 2.82kB done
#5 DONE 0.0s

#6 [1/5] FROM docker.io/library/python:3.12.15-slim@sha256:554838b75f0f5d89dee667d862b0b162322c417045c5c3e7a2a5e2ae622ffce4
#6 resolve docker.io/library/python:3.12.15-slim@sha256:554838b75f0f5d89dee667d862b0b162322c417045c5c3e7a2a5e2ae622ffce4 0.0s done
#6 DONE 0.0s

#7 [2/5] WORKDIR /srv
#7 CACHED

#8 [4/5] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED

#9 [3/5] COPY requirements.txt .
#9 CACHED

#10 [5/5] COPY app.py .
#10 CACHED

#11 exporting to image
#11 exporting layers
#11 exporting layers done
#11 exporting manifest sha256:4f175ce9b92b9d6a2e4ed9fc5ee411c4a22ac5d8bb1cc0481cf147326229dfef done
#11 exporting config sha256:aded196e6e7ad8e02ad133ec780807c4640b5cb30ae9c378fefab05c39f9649e done
#11 exporting attestation manifest sha256:e53ee3c36ec3107f0057fbdad54b780cf2fa50eb19bf217d33cb91036da2eabe done
#11 exporting manifest list sha256:a73d8541c1cef61bfcf0627ce683f4fa8a984d573fba206ab6c7b756332e2558 done
#11 naming to docker.io/library/tickets-app:latest done
#11 unpacking to docker.io/library/tickets-app:latest done
#11 DONE 0.1s

#12 resolving provenance for metadata file
#12 DONE 0.0s
 Image tickets-app Built 
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-db-1 Creating 
 Container tickets-db-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
app       Up Less than a second
db        Up 3 seconds (healthy)
lb        Up Less than a second
```

Três contêineres, e o `db` diz `healthy` porque o `compose.yaml` ensinou o Docker a perguntar.
Agora a bilheteria responde. Um show, e depois um ingresso comprado para ele:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "4e31882948b0"}
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "4e31882948b0"}
```

`"left": 1000000` antes da venda, o lugar `1` na resposta, e `host` nomeia o contêiner que
respondeu. Peça o show de novo e `left` está um a menos. O código na sua resposta é o mesmo do de
cima, porque é calculado a partir do show e do lugar e de mais nada.

## Parando e subindo de novo

`docker compose down` para e remove os contêineres, e **com eles o banco**, porque o
`compose.yaml` guarda os dados do PostgreSQL dentro do contêiner. É de propósito: toda aula começa
dos mesmos cem shows vazios com `docker compose up -d`. As aulas que precisam que os dados
sobrevivam a um reinício dizem isso, e dão um volume ao banco.

```sh
docker compose down
docker compose up -d
```
