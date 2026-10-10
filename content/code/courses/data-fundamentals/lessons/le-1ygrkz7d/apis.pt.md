---
title: APIs, lidas página por página no ritmo do dono
version: 1
---

**Uma API é uma fonte que só se lê do jeito que o dono permite: em páginas, num ritmo, e com uma
chave.** As cobranças e os estornos da Roda Livre ficam no provedor de pagamentos, outra empresa, e não
estão em nenhum banco que a Roda Livre tenha. O único jeito de tê-los é perguntar à API do provedor: um
programa manda uma requisição HTTP para um endereço como `https://api.payments.example/v1/charges` e
recebe uma resposta em JSON.

A imagem que as pessoas trazem é a de um download: uma requisição, todas as cobranças. Nenhuma API que
guarda mais do que uma tela de dados funciona assim, por um motivo que é do dono e não seu. Os mesmos
servidores respondem a todos os clientes do provedor, e um cliente pedindo três anos de cobranças numa
requisição deixaria tudo lento para os outros. Então o dono impõe três regras, e um programa que lê uma
API é, na maior parte, um programa que obedece a elas.

- **Paginação.** Uma resposta traz uma página de resultados e diz como pedir a próxima, muitas vezes
  com um campo como `next`. O cliente continua pedindo até não haver próxima página. Algumas APIs
  numeram as páginas; outras devolvem um cursor opaco, que continua correto quando linhas são
  acrescentadas durante a leitura, enquanto números de página podem pular uma linha ou mostrá-la duas
  vezes.
- **Limites de taxa.** O dono permite tantas requisições por minuto. Passado isso, a resposta é o status
  `429 Too Many Requests`, muitas vezes com um cabeçalho `Retry-After` dizendo quantos segundos esperar.
  O cliente que ignora isso e tenta de novo na hora é o cliente que tem a chave suspensa.
- **Autenticação.** Toda requisição leva um token que diz quem está pedindo. **O token nunca vai no
  código do programa**, porque código é copiado, compartilhado e versionado no git, e um token num
  repositório é um token que qualquer pessoa com o repositório pode usar. Ele é lido do ambiente, ou em
  produção de um cofre de segredos, assunto de `cloud`.

## Uma API na sua própria máquina

O laboratório não alcança um provedor de pagamentos, então um programa faz o papel de um. Ele serve sete
viagens, três por página, em `127.0.0.1`, um endereço que só a sua própria máquina alcança. Para mostrar
um limite de taxa sem esperar por um de verdade, ele recusa cada terceira requisição que recebe.

```schooling-example
{"language": "python", "file": "sources/api.py", "parts": [
{"code": "# sources/api.py\nimport json\nimport os\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom urllib.parse import parse_qs, urlparse\n\n", "note": "Só a biblioteca padrão: `http.server` responde às requisições, `urllib.parse` lê o endereço."},
{"code": "TOKEN = os.environ[\"RODA_TOKEN\"]\nRIDES = [{\"ride_id\": f\"R{n:06d}\", \"station\": f\"ST{n % 12 + 1:02d}\"} for n in range(201, 208)]\nPAGE = 3\ncalls = 0\n\n\n", "note": "O token vem do ambiente, nunca do código. Sete viagens, três por página, e um contador de requisições recebidas."},
{"code": "class Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        global calls\n        calls += 1\n", "note": "`do_GET` roda uma vez para cada requisição."},
{"code": "        if self.headers.get(\"Authorization\") != f\"Bearer {TOKEN}\":\n            return self.reply(401, {\"error\": \"missing or wrong token\"})\n", "note": "Sem token, ou com o errado: `401 Unauthorized`, verificado antes de tudo."},
{"code": "        if calls % 3 == 0:\n            return self.reply(429, {\"error\": \"too many requests\"}, {\"Retry-After\": \"1\"})\n", "note": "O limite de taxa encenado: cada terceira requisição é recusada com `429` e mandada esperar um segundo."},
{"code": "        page = int(parse_qs(urlparse(self.path).query).get(\"page\", [\"1\"])[0])\n        rides = RIDES[(page - 1) * PAGE : page * PAGE]\n        last = page * PAGE >= len(RIDES)\n        self.reply(200, {\"page\": page, \"rides\": rides, \"next\": None if last else page + 1})\n\n", "note": "A página pedida em `?page=`, a fatia de viagens dela, e `next`, que é `None` (o `null` do JSON) na última página."},
{"code": "    def reply(self, status, body, headers={}):\n        self.send_response(status)\n        for name, value in headers.items():\n            self.send_header(name, value)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.end_headers()\n        self.wfile.write(json.dumps(body).encode())\n\n    def log_message(self, *args):\n        pass\n\n\n", "note": "Toda resposta é JSON com um status e, às vezes, cabeçalhos extras. `log_message` fica calado para o terminal mostrar só o cliente."},
{"code": "HTTPServer((\"127.0.0.1\", 8040), Handler).serve_forever()\n", "note": "Escuta na porta 8040 de `127.0.0.1`, que nada fora da sua máquina alcança, até ser parado."}
]}
```

