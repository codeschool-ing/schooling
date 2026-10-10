---
title: A bilheteria
version: 1
---

Todas as aulas de desempenho deste curso medem a mesma aplicação, então você a digita uma vez só,
aqui. É a **boxoffice**, a bilheteria de um pequeno teatro: uma lista de espetáculos à venda, quantos
lugares restam em cada um e um jeito de reservar um. São dois arquivos de Python e um banco SQLite,
sem nada de fora da biblioteca padrão. Ela é pequena de propósito, e também é mais lenta do que
precisaria ser de propósito, em dois lugares que a aula 9 encontra.

Crie uma pasta para ela e entre nela:

```sh
mkdir -p ~/boxoffice && cd ~/boxoffice
```

## Os dados

O `seed.py` monta o banco: mil espetáculos, dos quais vinte estão à venda, e as reservas de todos os
espetáculos que já aconteceram. Os números saem de uma semente aleatória fixa, então o seu banco tem
as mesmas linhas que o das transcrições. Abra o editor com `nano seed.py`, copie o arquivo abaixo com
o botão no canto dele, cole, depois `Ctrl+O` para salvar e `Ctrl+X` para sair.

```python
# boxoffice/seed.py
# Builds boxoffice.db: 1,000 shows, of which 20 are on sale, and the
# bookings of every show already played. Run it again to start from scratch.
import os, random, sqlite3

os.makedirs("data", exist_ok=True)
if os.path.exists("data/boxoffice.db"):
    os.remove("data/boxoffice.db")
db = sqlite3.connect("data/boxoffice.db")
db.executescript("""
CREATE TABLE shows (id INTEGER PRIMARY KEY, title TEXT, day TEXT,
                    price_cents INTEGER, capacity INTEGER, on_sale INTEGER);
CREATE TABLE bookings (id INTEGER PRIMARY KEY, show_id INTEGER, seat INTEGER,
                       customer TEXT);
""")
rnd = random.Random(42)
plays = ["Hamlet", "The Seagull", "Antigone", "Waiting for Godot", "Medea",
         "The Tempest", "Uncle Vanya", "A Doll's House", "Macbeth", "Tartuffe"]
for show in range(1, 1001):
    on_sale = 1 if show > 980 else 0
    year = 2027 if on_sale else 2023 + show // 400
    day = f"{year}-{show % 12 + 1:02d}-{show % 28 + 1:02d}"
    db.execute("INSERT INTO shows VALUES (?, ?, ?, ?, ?, ?)",
               (show, rnd.choice(plays), day, rnd.choice([4000, 6000, 9000]), 300, on_sale))
    sold = 300 if not on_sale else rnd.randint(0, 120)
    seats = rnd.sample(range(1, 301), sold)
    db.executemany("INSERT INTO bookings (show_id, seat, customer) VALUES (?, ?, ?)",
                   [(show, s, f"c{rnd.randint(1, 50000)}") for s in seats])
db.commit()
print(db.execute("SELECT count(*) FROM shows").fetchone()[0], "shows,",
      db.execute("SELECT count(*) FROM bookings").fetchone()[0], "bookings")
```

Rode-o:

```
ana@nft:~/boxoffice$ python3 seed.py
1000 shows, 295112 bookings
ana@nft:~/boxoffice$ ls -l data
total 5904
-rw-r--r-- 1 ana ana 6045696 Oct 10 04:08 boxoffice.db
```

## O servidor

O `app.py` é a bilheteria em si. Crie-o do mesmo jeito, com `nano app.py`. O botão de copiar do bloco
abaixo leva o arquivo inteiro, sem as notas ao lado.

