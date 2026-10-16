---
title: Uma cadeia de três
version: 1
---

Para ver o que chamadas síncronas fazem umas com as outras, o laboratório monta uma cadeia: o checkout
da Quitanda pede ao preço o total da cesta, e o preço pergunta ao estoque se os itens existem. Os três
elos são o mesmo programinha com configurações diferentes. A aula trabalha em `~/lab/chain`:

```sh
mkdir -p ~/lab/chain && cd ~/lab/chain
```

`hop.py`, um elo da cadeia:

```schooling-example
{"language": "python", "file": "hop.py", "parts": [{"code": "\"\"\"A service that does some work and then asks the next one.\"\"\"\nimport json, os, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nNAME = os.environ[\"NAME\"]\nNEXT = os.environ.get(\"NEXT\")\nDELAY = int(os.environ.get(\"DELAY_MS\", \"0\")) / 1000\nTIMEOUT = float(os.environ[\"TIMEOUT_S\"]) if os.environ.get(\"TIMEOUT_S\") else None\n\n", "note": "Um elo de uma cadeia de serviços. Cada cópia faz DELAY_MS de trabalho e depois, se NEXT estiver definido, chama o próximo elo e espera a resposta dele, no máximo TIMEOUT_S segundos quando isso está definido e o tempo que for preciso quando não está."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        start = time.monotonic()\n        time.sleep(DELAY)\n        status, body = 200, {\"name\": NAME}\n        if NEXT:\n            try:\n                with urllib.request.urlopen(NEXT, timeout=TIMEOUT) as r:\n                    body[\"next\"] = json.loads(r.read())\n            except urllib.error.HTTPError as e:\n                status, body[\"error\"] = 502, f\"{NEXT} answered {e.code}\"\n                body[\"next\"] = json.loads(e.read())\n            except TimeoutError:\n                status, body[\"error\"] = 504, f\"{NEXT} did not answer within {TIMEOUT} s\"\n            except OSError as e:\n                status, body[\"error\"] = 502, f\"{NEXT} unreachable: {e}\"\n        body[\"took_ms\"] = round((time.monotonic() - start) * 1000)\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def log_message(self, fmt, *args):\n        print(f\"{NAME} {fmt % args}\", flush=True)\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "A resposta traz o nome deste elo, quanto a chamada inteira levou a partir daqui, e a resposta do próximo elo dentro dela, então uma resposta mostra a cadeia toda."}]}
```

`report.py` pertence a uma seção posterior desta aula; salve agora para ele estar na imagem:

```schooling-example
{"language": "python", "file": "report.py", "parts": [{"code": "\"\"\"Quitanda's monthly sales report, built in the background.\"\"\"\nimport json, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\njobs = {}\n\n\ndef build(job_id):\n    time.sleep(3)  # stands in for three seconds of queries\n    jobs[job_id] = {\"status\": \"done\", \"orders\": 412, \"revenue_cents\": 1893450}\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body, location=None):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        if location:\n            self.send_header(\"Location\", location)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n", "note": "Requisição e resposta assíncronas sobre HTTP comum. Um pedido para montar o relatório do mês é aceito na hora com `202 Accepted` e o endereço onde o resultado vai ficar; o trabalho roda em segundo plano, e o cliente pergunta nesse endereço até o relatório ficar pronto."}, {"code": "    def do_POST(self):\n        job_id = str(len(jobs) + 1)\n        jobs[job_id] = {\"status\": \"running\"}\n        threading.Thread(target=build, args=(job_id,)).start()\n        self.reply(202, {\"job\": job_id}, location=f\"/reports/{job_id}\")\n", "note": "O POST inicia um trabalho e retorna antes de ter feito qualquer parte dele."}, {"code": "    def do_GET(self):\n        job = jobs.get(self.path.rsplit(\"/\", 1)[-1])\n        self.reply(200, job) if job else self.reply(404, {\"error\": \"no such job\"})\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "O GET no endereço do trabalho diz até onde ele chegou. Um serviço de verdade guardaria os trabalhos num banco, não na memória, como a aula 4 explicou."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .\nCMD [\"python\", \"hop.py\"]", "note": "Uma imagem para todos os elos; o que diferencia cada elo é o ambiente dele."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  checkout:\n    build: .\n    environment: {NAME: checkout, NEXT: \"http://pricing:8000/\", DELAY_MS: \"100\"}\n    ports: [\"127.0.0.1:8000:8000\"]\n  pricing:\n    build: .\n    environment: {NAME: pricing, NEXT: \"http://stock:8000/\", DELAY_MS: \"100\", TIMEOUT_S: \"${PRICING_TIMEOUT_S:-}\"}\n  stock:\n    build: .\n    environment: {NAME: stock, DELAY_MS: \"${STOCK_DELAY_MS:-100}\"}", "note": "O checkout da Quitanda como uma cadeia: o checkout pergunta ao preço, o preço pergunta ao estoque. Cada elo faz 100 ms de trabalho próprio, e duas configurações podem ser mudadas pelo shell: quão lento o estoque é, e quanto o preço espera por ele."}, {"code": "  reports:\n    build: .\n    command: [\"python\", \"report.py\"]\n    ports: [\"127.0.0.1:8001:8000\"]", "note": "O relatório de vendas roda como serviço próprio, na porta 8001, e responde no estilo assíncrono da última seção."}]}
```

