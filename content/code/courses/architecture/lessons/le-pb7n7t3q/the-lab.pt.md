---
title: O laboratório: um monólito atrás de uma borda
version: 1
---

O laboratório é o monólito da Quitanda com o módulo de estoque já copiado para um serviço próprio, e um
**nginx** na frente dos dois como fachada. Mais dois programas pequenos ficam ao lado deles e são o
assunto da segunda metade da aula. Ele fica em `~/lab/strangler`:

```sh
mkdir -p ~/lab/strangler && cd ~/lab/strangler
```

`monolith.py`:

```schooling-example
{"language": "python", "file": "monolith.py", "parts": [{"code": "\"\"\"Quitanda's monolith: catalogue, stock and checkout in one process.\"\"\"\nimport urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nSTOCK = {\"coffee\": 12, \"tea\": 30}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        if self.path == \"/catalogue\":\n            return self.reply(200, \"monolith: coffee, tea\")\n        if self.path.startswith(\"/stock/\"):\n            sku = self.path.split(\"/\")[2]\n            return self.reply(200, f\"monolith: {sku} {STOCK[sku]}\")\n        self.reply(404, \"monolith: no such page\")\n\n    def do_POST(self):\n        try:\n            with urllib.request.urlopen(urllib.request.Request(\"http://localhost:9000/charge\", method=\"POST\"),\n                                        timeout=5) as r:\n                self.reply(200, f\"monolith: checkout done, gateway said {r.read().decode().strip()}\")\n        except urllib.error.HTTPError as e:\n            self.reply(502, f\"monolith: checkout failed, gateway said {e.code}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "O monólito, como a aula 1 o deixou, reduzido a três rotas: o catálogo, o estoque de um produto, e um checkout que cobra um cartão. O checkout chama o gateway de pagamento em `localhost:9000`, que é o endereço do ambassador, não do gateway: uma seção adiante explica."}]}
```

