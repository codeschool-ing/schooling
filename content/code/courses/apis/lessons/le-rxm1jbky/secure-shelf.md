---
title: The secured shelf
version: 1
---

This lesson adds two files to `~/shelf` and changes nothing that is already there. **`secure.py` is
the books API with every defence of the lesson built in**, and `site/page.html` is a web page that
calls it from another origin, which is what makes those defences visible. Lesson 1's `rest.py` stays
as it was; you can start this lesson from the end of lesson 1.

`secure.py` serves one kind of address, a single book at `/v1/books/<id>`, with two methods: GET
reads it and PATCH changes its stock. That is small on purpose. A GET is the request a browser sends without asking first, and a
PATCH with a JSON body is one it has to ask about, so between them they show both halves of CORS.
Save it as `~/shelf/secure.py` with `nano`, as you saved `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/secure.py",
  "parts": [
    {
      "code": "# shelf/secure.py\n\"\"\"The books API with lesson 13's defences: CORS, security headers and HTTPS.\n\n    python3 secure.py                  http://127.0.0.1:8000\n    python3 secure.py --tls            https://127.0.0.1:8443, with tls/server.crt\n    python3 secure.py --host 0.0.0.0 --origin http://192.168.64.5:8080\n\"\"\"\nimport argparse\nimport json\nimport os\nimport re\nimport ssl\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db\n\nHERE = os.path.dirname(os.path.abspath(__file__))",
      "note": "The same standard library as `rest.py`, plus `ssl` for the HTTPS mode and `argparse` for the three options in the docstring. `HERE` lets the program find its certificate whichever directory it is started from."
    },
    {
      "code": "ORIGINS = {\"http://localhost:8080\"}",
      "note": "The **allowlist**: the origins of the pages that may read this API's answers. It is a set of whole strings, compared exactly, and `--origin` adds to it when the program starts."
    },
    {
      "code": "SECURITY = [\n    (\"Content-Security-Policy\", \"default-src 'none'; frame-ancestors 'none'\"),\n    (\"X-Content-Type-Options\", \"nosniff\"),\n    (\"Referrer-Policy\", \"no-referrer\"),\n    (\"Cache-Control\", \"no-store\"),\n]\nHSTS = (\"Strict-Transport-Security\", \"max-age=31536000\")",
      "note": "Four headers that go on **every** answer, errors included, and a fifth that only makes sense over HTTPS. The section on headers says what each one does."
    },
    {
      "code": "\n\nclass Secure(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    tls = False\n\n    def version_string(self):\n        return \"shelf\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True",
      "note": "`version_string` is what the library puts in the `Server` header. Lesson 1's API sent the exact Python version there; this one sends a name and nothing else. The body is read whole before anything answers, as in `rest.py`."
    },
    {
      "code": "\n    def cors(self):\n        \"\"\"Vary always; Allow-Origin only for a page on the list.\"\"\"\n        headers = getattr(self, \"headers\", None)\n        origin = headers.get(\"Origin\") if headers else None\n        if origin in ORIGINS:\n            return [(\"Access-Control-Allow-Origin\", origin), (\"Vary\", \"Origin\")]\n        return [(\"Vary\", \"Origin\")]",
      "note": "The CORS decision, in one place. A page on the list gets its own origin back in `Access-Control-Allow-Origin`; any other origin gets nothing. `Vary: Origin` goes out either way, because the answer depends on that header even when it says no."
    },
    {
      "code": "\n    def reply(self, status, value=None, extra=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in SECURITY + ([HSTS] if self.tls else []) + self.cors() + list(extra):\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, extra=()):\n        self.reply(status, {\"error\": message}, extra)",
      "note": "Every answer leaves through `reply`, which is what makes \"every answer\" true: the security headers, HSTS when the connection is HTTPS, the CORS headers, then whatever the caller adds."
    },
    {
      "code": "\n    def send_error(self, code, message=None, explain=None):\n        \"\"\"What the library would have answered in HTML, answered in JSON.\"\"\"\n        self.close_connection = True\n        self.error(code, message or self.responses[code][0])",
      "note": "The library answers some errors itself, a method it has never heard of or a malformed request line, and it answers them in HTML with none of the headers above. Overriding `send_error` sends those through `reply` as well."
    },
    {
      "code": "\n    def book(self):\n        m = re.fullmatch(r\"/v1/books/(\\d+)\", self.path.split(\"?\")[0])\n        return int(m.group(1)) if m else None\n\n    def do_OPTIONS(self):\n        \"\"\"The preflight: may this page send this method with these headers?\"\"\"\n        if self.book() is None:\n            return self.error(404, \"no such resource\")\n        extra = [(\"Allow\", \"GET, PATCH, OPTIONS\")]\n        if self.headers.get(\"Origin\") in ORIGINS:\n            extra += [(\"Access-Control-Allow-Methods\", \"GET, PATCH\"),\n                      (\"Access-Control-Allow-Headers\", \"Content-Type\"),\n                      (\"Access-Control-Max-Age\", \"600\")]\n        self.reply(204, None, extra)",
      "note": "The **preflight**. Any client may ask which methods the address takes, and gets `Allow`. A page on the list also gets the methods and headers it may send, and `Max-Age`, the number of seconds its browser may remember the answer. It answers **204**, where lesson 1's API answered 501."
    },
    {
      "code": "\n    def do_GET(self):\n        ident = self.book()\n        if ident is None:\n            return self.error(404, \"no such resource\")\n        with db.connect() as conn:\n            row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\", (ident,)).fetchone()\n        return self.reply(200, dict(row)) if row else self.error(404, f\"no book {ident}\")\n\n    def do_PATCH(self):\n        ident = self.book()\n        if ident is None:\n            return self.error(404, \"no such resource\")\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            return self.error(415, \"send the change as application/json\")\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            return self.error(400, \"the body is not valid JSON\")\n        if (not isinstance(value, dict) or set(value) != {\"stock\"}\n                or type(value[\"stock\"]) is not int or value[\"stock\"] < 0):\n            return self.error(422, \"send {\\\"stock\\\": n}, n a whole number from 0\")\n        with db.connect() as conn:\n            conn.execute(\"UPDATE books SET stock = ? WHERE id = ?\", (value[\"stock\"], ident))\n            row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\", (ident,)).fetchone()\n        return self.reply(200, dict(row)) if row else self.error(404, f\"no book {ident}\")",
      "note": "One book, read and changed. PATCH accepts a single field, `stock`, and refuses everything else with the codes lesson 1 chose. Nothing in these two methods mentions CORS: the decision was made once, in `cors`."
    },
    {
      "code": "\n    def refuse(self):\n        self.error(405, f\"{self.command} is not allowed here\", [(\"Allow\", \"GET, PATCH, OPTIONS\")])\n\n    do_POST = do_PUT = do_DELETE = refuse",
      "note": "POST, PUT and DELETE are methods the library knows, so they get **405** and an `Allow` header instead of a 501."
    },
    {
      "code": "\n\ndef main():\n    args = argparse.ArgumentParser()\n    args.add_argument(\"--host\", default=\"127.0.0.1\")\n    args.add_argument(\"--origin\", action=\"append\", default=[])\n    args.add_argument(\"--tls\", action=\"store_true\")\n    a = args.parse_args()\n    ORIGINS.update(a.origin)\n    port = 8443 if a.tls else 8000\n    server = ThreadingHTTPServer((a.host, port), Secure)",
      "note": "Plain HTTP on port 8000 unless `--tls` is given. `--host` decides which address it listens on: 127.0.0.1 by default, which only this machine can reach."
    },
    {
      "code": "    if a.tls:\n        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)\n        ctx.minimum_version = ssl.TLSVersion.TLSv1_2\n        ctx.load_cert_chain(os.path.join(HERE, \"tls/server.crt\"), os.path.join(HERE, \"tls/server.key\"))\n        server.socket = ctx.wrap_socket(server.socket, server_side=True)\n        Secure.tls = True\n    scheme = \"https\" if a.tls else \"http\"\n    print(f\"secure shelf on {scheme}://{a.host}:{port}, pages allowed: {' '.join(sorted(ORIGINS))}\",\n          flush=True)\n    server.serve_forever()\n\n\nif __name__ == \"__main__\":\n    main()",
      "note": "The HTTPS mode on port 8443: the same server, its listening socket wrapped in TLS with the certificate and key the HTTPS section makes. Versions of TLS older than 1.2 are refused."
    }
  ]
}
```

