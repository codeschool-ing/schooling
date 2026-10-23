---
title: WSGI e ASGI, o contrato por baixo dos dois
version: 1
---

A primeira seção disse que o servidor e o framework são dois programas. Eles podem ser dois programas
porque o Python define o que um diz ao outro, e o mesmo servidor roda qualquer framework que cumpra o
contrato. São dois contratos, e a lista de arquivos que o `startproject` imprimiu tem os dois:
`hello/wsgi.py` e `hello/asgi.py`.

## WSGI: uma chamada, uma resposta

O **WSGI**, Web Server Gateway Interface, é de 2003 e foi atualizado para o Python 3 em 2010 como a
PEP 3333. Uma aplicação é uma função que o servidor chama uma vez por requisição, com dois
argumentos: um dicionário que descreve a requisição e uma função para chamar com o status e os
cabeçalhos. O que ela devolve é o corpo. Isto é uma aplicação WSGI inteira, sem framework nenhum, e
um servidor da biblioteca padrão do Python para rodá-la:

```python
# wsgi_app.py
import json
from wsgiref.simple_server import make_server


def app(environ, start_response):
    name = environ["PATH_INFO"].removeprefix("/hello/")
    body = json.dumps({"greeting": f"Hello, {name}", "framework": None}).encode()
    start_response("200 OK", [("Content-Type", "application/json")])
    return [body]


if __name__ == "__main__":
    make_server("127.0.0.1", 8002, app).serve_forever()
```

## ASGI: mensagens, enviadas e recebidas

O **ASGI**, Asynchronous Server Gateway Interface, saiu do projeto Django em 2016 e chegou à versão
3.0 em 2019. Uma aplicação é uma função `async`, chamada com um dicionário que descreve a conexão,
`scope`, e duas funções, `receive` e `send`. Ela responde **mandando mensagens**: uma com o status e
os cabeçalhos, depois uma ou mais com o corpo.

```python
# asgi_app.py
import json


async def app(scope, receive, send):
    name = scope["path"].removeprefix("/hello/")
    body = json.dumps({"greeting": f"Hello, {name}", "framework": None}).encode()
    await send({
        "type": "http.response.start",
        "status": 200,
        "headers": [(b"content-type", b"application/json")],
    })
    await send({"type": "http.response.body", "body": body})
```

Salve as duas em `~/hello-fastapi`, cujo ambiente já tem o uvicorn. Rode a primeira com
`uv run python wsgi_app.py` e a segunda com `uv run uvicorn asgi_app:app --port 8003`, cada uma num
terminal próprio, e pergunte às duas:

```
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8002/hello/ana; echo
HTTP/1.0 200 OK
Date: Fri, 16 Oct 2026 22:19:00 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
Content-Length: 45

{"greeting": "Hello, ana", "framework": null}
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8003/hello/ana; echo
HTTP/1.1 200 OK
date: Fri, 16 Oct 2026 22:18:59 GMT
server: uvicorn
content-type: application/json
Transfer-Encoding: chunked

{"greeting": "Hello, ana", "framework": null}
```

A linha de servidor da primeira resposta é a que o `runserver` do Django mandou, `WSGIServer/0.2`:
**o `runserver` é o servidor WSGI da biblioteca padrão com a aplicação do Django dentro.** E a segunda
resposta veio em pedaços, `chunked`, porque a aplicação mandou os cabeçalhos antes de o servidor saber
o tamanho do corpo, que é exatamente o que um fluxo de mensagens permite.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas faixas. No WSGI, o servidor chama a aplicação uma vez com a requisição e recebe o corpo de volta como valor de retorno; a chamada bloqueia até a aplicação terminar. No ASGI, o servidor chama uma aplicação assíncrona com a conexão, e a aplicação manda uma mensagem com o status e os cabeçalhos, depois uma ou mais mensagens com o corpo, e também pode receber mensagens, enquanto o servidor atende outras conexões nesse meio-tempo.\"> <defs><marker id=\"ga-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ga-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">WSGI</text> <rect x=\"80\" y=\"44\" width=\"120\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">servidor</text> <rect x=\"464\" y=\"44\" width=\"240\" height=\"80\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"584\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aplicação</text> <text x=\"584\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">def app(environ, start_response)</text> <path d=\"M200 70 L458 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma chamada por requisição</text> <path d=\"M464 104 L206 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o valor de retorno é o corpo</text> <text x=\"20\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">ASGI</text> <rect x=\"80\" y=\"150\" width=\"120\" height=\"100\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">servidor</text> <rect x=\"464\" y=\"150\" width=\"240\" height=\"100\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.12\" stroke=\"var(--phosphor)\"></rect> <text x=\"584\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aplicação</text> <text x=\"584\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">async def app(scope, receive, send)</text> <path d=\"M200 166 L458 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-arrow)\"></path> <text x=\"332\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">chamada uma vez por conexão</text> <path d=\"M464 192 L206 192\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-amber)\"></path> <text x=\"332\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http.response.start</text> <path d=\"M464 218 L206 218\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ga-amber)\"></path> <text x=\"332\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http.response.body</text> <text x=\"332\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mensagens, enquanto atende outras conexões</text> </svg>", "caption": "O WSGI é uma chamada de função que bloqueia até retornar. O ASGI é uma conversa em mensagens, e enquanto uma aplicação espera, o servidor pode atender outra conexão.", "same": ["WSGI", "ASGI"]}
```

## Por que a diferença importa

**Uma chamada WSGI segura o seu worker até retornar.** Se a função passa dois segundos esperando
outro serviço, esse worker não faz mais nada por dois segundos, e um servidor com oito workers
responde no máximo oito requisições assim ao mesmo tempo. **Uma aplicação ASGI pode fazer `await` na
resposta lenta**, e o servidor atende outras conexões nesse meio-tempo. O ASGI também consegue manter
uma conexão aberta e mandar mensagens por ela sempre que houver algo a dizer, que é o que um
WebSocket precisa e o WSGI nem consegue expressar.

Esse é o tamanho honesto da vantagem: ela importa quando as requisições passam o tempo **esperando**,
e não faz nada por uma requisição que passa o tempo calculando. A aula 9 mede os dois casos.

Neste curso os pares são fixos. **O Django roda sob WSGI** nas aulas 2 a 16, como a maioria dos sites
Django, com o Gunicorn como servidor em produção; ele também roda sob ASGI, e a aula 9 mostra quando
isso ajuda. **O FastAPI roda só sob ASGI**, com o Uvicorn. Nenhum dos frameworks precisa mudar para o
servidor mudar, que é o propósito de um contrato.
