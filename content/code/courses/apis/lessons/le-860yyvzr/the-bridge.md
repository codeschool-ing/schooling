---
title: An adapter at the boundary
version: 1
---

The tempting design is the one `restock.py` already is: wherever the shop needs to know about
stock, build a zeep client and call the distributor. It works on the first day. By the tenth, the
catalogue page reads `QtyAvail`, the order screen catches `zeep.exceptions.Fault` and compares
`E200`, and the price arrives in reais as a `Decimal` in a codebase that counts cents. **The
distributor's model has leaked into the shop**, and on the day the distributor changes a name, or
the shop changes distributor, every one of those places changes with it.

The fix has a name from domain-driven design: an **anti-corruption layer**. One module sits on the
boundary, speaks the old system's language on one side and the shop's on the other, and translates
in both directions, so that nothing past it knows the old system exists. The legacy model is kept
out rather than tidied up, which is the point of the name: the old system is not wrong, it is
somebody else's, and the shop should not be shaped by it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"The anti-corruption layer as a boundary. On the left, the shelf side speaks JSON on 127.0.0.1:8000. On the right, the distributor side speaks SOAP on 127.0.0.1:8001. bridge.py sits on the line between them and is the only program that reads distributor.wsdl. Five translations cross it: QtyAvail becomes available, 18.90 reais becomes 1890 cents, 20261012 becomes 2026-10-12, fault E200 with HTTP 500 becomes 409, and no answer within 2 seconds becomes 504.\"><defs><marker id=\"l05-acl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the shelf&#x27;s words: JSON</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the distributor&#x27;s words: SOAP</text><rect x=\"290\" y=\"36\" width=\"120\" height=\"222\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bridge.py</text><text x=\"350\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads the WSDL;</text><text x=\"350\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nobody else does</text><rect x=\"70\" y=\"106\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;available&quot;: 20</text><rect x=\"440\" y=\"106\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">QtyAvail 20</text><line x1=\"438\" y1=\"118\" x2=\"262\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"136\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;price_cents&quot;: 1890</text><rect x=\"440\" y=\"136\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UnitPrice 18.90</text><line x1=\"438\" y1=\"148\" x2=\"262\" y2=\"148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"166\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;2026-10-12&quot;</text><rect x=\"440\" y=\"166\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NextDelivery 20261012</text><line x1=\"438\" y1=\"178\" x2=\"262\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"196\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">409</text><rect x=\"440\" y=\"196\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fault E200, HTTP 500</text><line x1=\"438\" y1=\"208\" x2=\"262\" y2=\"208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line><rect x=\"70\" y=\"226\" width=\"190\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">504</text><rect x=\"440\" y=\"226\" width=\"210\" height=\"24\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no answer in 2 s</text><line x1=\"438\" y1=\"238\" x2=\"262\" y2=\"238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-acl-ah)\"></line></svg>", "caption": "The adapter is the boundary. Everything on the left is in the shelf's terms, everything on the right in the distributor's, and only bridge.py knows both."}
```

`bridge.py` is that layer for the shelf. It offers two addresses in the shelf's own style, JSON
like `rest.py`, and is the only file in the project that knows about SOAP. Save it beside the
others:

```schooling-example
{
  "language": "python",
  "file": "shelf/bridge.py",
  "parts": [
    {
      "code": "# shelf/bridge.py\n\"\"\"The distributor as the shelf wants to see it: small JSON on 127.0.0.1:8000.\n\nEverything the SOAP service says passes through here and comes out in the\nshelf's terms: its names, its units, its faults and its silences.\n\"\"\"\nimport json\nimport os\nimport re\nfrom datetime import datetime\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport requests\nimport zeep\nfrom zeep.transports import Transport",
      "note": "`zeep` speaks to the distributor and `requests` is the HTTP library zeep is built on, imported here only for its two exceptions."
    },
    {
      "code": "\nWSDL = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"distributor.wsdl\")\nTIMEOUT = 2  # seconds the shelf waits for the distributor, and not one more\ndistributor = zeep.Client(WSDL, transport=Transport(operation_timeout=TIMEOUT)).service",
      "note": "The client is built from the **copy of the WSDL in the project**, not from the live service. The bridge starts even while the distributor is down, and a change on their side cannot reach this code until somebody replaces the file and reads the diff. `operation_timeout` is the most important number in the file."
    },
    {
      "code": "\n# The distributor's error codes, in the shelf's terms.\nFAULTS = {\n    \"E100\": (404, \"the distributor does not sell that ISBN\"),\n    \"E200\": (409, \"the distributor does not have that many copies\"),\n    \"E300\": (422, \"an order needs a reference and a quantity above zero\"),\n}",
      "note": "The distributor's error codes, written once, each as a status and a sentence in the shelf's own words. Nothing else in the shelf ever sees `E200`."
    },
    {
      "code": "\n\ndef call(operation, **args):\n    \"\"\"(answer, None), or (None, (status, message)): never a fault, never a hang.\"\"\"\n    try:\n        return getattr(distributor, operation)(**args), None\n    except zeep.exceptions.Fault as fault:\n        code = None if fault.detail is None else fault.detail.findtext(\n            \"{http://distributor.example/stock}ErrorCode\")\n        return None, FAULTS.get(code, (502, f\"the distributor failed: {fault.message}\"))\n    except requests.Timeout:\n        return None, (504, f\"the distributor did not answer within {TIMEOUT} s\")\n    except requests.ConnectionError:\n        return None, (502, \"the distributor cannot be reached\")",
      "note": "Every call goes through `call`, which always comes back with an answer or a status. A fault with a known code becomes that code's status; any other fault becomes **502**; no answer within the timeout becomes **504**; a refused connection becomes **502**."
    },
    {
      "code": "\n\nclass Bridge(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value):\n        body = (json.dumps(value) + \"\\n\").encode()\n        self.send_response(status)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "The answer is JSON and nothing else, the same shape of reply as `rest.py`."
    },
    {
      "code": "\n    def do_GET(self):\n        m = re.fullmatch(r\"/stock/(\\d{13})\", self.path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        stock, error = call(\"GetStock\", ISBN=m.group(1))\n        if error:\n            return self.reply(error[0], {\"error\": error[1]})\n        self.reply(200, {\n            \"isbn\": stock.ISBN,\n            \"available\": stock.QtyAvail,\n            \"price_cents\": int(stock.UnitPrice * 100),\n            \"next_delivery\": datetime.strptime(stock.NextDelivery, \"%Y%m%d\").date().isoformat(),\n        })",
      "note": "The translation in one place. `QtyAvail` becomes `available`, a price of `18.90` reais becomes `1890` cents, as everywhere in the shelf, and `20261012` becomes an ISO date. `stock.UnitPrice` is a `Decimal`, so the multiplication is exact."
    },
    {
      "code": "\n    def do_POST(self):\n        raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        if self.path != \"/orders\":\n            return self.reply(404, {\"error\": \"no such resource\"})\n        try:\n            order = json.loads(raw)\n            isbn, quantity, reference = order[\"isbn\"], order[\"quantity\"], order[\"reference\"]\n        except (ValueError, TypeError, KeyError):\n            return self.reply(400, {\"error\": \"send isbn, quantity and reference as JSON\"})\n        if type(quantity) is not int or not isinstance(isbn, str) or not isinstance(reference, str):\n            return self.reply(422, {\"error\": \"isbn and reference are text, quantity a whole number\"})\n        placed, error = call(\"PlaceOrder\", ISBN=isbn, Qty=quantity, CustomerRef=reference)\n        if error:\n            return self.reply(error[0], {\"error\": error[1]})\n        self.reply(200 if placed.Repeated else 201, {\n            \"order\": placed.OrderNo, \"isbn\": isbn, \"quantity\": quantity, \"reference\": reference,\n        })",
      "note": "An order needs a reference from the caller, which goes to the distributor as `CustomerRef`. A new order answers **201**; the same reference again answers **200** with the order that already exists."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Bridge)\n    print(f\"bridge on http://127.0.0.1:8000, waiting {TIMEOUT} s at most\", flush=True)\n    server.serve_forever()",
      "note": "Port 8000, where `rest.py` listens, so the two do not run at the same time."
    }
  ]
}
```

## Running it

The bridge listens on port 8000, where `rest.py` did, so `rest.py` stays stopped. The distributor
keeps the second terminal; open a **third** one (`multipass shell api` again, with Multipass) and
start the bridge in it:

```sh
cd ~/shelf && python3 bridge.py
```

It says how long it will wait for the distributor:

```
bridge on http://127.0.0.1:8000, waiting 2 s at most
```

Every request from now on goes to the bridge, on port 8000. Stock first, then the two faults the
previous section mapped, then an order that breaks a rule and the same order made properly:

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

**Nothing in those answers is the distributor's.** `available` instead of `QtyAvail`, 1890 cents
instead of 18.90 reais, an ISO date instead of eight digits, and statuses the shelf's clients
already understand from lesson 1. The 422 came from the distributor's fault `E300`, and the 201
for the order with a quantity of 2 is the shelf's way of saying *created*. The reference `R-2001`
was used for all three orders, and only the third was placed, because the other two were refused.

## A distributor that does not answer

A fault is the easy failure, because it is an answer. The hard one is silence. Make the stand-in
slow: while a file called `slow` is in `~/shelf`, it waits that many seconds before it does
anything. Write 5 in it, and order through the bridge:

```
ana@api:~/shelf$ echo 5 > slow
ana@api:~/shelf$ curl -s -w '%{http_code} after %{time_total} s\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}'
{"error": "the distributor did not answer within 2 s"}
504 after 2.008635 s
```

**The bridge answered 504 after two seconds, because `operation_timeout` told it to.** Without
that one argument, zeep would wait as long as the distributor took, and every request to the shelf
that needed the distributor would wait with it, each one holding a thread and a connection, until
the shop's own callers gave up on the shop. A timeout turns *the distributor is slow* into a fast,
honest answer.

Leave the `slow` file where it is for a moment. The 504 says the shelf gave up; it does not say
what happened to the order, and the section after next is about finding out.
