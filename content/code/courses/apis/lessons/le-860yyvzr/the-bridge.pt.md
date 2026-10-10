---
title: Um adaptador na fronteira
version: 1
---

O desenho tentador é o que o `restock.py` já é: onde quer que a loja precise saber de estoque,
construir um cliente zeep e chamar o distribuidor. Funciona no primeiro dia. No décimo, a página do
catálogo lê `QtyAvail`, a tela de pedidos captura `zeep.exceptions.Fault` e compara com `E200`, e o
preço chega em reais como `Decimal` num código que conta centavos. **O modelo do distribuidor vazou
para dentro da loja**, e no dia em que o distribuidor mudar um nome, ou a loja mudar de distribuidor,
cada um desses lugares muda junto.

A solução tem um nome que vem do domain-driven design: uma **camada anticorrupção**. Um módulo fica
na fronteira, fala a língua do sistema antigo de um lado e a da loja do outro, e traduz nos dois
sentidos, para que nada depois dele saiba que o sistema antigo existe. O modelo legado é mantido do
lado de fora em vez de arrumado, e esse é o sentido do nome: o sistema antigo não está errado, ele é
de outra pessoa, e a loja não deveria ganhar a forma dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"A camada anticorrupção como uma fronteira. À esquerda, o lado do shelf fala JSON em 127.0.0.1:8000. À direita, o lado do distribuidor fala SOAP em 127.0.0.1:8001. O bridge.py fica na linha entre os dois e é o único programa que lê o distributor.wsdl. Cinco traduções a atravessam: QtyAvail vira available, 18.90 reais vira 1890 centavos, 20261012 vira 2026-10-12, a falha E200 com HTTP 500 vira 409, e nenhuma resposta em 2 segundos vira 504.\"><defs><marker id=\"l05-acl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">as palavras do shelf: JSON</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">as palavras do distribuidor: SOAP</text><rect x=\"290\" y=\"36\" width=\"120\" height=\"222\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bridge.py</text><text x=\"350\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê o WSDL;</text><text x=\"350\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ninguém mais lê</text><rect x=\"70\" y=\"106\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;available&quot;: 20</text><rect x=\"440\" y=\"106\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">QtyAvail 20</text><line x1=\"438\" y1=\"118\" x2=\"262\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"136\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;price_cents&quot;: 1890</text><rect x=\"440\" y=\"136\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UnitPrice 18.90</text><line x1=\"438\" y1=\"148\" x2=\"262\" y2=\"148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"166\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;2026-10-12&quot;</text><rect x=\"440\" y=\"166\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NextDelivery 20261012</text><line x1=\"438\" y1=\"178\" x2=\"262\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"196\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">409</text><rect x=\"440\" y=\"196\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fault E200, HTTP 500</text><line x1=\"438\" y1=\"208\" x2=\"262\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"226\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">504</text><rect x=\"440\" y=\"226\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem resposta em 2 s</text><line x1=\"438\" y1=\"238\" x2=\"262\" y2=\"238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line></svg>", "caption": "O adaptador é a fronteira. Tudo à esquerda está nos termos do shelf, tudo à direita nos do distribuidor, e só o bridge.py conhece os dois."}
```

O `bridge.py` é essa camada para o shelf. Ele oferece dois endereços no estilo do próprio shelf,
JSON como o `rest.py`, e é o único arquivo do projeto que sabe de SOAP. Salve-o ao lado dos outros:

```schooling-example
{
  "language": "python",
  "file": "shelf/bridge.py",
  "parts": [
    {
      "code": "# shelf/bridge.py\n\"\"\"The distributor as the shelf wants to see it: small JSON on 127.0.0.1:8000.\n\nEverything the SOAP service says passes through here and comes out in the\nshelf's terms: its names, its units, its faults and its silences.\n\"\"\"\nimport json\nimport os\nimport re\nfrom datetime import datetime\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport requests\nimport zeep\nfrom zeep.transports import Transport",
      "note": "O `zeep` fala com o distribuidor, e o `requests` é a biblioteca HTTP sobre a qual o zeep é construído, importada aqui só pelas duas exceções dela."
    },
    {
      "code": "\nWSDL = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"distributor.wsdl\")\nTIMEOUT = 2  # seconds the shelf waits for the distributor, and not one more\ndistributor = zeep.Client(WSDL, transport=Transport(operation_timeout=TIMEOUT)).service",
      "note": "O cliente é construído a partir da **cópia do WSDL que está no projeto**, e não do serviço no ar. A ponte sobe mesmo com o distribuidor fora do ar, e uma mudança do lado deles não chega a este código até alguém trocar o arquivo e ler o diff. `operation_timeout` é o número mais importante do arquivo."
    },
    {
      "code": "\n# The distributor's error codes, in the shelf's terms.\nFAULTS = {\n    \"E100\": (404, \"the distributor does not sell that ISBN\"),\n    \"E200\": (409, \"the distributor does not have that many copies\"),\n    \"E300\": (422, \"an order needs a reference and a quantity above zero\"),\n}",
      "note": "Os códigos de erro do distribuidor, escritos uma vez, cada um como um status e uma frase nas palavras do próprio shelf. Nada mais no shelf jamais vê `E200`."
    },
    {
      "code": "\n\ndef call(operation, **args):\n    \"\"\"(answer, None), or (None, (status, message)): never a fault, never a hang.\"\"\"\n    try:\n        return getattr(distributor, operation)(**args), None\n    except zeep.exceptions.Fault as fault:\n        code = None if fault.detail is None else fault.detail.findtext(\n            \"{http://distributor.example/stock}ErrorCode\")\n        return None, FAULTS.get(code, (502, f\"the distributor failed: {fault.message}\"))\n    except requests.Timeout:\n        return None, (504, f\"the distributor did not answer within {TIMEOUT} s\")\n    except requests.ConnectionError:\n        return None, (502, \"the distributor cannot be reached\")",
      "note": "Toda chamada passa por `call`, que sempre volta com uma resposta ou um status. Uma falha com código conhecido vira o status daquele código; qualquer outra falha vira **502**; nenhuma resposta dentro do timeout vira **504**; uma conexão recusada vira **502**."
    },
    {
      "code": "\n\nclass Bridge(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value):\n        body = (json.dumps(value) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "A resposta é JSON e nada mais, a mesma forma de resposta do `rest.py`."
    },
    {
      "code": "\n    def do_GET(self):\n        m = re.fullmatch(r\"/stock/(\\d{13})\", self.path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        stock, error = call(\"GetStock\", ISBN=m.group(1))\n        if error:\n            return self.reply(error[0], {\"error\": error[1]})\n        self.reply(200, {\n            \"isbn\": stock.ISBN,\n            \"available\": stock.QtyAvail,\n            \"price_cents\": int(stock.UnitPrice * 100),\n            \"next_delivery\": datetime.strptime(stock.NextDelivery, \"%Y%m%d\").date().isoformat(),\n        })",
      "note": "A tradução num lugar só. `QtyAvail` vira `available`, um preço de `18.90` reais vira `1890` centavos, como em todo o shelf, e `20261012` vira uma data ISO. `stock.UnitPrice` é um `Decimal`, então a multiplicação é exata."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        if self.path != \"/orders\":\n            return self.reply(404, {\"error\": \"no such resource\"})\n        try:\n            order = json.loads(raw)\n            isbn, quantity, reference = order[\"isbn\"], order[\"quantity\"], order[\"reference\"]\n        except (ValueError, TypeError, KeyError):\n            return self.reply(400, {\"error\": \"send isbn, quantity and reference as JSON\"})\n        if type(quantity) is not int or not isinstance(isbn, str) or not isinstance(reference, str):\n            return self.reply(422, {\"error\": \"isbn and reference are text, quantity a whole number\"})\n        placed, error = call(\"PlaceOrder\", ISBN=isbn, Qty=quantity, CustomerRef=reference)\n        if error:\n            return self.reply(error[0], {\"error\": error[1]})\n        self.reply(200 if placed.Repeated else 201, {\n            \"order\": placed.OrderNo, \"isbn\": isbn, \"quantity\": quantity, \"reference\": reference,\n        })",
      "note": "Um pedido precisa de uma referência de quem chama, que vai ao distribuidor como `CustomerRef`. Um pedido novo responde **201**; a mesma referência de novo responde **200** com o pedido que já existe."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Bridge)\n    print(f\"bridge on http://127.0.0.1:8000, waiting {TIMEOUT} s at most\", flush=True)\n    server.serve_forever()",
      "note": "Porta 8000, onde o `rest.py` escuta, então os dois não rodam ao mesmo tempo."
    }
  ]
}
```

## Rodando

A ponte escuta na porta 8000, onde o `rest.py` escutava, então o `rest.py` continua parado. O
distribuidor fica com o segundo terminal; abra um **terceiro** (`multipass shell api` de novo, com o
Multipass) e suba a ponte nele:

```sh
cd ~/shelf && python3 bridge.py
```

Ela diz quanto tempo vai esperar pelo distribuidor:

```
bridge on http://127.0.0.1:8000, waiting 2 s at most
```

Toda requisição daqui em diante vai para a ponte, na porta 8000. Primeiro o estoque, depois as duas
falhas que a seção anterior mapeou, depois um pedido que quebra uma regra e o mesmo pedido feito
direito:

```
ana@api:~/shelf$ curl -si localhost:8000/stock/9786500000030
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:41:02 GMT
Content-Type: application/json
Content-Length: 95

