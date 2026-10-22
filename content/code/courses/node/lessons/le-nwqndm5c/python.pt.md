---
title: Python
version: 1
---

**O Python é a linguagem que a maioria das pessoas conhece primeiro, e nos servidores é onde dados,
scripts e aprendizado de máquina encontram a web.** O Ubuntu já vem com ele, porque partes do sistema
são escritas nele:

```sh
python3 --version                 # Ubuntu and WSL: already there
brew install python               # a Mac, with Homebrew (not run for this course)
```

```
ana@dev:~/server/other/python$ python3 --version
Python 3.12.3
```

O servidor, só com a biblioteca padrão:

```schooling-example
{"language": "python", "file": "hello.py", "parts": [
 {"code": "# hello.py: the same server in Python, with nothing but the standard library.\nimport json\nimport os\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlparse", "note": "**Os imports dizem o que pegam**, como o `import { … } from` num módulo. O `http.server` é o equivalente do Python ao `node:http`."},
 {"code": "class Handler(BaseHTTPRequestHandler):\n    def send(self, status, body):\n        data = json.dumps(body).encode()\n        self.send_response(status)\n        self.send_header(\"content-type\", \"application/json\")\n        self.send_header(\"content-length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "**Uma classe com um método por verbo HTTP.** O servidor chama o `do_GET` a cada GET, num objeto feito para aquele pedido. A indentação é a sintaxe: não há chaves, e um bloco é o que está indentado embaixo da sua linha."},
 {"code": "    def do_GET(self):\n        url = urlparse(self.path)\n        if url.path == \"/hello\":\n            name = parse_qs(url.query).get(\"name\", [\"world\"])[0]\n            return self.send(200, {\"hello\": name})\n        if url.path == \"/slow\":\n            time.sleep(1)\n            return self.send(200, {\"slept\": 1000})\n        self.send(404, {\"error\": f\"nothing at {url.path}\"})", "note": "**O `time.sleep(1)` bloqueia**, o que no Node pararia todo pedido. Aqui ele para só este, porque cada pedido tem uma thread própria: o `ThreadingHTTPServer`, abaixo."},
 {"code": "port = int(os.environ.get(\"PORT\", \"3000\"))\nprint(f\"python on :{port}\", flush=True)\nThreadingHTTPServer((\"127.0.0.1\", port), Handler).serve_forever()", "note": "O `os.environ` é o `process.env`, e uma string `f\"…\"` é um template literal."}
]}
```

```
ana@dev:~/server/other/python$ python3 hello.py
python on :3000
127.0.0.1 - - [22/Oct/2026 20:11:16] "GET /hello?name=ana HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:16] "GET /nope HTTP/1.1" 404 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
127.0.0.1 - - [22/Oct/2026 20:11:17] "GET /slow HTTP/1.1" 200 -
^C
```

```
ana@dev:~/server/other/python$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello": "ana"}
ana@dev:~/server/other/python$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error": "nothing at /nope"} 404
ana@dev:~/server/other/python$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.015s
user	0m0.030s
sys	0m0.020s
```

**As mesmas respostas, com uma diferença nos bytes**: o `json.dumps` do Python põe um espaço depois de
cada dois-pontos, o que um leitor de JSON ignora e um teste que compara strings não ignoraria. E o
servidor escreve sozinho uma linha de log por pedido, no primeiro terminal.

**Dez pedidos lentos levaram um segundo** porque cada um ganhou uma thread própria, que é o caminho
contrário ao do Node: o Python bloqueia e roda muitas threads, o Node não bloqueia e roda uma. A seção
sobre modelos de concorrência mede quanto isso custa quando o trabalho é calcular em vez de esperar.

## O que um serviço Python de verdade usa

A própria documentação do Python diz que o `http.server` não é para produção, e ninguém o usa lá. As
escolhas de costume:

| o quê | em termos de Node |
|---|---|
| **FastAPI**, ou **Flask**, para uma API | Express |
| **Django**, um framework com camada de banco, admin e templates incluídos | sem equivalente único |
| `uvicorn` ou `gunicorn`, o servidor que roda a aplicação | `node server.js` |
| `pip`, e um **ambiente virtual** (`python3 -m venv .venv`) por projeto | `npm`, e o `node_modules/` |
| `requirements.txt` ou `pyproject.toml` | `package.json` |

O ambiente virtual é a parte de que o Node não precisa. O `npm` instala dentro do projeto por padrão,
e o `pip` instala no sistema inteiro a menos que um `venv` esteja ativo, e é por isso que o Ubuntu hoje
recusa um `pip install` simples fora de um.
