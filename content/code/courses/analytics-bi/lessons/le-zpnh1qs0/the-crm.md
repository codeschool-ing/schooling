---
title: A CRM to send to
version: 1
---

A real reverse ETL sends to Salesforce, HubSpot or a help desk, through each one's API, with an
account and a contract. To build the job without any of that, you need something that behaves like a
CRM's API and runs on your machine. Here is one, small enough to read. You do not need to know Python
to use it: copy it with the button on the code and save it as `~/reverse/crm.py`.

```schooling-example
{"language": "python", "file": "crm.py", "parts": [{"code": "# crm.py: a pretend CRM, so the sync has somewhere to send contacts.\nimport json, time\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom urllib.parse import urlparse, parse_qs\n\nHEALTH = {\"active\", \"at risk\", \"lapsed\"}\nLIMIT = 10                      # requests per second before it refuses\ncontacts, seen, stats = [], [], {\"requests\": 0, \"refused\": 0}", "note": "It uses only Python's standard library, so it runs with the `python3` Ubuntu already has. `HEALTH` is the CRM's picklist: the only values its health field accepts. `LIMIT` is how many requests a second it allows, like every real CRM's API."}, {"code": "class CRM(BaseHTTPRequestHandler):\n    def reply(self, code, body, extra=None):\n        data = json.dumps(body).encode()\n        self.send_response(code)\n        self.send_header(\"Content-Type\", \"application/json\")\n        for k, v in (extra or {}).items():\n            self.send_header(k, v)\n        self.send_header(\"Content-Length\", str(len(data)))\n        self.end_headers()\n        self.wfile.write(data)", "note": "Every answer is JSON with a status code, the way a real API answers."}, {"code": "    def busy(self):\n        now = time.time()\n        seen[:] = [t for t in seen if now - t < 1] + [now]\n        stats[\"requests\"] += 1\n        if len(seen) > LIMIT:\n            stats[\"refused\"] += 1\n            self.reply(429, {\"error\": \"too many requests\"}, {\"Retry-After\": \"1\"})\n            return True\n        return False", "note": "A request beyond `LIMIT` in the last second is refused with `429` and a `Retry-After` header saying how long to wait. Real APIs do this to protect themselves, and a sync has to respect it."}, {"code": "    def body(self):\n        return json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n\n    def do_GET(self):\n        url = urlparse(self.path)\n        if url.path == \"/stats\":\n            return self.reply(200, dict(stats, contacts=len(contacts)))\n        wanted = parse_qs(url.query).get(\"external_id\", [None])[0]\n        self.reply(200, [c for c in contacts if wanted in (None, c[\"external_id\"])])", "note": "`GET /contacts?external_id=…` lists the records with that key, and `/stats` says how many contacts it holds and how many requests it refused."}, {"code": "    def do_POST(self):\n        if self.busy():\n            return\n        contact = self.body()\n        contacts.append(dict(contact, crm_id=len(contacts) + 1))\n        self.reply(201, {\"status\": \"created\", \"crm_id\": len(contacts)})", "note": "`POST /contacts` always creates a new record, whatever is in it. That is what most CRMs do with POST, and this lesson shows what it does to a sync."}, {"code": "    def do_PUT(self):\n        if self.busy():\n            return\n        external_id, contact = self.path.rsplit(\"/\", 1)[1], self.body()\n        if contact.get(\"health\") not in HEALTH:\n            return self.reply(400, {\"error\": \"health must be one of \" + \", \".join(sorted(HEALTH))})\n        for c in contacts:\n            if c[\"external_id\"] == external_id:\n                c.update(contact)\n                return self.reply(200, {\"status\": \"updated\"})\n        contacts.append(dict(contact, external_id=external_id, crm_id=len(contacts) + 1))\n        self.reply(201, {\"status\": \"created\"})", "note": "`PUT /contacts/<id>` is an upsert keyed on the external id: update the record if it exists, create it if not. A health outside the picklist is refused with `400`."}, {"code": "    def do_DELETE(self):\n        if self.busy():\n            return\n        external_id = self.path.rsplit(\"/\", 1)[1]\n        before = len(contacts)\n        contacts[:] = [c for c in contacts if c[\"external_id\"] != external_id]\n        self.reply(200 if len(contacts) < before else 404, {\"status\": \"deleted\" if len(contacts) < before else \"not found\"})\n\n    def log_message(self, *args):\n        pass                    # quiet: the sync prints what matters", "note": "`DELETE /contacts/<id>` removes the records with that key. The last two lines silence the server's own request log."}, {"code": "HTTPServer((\"127.0.0.1\", 8000), CRM).serve_forever()", "note": "It listens on port 8000, on the machine only, and keeps everything in memory: stop it and the CRM is empty again."}]}
```

It behaves like the APIs it stands in for in the three ways a sync has to cope with: it identifies a
contact by a key you choose, it refuses values its fields do not allow, and it refuses requests that
arrive too fast. It differs in one way that matters for this lesson only: it forgets everything when
stopped, so a fresh start is a fresh CRM.

Open a **second terminal**, connect to the machine again with `ssh`, and start it there:

```sh
cd ~/reverse
python3 crm.py
```

It prints nothing and keeps running until Ctrl+C. Back in the first terminal, ask it how it is:

```
ana@vm:~/reverse$ curl -s -w '\n' localhost:8000/stats
{"requests": 0, "refused": 0, "contacts": 0}
```

An empty CRM, no requests yet. Leave it running for the rest of the lesson.
