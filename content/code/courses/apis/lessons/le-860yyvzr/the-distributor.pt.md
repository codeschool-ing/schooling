---
title: Um substituto para o distribuidor
version: 1
---

**O serviço real do distribuidor não pode ser alcançado a partir deste curso**, então você vai rodar
um substituto para ele na sua própria máquina. O endereço e as credenciais dele fariam parte de um
contrato entre duas empresas, e nenhum curso pode distribuir isso. O substituto faz o papel do
distribuidor o mais de perto que um programa curto consegue: serve o contrato que você acabou de
salvar, recebe os mesmos envelopes, responde no mesmo formato e falha com as mesmas falhas.

O trabalho de integração num emprego de verdade costuma começar do mesmo jeito. O ambiente de testes
do parceiro tende a chegar semanas depois do contrato, e um substituto construído a partir do WSDL é
contra o que você testa enquanto isso. **O que um substituto não consegue contar é como o serviço
real se comporta num dia ruim**, e é por isso que a seção sobre o adaptador deixa este lento de
propósito.

Onde ele difere do real: guarda o estoque e os pedidos em memória, então eles recomeçam sempre que
ele recomeça; não pede credenciais; e é um processo só, em 127.0.0.1, porta 8001.

Salve-o como `distributor.py`, ao lado do `distributor.wsdl`. Cada parte tem uma nota, e o botão de
copiar leva o programa inteiro sem elas:

