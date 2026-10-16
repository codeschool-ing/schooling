---
title: O mesmo endpoint, escrito duas vezes
version: 1
---

O jeito mais rápido de ver o que cada framework supõe é fazer os dois executarem a mesma coisa
pequena. A coisa é um endpoint: `GET /hello/<name>` responde com uma saudação curta em JSON. Os dois
projetos moram no seu diretório pessoal, lado a lado, e os dois são projetos uv, que a aula 19 de
`python` apresentou.

## Django

```
ana@vm:~$ mkdir hello-django && cd hello-django && uv init --bare
Initialized project `hello-django`
ana@vm:~/hello-django$ uv add django
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 5 packages in 300ms
Downloading django (8.0MiB)
 Downloaded django
Prepared 3 packages in 1.63s
Installed 3 packages in 405ms
 + asgiref==3.12.1
 + django==6.1.2
 + sqlparse==0.6.0
ana@vm:~/hello-django$ uv run django-admin startproject hello .
ana@vm:~/hello-django$ find . -path ./.venv -prune -o -type f -print | sort
./hello/__init__.py
./hello/asgi.py
./hello/settings.py
./hello/urls.py
./hello/wsgi.py
./manage.py
./pyproject.toml
./uv.lock
```

O `uv init --bare` escreve só o `pyproject.toml`; o Django traz o próprio esqueleto. O
`startproject` criou um pacote chamado `hello` com cinco arquivos e um `manage.py` ao lado, **antes
de existir uma única linha sua**. A aula 2 passa por cada um deles. Por enquanto, troque todo o
conteúdo de `hello/urls.py` por isto:

```python
# hello/urls.py
from django.http import JsonResponse
from django.urls import path


def hello(request, name):
    return JsonResponse({"greeting": f"Hello, {name}", "framework": "Django"})


urlpatterns = [
    path("hello/<str:name>", hello),
]
```

A função recebe a requisição e devolve uma resposta. A lista no fim diz qual URL roda essa função, e
`<str:name>` é a parte do caminho que vira o argumento. Suba o servidor de desenvolvimento neste
terminal:

```
ana@vm:~/hello-django$ uv run python manage.py runserver 8000
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).

You have 18 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
Run 'python manage.py migrate' to apply them.
October 16, 2026 - 22:18:47
Django version 6.1.2, using settings 'hello.settings'
Starting WSGI development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.

WARNING: This is a development server. Do not use it in a production setting. Use a production WSGI or ASGI server instead.
For more information on production servers see: https://docs.djangoproject.com/en/6.1/howto/deployment/
```

Ele continua rodando, e imprimindo uma linha por requisição, até você apertar Ctrl-C. **Abra um
segundo terminal** e pergunte a ele:

```
ana@vm:~/hello-django$ curl -si http://127.0.0.1:8000/hello/ana; echo
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:18:50 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
X-Frame-Options: DENY
Content-Length: 49
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin
Cross-Origin-Opener-Policy: same-origin

{"greeting": "Hello, ana", "framework": "Django"}
ana@vm:~/hello-django$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/goodbye/ana
404
```

O `-s` cala o medidor de progresso do curl, o `-i` mostra os cabeçalhos, e o `echo` devolve o prompt
para uma linha própria, já que o corpo termina sem quebra de linha.

## FastAPI

No segundo terminal, um segundo projeto:

```
ana@vm:~$ mkdir hello-fastapi && cd hello-fastapi && uv init --bare
Initialized project `hello-fastapi`
ana@vm:~/hello-fastapi$ uv add fastapi uvicorn
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 15 packages in 396ms
Downloading pydantic-core (2.1MiB)
 Downloaded pydantic-core
Prepared 14 packages in 164ms
Installed 14 packages in 8ms
 + annotated-doc==0.0.5
 + annotated-types==0.8.0
 + anyio==4.15.1
 + click==8.5.0
 + fastapi==0.143.3
 + h11==0.16.0
 + idna==3.20
 + opentelemetry-api==1.45.1
 + pydantic==2.14.1
 + pydantic-core==2.50.1
 + starlette==1.8.0
 + typing-extensions==4.16.0
 + typing-inspection==0.4.4
 + uvicorn==0.54.0
```

