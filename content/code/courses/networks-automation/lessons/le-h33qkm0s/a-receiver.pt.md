---
title: O menor receptor possível
version: 2
---

Um receptor é um servidor web com um handler, e a biblioteca padrão do Python tem um:

```schooling-example
{
  "language": "python",
  "file": "hook_print.py",
  "parts": [
    {
      "code": "import json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\n\nclass Hook(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = self.rfile.read(int(self.headers[\"Content-Length\"]))\n        print(\"headers:\", {k: v for k, v in self.headers.items() if k.startswith(\"X-Devapi\")})\n        print(\"body:   \", json.loads(body))",
      "note": "**Um receptor de webhook é um pequeno servidor web.** Ele escuta, e cada evento chega como um POST HTTP com corpo JSON. A biblioteca padrão basta."
    },
    {
      "code": "        self.send_response(204)\n        self.end_headers()\n\n    def log_message(self, *args):\n        pass\n\n",
      "note": "**Responda rápido, e responda 2xx.** O remetente só precisa saber que o evento chegou; o que o receptor faz com ele vem depois."
    },
    {
      "code": "HTTPServer((\"192.0.2.10\", 8080), Hook).handle_request()",
      "note": "**Uma requisição, e para**, para a transcrição terminar; um receptor de verdade roda `serve_forever()`."
    }
  ]
}
```

O roteador precisa saber para onde enviar, então o primeiro passo é uma assinatura, criada pelo
mesmo cliente de API que a aula 2 escreveu, o `devapi.py`, que continua na home da `ana`. O roteador
assina cada entrega com um segredo que as duas pontas conhecem, e a `ana` o cria uma vez, como uma
sequência aleatória num arquivo que só ela consegue ler:

```
ana@ctl:~$ head -c 24 /dev/urandom | base64 > ~/.hook-secret; chmod 600 ~/.hook-secret
```

Os eventos são os dois que o roteador oferece, um link caindo e voltando:

```schooling-example
{
  "language": "python",
  "file": "subscribe.py",
  "parts": [
    {
      "code": "import sys\nfrom pathlib import Path\n\nfrom devapi import Device\n"
    },
    {
      "code": "secret = Path(\"~/.hook-secret\").expanduser().read_text().strip()\nedge1 = Device(\"edge1\")\nhook = edge1.request(\"POST\", \"/webhooks\", json={\n    \"url\": \"http://192.0.2.10:8080/hook\",\n    \"events\": [\"interface.down\", \"interface.up\"],\n    \"secret\": secret})\nprint(hook)",
      "note": "**O segredo é compartilhado pelas duas pontas e nunca viaja com um evento.** O roteador o usa para assinar cada entrega; o receptor, para conferir a assinatura."
    }
  ]
}
```

```
ana@ctl:~$ python subscribe.py
{'id': 'wh-b26d9c7e', 'url': 'http://192.0.2.10:8080/hook', 'events': ['interface.down', 'interface.up']}
```

O roteador respondeu com o id da assinatura, e **não repetiu o segredo**: um segredo que uma API
devolve é um segredo que acaba em logs. Agora o receptor roda em um terminal, e em outro um pequeno
script derruba a `eth2` do `edge1` pela API do roteador, do jeito que uma mudança ou uma falha
faria:

```schooling-example
{
  "language": "python",
  "file": "link.py",
  "parts": [
    {
      "code": "import sys\n\nfrom devapi import Device\n"
    },
    {
      "code": "router, interface, state = sys.argv[1:4]\nDevice(router).request(\"PATCH\", f\"/interfaces/{interface}\", json={\"enabled\": state == \"up\"})\nprint(f\"{router} {interface}: {state}\")",
      "note": "**Derruba ou levanta um link pela API do roteador**, como faria a mudança de um operador ou uma falha. `python link.py edge1 eth2 down`."
    }
  ]
}
```

```
ana@ctl:~$ python link.py edge1 eth2 down
edge1 eth2: down
```

O que o receptor imprimiu:

```
ana@ctl:~$ python hook_print.py
headers: {'X-Devapi-Event': 'interface.down', 'X-Devapi-Delivery': 'edge1-1790682864-1', 'X-Devapi-Signature': 'sha256=314b71b4150b6625b24404cfa0b6636478fcdc35db7f1971375f1f582605c750'}
body:    {'id': 'edge1-1790682864-1', 'event': 'interface.down', 'device': 'edge1', 'interface': 'eth2', 'description': 'branch LAN', 'time': '2026-09-29T08:54:45-03:00'}
```

**O evento é um pequeno documento JSON**: o que aconteceu, em qual equipamento e interface, a
descrição da interface, e quando. O `id` dele se repete em um header, `X-Devapi-Delivery`, ao lado
do nome do evento e de uma **assinatura**. Cada um dos três headers tem uma função, e as próximas
três seções tratam de um cada.

O receptor respondeu `204 No Content` e parou, porque trata uma requisição e sai; um de verdade
roda `serve_forever()`. **Responder rápido importa mais do que parece.** Quem envia espera a
resposta, e um receptor que faz o trabalho antes de responder, chamando um sistema de chamados que
leva oito segundos, faz quem enviou achar que falhou.
