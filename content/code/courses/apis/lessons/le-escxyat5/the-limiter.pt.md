---
title: O limitador
version: 1
---

**O `limits.py` é uma segunda API na frente dos mesmos livros: ele pede uma chave a toda requisição,
cobra do balde da chave, e só então lê o banco.** Ele responde em três endereços, `/books`,
`/books/<id>` e `/search?q=`, e é um programa separado em vez de uma mudança no `rest.py` para que a
API da aula 1 continue como estava.

Ele só precisa do que a aula 1 montou, o `db.py` em `~/shelf`. Salve o arquivo como
`~/shelf/limits.py` no editor, como fez com o `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/limits.py",
  "parts": [
    {
      "code": "# shelf/limits.py\n\"\"\"The books behind an API key, with a rate limit and a daily quota per key.\n\nRun it with `python3 limits.py` for a token bucket, or `python3 limits.py window`\nfor a fixed window. A second argument is the port; the default is 8000.\n\"\"\"\nimport json\nimport math\nimport sys\nimport threading\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlsplit\n\nimport db",
      "note": "A biblioteca padrão e o `db.py` de novo, e nada mais. O `limits.py` lê o mesmo `shelf.db` que o `rest.py`; só um dos dois pode ocupar a porta 8000 de cada vez, então pare o `rest.py` antes de iniciar este."
    },
    {
      "code": "\nKEYS = {\"demo-ana\": \"trial\", \"demo-bia\": \"free\", \"demo-caio\": \"pro\"}\n\nTIERS = {\n    \"trial\": {\"capacity\": 10, \"per_second\": 1, \"daily\": 20},\n    \"free\": {\"capacity\": 10, \"per_second\": 1, \"daily\": 5000},\n    \"pro\": {\"capacity\": 100, \"per_second\": 10, \"daily\": 500000},\n}\n\nCOST = {\"/search\": 5}",
      "note": "Três **chaves de demonstração**, escritas no arquivo para a aula poder usá-las. Uma chave de verdade é longa, aleatória, emitida por cliente e guardada como hash; a aula 7 mostra como. Cada chave tem um plano, e o plano guarda os números: um balde de 10 reabastecido a 1 por segundo, e uma cota diária. Uma busca custa 5 unidades, todo o resto custa 1."
    },
    {
      "code": "\n\nclass TokenBucket:\n    \"\"\"Holds up to `capacity` tokens and gains `per_second` more every second.\"\"\"\n\n    def __init__(self, capacity, per_second):\n        self.capacity, self.per_second = capacity, per_second\n        self.tokens, self.last = capacity, time.monotonic()\n\n    def refill(self):\n        now = time.monotonic()\n        self.tokens = min(self.capacity, self.tokens + (now - self.last) * self.per_second)\n        self.last = now\n\n    def take(self, cost):\n        self.refill()\n        if self.tokens < cost:\n            return False\n        self.tokens -= cost\n        return True\n\n    def left(self):\n        self.refill()\n        return math.floor(self.tokens)\n\n    def wait(self, cost):\n        \"\"\"Seconds until `cost` tokens are in the bucket.\"\"\"\n        return max(0, math.ceil((cost - self.tokens) / self.per_second))",
      "note": "O **balde de fichas** (*token bucket*). Ele não guarda lista de requisições, só um número e a hora em que foi completado pela última vez: `refill` soma o que o tempo decorrido vale, até o teto `capacity`. `take` gasta o custo ou recusa. `wait` é a conta por trás do `Retry-After`: as fichas que faltam divididas pela taxa, arredondadas para cima em segundos inteiros."
    },
    {
      "code": "\n\nclass FixedWindow:\n    \"\"\"Counts up to `limit` in each window of `seconds`; windows start on the clock.\"\"\"\n\n    def __init__(self, limit, seconds):\n        self.limit, self.seconds = limit, seconds\n        self.window, self.used = None, 0\n\n    def roll(self):\n        window = int(time.time() // self.seconds)\n        if window != self.window:\n            self.window, self.used = window, 0\n\n    def take(self, cost):\n        self.roll()\n        if self.used + cost > self.limit:\n            return False\n        self.used += cost\n        return True\n\n    def left(self):\n        self.roll()\n        return self.limit - self.used\n\n    def wait(self, cost):\n        \"\"\"Seconds until this window ends and the count starts again.\"\"\"\n        return math.ceil((self.window + 1) * self.seconds - time.time())",
      "note": "A **janela fixa**, mantida para comparar e reaproveitada para a cota diária. O número da janela é o relógio dividido pela duração dela, então toda janela começa num múltiplo de dez segundos desde 1970, e o dia começa à meia-noite UTC. Quando o número muda, a contagem volta a zero."
    },
    {
      "code": "\n\nMODE = sys.argv[1] if len(sys.argv) > 1 else \"bucket\"\nPORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8000\nLOCK = threading.Lock()\nLIMITS = {}",
      "note": "Qual limitador roda é o primeiro argumento, e a porta é o segundo. Todo contador vive em `LIMITS`, um dicionário na memória deste processo. A seção sobre mais de um servidor trata do que isso custa. A trava importa porque o `ThreadingHTTPServer` atende cada requisição numa thread própria, e duas threads lendo o mesmo balde ao mesmo tempo veriam as duas a última ficha."
    },
    {
      "code": "\n\ndef admit(key, cost):\n    \"\"\"(allowed, the RateLimit headers, seconds to wait) for one request.\"\"\"\n    tier = TIERS[KEYS[key]]\n    with LOCK:\n        if key not in LIMITS:\n            rate, size = tier[\"per_second\"], tier[\"capacity\"]\n            burst = TokenBucket(size, rate) if MODE == \"bucket\" else FixedWindow(size, size / rate)\n            LIMITS[key] = burst, FixedWindow(tier[\"daily\"], 86400)\n        burst, day = LIMITS[key]\n        if day.left() < cost:\n            ok, wait, why = False, day.wait(cost), \"daily quota used up\"\n        elif not burst.take(cost):\n            ok, wait, why = False, burst.wait(cost), \"too many requests\"\n        else:\n            day.take(cost)\n            ok, wait, why = True, 0, None\n        policy = (f'\"burst\";q={tier[\"capacity\"]};w={tier[\"capacity\"] // tier[\"per_second\"]}, '\n                  f'\"daily\";q={tier[\"daily\"]};w=86400')\n        state = \", \".join(f'\"{name}\";r={lim.left()};t={lim.wait(lim.left() + 1)}'\n                          for name, lim in ((\"burst\", burst), (\"daily\", day)))\n    return ok, [(\"RateLimit-Policy\", policy), (\"RateLimit\", state)], wait, why",
      "note": "`admit` decide uma requisição. A cota diária é conferida primeiro sem gastar nada, então uma requisição que o balde recusa em seguida não consumiu parte do dia. Os dois cabeçalhos seguem o rascunho da IETF: `RateLimit-Policy` declara cada política (`q` unidades a cada `w` segundos) e `RateLimit` o que sobra dela (`r` unidades nos próximos `t` segundos)."
    },
    {
      "code": "\n\nclass Limited(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value, headers=()):\n        body = (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "`reply` é o do `rest.py`, sem o caso de resposta vazia: toda resposta aqui é JSON."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        key = self.headers.get(\"X-API-Key\")\n        if key not in KEYS:\n            return self.reply(401, {\"error\": \"send a valid X-API-Key header\"})\n        top = \"/\" + url.path.split(\"/\")[1]\n        ok, headers, wait, why = admit(key, COST.get(top, 1))\n        if not ok:\n            return self.reply(429, {\"error\": f\"{why}: retry in {wait} s\"},\n                              headers + [(\"Retry-After\", str(wait))])\n        with db.connect() as conn:\n            if url.path == \"/books\":\n                rows = conn.execute(\"SELECT id, title FROM books ORDER BY id\").fetchall()\n                return self.reply(200, [dict(r) for r in rows], headers)\n            if top == \"/books\" and url.path[7:].isdigit():\n                row = conn.execute(\"SELECT id, title, price_cents FROM books WHERE id = ?\",\n                                   (int(url.path[7:]),)).fetchone()\n                if row:\n                    return self.reply(200, dict(row), headers)\n            if url.path == \"/search\":\n                words = parse_qs(url.query).get(\"q\", [\"\"])[0]\n                rows = conn.execute(\"SELECT id, title FROM books WHERE title LIKE ? ORDER BY id\",\n                                    (f\"%{words}%\",)).fetchall()\n                return self.reply(200, [dict(r) for r in rows], headers)\n        return self.reply(404, {\"error\": \"no such resource\"}, headers)",
      "note": "A ordem é o projeto. **Sem chave, sem serviço**: 401 antes de qualquer contagem. Depois o limite, **antes mesmo de olhar a rota**, então uma requisição para um endereço que não existe custa o mesmo que uma para um que existe; do contrário, uma enxurrada de 404 sairia de graça. Uma recusa é **429** com `Retry-After`. Só então o banco é aberto."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", PORT), Limited)\n    print(f\"limits ({MODE}) on http://127.0.0.1:{PORT}\", flush=True)\n    server.serve_forever()",
      "note": "Como o `rest.py`, escuta só em 127.0.0.1, e na porta 8000 se nada disser outra coisa."
    }
  ]
}
```

