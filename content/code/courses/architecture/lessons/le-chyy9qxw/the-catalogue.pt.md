---
title: Um catálogo escrito pelos fatores
version: 1
---

O programa da aula é de novo o catálogo da Quitanda, desta vez com PostgreSQL em vez de um arquivo
SQLite, porque um servidor de banco de verdade é o serviço de apoio de que a maioria dos fatores
trata. Ele mora em `~/lab/twelve`:

```sh
mkdir -p ~/lab/twelve && cd ~/lab/twelve
```

`catalogue.py`:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [{"code": "\"\"\"Quitanda's catalogue, written to the twelve factors.\"\"\"\nimport json, os, signal, socket, sys, threading\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport psycopg\n\nDATABASE_URL = os.environ.get(\"DATABASE_URL\")\nif not DATABASE_URL:\n    sys.exit(\"DATABASE_URL is not set: give the catalogue the address of its database\")\nPORT = int(os.environ.get(\"PORT\", \"8000\"))\nHOST = socket.gethostname()\nhits = 0\n", "note": "O catálogo da Quitanda como uma aplicação de doze fatores. Toda configuração vem do ambiente (III), e a única sem a qual nada funciona, o endereço do banco, para o programa na hora com uma frase dizendo o que falta."}, {"code": "PRODUCTS = [(\"tomato\", \"Tomatoes, 1 kg\", 899), (\"banana\", \"Bananas, 1 kg\", 649),\n            (\"coffee\", \"Coffee beans, 500 g\", 3290), (\"cheese\", \"Minas cheese, 500 g\", 2450),\n            (\"bread\", \"Bread rolls, 6\", 990)]\n\n\ndef migrate():\n    with psycopg.connect(DATABASE_URL) as con:\n        con.execute(\"CREATE TABLE IF NOT EXISTS products (sku text PRIMARY KEY, name text, price_cents int)\")\n        for p in PRODUCTS:\n            con.execute(\"INSERT INTO products VALUES (%s, %s, %s) ON CONFLICT DO NOTHING\", p)\n    print(f\"migrated: {len(PRODUCTS)} products\", flush=True)\n\n", "note": "A tarefa administrativa (XII) faz parte do mesmo programa: `python catalogue.py migrate` cria a tabela e os produtos e sai. Ela roda com o mesmo código e a mesma configuração do serviço."}, {"code": "class Handler(BaseHTTPRequestHandler):\n    def reply(self, status, body):\n        data = (json.dumps(body) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)\n\n    def do_GET(self):\n        global hits\n        hits += 1\n        if self.path == \"/products\":\n            with psycopg.connect(DATABASE_URL) as con:\n                rows = con.execute(\"SELECT sku, price_cents FROM products ORDER BY sku\").fetchall()\n            self.reply(200, {\"served_by\": HOST, \"products\": dict(rows)})\n        elif self.path == \"/hits\":\n            self.reply(200, {\"served_by\": HOST, \"hits\": hits})\n        else:\n            self.reply(404, {\"error\": \"not found\"})\n", "note": "O serviço. `/products` lê o banco de apoio (IV). `/hits` conta requisições na memória deste processo, que é exatamente o que o fator VI diz para não fazer; está ali para ser visto falhando."}, {"code": "    def log_message(self, fmt, *args):\n        print(f\"{HOST} {fmt % args}\", flush=True)\n\n", "note": "Os logs vão para a saída padrão, uma linha por requisição, e para nenhum outro lugar (XI). Coletar e guardar é trabalho da plataforma."}, {"code": "def serve():\n    server = ThreadingHTTPServer((\"\", PORT), Handler)\n    server.daemon_threads = False\n\n    def stop(signum, frame):\n        print(f\"{HOST} SIGTERM: finishing requests in progress, then exiting\", flush=True)\n        threading.Thread(target=server.shutdown).start()\n\n    signal.signal(signal.SIGTERM, stop)\n    print(f\"{HOST} catalogue listening on :{PORT}\", flush=True)\n    server.serve_forever()\n    server.server_close()\n    print(f\"{HOST} stopped\", flush=True)\n\n\nif __name__ == \"__main__\":\n    migrate() if sys.argv[1:] == [\"migrate\"] else serve()", "note": "Descartabilidade (IX): no SIGTERM o servidor para de aceitar requisições novas, deixa as que estão em andamento terminarem, e o processo sai. Sem o handler, o Python rodando como primeiro processo do contêiner ignoraria o SIGTERM, e o Docker esperaria dez segundos e o mataria."}]}
```

`requirements.txt`:

```schooling-example
{"language": "sh", "file": "requirements.txt", "parts": [{"code": "psycopg[binary]==3.3.6", "note": "Dependências declaradas, com versões exatas (II). A imagem instala esta lista e mais nada, então dois builds com um mês de distância recebem a mesma biblioteca."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY catalogue.py .\nCMD [\"python\", \"catalogue.py\"]", "note": "Build (V): primeiro as dependências, para uma mudança no código reaproveitar a camada delas, depois o código. A imagem que sai é a mesma em todo ambiente."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  catalogue:\n    build: .\n    image: quitanda/catalogue:${TAG:-dev}\n    environment:\n      DATABASE_URL: ${DATABASE_URL:-postgresql://quitanda:quitanda@db:5432/quitanda}\n      PORT: \"8000\"\n    ports:\n      - \"127.0.0.1:8000-8002:8000\"\n    depends_on:\n      db:\n        condition: service_healthy", "note": "A release (V) é esta imagem mais esta configuração. O banco é um serviço de apoio (IV), nomeado só por uma URL; `${DATABASE_URL:-…}` pega a URL do ambiente do shell quando há uma ali, e a tag da imagem vem de TAG do mesmo jeito."}, {"code": "  db:\n    image: postgres:17\n    environment:\n      POSTGRES_USER: quitanda\n      POSTGRES_PASSWORD: quitanda\n    healthcheck:\n      test: [\"CMD\", \"pg_isready\", \"-U\", \"quitanda\"]\n      interval: 2s\n      retries: 15", "note": "A mesma versão principal do Postgres que a produção (X), com um health check, para o catálogo só iniciar quando o banco aceitar conexões."}]}
```

## I, base de código: um diretório, muitas implantações

Tudo acima é uma base de código. Num projeto de verdade é um repositório, e **o mesmo commit é
implantado em todo lugar**: no seu laptop, em homologação, em produção. Dois programas dividindo um
repositório é um monorepo, o que está certo; um programa cuja cópia de produção mora num repositório
diferente da cópia de desenvolvimento não está, porque as duas se distanciam e ninguém sabe dizer qual
está rodando.

## II, dependências: declaradas e isoladas

`catalogue.py` importa `psycopg`, e `requirements.txt` diz exatamente que versão. A imagem instala essa
lista e mais nada, então o programa nunca depende de algo que por acaso está numa máquina. Construa,
rode a tarefa administrativa que cria a tabela, e inicie o serviço:

```
ana@vm:~/lab/twelve$ docker compose build --quiet
 Image quitanda/catalogue:dev Building 
 Image quitanda/catalogue:dev Built 
ana@vm:~/lab/twelve$ docker compose run --rm catalogue python catalogue.py migrate
 Network twelve_default Creating 
 Network twelve_default Creating 
 Network twelve_default Created 
 Network twelve_default Created 
 Container twelve-db-1 Creating 
 Container twelve-db-1 Created 
 Container twelve-db-1 Starting 
 Container twelve-db-1 Started 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-d2ea61a78579 Creating 
 Container twelve-catalogue-run-d2ea61a78579 Created 
migrated: 5 products
ana@vm:~/lab/twelve$ docker compose up -d
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Creating 
 Container twelve-catalogue-1 Created 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
```

Dentro do contêiner, os pacotes instalados são o declarado e aquilo de que ele depende:

```
ana@vm:~/lab/twelve$ docker compose exec catalogue pip freeze
psycopg==3.3.6
psycopg-binary==3.3.6
typing_extensions==4.16.0
```

**`psycopg-binary` e `typing_extensions` nunca foram escritos por você**; `psycopg[binary]` os puxou.
Fixar só o primeiro nível deixa esses livres para mudar entre dois builds. Ferramentas como
`pip-compile`, o arquivo de lock do Poetry, `package-lock.json` no Node ou `go.sum` no Go anotam a
árvore inteira, e um build a partir do arquivo de lock recebe as mesmas versões sempre.

E o serviço responde, a partir do banco dele:

```
ana@vm:~/lab/twelve$ curl -s localhost:8000/products
{"served_by": "144d3a898221", "products": {"banana": 649, "bread": 990, "cheese": 2450, "coffee": 3290, "tomato": 899}}
```

`served_by` é o hostname do contêiner, que o Docker define como o começo do id dele. Ele importa na
seção sobre processos, onde vão ser três.