{"isbn": "9786500000030", "available": 20, "price_cents": 1890, "next_delivery": "2026-10-12"}
ana@api:~/shelf$ curl -s -w '%{http_code}\n' localhost:8000/stock/9780000000000
{"error": "the distributor does not sell that ISBN"}
404
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000061", "quantity": 10, "reference": "R-2001"}'
{"error": "the distributor does not have that many copies"}
409
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000061", "quantity": 0, "reference": "R-2001"}'
{"error": "an order needs a reference and a quantity above zero"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000061", "quantity": 2, "reference": "R-2001"}'
{"order": "PO100002", "isbn": "9786500000061", "quantity": 2, "reference": "R-2001"}
201
```

**Nada nessas respostas é do distribuidor.** `available` no lugar de `QtyAvail`, 1890 centavos no
lugar de 18.90 reais, uma data ISO no lugar de oito dígitos, e status que os clientes do shelf já
entendem desde a aula 1. O 422 veio da falha `E300` do distribuidor, e o 201 do pedido com
quantidade 2 é o jeito do shelf de dizer *criado*. A referência `R-2001` foi usada nos três pedidos,
e só o terceiro foi feito, porque os outros dois foram recusados.

## Um distribuidor que não responde

Uma falha é o defeito fácil, porque é uma resposta. O difícil é o silêncio. Deixe o substituto
lento: enquanto existir um arquivo chamado `slow` em `~/shelf`, ele espera aquela quantidade de
segundos antes de fazer qualquer coisa. Escreva 5 nele e faça um pedido pela ponte:

```
ana@api:~/shelf$ echo 5 > slow
ana@api:~/shelf$ curl -s -w '%{http_code} after %{time_total} s\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}'
{"error": "the distributor did not answer within 2 s"}
504 after 2.008635 s
```

**A ponte respondeu 504 depois de dois segundos, porque o `operation_timeout` mandou.** Sem esse
argumento, o zeep esperaria o quanto o distribuidor levasse, e toda requisição ao shelf que
precisasse do distribuidor esperaria junto, cada uma segurando uma thread e uma conexão, até os
próprios clientes da loja desistirem dela. Um timeout transforma *o distribuidor está lento* numa
resposta rápida e honesta.

Deixe o arquivo `slow` onde está por enquanto. O 504 diz que o shelf desistiu; ele não diz o que
aconteceu com o pedido, e a seção depois da próxima trata de descobrir.
