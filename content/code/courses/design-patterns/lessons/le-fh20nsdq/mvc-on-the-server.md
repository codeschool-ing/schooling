---
title: MVC on the server, where the observer is lost
version: 1
---

**Every web framework says it is MVC, and every one of them means something different from
Smalltalk's.** On the server a route is the controller, a template is the view, and the controller
fetches what the view needs and hands it over. The view does not watch the model, because it
cannot: by the time the model changes again, the page it drew is in somebody's browser. The name
came along when an early JavaServer Pages specification, around 1998, described this arrangement
as *Model 2*, and Rails, Django, Spring MVC and ASP.NET MVC all followed that adaptation.

Here is the loan desk as a tiny web application, still on `desk_model.py`, with no framework:

```schooling-example
{"language": "python", "file": "web.py", "parts": [
 {"code": "# web.py\nfrom datetime import date\nfrom html import escape\nfrom urllib.parse import parse_qs\nfrom desk_model import Desk\n\ndesk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\nTODAY = date(2026, 3, 2)", "note": "The same model, imported unchanged. One desk lives as long as the process, which is how a small server keeps state between requests until lesson 10 gives it a database."},
 {"code": "\n\ndef shelf_page(on_shelf: list[str], loans: int) -> str:\n    items = \"\".join(f\"<li>{escape(code)}</li>\" for code in sorted(on_shelf))\n    return f\"<h1>On the shelf</h1><ul>{items}</ul><p>{loans} out</p>\"\n\n\ndef message_page(text: str) -> str:\n    return f\"<p class=msg>{escape(text)}</p>\"", "note": "The views. Each is a function from plain values to HTML; neither has heard of `Desk`. `escape` is the view's job, because only the view knows the output is HTML."},
 {"code": "\n\ndef show_shelf(form: dict) -> tuple[str, str]:\n    return \"200 OK\", shelf_page(desk.on_shelf, len(desk.loans))\n\n\ndef lend(form: dict) -> tuple[str, str]:\n    try:\n        loan = desk.lend(form[\"code\"], form[\"member\"], TODAY)\n    except ValueError as err:\n        return \"409 Conflict\", message_page(f\"refused: {err}\")\n    return \"200 OK\", message_page(f\"{loan.code} due back {loan.due}\")", "note": "The controllers. Each takes what the request carried, calls the model, and picks a view and a status. A refusal becomes `409 Conflict`, which is a decision about HTTP and so belongs here rather than in the model."},
 {"code": "\n\nROUTES = {\n    (\"GET\", \"/shelf\"): show_shelf,\n    (\"POST\", \"/loans\"): lend,\n}", "note": "The route table is the list of controllers. Django's `urls.py`, Flask's `@app.route`, Express's `app.post` and Go's `http.HandleFunc` all build one of these."},
 {"code": "\n\ndef app(environ, start_response):\n    key = (environ[\"REQUEST_METHOD\"], environ[\"PATH_INFO\"])\n    controller = ROUTES.get(key)\n    if controller is None:\n        status, body = \"404 Not Found\", message_page(\"no such page\")\n    else:\n        size = int(environ.get(\"CONTENT_LENGTH\") or 0)\n        raw = environ[\"wsgi.input\"].read(size).decode()\n        form = {k: v[0] for k, v in parse_qs(raw).items()}\n        status, body = controller(form)\n    start_response(status, [(\"Content-Type\", \"text/html; charset=utf-8\")])\n    return [body.encode()]", "note": "A WSGI application: a function every Python web server knows how to call with the request, a dictionary, and a callback for the status line. It finds the controller, decodes the form, and returns the page."},
 {"code": "\n\nif __name__ == \"__main__\":\n    import io\n    from wsgiref.util import setup_testing_defaults\n\n    def request(method: str, path: str, body: str = \"\") -> None:\n        environ = {\"REQUEST_METHOD\": method, \"PATH_INFO\": path,\n                   \"CONTENT_LENGTH\": str(len(body)), \"wsgi.input\": io.BytesIO(body.encode())}\n        setup_testing_defaults(environ)\n        print(f\"{method} {path} {body}\".rstrip())\n        page = app(environ, lambda status, headers: print(\" \", status))\n        print(\" \", page[0].decode())\n\n    request(\"GET\", \"/shelf\")\n    request(\"POST\", \"/loans\", \"code=B1&member=bia\")\n    request(\"POST\", \"/loans\", \"code=B1&member=caio\")\n    request(\"GET\", \"/shelf\")", "note": "Instead of starting a server, the program builds four requests the way a server would and calls `app` with each. The output is what a browser would receive."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 web.py
GET /shelf
  200 OK
  <h1>On the shelf</h1><ul><li>B1</li><li>B2</li><li>B3</li></ul><p>0 out</p>
POST /loans code=B1&member=bia
  200 OK
  <p class=msg>B1 due back 2026-03-16</p>
POST /loans code=B1&member=caio
  409 Conflict
  <p class=msg>refused: B1 is not on the shelf</p>
GET /shelf
  200 OK
  <h1>On the shelf</h1><ul><li>B2</li><li>B3</li></ul><p>1 out</p>
```

