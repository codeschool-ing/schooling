---
title: A stand-in for the distributor
version: 1
---

**The distributor's real service cannot be reached from this course**, so you will run a stand-in
for it on your own machine. Its address and its credentials would be part of a contract between
two companies, and no course can hand those out. The stand-in plays the distributor's part as
closely as a short program can: it serves the contract you just saved, takes the same envelopes,
answers in the same shape and fails with the same faults.

Integration work in a real job often starts the same way. The partner's test environment tends to
arrive weeks after the contract, and a stand-in built from the WSDL is what you test against in the
meantime. **What a stand-in cannot tell you is how the real service behaves when it is
having a bad day**, which is why the section on the adapter makes this one slow on purpose.

Where it differs from the real thing: it keeps its stock and its orders in memory, so they start
again whenever it does; it asks for no credentials; and it is one process on 127.0.0.1, port 8001.

Save it as `distributor.py`, beside `distributor.wsdl`. Each part has a note, and the copy button
takes the whole program without them:

```schooling-example
{
  "language": "python",
  "file": "shelf/distributor.py",
  "parts": [
    {
      "code": "# shelf/distributor.py\n\"\"\"A stand-in for the book distributor's SOAP 1.1 service, on 127.0.0.1:8001.\n\nThe real service cannot be reached from this course, so this one plays its\npart: the same kind of contract, the same envelopes, the same faults. Its stock\nlives in memory and starts again whenever the program does.\n\"\"\"\nimport os\nimport threading\nimport time\nimport traceback\nimport xml.etree.ElementTree as ET\nfrom datetime import date, timedelta\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom xml.sax.saxutils import escape",
      "note": "Standard library only, like `rest.py`. `xml.etree` reads the envelopes that arrive; the ones that leave are written as strings, because a stand-in with two operations does not need an XML builder."
    },
    {
      "code": "\nHERE = os.path.dirname(os.path.abspath(__file__))\nSOAP = \"http://schemas.xmlsoap.org/soap/envelope/\"\nTNS = \"http://distributor.example/stock\"\n\n# ISBN: [copies in the warehouse, wholesale price in reais, days to deliver]\nSTOCK = {\n    \"9786500000016\": [40, \"21.50\", 2],\n    \"9786500000023\": [0, \"24.00\", 9],\n    \"9786500000030\": [25, \"18.90\", 2],\n    \"9786500000047\": [6, \"22.90\", 4],\n    \"9786500000054\": [12, \"31.00\", 3],\n    \"9786500000061\": [3, \"35.50\", 5],\n}\nORDERS = {}  # CustomerRef: OrderNo\nLOCK = threading.Lock()",
      "note": "The two **namespaces** every message uses: SOAP 1.1's own, for the envelope, and the distributor's, for what is inside it. The warehouse is a dictionary keyed by the shelf's own ISBNs, priced in reais as a decimal string, the way the distributor quotes them. `ORDERS` remembers each customer reference, which is what makes an order sent twice an order placed once."
    },
    {
      "code": "\n\nclass Fault(Exception):\n    \"\"\"A SOAP fault: Client when the request is wrong, Server when we are.\"\"\"\n    def __init__(self, who, text, code=None):\n        super().__init__(text)\n        self.who, self.text, self.code = who, text, code",
      "note": "A fault carries who is to blame, `Client` or `Server`, a sentence for a person and, when there is one, the distributor's own error code for a program."
    },
    {
      "code": "\n\ndef get_stock(req):\n    isbn = req.findtext(f\"{{{TNS}}}ISBN\", \"\")\n    if isbn not in STOCK:\n        raise Fault(\"Client\", f\"ISBN {isbn} is not in the catalogue\", \"E100\")\n    qty, price, days = STOCK[isbn]\n    due = (date.today() + timedelta(days=days)).strftime(\"%Y%m%d\")\n    return (f'<GetStockResponse xmlns=\"{TNS}\"><ISBN>{isbn}</ISBN><QtyAvail>{qty}</QtyAvail>'\n            f\"<UnitPrice>{price}</UnitPrice><NextDelivery>{due}</NextDelivery></GetStockResponse>\")",
      "note": "`GetStock` answers with the distributor's names and units: `QtyAvail`, a price in reais with a decimal point, and a delivery date written `20261012`, which is how a lot of older systems store one."
    },
    {
      "code": "\n\ndef place_order(req):\n    isbn = req.findtext(f\"{{{TNS}}}ISBN\", \"\")\n    ref = req.findtext(f\"{{{TNS}}}CustomerRef\", \"\").strip()\n    qty = req.findtext(f\"{{{TNS}}}Qty\", \"\")\n    if not ref or not qty.isdigit() or int(qty) < 1:\n        raise Fault(\"Client\", \"an order needs a CustomerRef and a Qty above zero\", \"E300\")\n    with LOCK:\n        if ref in ORDERS:\n            number, repeated = ORDERS[ref], \"true\"\n        else:\n            if isbn not in STOCK:\n                raise Fault(\"Client\", f\"ISBN {isbn} is not in the catalogue\", \"E100\")\n            if STOCK[isbn][0] < int(qty):\n                raise Fault(\"Client\", f\"only {STOCK[isbn][0]} of {isbn} available\", \"E200\")\n            STOCK[isbn][0] -= int(qty)\n            number, repeated = f\"PO{100001 + len(ORDERS)}\", \"false\"\n            ORDERS[ref] = number\n            print(f\"order {number}: {qty} x {isbn} for {ref}\", flush=True)\n    return (f'<PlaceOrderResponse xmlns=\"{TNS}\"><OrderNo>{number}</OrderNo>'\n            f\"<Repeated>{repeated}</Repeated></PlaceOrderResponse>\")",
      "note": "`PlaceOrder` looks the reference up **before** it checks anything else. A reference it has seen gets the same order number back with `Repeated` set to true, and no second order. The lock keeps two orders arriving together from both taking the last copies."
    },
    {
      "code": "\n\nOPERATIONS = {f\"{{{TNS}}}GetStock\": get_stock, f\"{{{TNS}}}PlaceOrder\": place_order}",
      "note": "Which function answers is decided by the first element inside the `Body`, with its namespace."
    },
    {
      "code": "\n\nclass Distributor(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def send(self, status, text, content_type=\"text/xml; charset=utf-8\"):\n        data = text.encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", content_type)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        try:\n            self.wfile.write(data)\n        except (BrokenPipeError, ConnectionResetError):\n            print(\"the caller left before the answer\", flush=True)",
      "note": "Every answer leaves through `send`. A caller that hung up before the answer is not an error here, but it is not silence either: the log says so, because whatever the request did has already been done."
    },
    {
      "code": "\n    def do_GET(self):\n        if self.path.lower() != \"/distributor?wsdl\":\n            return self.send(404, \"no such document\\n\", \"text/plain\")\n        with open(os.path.join(HERE, \"distributor.wsdl\"), encoding=\"utf-8\") as f:\n            self.send(200, f.read())",
      "note": "The contract is published at the service's own address with `?wsdl` on the end, the convention every SOAP toolkit expects."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        slow = os.path.join(HERE, \"slow\")\n        if os.path.exists(slow):\n            with open(slow) as f:\n                time.sleep(float(f.read().strip() or 0))",
      "note": "The body is read whole first, as in `rest.py`. Then, while a file called `slow` exists beside the program, it waits the number of seconds written in it. That is how this lesson makes the distributor slow on request."
    },
    {
      "code": "        try:\n            if self.path != \"/distributor\":\n                raise Fault(\"Client\", f\"no service at {self.path}\")\n            if \"SOAPAction\" not in self.headers:\n                raise Fault(\"Client\", \"the SOAPAction header is missing\")\n            if b\"<!DOCTYPE\" in raw:\n                raise Fault(\"Client\", \"a SOAP message must not contain a DTD\")\n            try:\n                envelope = ET.fromstring(raw)\n            except ET.ParseError as e:\n                raise Fault(\"Client\", f\"not well-formed XML: {e}\")\n            req = envelope.find(f\"{{{SOAP}}}Body/*\")\n            if envelope.tag != f\"{{{SOAP}}}Envelope\" or req is None:\n                raise Fault(\"Client\", \"not a SOAP 1.1 envelope\")\n            if req.tag not in OPERATIONS:\n                raise Fault(\"Client\", f\"no operation {req.tag}\")\n            status, body = 200, OPERATIONS[req.tag](req)",
      "note": "The checks a SOAP service makes before it looks at the operation: a `SOAPAction` header, no document type declaration, well-formed XML, and an `Envelope` with a `Body`."
    },
    {
      "code": "        except Fault as f:\n            detail = f'<detail><ErrorCode xmlns=\"{TNS}\">{f.code}</ErrorCode></detail>' if f.code else \"\"\n            status, body = 500, (f\"<soap:Fault><faultcode>soap:{f.who}</faultcode>\"\n                                 f\"<faultstring>{escape(f.text)}</faultstring>{detail}</soap:Fault>\")\n        except Exception:\n            traceback.print_exc()\n            status, body = 500, (\"<soap:Fault><faultcode>soap:Server</faultcode>\"\n                                 \"<faultstring>internal error</faultstring></soap:Fault>\")\n        self.send(status, f'<soap:Envelope xmlns:soap=\"{SOAP}\"><soap:Body>{body}</soap:Body></soap:Envelope>')",
      "note": "Any fault becomes a `Fault` element inside an ordinary envelope, sent with HTTP **500**, whoever was to blame. That is SOAP 1.1's rule, and the section on faults is about what it costs. An exception nobody expected is printed in full to the log and answered as a `Server` fault."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8001), Distributor)\n    print(\"distributor on http://127.0.0.1:8001/distributor\", flush=True)\n    server.serve_forever()",
      "note": "Port 8001, on 127.0.0.1 only, so it can run beside a server on 8000."
    }
  ]
}
```

## Running it

The distributor needs a terminal of its own, like `rest.py` in lesson 1, and this lesson uses the
second terminal for it. In that terminal, stop `rest.py` with `Ctrl+C` and start the distributor
instead:

```sh
cd ~/shelf && python3 distributor.py
```

It prints one line and waits:

```
distributor on http://127.0.0.1:8001/distributor
```

Back in the first terminal, ask for the contract, the way every toolkit will:

```
ana@api:~/shelf$ curl -s 'localhost:8001/distributor?wsdl' | head -3
<!-- shelf/distributor.wsdl -->
<definitions name="Distributor"
    targetNamespace="http://distributor.example/stock"
```

The first line is the comment you typed. The service reads `distributor.wsdl` from its own
directory and sends it as it is, so **the contract a client downloads is the file you read**,
character for character. The file and `distributor.py` are still two things that could disagree:
rename an element in the code and the contract goes on promising the old name. Many real services
generate their WSDL from their code for that reason.
