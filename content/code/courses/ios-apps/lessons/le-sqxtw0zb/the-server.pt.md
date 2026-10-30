---
title: Um servidor na sua própria máquina
version: 1
---

**Um app que fala com a rede precisa de algo do outro lado, e esta aula dá um que cabe numa
página.** O servidor do planner é um programa Python de umas setenta linhas que guarda os cursos e as
sessões na memória e responde a quatro pedidos. Ele não usa nada além da biblioteca padrão do Python,
então o Ubuntu da aula 1 já tem tudo de que ele precisa, e um Mac também.

Ele é um substituto, e diz isso. Um backend de verdade tem banco de dados, contas e um deploy, e é na
trilha `backend` que essas coisas são construídas. O que o app precisa dele neste curso é mais
estreito: **uma URL que responde com JSON, e que também sabe responder mal de propósito**, porque a
metade interessante do código de rede é o que ele faz quando a resposta não é a que ele esperava.

## O programa

Salve isto como `serve.py`, num diretório próprio, `~/server`:

```python
#!/usr/bin/env python3
# serve.py
# The study planner's server, for lessons 12 to 16 of ios-apps.
import json, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs

COURSES = [
    {"id": "sql", "title": "SQL Databases"},
    {"id": "mobile", "title": "Mobile Fundamentals"},
]
SESSIONS = [
    {"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": True},
    {"id": "s2", "courseId": "mobile", "date": "2026-10-20", "minutes": 40, "done": True},
    {"id": "s3", "courseId": "sql", "date": "2026-10-23", "minutes": 60, "done": False},
    {"id": "s4", "courseId": "mobile", "date": "2026-10-27", "minutes": 45, "done": False},
]


class Planner(BaseHTTPRequestHandler):
    def reply(self, status, body):
        data = (json.dumps(body) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            print(f"{self.command} {self.path}: the client had gone", flush=True)

    def do_GET(self):
        url = urlsplit(self.path)
        query = parse_qs(url.query, keep_blank_values=True)
        time.sleep(float(query.get("delay", ["0"])[0]))  # ?delay=3: answer slowly
        if "fail" in query:                               # ?fail: answer with an error
            return self.reply(500, {"error": "The server failed on purpose."})
        parts = url.path.strip("/").split("/")
        if parts == ["courses"]:
            return self.reply(200, COURSES)
        if len(parts) == 3 and parts[0] == "courses" and parts[2] == "sessions":
            if not any(c["id"] == parts[1] for c in COURSES):
                return self.reply(404, {"error": f"no course {parts[1]}"})
            return self.reply(200, [s for s in SESSIONS if s["courseId"] == parts[1]])
        self.reply(404, {"error": f"no such path {url.path}"})

    def do_POST(self):
        if self.path != "/sessions":
            return self.reply(404, {"error": f"no such path {self.path}"})
        try:
            s = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            fields = (s["id"], s["courseId"], s["date"], s["minutes"], s["done"])
        except (ValueError, KeyError, TypeError):
            return self.reply(400, {"error": "a session needs id, courseId, date, minutes and done"})
        if not any(c["id"] == s["courseId"] for c in COURSES):
            return self.reply(422, {"error": f"no course {s['courseId']}"})
        for kept in SESSIONS:
            if kept["id"] == s["id"]:  # the same session posted twice is kept once
                return self.reply(200, kept)
        SESSIONS.append(s)
        self.reply(201, s)

    def log_message(self, fmt, *args):  # one short line per request
        print(f"{self.command} {self.path} {args[1]}", flush=True)


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8012
print(f"the planner is on http://127.0.0.1:{port}", flush=True)
ThreadingHTTPServer(("127.0.0.1", port), Planner).serve_forever()
```

Três coisas nele estão ali para seções seguintes. `?delay=3` faz qualquer pedido esperar três
segundos antes de responder, que é como a seção 07 consegue um pedido lento o bastante para
cancelar. `?fail` transforma qualquer pedido num `500`, que é como a seção 06 consegue um erro que
ela não causou. Uma sessão enviada duas vezes com o mesmo `id` é guardada uma vez só, e a aula 14 se
apoia nisso. E **ele escuta só em `127.0.0.1`**, o endereço que quer dizer "esta máquina": nada mais
na sua rede o alcança, o que é certo para um programa sem senha que aceita qualquer coisa que você
enviar a ele.

## Iniciando o servidor, e perguntando algo a ele

O servidor roda até você pará-lo, então dê a ele um terminal só dele. Abra um segundo terminal, vá
para `~/server` e inicie-o ali. Esse terminal mostra uma linha quando ele começa e uma linha para
cada pedido que ele responde, e no fim desta aula ele estava assim:

```
ana@vm:~/server$ python3 serve.py
the planner is on http://127.0.0.1:8012
GET /courses 200
GET /courses/sql/sessions 200
GET /courses/art/sessions 404
GET /courses 200
GET /courses/sql/sessions 200
GET /courses 200
GET /courses/sql/sessions 200
POST /sessions 201
GET /courses/art/sessions 404
POST /sessions 422
GET /courses 200
GET /courses?fail 500
GET /courses?delay=3 200
GET /courses?delay=3: the client had gone
GET /courses?delay=3 200
GET /courses?delay=3: the client had gone
```

No seu primeiro terminal, peça os cursos com o `curl`, que imprime o corpo como ele chegou. O `-s`
o deixa calado sobre o próprio progresso, e o `-i` acrescenta a linha de status e os cabeçalhos
acima do corpo:

```
ana@vm:~/server$ curl -si http://127.0.0.1:8012/courses
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 30 Oct 2026 18:26:18 GMT
Content-Type: application/json
Content-Length: 92

[{"id": "sql", "title": "SQL Databases"}, {"id": "mobile", "title": "Mobile Fundamentals"}]
ana@vm:~/server$ curl -s http://127.0.0.1:8012/courses/sql/sessions
[{"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": true}, {"id": "s3", "courseId": "sql", "date": "2026-10-23", "minutes": 60, "done": false}]
ana@vm:~/server$ curl -si http://127.0.0.1:8012/courses/art/sessions
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 30 Oct 2026 18:26:18 GMT
Content-Type: application/json
Content-Length: 27

{"error": "no course art"}
```

**Este é o contrato inteiro contra o qual o app vai ser escrito**: um caminho, um código de status,
um `Content-Type` que diz JSON e um corpo no formato que o app espera. O último pedido pergunta por um
curso que não existe e recebe `404` com um corpo que diz por quê. Um app que só confere se veio um
corpo tentaria ler `{"error": …}` como uma lista de sessões, e a seção 05 é sobre não fazer isso.

`Ctrl-C` no terminal do servidor o para. As sessões que você envia ficam na memória, então pará-lo
também as esquece, e iniciá-lo de novo devolve as quatro sessões acima. Num curso isso é uma
vantagem: cada execução de cada aula começa dos mesmos dados.