## Os cabeçalhos que ele envia

Como um servidor conta a um cliente sobre os limites dele nunca foi padronizado, e cada API inventou os
próprios nomes: `X-RateLimit-Limit`, `X-RateLimit-Remaining` e `X-RateLimit-Reset` são os mais comuns,
com o reset às vezes em segundos e às vezes como uma hora no relógio. O grupo de trabalho de APIs HTTP
da IETF vem escrevendo um padrão para isso, **RateLimit header fields for HTTP**, e ele ainda é um
Internet-Draft, não uma RFC. As primeiras versões usavam três campos chamados `RateLimit-Limit`,
`RateLimit-Remaining` e `RateLimit-Reset`; a versão em vigor quando esta aula foi escrita, em 2026,
usa dois, e o `limits.py` envia esses:

| campo | exemplo | diz |
|---|---|---|
| `RateLimit-Policy` | `"burst";q=10;w=10` | cada política pelo nome: `q` unidades permitidas a cada `w` segundos. Não muda de uma resposta para outra |
| `RateLimit` | `"burst";r=8;t=1` | quanto sobra agora: `r` unidades disponíveis nos próximos `t` segundos |
| `Retry-After` | `1` | só numa recusa: quantos segundos esperar |

Como é um rascunho, os nomes ainda podem mudar, e um cliente não pode contar com nenhuma API
enviando-os. **O `Retry-After` e o status `429` são as partes em que um cliente pode confiar**: o `429
Too Many Requests` é um status padrão desde 2012, e o `Retry-After` é definido pelo próprio HTTP.