## The page

The page has two buttons. "Read it" sends a GET, "Set the stock to 11" sends a PATCH, and each prints
what came back, or the error, under the buttons and in the browser's console. It builds the API's
address from its own, swapping the port for 8000, so it calls the API on whichever host it was
loaded from.

```sh
mkdir ~/shelf/site
```

Save it as `~/shelf/site/page.html`:

```html
<!-- shelf/site/page.html -->
<!doctype html>
<meta charset="utf-8">
<title>A page on another origin</title>
<h1>Book 1, read from another origin</h1>
<button id="read">Read it</button>
<button id="sell">Set the stock to 11</button>
<pre id="out"></pre>
<script>
  const api = `${location.protocol}//${location.hostname}:8000/v1/books/1`;
  const show = (line) => {
    document.getElementById("out").textContent += line + "\n";
    console.log(line);
  };
  document.getElementById("read").onclick = async () => {
    try {
      const r = await fetch(api);
      show(`GET ${r.status} ${await r.text()}`);
    } catch (e) {
      show(`GET failed: ${e}`);
    }
  };
  document.getElementById("sell").onclick = async () => {
    try {
      const r = await fetch(api, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ stock: 11 }),
      });
      show(`PATCH ${r.status} ${await r.text()}`);
    } catch (e) {
      show(`PATCH failed: ${e}`);
    }
  };