Ele lê o token do ambiente, como o cliente abaixo, então defina um no terminal e inicie o servidor em
segundo plano. O `&` devolve o terminal enquanto o servidor continua rodando:

```sh
export RODA_TOKEN=lab-token-not-a-secret
python api.py &
```

O cliente percorre as páginas, espera quando mandam, e para quando `next` vem vazio:

```python
# sources/walk.py
import json
import os
import time
import urllib.error
import urllib.request

TOKEN = os.environ["RODA_TOKEN"]
page, rides = 1, []
while page is not None:
    request = urllib.request.Request(f"http://127.0.0.1:8040/rides?page={page}",
                                     headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        with urllib.request.urlopen(request) as response:
            body = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code != 429:
            raise
        wait = int(error.headers["Retry-After"])
        print(f"page {page}: 429, waiting {wait} s as the server asked")
        time.sleep(wait)
        continue
    print(f"page {page}: {[r['ride_id'] for r in body['rides']]} next={body['next']}")
    rides += body["rides"]
    page = body["next"]
print(len(rides), "rides in all")
```

```
ana@lab:~/roda/sources$ python walk.py
page 1: ['R000201', 'R000202', 'R000203'] next=2
page 2: ['R000204', 'R000205', 'R000206'] next=3
page 3: 429, waiting 1 s as the server asked
page 3: ['R000207'] next=None
7 rides in all
```

Quatro requisições para três páginas. A terceira foi recusada, o cliente esperou o um segundo que lhe
pediram, e pediu a página 3 de novo. Repare no que o `continue` faz: volta ao começo do laço **sem
avançar `page`**, então a página recusada é pedida de novo em vez de pulada. Um cliente que tratasse o
429 como página vazia relataria seis viagens, e nada mais reclamaria.

Qualquer outro erro é levantado e para o programa, que é o que um token errado deve fazer. Aqui só fica
a última linha do traceback:

```
ana@lab:~/roda/sources$ RODA_TOKEN=wrong python walk.py 2>&1 | tail -1
urllib.error.HTTPError: HTTP Error 401: Unauthorized
```

Quando terminar, `kill %1` para o servidor.

## O que muda debaixo de você

Uma API é versionada pelo dono, e é para isso que serve o `v1` no endereço: uma nova `v2` pode mudar as
respostas enquanto a `v1` cumpre a promessa dela por um tempo. As mudanças que doem são as feitas dentro
de uma versão, sem número novo, como um campo que sempre vinha passar a ser opcional, ou um valor em
reais passar a vir em centavos. Nada na requisição HTTP falha. Construir APIs, e cumprir essas promessas
do outro lado, é o assunto do curso `apis`.
