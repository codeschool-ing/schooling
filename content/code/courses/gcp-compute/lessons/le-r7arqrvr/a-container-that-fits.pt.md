---
title: Um contêiner que cabe, montado e rodado em casa
version: 1
---

O serviço de pedidos da loja é o programa que as próximas quatro lições publicam, dividem, agendam
e carregam. **Ele é pequeno de propósito: umas cinquenta linhas de Python sem dependências, e um
Dockerfile de cinco linhas.** Tudo nele está lá porque o contrato da seção anterior pede, e nada
nele é específico do Google.

## O programa

**Crie uma pasta `orders` em `~/gcp` e salve isto como `app.py` dentro dela:**

```python
# orders/app.py
"""The shop's orders service: a small HTTP API that keeps Cloud Run's contract."""
import json
import os
import signal
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ORDERS = [
    {'id': 1001, 'item': 'notebook', 'quantity': 2},
    {'id': 1002, 'item': 'pencil', 'quantity': 12},
]
DELAY = int(os.environ.get('ORDERS_DELAY_MS', '0')) / 1000


def log(message):
    print(json.dumps({'severity': 'INFO', 'message': message}), flush=True)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.reply(200, {'status': 'ok'})
        elif self.path == '/orders':
            time.sleep(DELAY)
            self.reply(200, {'orders': ORDERS, 'revision': os.environ.get('K_REVISION', 'local')})
        else:
            self.reply(404, {'error': 'not found'})

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        log(fmt % args)


def stop(signum, frame):
    log('SIGTERM: shutting down')
    sys.exit(0)


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, stop)
    port = int(os.environ.get('PORT', '8080'))
    server = ThreadingHTTPServer(('0.0.0.0', port), Handler)
    log(f'listening on {port}')
    server.serve_forever()
```

Leia contra o contrato. **A porta vem de `PORT`**, com 8080 quando nada a define, e o servidor se
liga a `0.0.0.0`, todas as interfaces do contêiner. **Os logs são um objeto JSON por linha na
saída padrão**, que o Cloud Logging lê como entradas estruturadas com `severity`, então um aviso
continua aviso no console em vez de virar texto. **O `SIGTERM` é tratado**: o tratador registra
uma linha e sai na hora, bem dentro dos dez segundos que a plataforma dá.

Três detalhes estão lá para lições seguintes. O `ThreadingHTTPServer` atende cada requisição numa
thread própria, então uma instância serve várias requisições ao mesmo tempo; a lição 11 mede o que
isso compra. O `ORDERS_DELAY_MS` faz o `/orders` esperar antes de responder, no lugar da chamada ao
banco que um serviço real faria, e vale zero se ninguém o definir. E a resposta traz o `K_REVISION`,
uma variável que o Cloud Run define com o nome da revisão que atende a requisição, que a lição 9 lê
enquanto divide o tráfego; em casa ela diz `local`.

## A imagem

Salve isto como `Dockerfile` na mesma pasta:

```dockerfile
# orders/Dockerfile
FROM python:3.12.13-slim
WORKDIR /app
COPY app.py .
USER nobody
CMD ["python3", "app.py"]
```

O `CMD` está escrito na **forma exec**, uma lista JSON, então o próprio `python3` é o primeiro
processo do contêiner e recebe o `SIGTERM` direto; a seção 04 mostra quanto custa a outra forma. O
`USER nobody` roda o programa sem root, o que não custa nada aqui porque ele não escreve arquivo
nenhum. Monte a partir de `~/gcp`:

```
ana@laptop:~/gcp$ docker build -q -t orders:1 orders
sha256:fe71508314d462d9a3951a947556bd36a83f51dc4b03f31e244ba11d4760a6a0
ana@laptop:~/gcp$ docker image ls orders:1 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
orders:1  177MB
```

O `-q` imprime só o id da imagem. **Uns 180 MB, quase tudo a imagem base do Python**; o programa
acrescenta alguns kilobytes. O Cloud Run baixa a imagem do Artifact Registry quando inicia uma
instância, assunto da lição 21, e uma imagem menor sobe antes; a lição 11 mede quanto isso importa
e quanto não importa.