</script>
```

**The page lives in a directory of its own because the server that publishes it publishes
everything.** `python3 -m http.server` hands out every file under the directory it starts in, to
anybody who asks. Started in `~/shelf`, it would serve `shelf.db` and, by the end of the HTTPS
section, a private key.

With both files saved, the project looks like this:

```
ana@api:~/shelf$ ls; ls site
db.py
rest.py
secure.py
site
page.html
```

## Running both

Each server needs a terminal of its own, so this lesson uses three: the first for your commands, as
always, and two more for the servers. If `rest.py` is still running from an earlier lesson, stop it
with `Ctrl+C` first, because both programs want port 8000. In the second terminal:

```sh
cd ~/shelf && python3 secure.py
```

It names the address it listens on and the one origin it trusts:

```
secure shelf on http://127.0.0.1:8000, pages allowed: http://localhost:8080
```

And in the third:

```sh
cd ~/shelf/site && python3 -m http.server 8080
```

The API is now at `http://localhost:8000` and the page at `http://localhost:8080/page.html`. Same
machine, same name, different port: two origins, as the previous section showed.

## Seeing it in your own browser

**CORS is enforced by the browser, so the only way to watch it work is in one.** The VM has no
screen, and the browser you have is the one on your own computer. That raises a problem the curl
commands never had.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Your computer holds a browser and its own 127.0.0.1. Inside it, the VM has its own 127.0.0.1 and an address on a private network, 192.168.64.5. The browser reaches the VM only through that address; a server listening on the VM&#x27;s 127.0.0.1 cannot be reached from the browser.\"><defs><marker id=\"l13-vm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">your computer</text><rect x=\"30\" y=\"60\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">browser</text><rect x=\"30\" y=\"150\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"115.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the computer itself</text><rect x=\"330\" y=\"45\" width=\"370\" height=\"180\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">the VM, api</text><rect x=\"350\" y=\"85\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.64.5</text><text x=\"430.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its network address</text><rect x=\"350\" y=\"155\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"430.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the VM itself</text><rect x=\"540\" y=\"85\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"612.5\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">secure.py</text><text x=\"612.5\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--host 0.0.0.0</text><rect x=\"540\" y=\"155\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612.5\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">secure.py</text><text x=\"612.5\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">default: 127.0.0.1</text><line x1=\"200\" y1=\"85\" x2=\"348\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><text x=\"262\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">http://192.168.64.5:8000</text><line x1=\"115\" y1=\"110\" x2=\"115\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><text x=\"122\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">http://127.0.0.1:8000</text><text x=\"115\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nothing listens on 8000 here</text><line x1=\"510\" y1=\"110\" x2=\"538\" y2=\"110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line><line x1=\"510\" y1=\"180\" x2=\"538\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l13-vm-ah)\"></line></svg>", "caption": "Two different machines answer to 127.0.0.1. The browser on your computer reaches the VM only through the VM's address on its network, so the API has to listen there."}
```

`127.0.0.1` means "this machine" to whoever reads it. Inside the VM it is the VM; typed into the
browser on your computer it is your computer, where nothing listens on 8000. **To reach the VM from
outside, a server has to listen on an address the VM has on its network**, and `secure.py` listens
on `127.0.0.1` unless told otherwise. `http.server` already listens on every address the machine has.

Find the VM's address in your computer's own terminal:

```sh
multipass info api
```

The line that matters is `IPv4`. Suppose it says `192.168.64.5`; use your own wherever this lesson
writes that one. Stop `secure.py` with `Ctrl+C` and start it again listening on every address,
trusting the page as your browser will see it:

```sh
python3 secure.py --host 0.0.0.0 --origin http://192.168.64.5:8080
```

Then open `http://192.168.64.5:8080/page.html` in your browser, open its developer tools (`F12` in
most browsers, or `Ctrl+Shift+I`; `Cmd+Option+I` on a Mac) and choose the Console tab. **These three
commands were not run for this course**: the machine it was recorded on has no address outside
itself, for the reason lesson 1 gives. What the next sections quote from a browser was recorded with
Chromium on the recording computer, reaching the lab machine's `localhost`.

`0.0.0.0` means every address, and that is as wide as it sounds. Multipass puts the VM on a network
only your own computer can reach, which is what makes it safe here. On a machine rented online the
same command would put the API on the internet, so do not run it there.