The second request lends B1 to Bia and the third, Caio asking for the same book, is refused with
`409 Conflict`. The last `GET /shelf` shows two items on the shelf and `1 out`, so the state
survived between requests because the `desk` object did. To try it in a browser, the standard
library's own server can call the same `app`:
`make_server("127.0.0.1", 8000, app).serve_forever()`, imported from `wsgiref.simple_server`. Nothing
else changes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l07-request\" aria-label=\"A sequence diagram of one request to web.py, POST /loans, read from top to bottom. Five lifelines: the browser, app, the lend controller, the Desk model and the message_page view. The browser sends the request to app; app looks up the route and calls lend with the form; lend calls desk.lend, which returns a Loan; lend calls message_page with a sentence and gets HTML back; lend returns 200 OK and the HTML to app, and app sends the response to the browser. After that the page is in the browser, and a later change to the desk redraws nothing until the browser asks again.\"><defs><marker id=\"l07-request-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l07-request-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><text x=\"70.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">client</text><path d=\"M70.0 72.0 L70.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"157.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app</text><text x=\"215.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">router</text><path d=\"M215.0 72.0 L215.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"302.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lend</text><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">controller</text><path d=\"M360.0 72.0 L360.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"447.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Desk</text><text x=\"505.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">model</text><path d=\"M505.0 72.0 L505.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"592.0\" y=\"19.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">message_page</text><text x=\"650.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">view</text><path d=\"M650.0 72.0 L650.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M74.0 96.0 L209.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"142.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /loans</text><path d=\"M219.0 122.0 L354.0 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"287.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend(form)</text><path d=\"M364.0 148.0 L499.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"432.5\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">desk.lend(…)</text><path d=\"M501.0 174.0 L366.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"432.5\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Loan</text><path d=\"M364.0 200.0 L644.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-request-dp-ah-phosphor)\"></path><text x=\"505.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">message_page(…)</text><path d=\"M646.0 226.0 L366.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"505.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt;…&lt;/p&gt;</text><path d=\"M356.0 252.0 L221.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"287.5\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;200 OK&quot;, html</text><path d=\"M211.0 278.0 L76.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-request-dp-ah-paper-dim)\"></path><text x=\"142.5\" y=\"269.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the page</text><text x=\"360.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the page is sent: a later change to the desk redraws nothing until the next request</text></svg>", "caption": "One request, top to bottom. The controller calls the model, hands plain values to a view, and the page leaves; nothing is watching afterwards."}
```

## What changed from the desktop version

Three things, and each follows from HTTP.

**The view receives values, it does not read the model.** `shelf_page` takes a list and a number.
It could be a Jinja2 or Django template, a Thymeleaf page in Spring or an `html/template` file in Go;
all of them are functions from a dictionary of values to text. That is a real gain over the
desktop view of the last section, whose formatting could only be checked on a screen. Here a test
calls `shelf_page(["B2"], 1)` and reads a string.

**Nobody subscribes.** `desk.subscribe` is never called in `web.py`. A change on the desk cannot
reach a page already sent, so each request renders from scratch, and a page that needs to update on
its own has to ask again or hold a connection open. That job moved to code running in the browser,
which is where MVP and MVVM come back in.

**The controller decides about HTTP.** The status code, which view to use, and what a refusal looks
like to a browser are presentation decisions about the web, and they sit in `lend`. The model still
raises a `ValueError` with a sentence, exactly as it did for the terminal.

## The names, framework by framework

The words drift, so read each framework by its arrows rather than its vocabulary:

| framework | the controller is | the view is |
|---|---|---|
| Django (Python) | a function or class in `views.py` | a template; Django calls the pattern MTV, model-template-view |
| Flask (Python) | a function under `@app.route` | a Jinja2 template |
| Express (JavaScript / TypeScript) | a handler passed to `app.get` or `app.post` | a template engine, or `res.json` for an API |
| Spring MVC (Java) | a method in a `@Controller` class | a Thymeleaf or JSP page, or a returned object for an API |
| `net/http` (Go) | an `http.HandlerFunc` | an `html/template`, or `json.NewEncoder(w)` |

Django's naming is the one that confuses people most: its "view" is the controller of the table
above. The arrows are the same as every other row.

**A route handler that does the work itself is the tangled loop again, with a URL in front of
it.** The commonest server-side mistake is a controller that opens the database, checks the limit,
computes the fine and formats the reply in one function. Keep the rule in the model and the
controller is three lines: read the request, call the model, choose a view.

For an API that returns JSON, the "view" is only the serialiser. The presentation patterns of the
next two sections live in the client that reads it: a browser application or a phone app, with its
own screen and its own model of what to show.