```schooling-example
{
  "language": "python",
  "file": "shelf/distributor.py",
  "parts": [
    {
      "code": "# shelf/distributor.py\n\"\"\"A stand-in for the book distributor's SOAP 1.1 service, on 127.0.0.1:8001.\n\nThe real service cannot be reached from this course, so this one plays its\npart: the same kind of contract, the same envelopes, the same faults. Its stock\nlives in memory and starts again whenever the program does.\n\"\"\"\nimport os\nimport threading\nimport time\nimport traceback\nimport xml.etree.ElementTree as ET\nfrom datetime import date, timedelta\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom xml.sax.saxutils import escape",
      "note": "Só a biblioteca padrão, como o `rest.py`. O `xml.etree` lê os envelopes que chegam; os que saem são escritos como strings, porque um substituto com duas operações não precisa de um construtor de XML."
    },
    {
      "code": "\nHERE = os.path.dirname(os.path.abspath(__file__))\nSOAP = \"http://schemas.xmlsoap.org/soap/envelope/\"\nTNS = \"http://distributor.example/stock\"\n\n# ISBN: [copies in the warehouse, wholesale price in reais, days to deliver]\nSTOCK = {\n    \"9786500000016\": [40, \"21.50\", 2],\n    \"9786500000023\": [0, \"24.00\", 9],\n    \"9786500000030\": [25, \"18.90\", 2],\n    \"9786500000047\": [6, \"22.90\", 4],\n    \"9786500000054\": [12, \"31.00\", 3],\n    \"9786500000061\": [3, \"35.50\", 5],\n}\nORDERS = {}  # CustomerRef: OrderNo\nLOCK = threading.Lock()",
      "note": "Os dois **namespaces** que toda mensagem usa: o do próprio SOAP 1.1, para o envelope, e o do distribuidor, para o que vai dentro dele. O estoque é um dicionário indexado pelos ISBNs do próprio shelf, com preço em reais numa string decimal, do jeito que o distribuidor cota. `ORDERS` lembra cada referência de cliente, e é isso que faz um pedido enviado duas vezes virar um pedido feito uma vez."
    },
    {
      "code": "\n\nclass Fault(Exception):\n    \"\"\"A SOAP fault: Client when the request is wrong, Server when we are.\"\"\"\n    def __init__(self, who, text, code=None):\n        super().__init__(text)\n        self.who, self.text, self.code = who, text, code",
      "note": "Uma falha diz de quem é a culpa, `Client` ou `Server`, traz uma frase para uma pessoa e, quando existe, o código de erro do próprio distribuidor para um programa."
    },
    {
      "code": "\n\ndef get_stock(req):\n    isbn = req.findtext(f\"{{{TNS}}}ISBN\", \"\")\n    if isbn not in STOCK:\n        raise Fault(\"Client\", f\"ISBN {isbn} is not in the catalogue\", \"E100\")\n    qty, price, days = STOCK[isbn]\n    due = (date.today() + timedelta(days=days)).strftime(\"%Y%m%d\")\n    return (f'<GetStockResponse xmlns=\"{TNS}\"><ISBN>{isbn}</ISBN><QtyAvail>{qty}</QtyAvail>'\n            f\"<UnitPrice>{price}</UnitPrice><NextDelivery>{due}</NextDelivery></GetStockResponse>\")",
      "note": "`GetStock` responde com os nomes e as unidades do distribuidor: `QtyAvail`, um preço em reais com ponto decimal e uma data de entrega escrita `20261012`, que é como muito sistema antigo guarda uma."
    },
    {
      "code": "\n\ndef place_order(req):\n    isbn = req.findtext(f\"{{{TNS}}}ISBN\", \"\")\n    ref = req.findtext(f\"{{{TNS}}}CustomerRef\", \"\").strip()\n    qty = req.findtext(f\"{{{TNS}}}Qty\", \"\")\n    if not ref or not qty.isdigit() or int(qty) < 1:\n        raise Fault(\"Client\", \"an order needs a CustomerRef and a Qty above zero\", \"E300\")\n    with LOCK:\n        if ref in ORDERS:\n            number, repeated = ORDERS[ref], \"true\"\n        else:\n            if isbn not in STOCK:\n                raise Fault(\"Client\", f\"ISBN {isbn} is not in the catalogue\", \"E100\")\n            if STOCK[isbn][0] < int(qty):\n                raise Fault(\"Client\", f\"only {STOCK[isbn][0]} of {isbn} available\", \"E200\")\n            STOCK[isbn][0] -= int(qty)\n            number, repeated = f\"PO{100001 + len(ORDERS)}\", \"false\"\n            ORDERS[ref] = number\n            print(f\"order {number}: {qty} x {isbn} for {ref}\", flush=True)\n    return (f'<PlaceOrderResponse xmlns=\"{TNS}\"><OrderNo>{number}</OrderNo>'\n            f\"<Repeated>{repeated}</Repeated></PlaceOrderResponse>\")",
      "note": "`PlaceOrder` procura a referência **antes** de conferir qualquer outra coisa. Uma referência já vista recebe de volta o mesmo número de pedido, com `Repeated` verdadeiro, e nenhum segundo pedido. O lock impede que dois pedidos chegando juntos levem, os dois, as últimas cópias."
    },
    {
      "code": "\n\nOPERATIONS = {f\"{{{TNS}}}GetStock\": get_stock, f\"{{{TNS}}}PlaceOrder\": place_order}",
      "note": "Qual função responde é decidido pelo primeiro elemento dentro do `Body`, com o namespace dele."
    },
    {
      "code": "\n\nclass Distributor(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def send(self, status, text, content_type=\"text/xml; charset=utf-8\"):\n        data = text.encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        try:\n            self.wfile.write(data)\n        except (BrokenPipeError, ConnectionResetError):\n            print(\"the caller left before the answer\", flush=True)",
      "note": "Toda resposta sai por `send`. Quem desligou antes da resposta não é um erro aqui, mas também não passa em silêncio: o log diz, porque o que a requisição fazia já foi feito."
    },
    {
      "code": "\n    def do_GET(self):\n        if self.path.lower() != \"/distributor?wsdl\":\n            return self.send(404, \"no such document\\n\", \"text/plain\")\n        with open(os.path.join(HERE, \"distributor.wsdl\"), encoding=\"utf-8\") as f:\n            self.send(200, f.read())",
      "note": "O contrato é publicado no próprio endereço do serviço com `?wsdl` no fim, a convenção que todo toolkit de SOAP espera."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        slow = os.path.join(HERE, \"slow\")\n        if os.path.exists(slow):\n            with open(slow) as f:\n                time.sleep(float(f.read().strip() or 0))",
      "note": "Primeiro o corpo é lido inteiro, como no `rest.py`. Depois, enquanto existir um arquivo chamado `slow` ao lado do programa, ele espera o número de segundos escrito nele. É assim que esta aula deixa o distribuidor lento quando quer."
    },
    {
      "code": "        try:\n            if self.path != \"/distributor\":\n                raise Fault(\"Client\", f\"no service at {self.path}\")\n            if \"SOAPAction\" not in self.headers:\n                raise Fault(\"Client\", \"the SOAPAction header is missing\")\n            if b\"<!DOCTYPE\" in raw:\n                raise Fault(\"Client\", \"a SOAP message must not contain a DTD\")\n            try:\n                envelope = ET.fromstring(raw)\n            except ET.ParseError as e:\n                raise Fault(\"Client\", f\"not well-formed XML: {e}\")\n            req = envelope.find(f\"{{{SOAP}}}Body/*\")\n            if envelope.tag != f\"{{{SOAP}}}Envelope\" or req is None:\n                raise Fault(\"Client\", \"not a SOAP 1.1 envelope\")\n            if req.tag not in OPERATIONS:\n                raise Fault(\"Client\", f\"no operation {req.tag}\")\n            status, body = 200, OPERATIONS[req.tag](req)",
      "note": "As verificações que um serviço SOAP faz antes de olhar a operação: um cabeçalho `SOAPAction`, nenhuma declaração de tipo de documento, XML bem formado e um `Envelope` com um `Body`."
    },
    {
      "code": "        except Fault as f:\n            detail = f'<detail><ErrorCode xmlns=\"{TNS}\">{f.code}</ErrorCode></detail>' if f.code else \"\"\n            status, body = 500, (f\"<soap:Fault><faultcode>soap:{f.who}</faultcode>\"\n                                 f\"<faultstring>{escape(f.text)}</faultstring>{detail}</soap:Fault>\")\n        except Exception:\n            traceback.print_exc()\n            status, body = 500, (\"<soap:Fault><faultcode>soap:Server</faultcode>\"\n                                 \"<faultstring>internal error</faultstring></soap:Fault>\")\n        self.send(status, f'<soap:Envelope xmlns:soap=\"{SOAP}\"><soap:Body>{body}</soap:Body></soap:Envelope>')",
      "note": "Toda falha vira um elemento `Fault` dentro de um envelope comum, enviado com HTTP **500**, seja de quem for a culpa. É a regra do SOAP 1.1, e a seção sobre falhas trata do que ela custa. Uma exceção que ninguém esperava é impressa inteira no log e respondida como falha `Server`."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8001), Distributor)\n    print(\"distributor on http://127.0.0.1:8001/distributor\", flush=True)\n    server.serve_forever()",
      "note": "Porta 8001, só em 127.0.0.1, para poder rodar ao lado de um servidor na 8000."
    }
  ]
}
```

## Rodando

O distribuidor precisa de um terminal só dele, como o `rest.py` na aula 1, e esta aula usa o segundo
terminal para isso. Nesse terminal, pare o `rest.py` com `Ctrl+C` e suba o distribuidor no lugar:

```sh
cd ~/shelf && python3 distributor.py
```

Ele imprime uma linha e espera:

```
distributor on http://127.0.0.1:8001/distributor
```

De volta ao primeiro terminal, peça o contrato, do jeito que todo toolkit vai pedir:

```
ana@api:~/shelf$ curl -s 'localhost:8001/distributor?wsdl' | head -3
<!-- shelf/distributor.wsdl -->
<definitions name="Distributor"
    targetNamespace="http://distributor.example/stock"
```

A primeira linha é o comentário que você digitou. O serviço lê o `distributor.wsdl` do próprio
diretório e o envia como está, então **o contrato que um cliente baixa é o arquivo que você leu**,
caractere por caractere. O arquivo e o `distributor.py` ainda são duas coisas que podem discordar:
renomeie um elemento no código e o contrato continua prometendo o nome antigo. Muitos serviços reais
geram o WSDL a partir do código por esse motivo.
