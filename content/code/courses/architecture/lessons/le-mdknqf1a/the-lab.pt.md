---
title: O laboratório: Consul, Traefik e três instâncias
version: 1
---

Três instâncias do serviço de estoque, o **Consul** como registro, e o **Traefik** como gateway na frente
delas. Nem o Consul nem o Traefik ficam sabendo das instâncias de antemão: as instâncias se registram
sozinhas, e o gateway aprende sobre elas pelo registro. Ele fica em `~/lab/gateway`:

```sh
mkdir -p ~/lab/gateway && cd ~/lab/gateway
```

`stock.py`, uma instância que se registra sozinha:

```schooling-example
{"language": "python", "file": "stock.py", "parts": [{"code": "\"\"\"A stock instance that registers itself with Consul and reports its health.\"\"\"\nimport json, os, signal, socket, sys, time, urllib.error, urllib.request\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nNAME = os.environ[\"NAME\"]\nCONSUL = \"http://consul:8500\"\nADDRESS = socket.gethostbyname(socket.gethostname())\nstate = {\"healthy\": True}\n\n\ndef consul(method, path, body=None):\n    req = urllib.request.Request(CONSUL + path, method=method,\n                                 data=json.dumps(body).encode() if body is not None else None)\n    urllib.request.urlopen(req).read()\n\n", "note": "Uma instância do serviço de estoque que se registra sozinha. Ao subir ela diz ao agente Consul local o nome, o endereço e como conferir a saúde dela; numa parada limpa ela se desregistra. `POST /sick` faz o health check dela falhar, como um processo que perdeu a conexão com o banco deveria se reportar."}, {"code": "def register(body):\n    while True:\n        try:\n            return consul(\"PUT\", \"/v1/agent/service/register\", body)\n        except urllib.error.URLError:\n            time.sleep(1)\n\n", "note": "O Consul pode ainda estar subindo quando a instância sobe, então o registro é tentado de novo a cada segundo até o Consul responder."}, {"code": "register({\n    \"ID\": NAME, \"Name\": \"stock\", \"Address\": ADDRESS, \"Port\": 8000,\n    \"Tags\": [\"traefik.enable=true\",\n             \"traefik.http.routers.stock.rule=PathPrefix(`/stock`)\",\n             \"traefik.http.routers.stock.middlewares=stock-limit\",\n             \"traefik.http.middlewares.stock-limit.ratelimit.average=5\",\n             \"traefik.http.middlewares.stock-limit.ratelimit.burst=5\"],\n    \"Check\": {\"HTTP\": f\"http://{ADDRESS}:8000/health\", \"Interval\": \"2s\",\n              \"DeregisterCriticalServiceAfter\": \"1m\"},\n})\n\n", "note": "O registro. As tags não são para o Consul: são lidas pelo gateway, que manda `/stock` para toda instância saudável de `stock` e limita cada cliente a cinco requisições por segundo, com rajada de cinco."}, {"code": "def stop(*_):\n    consul(\"PUT\", f\"/v1/agent/service/deregister/{NAME}\")\n    sys.exit(0)\n\n\nsignal.signal(signal.SIGTERM, stop)\n\n\nclass Handler(BaseHTTPRequestHandler):\n    def reply(self, code, text):\n        body = (text + \"\\n\").encode()\n        self.send_response(code)\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)\n\n    def do_GET(self):\n        if self.path == \"/health\":\n            return self.reply(200 if state[\"healthy\"] else 503, \"ok\" if state[\"healthy\"] else \"sick\")\n        self.reply(200, f\"{NAME}: coffee 12\")\n\n    def do_POST(self):\n        state[\"healthy\"] = self.path != \"/sick\"\n        self.reply(200, f\"{NAME}: {'healthy' if state['healthy'] else 'sick'}\")\n\n    def log_message(self, *args):\n        pass\n\n\nThreadingHTTPServer((\"\", 8000), Handler).serve_forever()", "note": "Uma parada limpa tira a instância do registro na hora, em vez de deixar o gateway descobrir por um health check que falhou."}]}
```

`where.py`, um cliente perguntando ao registro:

```schooling-example
{"language": "python", "file": "where.py", "parts": [{"code": "\"\"\"List the healthy instances of a service, from Consul.\"\"\"\nimport json, sys, urllib.request\n\nwith urllib.request.urlopen(f\"http://consul:8500/v1/health/service/{sys.argv[1]}?passing\") as r:\n    entries = json.load(r)\nprint(f\"{len(entries)} healthy instance(s) of {sys.argv[1]}\")\nfor e in sorted(entries, key=lambda e: e[\"Service\"][\"ID\"]):\n    print(f\"  {e['Service']['ID']} at {e['Service']['Address']}:{e['Service']['Port']}\")", "note": "Descoberta, do jeito que uma biblioteca cliente faz: perguntar ao registro as instâncias de um serviço que estão passando nos health checks, e imprimir onde estão."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY *.py .", "note": "Os dois programas usam só a biblioteca padrão do Python."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  consul:\n    image: hashicorp/consul:1.20.2\n    command: agent -dev -client 0.0.0.0 -log-level warn", "note": "O Consul, como um servidor em modo de desenvolvimento, que guarda tudo em memória. Um cluster de verdade roda três ou cinco servidores, pelos motivos da aula 10."}, {"code": "  gateway:\n    image: traefik:v3.3.4\n    command:\n      - --entrypoints.web.address=:80\n      - --providers.consulcatalog=true\n      - --providers.consulcatalog.endpoint.address=consul:8500\n      - --providers.consulcatalog.exposedbydefault=false\n      - --providers.consulcatalog.refreshinterval=2s\n    ports:\n      - \"8080:80\"\n    depends_on:\n      - consul", "note": "O gateway: o Traefik, lendo as rotas do catálogo do Consul, para aprender sobre cada instância pelo registro e mandar tráfego só para as saudáveis. É a única porta da loja, na porta 8080 da máquina."}, {"code": "  stock-1:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-1}\n    ports: [\"8001:8000\"]\n    depends_on: [consul]\n  stock-2:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-2}\n    ports: [\"8002:8000\"]\n    depends_on: [consul]\n  stock-3:\n    build: .\n    command: python stock.py\n    environment: {NAME: stock-3}\n    ports: [\"8003:8000\"]\n    depends_on: [consul]\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"where.py\"]", "note": "Três instâncias do serviço de estoque, que não sabem nada umas das outras nem do gateway; cada uma só avisa o Consul que existe. As portas 8001 a 8003 deixam o `curl` alcançar cada uma diretamente."}]}
```

Suba tudo, dê quinze segundos, e guarde numa variável o comando do `where.py`:

```sh
docker compose up -d --build
D="docker compose --progress quiet run --rm tools"
```

O gateway responde na porta 8080 e aplica um limite de taxa, então os laços da aula fazem pausas entre as
requisições para ficar abaixo dele; o limite ganha uma seção própria.