## Uma requisição pela cadeia

```
ana@vm:~/lab/chain$ docker compose ps --format "{{.Service}} {{.Status}} {{.Ports}}"
checkout Up 2 seconds 127.0.0.1:8000->8000/tcp
pricing Up 2 seconds 
reports Up 2 seconds 127.0.0.1:8001->8000/tcp
stock Up 2 seconds 
ana@vm:~/lab/chain$ curl -s localhost:8000/
{"name": "checkout", "next": {"name": "pricing", "next": {"name": "stock", "took_ms": 100}, "took_ms": 242}, "took_ms": 373}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um diagrama de sequência com quatro linhas de vida: o cliente, checkout, preço e estoque. A requisição do cliente vai ao checkout, que chama o preço, que chama o estoque. Cada um que chama aparece com uma barra de espera que dura até a resposta de baixo voltar, então o cliente espera a pilha inteira de trabalho.\"><defs><marker id=\"l5-wait-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><rect x=\"210\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">checkout</text><rect x=\"390\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">preço</text><rect x=\"570\" y=\"24\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estoque</text><path d=\"M90 56 L90 68\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M90 268 L90 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M270 56 L270 80\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M270 256 L270 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450 56 L450 92\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M450 244 L450 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630 56 L630 104\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M630 232 L630 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"84\" y=\"70\" width=\"12\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"264\" y=\"82\" width=\"12\" height=\"172\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"444\" y=\"94\" width=\"12\" height=\"148\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"106\" width=\"12\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M98 80 L262 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M262 262 L98 262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M278 92 L442 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M442 250 L278 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M458 104 L622 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><path d=\"M622 238 L458 238\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-wait-ah-phosphor)\"></path><text x=\"180\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">esperando</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">esperando</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">esperando</text><text x=\"680\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">trabalho</text></svg>", "caption": "Numa cadeia síncrona todo chamador espera tudo o que está abaixo dele. A espera do cliente é a soma de todo o trabalho, mais cada salto.", "same": ["checkout"]}
```

Leia a resposta de dentro para fora. O estoque fez os seus 100 ms de trabalho e respondeu em 100. O
preço fez os seus 100 ms, esperou o estoque e respondeu depois de 242. O checkout fez o mesmo por cima
e respondeu depois de 373. **O tempo de cada elo inclui tudo o que está abaixo dele**: o cliente esperou
o trabalho dos três serviços mais cada salto de rede entre eles, e cada salto ainda pagou a abertura de uma
conexão nova, já que o `urllib` abre uma por requisição.

Essa soma é o primeiro custo de uma cadeia. Um checkout que chama cinco serviços um depois do outro, cada
um levando 50 ms, não consegue responder em menos de 250 ms, por mais rápido que o próprio checkout seja.
Onde as chamadas não dependem umas das outras, fazê-las **em paralelo** transforma a soma na mais lenta
delas, que é uma das poucas otimizações que mudam a aritmética de uma cadeia em vez das constantes.