**Foram pedidos dois pacotes, porque o FastAPI não é um servidor.** O `uvicorn` é o programa que
escuta na porta e chama o FastAPI; o `runserver` do Django fazia os dois trabalhos dentro de um
comando só. A aplicação inteira é um arquivo, `main.py`, no diretório do projeto:

```python
# main.py
from fastapi import FastAPI

app = FastAPI()


@app.get("/hello/{name}")
def hello(name: str):
    return {"greeting": f"Hello, {name}", "framework": "FastAPI"}
```

O decorador é a rota: o método, o caminho, e `{name}` como a parte variável. A função devolve um
dicionário, e o FastAPI o transforma em JSON. Suba, neste terminal:

```
ana@vm:~/hello-fastapi$ uv run uvicorn main:app --port 8001
INFO:     Started server process [275]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
```

`main:app` se lê como "o objeto `app` no módulo `main`". **Abra um terceiro terminal** e pergunte:

```
ana@vm:~/hello-fastapi$ curl -si http://127.0.0.1:8001/hello/ana; echo
HTTP/1.1 200 OK
date: Fri, 16 Oct 2026 22:18:59 GMT
server: uvicorn
content-length: 47
content-type: application/json

{"greeting":"Hello, ana","framework":"FastAPI"}
ana@vm:~/hello-fastapi$ curl -s http://127.0.0.1:8001/openapi.json | head -c 160; echo
{"openapi":"3.1.0","info":{"title":"FastAPI","version":"0.1.0"},"paths":{"/hello/{name}":{"get":{"summary":"Hello","operationId":"hello_hello__name__get","param
```

## O que as duas respostas dizem

Os corpos concordam; todo o resto em volta deles são os frameworks falando de si mesmos.

- **O Django mandou quatro cabeçalhos que ninguém pediu**: `X-Frame-Options: DENY`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy` e `Cross-Origin-Opener-Policy`. Eles vêm de
  middleware que o `startproject` ligou, e cada um manda o navegador recusar algo que ele permitiria,
  como mostrar a sua página dentro do frame de outro site. **O FastAPI não mandou nenhum.** A aula 16
  os acrescenta na frente dele.
- **O FastAPI publicou uma descrição do endpoint que ninguém escreveu**: `/openapi.json` dá o
  caminho, o método e o parâmetro, e a aula 8 transforma isso numa página de documentação. O Django
  não tem nada nesse endereço.
- **O Django já espera um banco.** As "18 unapplied migrations" são as tabelas que os apps embutidos
  dele querem, usuários, sessões e o admin, para um endpoint que não usa nenhum deles.
- **Os tamanhos seguem as suposições.**

```
ana@vm:~$ for p in hello-django hello-fastapi; do echo "$p: $(cd $p && uv pip list 2>/dev/null | tail -n +3 | wc -l) packages, $(du -sh $p/.venv | cut -f1) in .venv"; done
hello-django: 3 packages, 47M in .venv
hello-fastapi: 14 packages, 17M in .venv
```

**O Django são três pacotes e 47 MB; o FastAPI são catorze pacotes e 17 MB.** O Django é um pacote
grande porque carrega tudo da tabela da primeira seção, incluindo as páginas do admin e traduções
para dezenas de idiomas. O FastAPI são peças pequenas, cada uma com um trabalho, e mais delas chegam
conforme a aplicação pede: uma camada de banco na aula 10, um hasher de senhas na aula 11.

Deixe os dois projetos onde estão. Aperte Ctrl-C nos dois terminais com servidores antes da próxima
aula, que começa o projeto de verdade do zero.