## Rodando

Pare o `rest.py` com `Ctrl+C` no segundo terminal, já que os dois querem a porta 8000, e inicie este
no lugar dele:

```sh
cd ~/shelf && python3 limits.py
```

Ele imprime `limits (bucket) on http://127.0.0.1:8000`. Uma requisição sem chave é recusada antes de
qualquer contagem, e uma com chave é atendida:

```
ana@api:~/shelf$ curl -s localhost:8000/books
{"error": "send a valid X-API-Key header"}
ana@api:~/shelf$ curl -s -H 'X-API-Key: demo-bia' localhost:8000/books
[{"id": 1, "title": "Dom Casmurro"}, {"id": 2, "title": "Memórias Póstumas de Brás Cubas"}, {"id": 3, "title": "A Hora da Estrela"}, {"id": 4, "title": "Perto do Coração Selvagem"}, {"id": 5, "title": "Ensaio sobre a Cegueira"}, {"id": 6, "title": "Americanah"}]
```

Com `-i`, os cabeçalhos de um livro:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/3
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:48:44 GMT
Content-Type: application/json
Content-Length: 61
RateLimit-Policy: "burst";q=10;w=10, "daily";q=5000;w=86400
RateLimit: "burst";r=8;t=1, "daily";r=4998;t=69076

{"id": 3, "title": "A Hora da Estrela", "price_cents": 3490}
```

Duas políticas em cada cabeçalho, separadas por vírgula. `burst` é o balde: dez fichas, dez segundos
para encher a partir de vazio, e oito sobrando: esta foi a segunda requisição da chave, cedo demais
depois da primeira para uma ficha inteira ter voltado. `daily` é a cota, 5.000 por dia no plano free,
e o `t` dela é o número de segundos até a meia-noite UTC, quando a contagem do dia recomeça.

As três chaves e os planos delas:

| chave | plano | balde | cota diária |
|---|---|---|---|
| `demo-ana` | trial | 10, reabastecido a 1 por segundo | 20 |
| `demo-bia` | free | 10, reabastecido a 1 por segundo | 5.000 |
| `demo-caio` | pro | 100, reabastecido a 10 por segundo | 500.000 |
