---
title: Conferindo quem enviou
version: 1
---

O receptor escuta numa porta que qualquer um na rede alcança, e qualquer um pode enviar JSON por
POST para ela. **Sem uma verificação, um "link down" forjado abre um chamado, e um "link up"
forjado fecha um.** O segredo da assinatura é o que impede isso: o roteador calcula um HMAC dos
bytes exatos do corpo com o segredo, e o envia em `X-Devapi-Signature`. Ninguém sem o segredo
consegue calculá-lo, e qualquer mudança no corpo o muda.

O receptor que o resto da aula usa verifica isso primeiro, antes de ler qualquer coisa do corpo:

```schooling-example
{
  "language": "python",
  "file": "receiver.py",
  "parts": [
    {
      "code": "import hashlib\nimport hmac\nimport json\nimport sys\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom pathlib import Path\n\nimport desk\n\nSECRET = Path(\"~/.hook-secret\").expanduser().read_text().strip().encode()\nSEEN = set()\nFAIL_ONCE = \"--fail-once\" in sys.argv\n\n",
      "note": "**O receptor sobre o qual o resto da aula constrói.** Ele confere a assinatura de cada entrega, ignora uma entrega que já tratou e transforma eventos em chamados."
    },
    {
      "code": "def signed(body, header):\n    want = \"sha256=\" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()\n    return hmac.compare_digest(want, header or \"\")\n\n\nclass Hook(BaseHTTPRequestHandler):\n    def do_POST(self):\n        body = self.rfile.read(int(self.headers[\"Content-Length\"]))\n        delivery = self.headers.get(\"X-Devapi-Delivery\")\n        if not signed(body, self.headers.get(\"X-Devapi-Signature\")):\n            print(f\"{delivery}: bad signature, refused\")\n            return self.answer(401)",
      "note": "**A assinatura é um HMAC dos bytes exatos recebidos**, calculado com o segredo compartilhado. `compare_digest` compara em tempo constante, então o tempo que leva não diz quanto de uma assinatura forjada estava certo."
    },
    {
      "code": "        if delivery in SEEN:\n            print(f\"{delivery}: already handled, ignored\")\n            return self.answer(204)\n        event = json.loads(body)\n        print(f\"{delivery}: {event['event']} {event['device']} {event['interface']}\")\n        print(\"  \", desk.handle(event))\n        SEEN.add(delivery)\n        if FAIL_ONCE and len(SEEN) == 1:\n            print(f\"{delivery}: answering 500 on purpose\")\n            return self.answer(500)\n        self.answer(204)\n\n    def answer(self, status):\n        self.send_response(status)\n        self.end_headers()\n\n    def log_message(self, *args):\n        pass\n\n\nserver = HTTPServer((\"192.0.2.10\", 8080), Hook)\nfor _ in range(int(sys.argv[1])):\n    server.handle_request()",
      "note": "**O id da entrega torna uma nova tentativa inofensiva.** Um remetente que não ouviu resposta manda o mesmo evento de novo, com o mesmo id, e o receptor já agiu sobre ele."
    }
  ]
}
```

Uma requisição forjada, com uma assinatura inventada:

```
ana@ctl:~$ curl -s -o /dev/null -w "%{http_code}\n" -H "Content-Type: application/json" -H "X-Devapi-Delivery: forged-1" -H "X-Devapi-Signature: sha256=0000" -d '{"event": "interface.up", "device": "edge1", "interface": "eth1"}' http://192.0.2.10:8080/hook
401
```

```
ana@ctl:~$ python receiver.py 1
forged-1: bad signature, refused
```

`401`, e nada mais aconteceu. Três detalhes em `signed` são o que fazem dela uma verificação de
verdade:

- **Ela assina os bytes crus**, como chegaram, e não o JSON depois da análise. Analisar e
  serializar de novo pode mudar espaços ou a ordem das chaves, e aí uma assinatura legítima
  deixaria de bater.
- **Ela usa `hmac.compare_digest`**, e não `==`. Uma comparação comum para no primeiro caractere
  diferente, então o tempo dela vaza quantos caracteres de um palpite estavam certos.
- **O segredo fica num arquivo que só a `ana` pode ler**, `~/.hook-secret`, e nunca no código.

Muitos remetentes também põem um timestamp no que assinam, para que uma entrega antiga capturada
na rede não possa ser reenviada amanhã. O roteador do laboratório não faz isso; o id da entrega, na
próxima seção, limita o estrago que um reenvio pode fazer.
