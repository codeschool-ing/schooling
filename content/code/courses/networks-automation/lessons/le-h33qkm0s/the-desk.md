---
title: The service desk
version: 1
---

The ticketing systems people use at work, ServiceNow, Jira Service Management or the open-source
desks such as Zammad and GLPI, are either licensed or a small data centre to install, and this
lesson needs only the part they share: tickets with a number, a status and comments, behind a JSON
API that takes a token. The lab's service desk is that part, a program called `deskd` written for
this course, and it runs on the machine called `tickets`.

It is short enough to read in full, and reading it tells you exactly what `opening-a-ticket` can
and cannot ask of it. Save it as `~/netlab/deskd.py`:

```python
#!/opt/netauto/bin/python
"""deskd: the lab's service desk, written for this course.

Lesson 7 opens tickets from network events, and the ticketing systems people
use at work (ServiceNow, Jira Service Management, Zammad, GLPI) are either
licensed or a small data centre to install. What they have in common is small,
and this is that part: tickets with a number, a status and comments, behind a
JSON API that takes a token in the Authorization header.

  POST   /api/tickets                 {"title", "body", "priority", "requester"}
  GET    /api/tickets?status=open&q=  search (q matches the title)
  GET    /api/tickets/<number>
  PATCH  /api/tickets/<number>        {"status": "open" | "resolved"}
  POST   /api/tickets/<number>/comments {"body"}

Tickets are kept in /var/lib/deskd/tickets.json and numbered from INC-1001.
"""
import json
import ssl
import sys
import threading
import urllib.parse
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONF = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "/etc/deskd/deskd.json"))
STORE = "/var/lib/deskd/tickets.json"
LOCK = threading.Lock()


def load():
    try:
        return json.load(open(STORE))
    except FileNotFoundError:
        return []


def save(tickets):
    with open(STORE, "w") as f:
        json.dump(tickets, f, indent=1)


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


class Desk(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def version_string(self):
        return "deskd/1.0"

    def log_message(self, fmt, *args):
        with open("/var/lib/deskd/access.log", "a") as f:
            f.write("%s %s %s\n" % (now(), self.address_string(), fmt % args))

    def send(self, status, body):
        data = (json.dumps(body, indent=2) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            return None
        return data if isinstance(data, dict) else None

    def route(self, verb):
        if self.headers.get("Authorization") != "Token " + CONF["token"]:
            return self.send(401, {"error": "send Authorization: Token <your token>"})
        url = urllib.parse.urlsplit(self.path)
        parts = [p for p in url.path.split("/") if p]
        q = urllib.parse.parse_qs(url.query)
        with LOCK:
            tickets = load()
            if parts == ["api", "tickets"] and verb == "GET":
                found = [t for t in tickets
                         if ("status" not in q or t["status"] == q["status"][0])
                         and ("q" not in q or q["q"][0].lower() in t["title"].lower())]
                return self.send(200, {"count": len(found), "results": found})
            if parts == ["api", "tickets"] and verb == "POST":
                b = self.body()
                if not b or not b.get("title"):
                    return self.send(400, {"error": "a ticket needs at least a title"})
                if b.get("priority", "normal") not in ("low", "normal", "high"):
                    return self.send(400, {"error": "priority is low, normal or high"})
                t = {"number": f"INC-{1001 + len(tickets)}", "title": b["title"],
                     "body": b.get("body", ""), "priority": b.get("priority", "normal"),
                     "requester": b.get("requester", ""), "status": "open",
                     "opened": now(), "comments": []}
                tickets.append(t)
                save(tickets)
                return self.send(201, t)
            if len(parts) >= 3 and parts[:2] == ["api", "tickets"]:
                t = next((t for t in tickets if t["number"] == parts[2]), None)
                if not t:
                    return self.send(404, {"error": f"no ticket {parts[2]}"})
                if len(parts) == 3 and verb == "GET":
                    return self.send(200, t)
                if len(parts) == 3 and verb == "PATCH":
                    b = self.body()
                    if not b or b.get("status") not in ("open", "resolved"):
                        return self.send(400, {"error": "status is open or resolved"})
                    t["status"] = b["status"]
                    save(tickets)
                    return self.send(200, t)
                if parts[3:] == ["comments"] and verb == "POST":
                    b = self.body()
                    if not b or not b.get("body"):
                        return self.send(400, {"error": "a comment needs a body"})
                    t["comments"].append({"time": now(), "body": b["body"]})
                    save(tickets)
                    return self.send(201, t)
            return self.send(404, {"error": f"nothing for {verb} {url.path}"})

    def do_GET(self): self.route("GET")
    def do_POST(self): self.route("POST")
    def do_PATCH(self): self.route("PATCH")


def main():
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ctx.load_cert_chain(CONF["cert"], CONF["key"])
    httpd = ThreadingHTTPServer((CONF["address"], 443), Desk)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
```

Rebuild the lab, and `netlab.sh` starts it, writes its token to `~/.desk-token` in `ana`'s home,
and says so:

```sh
sudo ~/netlab/netlab.sh reset
```
