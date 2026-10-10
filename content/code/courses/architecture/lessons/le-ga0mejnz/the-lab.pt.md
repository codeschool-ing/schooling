---
title: O laboratório: um serviço com capacidade fixa
version: 1
---

O laboratório é um serviço de estoque e um cliente fazendo o papel do checkout. O serviço tem **uma
capacidade fixa**, que serviços de verdade também têm mesmo quando ninguém a mediu: quatro workers, 50
milissegundos cada por resposta, então 80 respostas por segundo. O cliente o chama num ritmo constante, e
as opções dele ligam cada técnica que a aula experimenta. Ele fica em `~/lab/resilience`:

```sh
mkdir -p ~/lab/resilience && cd ~/lab/resilience
```

`stock.py`, o serviço:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"A stock service with four workers, which can be told to fail or to freeze.\"\"\"\nimport json, random, threading, time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nworkers = threading.Semaphore(4)\nstate = {\"fail\": 0.0, \"frozen_until\": 0.0}\nstats = {\"answered\": 0, \"late\": 0}\nlock = threading.Lock()\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n", "note": "Um serviço de estoque com capacidade fixa: quatro workers, e toda resposta toma 50 milissegundos de um worker, então ele responde 80 requisições por segundo e nada mais. Requisições além disso esperam um worker, por ordem de chegada."}, {"code": "    def do_GET(self):\n        if self.path == \"/stats\":\n            with lock:\n                return self.reply(200, json.dumps(stats))\n        with workers:\n            time.sleep(max(0.0, state[\"frozen_until\"] - time.time()) + 0.05)\n        late = time.time() > float(self.headers.get(\"X-Deadline\", \"inf\"))\n        with lock:\n            stats[\"answered\"] += 1\n            stats[\"late\"] += late\n        if random.random() < state[\"fail\"]:\n            return self.reply(503, \"try again\")\n        self.reply(200, \"coffee: 12\")\n", "note": "Cada chamador manda o momento em que vai parar de esperar, em `X-Deadline`. O serviço não o usa para decidir nada; só conta as respostas terminadas depois de o chamador já ter desistido, que é trabalho feito para ninguém."}, {"code": "    def do_POST(self):\n        _, what, value = self.path.split(\"/\")\n        if what == \"fail\":\n            state[\"fail\"] = float(value)\n        elif what == \"freeze\":\n            state[\"frozen_until\"] = time.time() + float(value)\n        self.reply(200, f\"{what} {value}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "`POST /fail/0.2` faz uma resposta em cada cinco ser um `503`. `POST /freeze/3` para todo worker por três segundos, como uma pausa longa de coleta de lixo ou um failover do banco fariam."}]}
```

`client.py`, o lado do checkout:

```schooling-example
{"language": "python", "file": "client.py", "parts": [{"code": "\"\"\"Call the stock service at a steady rate, with or without retries, backoff and a breaker.\"\"\"\nimport argparse, json, random, threading, time, urllib.error, urllib.request\nfrom concurrent.futures import ThreadPoolExecutor\n\np = argparse.ArgumentParser()\np.add_argument(\"--rate\", type=int, default=60, help=\"requests a second\")\np.add_argument(\"--seconds\", type=int, default=30)\np.add_argument(\"--timeout\", type=float, default=0.5)\np.add_argument(\"--retries\", type=int, default=0)\np.add_argument(\"--backoff\", choices=[\"none\", \"jitter\"], default=\"none\")\np.add_argument(\"--breaker\", action=\"store_true\")\np.add_argument(\"--freeze-at\", type=int, help=\"second at which to freeze the service for 3 seconds\")\nargs = p.parse_args()\nSTOCK = \"http://stock:8000\"\nstart = time.time()\ncounts = {}  # two-second bucket -> {\"ok\": n, \"failed\": n, \"calls\": n}\nlock = threading.Lock()\n\n\ndef count(what, at=None):\n    bucket = int((at or time.time()) - start) // 2 * 2\n    with lock:\n        counts.setdefault(bucket, {\"ok\": 0, \"failed\": 0, \"calls\": 0})[what] += 1\n\n", "note": "O lado do checkout: ele pergunta ao serviço de estoque num ritmo constante e informa, para as requisições enviadas a cada dois segundos, quantas deram certo e quantas falharam, e quantas chamadas chegaram ao serviço nesses segundos, contando as novas tentativas. Toda opção é uma flag, então cada execução da aula é um comando."}, {"code": "class Breaker:\n    def __init__(self):\n        self.failures, self.open_until, self.probing = 0, 0.0, False\n        self.lock = threading.Lock()\n\n    def allow(self):\n        with self.lock:\n            if self.failures < 5:\n                return True\n            if time.time() < self.open_until or self.probing:\n                return False\n            self.probing = True\n            return True\n\n    def record(self, ok):\n        with self.lock:\n            self.probing = False\n            self.failures = 0 if ok else self.failures + 1\n            if self.failures >= 5:\n                self.open_until = time.time() + 2\n\n\nbreaker = Breaker() if args.breaker else None\n\n\ndef call():\n    if breaker and not breaker.allow():\n        return False\n    count(\"calls\")\n    req = urllib.request.Request(STOCK + \"/stock/coffee\",\n                                 headers={\"X-Deadline\": str(time.time() + args.timeout)})\n    try:\n        with urllib.request.urlopen(req, timeout=args.timeout):\n            ok = True\n    except (urllib.error.URLError, TimeoutError, ConnectionError):\n        ok = False\n    if breaker:\n        breaker.record(ok)\n    return ok\n\n", "note": "O circuit breaker. Depois de cinco falhas seguidas ele abre, e nos dois segundos seguintes toda chamada falha na hora sem chegar ao serviço. Depois ele deixa uma chamada passar, meio aberto: se ela der certo ele fecha, e se falhar ele abre de novo."}, {"code": "def request():\n    sent = time.time()\n    for attempt in range(1 + args.retries):\n        if attempt and args.backoff == \"jitter\":\n            time.sleep(random.uniform(0, 0.1 * 2 ** (attempt - 1)))\n        if call():\n            return count(\"ok\", sent)\n    count(\"failed\", sent)\n\n\ndef freeze():\n    time.sleep(args.freeze_at)\n    urllib.request.urlopen(urllib.request.Request(STOCK + \"/freeze/3\", method=\"POST\")).read()\n\n\ndef stats():\n    with urllib.request.urlopen(STOCK + \"/stats\") as r:\n        return json.load(r)\n\n", "note": "Uma requisição do checkout: a primeira chamada, e até `--retries` outras se ela falhar. Com `--backoff jitter` ela espera antes de cada nova tentativa, um tempo aleatório até 0,1, 0,2, 0,4 segundo e assim por diante, dobrando a cada vez."}, {"code": "def report(before):\n    after = stats()\n    while True:\n        time.sleep(1)\n        now, after = after, stats()\n        if now == after:\n            break\n    print(f\"the stock service answered {after['answered'] - before['answered']} calls, \"\n          f\"{after['late'] - before['late']} of them after the caller had given up\")\n\n\nbefore = stats()\nif args.freeze_at is not None:\n    threading.Thread(target=freeze, daemon=True).start()\nwith ThreadPoolExecutor(max_workers=2000) as pool:\n    for n in range(args.rate * args.seconds):\n        time.sleep(max(0.0, start + n / args.rate - time.time()))\n        pool.submit(request)\nprint(\" second      ok  failed   calls\")\nfor bucket in sorted(counts):\n    c = counts[bucket]\n    print(f\"{bucket:3}-{bucket + 2:<3}  {c['ok']:6}  {c['failed']:6}  {c['calls']:6}\")\nreport(before)", "note": "No fim o cliente espera o serviço parar de responder chamadas, porque uma chamada da qual o cliente desistiu ainda está na fila do serviço, e informa o que o serviço fez nesta execução: quantas chamadas respondeu, e quantas delas depois de o chamador ter parado de esperar."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Os dois programas usam só a biblioteca padrão do Python."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  stock:\n    build: .\n    command: python stock.py\n    ports:\n      - \"8001:8000\"\n  client:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"client.py\"]\n    depends_on:\n      - stock", "note": "O serviço de estoque, acessível da máquina na porta 8001 para o `curl`, e o cliente do checkout, que só roda quando pedido."}]}
```

Suba o serviço, e guarde numa variável o comando que roda o cliente:

```sh
docker compose up -d --build
C="docker compose --progress quiet run --rm client"
```

Primeiro uma execução saudável: 60 requisições por segundo durante dez segundos, três quartos da
capacidade do serviço, com o timeout padrão de meio segundo e sem retries:

```
ana@vm:~/lab/resilience$ $C --seconds 10
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8       120       0     120
  8-10      120       0     120
the stock service answered 600 calls, 0 of them after the caller had given up
```

Toda requisição deu certo, cada uma fez exatamente uma chamada, e o serviço respondeu todas a tempo. É a
base para tudo o que vem depois.