```schooling-example
{"language": "python", "file": "boxoffice/app.py", "parts": [{"code": "# boxoffice/app.py\n# The box office every lesson tests: shows, seats and bookings, over HTTP.\nimport json, os, sqlite3, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom pathlib import Path\nfrom urllib.parse import parse_qs, urlparse\n\nDB = \"data/boxoffice.db\"\nSTATIC = Path(\"static\")\nPAYMENT_SECONDS = 0.040        # the payment provider, faked: 40 ms a call\nbooking_lock = threading.Lock()\nKINDS = {\".html\": \"text/html; charset=utf-8\", \".css\": \"text/css\",\n         \".js\": \"text/javascript\", \".svg\": \"image/svg+xml\", \".png\": \"image/png\"}\n", "note": "Só a biblioteca padrão, então nada aqui precisa ser instalado. `PAYMENT_SECONDS` é o provedor de pagamento: uma bilheteria de verdade chamaria um pela rede, e esta espera 40 ms no lugar, que é mais ou menos o que uma chamada dessas custa. `booking_lock` garante que duas pessoas não paguem pelo mesmo assento no mesmo instante."}, {"code": "def pay(customer, cents):\n    time.sleep(PAYMENT_SECONDS)\n\ndef rows_as(names, rows):\n    return [dict(zip(names, r)) for r in rows]\n", "note": "`pay` é tudo o que existe do provedor. A aula 9 volta a ela, porque uma espera inofensiva para um cliente deixa de ser inofensiva enquanto uma trava está presa."}, {"code": "class Box(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def handle_one_request(self):\n        self.started, self.timing = time.perf_counter(), {\"db\": 0.0, \"pay\": 0.0}\n        self.db = sqlite3.connect(DB, timeout=10)\n        try:\n            super().handle_one_request()\n        finally:\n            self.db.close()\n\n    def log_message(self, *args):\n        pass                       # quiet: a load test sends thousands\n", "note": "Um objeto de tratamento por conexão, e uma conexão SQLite por requisição. O log está desligado: um teste de carga manda milhares de requisições, e imprimir uma linha para cada faria do terminal a parte mais lenta do sistema."}, {"code": "    def query(self, sql, *args):\n        start = time.perf_counter()\n        rows = self.db.execute(sql, args).fetchall()\n        self.timing[\"db\"] += time.perf_counter() - start\n        return rows\n\n    def send(self, status, body, kind=\"application/json\"):\n        data = body if isinstance(body, bytes) else (json.dumps(body) + \"\\n\").encode()\n        spent = [f\"{k};dur={v * 1000:.1f}\" for k, v in self.timing.items()]\n        spent.append(f\"total;dur={(time.perf_counter() - self.started) * 1000:.1f}\")\n        self.send_response(status)\n        self.send_header(\"Content-Type\", kind)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.send_header(\"Server-Timing\", \", \".join(spent))\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Toda consulta é cronometrada, e toda resposta leva um cabeçalho `Server-Timing` dizendo quanto o banco levou, quanto o pagamento levou e quanto a requisição inteira levou, do ponto de vista do servidor. É o relato do próprio servidor sobre para onde foi o tempo, e a aula 9 o lê."}, {"code": "    def do_GET(self):\n        url = urlparse(self.path)\n        parts = url.path.strip(\"/\").split(\"/\")\n        if url.path == \"/health\":\n            return self.send(200, {\"ok\": True})\n        if url.path == \"/shows\":\n            rows = self.query(\"SELECT id, title, day, price_cents FROM shows WHERE on_sale = 1\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\", \"price_cents\"), rows))\n        if len(parts) == 2 and parts[0] == \"shows\" and parts[1].isdigit():\n            show_id = int(parts[1])\n            show = self.query(\"SELECT id, title, day, price_cents, capacity FROM shows\"\n                              \" WHERE id = ?\", show_id)\n            if not show:\n                return self.send(404, {\"error\": \"no such show\"})\n            sold = self.query(\"SELECT count(*) FROM bookings WHERE show_id = ?\", show_id)[0][0]\n            body = rows_as((\"id\", \"title\", \"day\", \"price_cents\", \"capacity\"), show)[0]\n            return self.send(200, {**body, \"sold\": sold, \"left\": body[\"capacity\"] - sold})\n        if url.path == \"/search\":\n            q = parse_qs(url.query).get(\"q\", [\"\"])[0]\n            rows = self.query(\"SELECT id, title, day FROM shows\"\n                              \" WHERE on_sale = 1 AND title LIKE ?\", f\"%{q}%\")\n            return self.send(200, rows_as((\"id\", \"title\", \"day\"), rows))\n        file = STATIC / (url.path.lstrip(\"/\") or \"index.html\")\n        if file.resolve().is_relative_to(STATIC.resolve()) and file.is_file():\n            kind = KINDS.get(file.suffix, \"application/octet-stream\")\n            return self.send(200, file.read_bytes(), kind)\n        return self.send(404, {\"error\": \"not found\"})\n", "note": "Cinco entradas: `/health`, a lista de espetáculos à venda, um espetáculo com os assentos que restam, uma busca pelo título e qualquer arquivo em `static/`, que as aulas 10 a 15 preenchem. Contar os assentos vendidos lê a tabela `bookings`, que tem quase trezentas mil linhas."}, {"code": "    def do_POST(self):\n        if self.path != \"/bookings\":\n            return self.send(404, {\"error\": \"not found\"})\n        try:\n            order = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\", 0))))\n            show, seat = int(order[\"show_id\"]), int(order[\"seat\"])\n            customer = str(order[\"customer\"])\n        except (ValueError, KeyError, TypeError):\n            return self.send(400, {\"error\": \"send show_id, seat and customer\"})\n        found = self.query(\"SELECT price_cents, capacity FROM shows\"\n                           \" WHERE id = ? AND on_sale = 1\", show)\n        if not found or not 1 <= seat <= found[0][1]:\n            return self.send(404, {\"error\": \"no such seat on sale\"})\n        with booking_lock:\n            if self.query(\"SELECT 1 FROM bookings WHERE show_id = ? AND seat = ?\", show, seat):\n                return self.send(409, {\"error\": \"seat taken\"})\n            start = time.perf_counter()\n            pay(customer, found[0][0])\n            self.timing[\"pay\"] += time.perf_counter() - start\n            cur = self.db.execute(\"INSERT INTO bookings (show_id, seat, customer)\"\n                                  \" VALUES (?, ?, ?)\", (show, seat, customer))\n            self.db.commit()\n        return self.send(201, {\"id\": cur.lastrowid, \"show_id\": show, \"seat\": seat})\n", "note": "Uma reserva confere a requisição, depois pega a trava, confere se o assento está livre, paga e grava a linha. Uma requisição malformada é 400, um assento que não existe é 404, um assento já vendido é 409, e uma reserva é 201."}, {"code": "if __name__ == \"__main__\":\n    host = os.environ.get(\"BOXOFFICE_HOST\", \"127.0.0.1\")\n    server = ThreadingHTTPServer((host, 8000), Box)\n    print(f\"boxoffice on http://{host}:8000\", flush=True)\n    server.serve_forever()", "note": "Ele escuta em `127.0.0.1:8000`, que só programas na mesma máquina alcançam. `BOXOFFICE_HOST=0.0.0.0` o abre para o seu próprio computador, nas aulas que usam o navegador do seu desktop."}]}
```