`stock.py`, o módulo de estoque como serviço:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"The stock service, taken out of the monolith.\"\"\"\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nSTOCK = {\"coffee\": 12, \"tea\": 30}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        sku = self.path.split(\"/\")[2]\n        body = f\"stock service: {sku} {STOCK[sku]}\\n\".encode()\n        self.send_response(200)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "O módulo de estoque, levado para fora num serviço próprio. Ele responde a mesma URL que o monólito respondia, com os mesmos números, para nada que o chama precisar mudar; só o nome na resposta é diferente, que é como a aula consegue ver qual dos dois respondeu."}]}
```

`proxy.py`, que roda duas vezes, como sidecar e como ambassador:

```schooling-example
{"language": "python", "file": "proxy.py", "parts": [{"code": "\"\"\"Forward requests to one upstream, logging each, with optional retries and an API key.\"\"\"\nimport os, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nLISTEN = int(os.environ[\"LISTEN\"])\nUPSTREAM = os.environ[\"UPSTREAM\"]\nRETRIES = int(os.environ.get(\"RETRIES\", \"0\"))\nAPI_KEY = os.environ.get(\"API_KEY\")\nNAME = os.environ[\"NAME\"]\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def forward(self):\n        start = time.time()\n        headers = {\"X-Api-Key\": API_KEY} if API_KEY else {}\n        for attempt in range(1 + RETRIES):\n            req = urllib.request.Request(UPSTREAM + self.path, method=self.command, headers=headers)\n            try:\n                with urllib.request.urlopen(req, timeout=5) as r:\n                    status, body = r.status, r.read()\n            except urllib.error.HTTPError as e:\n                status, body = e.code, e.read()\n            if status != 503:\n                break\n        ms = (time.time() - start) * 1000\n        print(f\"{NAME}: {self.command} {self.path} -> {status} in {ms:.0f} ms, {attempt + 1} attempt(s)\",\n              flush=True)\n        self.send_response(status)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    do_GET = do_POST = forward\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", LISTEN), Handler).serve_forever()", "note": "Um proxy pequeno, usado duas vezes no laboratório. Ele escuta em `LISTEN`, repassa toda requisição para `UPSTREAM`, e imprime uma linha para cada: método, caminho, status e tempo gasto. Com `RETRIES` definida ele tenta de novo num `503`, e com `API_KEY` definida acrescenta a chave à requisição. O que o torna um sidecar ou um ambassador não é o código, mas ao lado de quem ele é posto."}]}
```

`gateway.py`, fazendo o papel de um gateway de pagamento externo:

```schooling-example
{"language": "python", "file": "gateway.py", "parts": [{"code": "\"\"\"A payment gateway that wants an API key and is busy half the time.\"\"\"\nimport itertools\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\ncalls = itertools.count(1)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def do_POST(self):\n        if self.headers.get(\"X-Api-Key\") != \"sk_test_quitanda\":\n            code, text = 401, \"no valid API key\"\n        elif next(calls) % 2 == 0:\n            code, text = 503, \"busy, try again\"\n        else:\n            code, text = 200, \"charged\"\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "Um substituto de um gateway de pagamento externo: ele recusa uma requisição sem a chave de API certa, e responde toda segunda requisição com `503`, como um terceiro ocupado faz."}]}
```

`nginx.conf`, a borda:

```schooling-example
{"language": "conf", "file": "nginx.conf", "parts": [{"code": "events {}\nhttp {\n    upstream monolith { server monolith:8000; }\n    upstream stock    { server stock:8080; }\n", "note": "A borda, a fachada do strangler: toda requisição à loja entra aqui, na porta 8080 da máquina. `/stock/` vai para o backend que o `stock-split.conf` escolher para a requisição; todo o resto vai para o monólito."}, {"code": "    include /etc/nginx/stock-split.conf;\n\n    server {\n        listen 80;\n        location /stock/ { proxy_pass http://$stock_backend; }\n        location /       { proxy_pass http://monolith; }\n    }\n}", "note": "Que backend atende o `/stock/` é decidido num arquivo próprio, para mover tráfego ser editar esse arquivo e recarregar."}]}
```

`stock-split.conf`, a única configuração que a migração mexe:

```schooling-example
{"language": "conf", "file": "stock-split.conf", "parts": [{"code": "split_clients \"${request_id}\" $stock_backend {\n    * monolith;\n}", "note": "Para onde vai o `/stock/`. O `split_clients` transforma o id de cada requisição numa porcentagem e escolhe um backend por ela; no começo, tudo vai para o monólito."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Todo programa do laboratório usa só a biblioteca padrão do Python."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  edge:\n    image: nginx:1.27-alpine\n    volumes:\n      - ./nginx.conf:/etc/nginx/nginx.conf:ro\n      - ./stock-split.conf:/etc/nginx/stock-split.conf:ro\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - monolith\n      - stock", "note": "A borda, publicada na porta 8080 da máquina, com os dois arquivos de configuração montados a partir do diretório do laboratório."}, {"code": "  monolith:\n    build: .\n    command: python monolith.py\n  ambassador:\n    build: .\n    command: python proxy.py\n    network_mode: service:monolith\n    environment:\n      NAME: ambassador\n      LISTEN: \"9000\"\n      UPSTREAM: http://gateway:8000\n      RETRIES: \"2\"\n      API_KEY: sk_test_quitanda\n  gateway:\n    build: .\n    command: python gateway.py", "note": "O monólito, e o seu **ambassador**: um proxy no próprio namespace de rede do monólito (`network_mode: service:monolith`), para ele ser, para o monólito, `localhost:9000`. Ele acrescenta a chave de API e tenta de novo os `503` do gateway."}, {"code": "  stock:\n    build: .\n    command: python stock.py\n  sidecar:\n    build: .\n    command: python proxy.py\n    network_mode: service:stock\n    environment:\n      NAME: sidecar\n      LISTEN: \"8080\"\n      UPSTREAM: http://localhost:8000", "note": "O novo serviço de estoque, e o seu **sidecar**: um proxy no namespace do serviço de estoque, escutando na 8080 e repassando para o serviço em `localhost:8000`, registrando toda requisição na entrada. A borda fala com o sidecar, nunca direto com o serviço."}]}
```

Suba tudo, e peça à borda uma página e o estoque de café:

```
ana@vm:~/lab/strangler$ curl -s localhost:8080/catalogue; curl -s localhost:8080/stock/coffee
monolith: coffee, tea
monolith: coffee 12
```

As duas respostas vieram do monólito, pela borda. É o passo 1 da migração, e ele já importa: daqui em
diante nenhum cliente fala direto com o monólito, então para onde vai uma requisição pode ser mudado num
lugar só sem ninguém mais saber.