Inicie-o e deixe rodando:

```
ana@nft:~/boxoffice$ python3 app.py
boxoffice on http://127.0.0.1:8000
```

**Este terminal agora é do servidor.** Abra um segundo com `multipass shell nft`, vá para
`~/boxoffice` e digite o resto da aula lá.

## Perguntando algo a ele

```
ana@nft:~/boxoffice$ curl -s localhost:8000/health
{"ok": true}
ana@nft:~/boxoffice$ curl -s localhost:8000/shows | jq -c ".[:3][]"
{"id":981,"title":"Hamlet","day":"2027-10-02","price_cents":6000}
{"id":982,"title":"Antigone","day":"2027-11-03","price_cents":4000}
{"id":983,"title":"Uncle Vanya","day":"2027-12-04","price_cents":4000}
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:08:19 GMT
Content-Type: application/json
Content-Length: 119
Server-Timing: db;dur=17.8, pay;dur=0.0, total;dur=18.3

{"id": 990, "title": "The Tempest", "day": "2027-07-11", "price_cents": 4000, "capacity": 300, "sold": 7, "left": 293}
```

Olhe o último cabeçalho antes do corpo. **O `Server-Timing` é o servidor contando para onde foi o
tempo dele**: aqui o banco ficou com quase todo, contando as reservas de um espetáculo no meio de
quase trezentas mil. Guarde esse número; o requisito de "Do adjetivo ao número" pedia 200 ms no
percentil 95, e esta é uma requisição só, sozinha.

Uma reserva é um `POST`, e as respostas que voltam dependem do assento:

```
ana@nft:~/boxoffice$ curl -si -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "ana"}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 07:08:19 GMT
Content-Type: application/json
Content-Length: 43
Server-Timing: db;dur=16.6, pay;dur=40.1, total;dur=59.5

{"id": 295113, "show_id": 990, "seat": 12}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{"show_id": 990, "seat": 12, "customer": "bia"}'
{"error": "seat taken"}
409
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{"show_id": 990}'
{"error": "send show_id, seat and customer"}
400
```

A primeira reserva levou uns 40 ms a mais que a consulta acima dela, e o cabeçalho diz por quê: `pay`
é o substituto do provedor de pagamento. A segunda pede o mesmo assento e recebe 409; a terceira
deixa campos de fora e recebe 400.

Uma requisição diz muito pouco sobre a próxima, e esse é o assunto inteiro da aula 8. Peça a mesma
coisa cinco vezes e meça no cliente:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{time_total}\n" localhost:8000/shows/990; done
0.017540
0.020043
0.019568
0.017246
0.017334
```

Cinco requisições, carga nenhuma, e cinco tempos diferentes, de 0.017246 a 0.020043 segundo. Numa
máquina ocupada o espalhamento é bem maior. Um requisito escrito como "responde em N milissegundos"
não dá para conferir contra um espalhamento, e é por isso que o requisito nomeia uma estatística.

## Abrindo pelo seu próprio navegador

O servidor só responde na própria VM. Para as aulas que usam o navegador do seu computador, pare-o
com `Ctrl+C` e inicie-o com o endereço que aceita outras máquinas:

```sh
BOXOFFICE_HOST=0.0.0.0 python3 app.py
```

Depois, `multipass info nft`, no terminal do seu computador, mostra o endereço da VM na linha
`IPv4`, e `http://` seguido desse endereço e de `:8000/shows` abre no seu navegador. No WSL,
`http://localhost:8000/shows` chega direto. Volte ao `python3 app.py` simples quando terminar: não há
motivo para um servidor de teste responder a mais máquinas do que as que o testam.
