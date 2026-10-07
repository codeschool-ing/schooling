---
title: A API do outro lado
version: 1
---

Os roteadores que você construiu na aula 1 rodam o FRR, e **o FRR não tem API REST nem porta
gNMI.** Os equipamentos que as pessoas automatizam no trabalho têm as duas, então o laboratório põe
na frente de cada roteador um programa pequeno que tem: o `devapid`, escrito para este curso. Toda
leitura que ele responde vem da saída JSON do próprio FRR ou dos contadores do kernel, e toda
mudança que ele aceita é um comando `vtysh`, o mesmo que uma pessoa digitaria. Ele não guarda nada
próprio além das sessões de login, das assinaturas de webhook e do contador que limita a velocidade com
que um cliente pode perguntar.

O que ele copia dos equipamentos reais é o padrão, que é o que esta aula e as aulas 4 e 7 ensinam:
um login que devolve um token que expira, JSON em tudo, os verbos HTTP com os códigos de status que
a norma dá a eles, páginas com um link `next`, `429` quando um cliente pergunta rápido demais, e
webhooks assinados com um segredo compartilhado. A porta gNMI da aula 4 é a segunda metade do mesmo
programa.

**Você não precisa lê-lo para acompanhar a aula.** Ele está aqui porque a aula não roda sem ele, e
porque um servidor que se pode ler é o melhor jeito de resolver o que um cliente viu: quando uma
transcrição abaixo responde `422` ou `409`, a linha que decidiu isso está neste arquivo. Salve-o
como `~/netlab/devapid.py`:

```python
#!/opt/netauto/bin/python
"""devapi: the management API of the lab's routers, written for this course.

A router you buy answers on a REST API and a gNMI port. FRR answers on neither,
so this program does, in front of it: every read comes from FRR (vtysh ... json)
or the kernel (/sys/class/net), and every write is a vtysh command, the same one
a person would type. Nothing is kept here that FRR does not also hold, apart
from sessions, webhook subscriptions and the rate limiter.

What it copies from real equipment, so the lessons can be about the pattern
rather than about this program:
  REST  a login that returns a bearer token which expires; JSON everywhere;
        GET/POST/PUT/PATCH/DELETE with the status codes RFC 9110 gives them;
        offset pagination with a `next` link, as NetBox and many controllers
        do; 429 with Retry-After when a client asks too fast; webhooks signed
        with HMAC-SHA256.
  gNMI  the gNMI 0.8 service (Capabilities, Get, Set, Subscribe) over TLS, with
        the credentials in the call's metadata, on port 9339, serving a subset
        of openconfig-interfaces and openconfig-system.

Configuration: /etc/devapi/devapi.json. Run as root inside the router.
"""
import base64
import hashlib
import hmac
import ipaddress
import json
import os
import re
import secrets
import socket
import ssl
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
from concurrent import futures
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import grpc
from pygnmi.spec.v080 import gnmi_pb2, gnmi_pb2_grpc

CONF = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "/etc/devapi/devapi.json"))
HOST = CONF["hostname"]
USERS = CONF["users"]              # name -> {"password": ..., "role": "read-write"|"read-only"}
TOKEN_LIFE = CONF.get("token_seconds", 900)
RATE = CONF.get("rate", [30, 10])  # at most RATE[0] requests per RATE[1] seconds, per token
STARTED = time.time()
LOCK = threading.Lock()


# ------------------------------------------------------------------ FRR itself
def vtysh(*commands):
    args = ["vtysh"]
    for c in commands:
        args += ["-c", c]
    r = subprocess.run(args, capture_output=True, text=True)
    return r.stdout + r.stderr


def vtysh_json(command):
    return json.loads(vtysh(command) or "{}")


def configure(lines):
    """Apply configuration lines to the running configuration, as a person would."""
    out = vtysh("configure terminal", *lines, "end")
    bad = [l for l in out.splitlines() if l.startswith("%")]
    if bad:
        raise ValueError("; ".join(bad))


def sysfs(ifname, name):
    try:
        return open(f"/sys/class/net/{ifname}/{name}").read().strip()
    except OSError:
        return None


def interfaces():
    raw = vtysh_json("show interface json")
    out = []
    for name in sorted(raw):
        i = raw[name]
        oper = sysfs(name, "operstate")
        if name == "lo":
            oper = "up"
        out.append({
            "name": name,
            "description": i.get("description", ""),
            "enabled": i.get("administrativeStatus") == "up",
            "oper_status": "up" if oper in ("up", "unknown") else "down",
            "mtu": i.get("mtu"),
            "mac_address": i.get("hardwareAddress", ""),
            "addresses": [a["address"] for a in i.get("ipAddresses", [])],
        })
    return out


def counters(ifname):
    s = lambda n: int(sysfs(ifname, "statistics/" + n) or 0)
    return {"in-octets": s("rx_bytes"), "out-octets": s("tx_bytes"),
            "in-pkts": s("rx_packets"), "out-pkts": s("tx_packets"),
            "in-errors": s("rx_errors"), "out-errors": s("tx_errors"),
            "in-discards": s("rx_dropped"), "out-discards": s("tx_dropped")}


def routes():
    raw = vtysh_json("show ip route json")
    out = []
    for prefix in sorted(raw, key=lambda p: ipaddress.ip_network(p)):
        for r in raw[prefix]:
            out.append({
                "prefix": prefix,
                "protocol": r.get("protocol"),
                "selected": bool(r.get("selected")),
                "distance": r.get("distance"),
                "metric": r.get("metric"),
                "next_hops": [{k: v for k, v in (("ip", n.get("ip")), ("interface", n.get("interfaceName"))) if v}
                              for n in r.get("nexthops", [])],
            })
    return out


STATIC = re.compile(r"^ip route (\S+) (\S+)(?: (\d+))?$")


def static_routes():
    out = []
    for line in vtysh("show running-config").splitlines():
        m = STATIC.match(line.strip())
        if m:
            out.append({"prefix": m[1], "next_hop": m[2], "distance": int(m[3] or 1)})
    return out


def version():
    first = vtysh("show version").splitlines()[0]
    return first.split(" (")[0]


# ------------------------------------------------------------------- webhooks
HOOKS = {}      # id -> subscription
DELIVERIES = []


def sign(secret, body):
    return "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()


def deliver(hook, event):
    body = json.dumps(event, separators=(",", ":")).encode()
    for attempt, wait in enumerate((0, 1, 2, 4), start=1):
        time.sleep(wait)
        req = urllib.request.Request(hook["url"], data=body, method="POST", headers={
            "Content-Type": "application/json",
            "User-Agent": "devapi/1.0",
            "X-Devapi-Event": event["event"],
            "X-Devapi-Delivery": event["id"],
            "X-Devapi-Signature": sign(hook["secret"], body)})
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                status = r.status
        except urllib.error.HTTPError as e:
            status = e.code
        except OSError:
            status = None
        with LOCK:
            DELIVERIES.append({"hook": hook["id"], "delivery": event["id"], "attempt": attempt,
                               "status": status, "time": now()})
        if status is not None and 200 <= status < 300:
            return


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def watch_links():
    """Turn a change of an interface's operational state into an event."""
    last = {}
    n = 0
    while True:
        for i in interfaces():
            before = last.get(i["name"])
            last[i["name"]] = i["oper_status"]
            if before is None or before == i["oper_status"]:
                continue
            n += 1
            event = {"id": f"{HOST}-{int(STARTED)}-{n}", "event": "interface." + i["oper_status"],
                     "device": HOST, "interface": i["name"], "description": i["description"],
                     "time": now()}
            for hook in list(HOOKS.values()):
                if event["event"] in hook["events"]:
                    threading.Thread(target=deliver, args=(hook, event), daemon=True).start()
        time.sleep(0.5)


# ------------------------------------------------------------------------ REST
SESSIONS = {}   # token -> (user, expires)
BUCKETS = {}    # token -> [request times]


class Problem(Exception):
    def __init__(self, status, message, **extra):
        self.status, self.message, self.extra = status, message, extra


def page(items, query, path):
    try:
        limit = int(query.get("limit", ["50"])[0])
        offset = int(query.get("offset", ["0"])[0])
    except ValueError:
        raise Problem(400, "limit and offset are whole numbers")
    if not 1 <= limit <= 100 or offset < 0:
        raise Problem(400, "limit is between 1 and 100, and offset is 0 or more")
    base = f"https://{HOST}.example.net{path}"
    keep = {k: v[0] for k, v in query.items() if k not in ("limit", "offset")}

    def link(o):
        return base + "?" + urllib.parse.urlencode({**keep, "limit": limit, "offset": o})

    return {"count": len(items),
            "next": link(offset + limit) if offset + limit < len(items) else None,
            "previous": link(max(offset - limit, 0)) if offset > 0 else None,
            "results": items[offset:offset + limit]}


class Api(BaseHTTPRequestHandler):
    def version_string(self):
        return "devapi/1.0"
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        with open("/var/log/devapi.log", "a") as f:
            f.write("%s %s %s\n" % (now(), self.address_string(), fmt % args))

    # --- plumbing
    def send(self, status, body=None, headers=()):
        data = b"" if body is None else (json.dumps(body, indent=2) + "\n").encode()
        self.send_response(status)
        if body is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        if not raw:
            return {}
        if not (self.headers.get("Content-Type") or "").startswith("application/json"):
            raise Problem(415, "send the body as application/json")
        try:
            data = json.loads(raw)
        except ValueError:
            raise Problem(400, "the body is not valid JSON")
        if not isinstance(data, dict):
            raise Problem(400, "the body is a JSON object")
        return data

    def who(self):
        auth = self.headers.get("Authorization", "")
        token = auth[7:] if auth.startswith("Bearer ") else None
        s = SESSIONS.get(token)
        if not s:
            raise Problem(401, "missing or unknown token: log in at /api/v1/auth/login")
        if s[1] < time.time():
            del SESSIONS[token]
            raise Problem(401, "the token has expired: log in again")
        with LOCK:
            times = [t for t in BUCKETS.get(token, []) if t > time.time() - RATE[1]]
            if len(times) >= RATE[0]:
                BUCKETS[token] = times
                raise Problem(429, f"more than {RATE[0]} requests in {RATE[1]} seconds",
                              retry=int(times[0] + RATE[1] - time.time()) + 1)
            times.append(time.time())
            BUCKETS[token] = times
        return s[0]

    def writer(self):
        user = self.who()
        if USERS[user]["role"] != "read-write":
            raise Problem(403, f"{user} may read and may not change anything")
        return user

    def handle_any(self, verb):
        url = urllib.parse.urlsplit(self.path)
        path = url.path.rstrip("/") or "/"
        query = urllib.parse.parse_qs(url.query)
        try:
            for pattern, handlers in ROUTES:
                m = re.fullmatch(pattern, path)
                if m:
                    h = handlers.get(verb)
                    if not h:
                        raise Problem(405, f"{verb} is not allowed on {path}",
                                      allow=", ".join(sorted(handlers)))
                    return h(self, query, path, *[urllib.parse.unquote(g) for g in m.groups()])
            raise Problem(404, f"nothing at {path}")
        except Problem as p:
            headers = []
            if p.status == 401:
                headers.append(("WWW-Authenticate", 'Bearer realm="devapi"'))
            if p.status == 429:
                headers.append(("Retry-After", str(p.extra["retry"])))
            if p.status == 405:
                headers.append(("Allow", p.extra["allow"]))
            body = {"error": p.message}
            body.update({k: v for k, v in p.extra.items() if k not in ("retry", "allow")})
            self.send(p.status, body, headers)

    def do_GET(self): self.handle_any("GET")
    def do_POST(self): self.handle_any("POST")
    def do_PUT(self): self.handle_any("PUT")
    def do_PATCH(self): self.handle_any("PATCH")
    def do_DELETE(self): self.handle_any("DELETE")

    # --- resources
    def login(self, q, path):
        b = self.body()
        u = USERS.get(b.get("username"))
        if not u or not hmac.compare_digest(u["password"], str(b.get("password", ""))):
            raise Problem(401, "wrong username or password")
        token = secrets.token_hex(16)
        SESSIONS[token] = (b["username"], time.time() + TOKEN_LIFE)
        self.send(200, {"token": token, "token_type": "Bearer", "expires_in": TOKEN_LIFE})

    def logout(self, q, path):
        self.who()
        SESSIONS.pop(self.headers["Authorization"][7:], None)
        self.send(204)

    def system(self, q, path):
        self.who()
        self.send(200, {"hostname": HOST, "software": version(),
                        "uptime_seconds": int(time.time() - STARTED),
                        "management_address": CONF["address"]})

    def list_interfaces(self, q, path):
        self.who()
        self.send(200, page(interfaces(), q, path))

    def get_interface(self, q, path, name):
        self.who()
        for i in interfaces():
            if i["name"] == name:
                return self.send(200, i)
        raise Problem(404, f"no interface {name}")

    def patch_interface(self, q, path, name):
        self.writer()
        b = self.body()
        if name not in [i["name"] for i in interfaces()]:
            raise Problem(404, f"no interface {name}")
        unknown = set(b) - {"description", "enabled"}
        if unknown:
            raise Problem(422, "only description and enabled can be changed",
                          fields=sorted(unknown))
        lines = [f"interface {name}"]
        if "description" in b:
            d = b["description"]
            if not isinstance(d, str) or len(d) > 80:
                raise Problem(422, "description is text of at most 80 characters")
            lines.append(f"description {d}" if d else "no description")
        if "enabled" in b:
            if not isinstance(b["enabled"], bool):
                raise Problem(422, "enabled is true or false")
            lines.append("no shutdown" if b["enabled"] else "shutdown")
        configure(lines)
        self.get_interface(q, path, name)

    def list_routes(self, q, path):
        self.who()
        items = routes()
        if "protocol" in q:
            items = [r for r in items if r["protocol"] == q["protocol"][0]]
        self.send(200, page(items, q, path))

    def list_static(self, q, path):
        self.who()
        self.send(200, page(static_routes(), q, path))

    def check_static(self, b, prefix=None):
        prefix = prefix or b.get("prefix")
        try:
            net = ipaddress.ip_network(str(prefix))
        except ValueError:
            raise Problem(422, f"{prefix!r} is not a network in CIDR form, such as 192.0.2.0/24",
                          field="prefix")
        if str(net) != prefix:
            raise Problem(422, f"{prefix} has host bits set: the network is {net}", field="prefix")
        try:
            ipaddress.ip_address(str(b.get("next_hop")))
        except ValueError:
            raise Problem(422, f"{b.get('next_hop')!r} is not an IP address", field="next_hop")
        d = b.get("distance", 1)
        if not isinstance(d, int) or not 1 <= d <= 255:
            raise Problem(422, "distance is a whole number from 1 to 255", field="distance")
        return {"prefix": prefix, "next_hop": b["next_hop"], "distance": d}

    def route_line(self, r):
        return f"ip route {r['prefix']} {r['next_hop']}" + (f" {r['distance']}" if r["distance"] != 1 else "")

    def create_static(self, q, path):
        self.writer()
        r = self.check_static(self.body())
        if any(s["prefix"] == r["prefix"] for s in static_routes()):
            raise Problem(409, f"a static route to {r['prefix']} already exists",
                          existing=f"{path}/{urllib.parse.quote(r['prefix'], safe='')}")
        configure([self.route_line(r)])
        self.send(201, r, [("Location", f"{path}/{urllib.parse.quote(r['prefix'], safe='')}")])

    def find_static(self, prefix):
        for s in static_routes():
            if s["prefix"] == prefix:
                return s
        return None

    def get_static(self, q, path, prefix):
        self.who()
        s = self.find_static(prefix)
        if not s:
            raise Problem(404, f"no static route to {prefix}")
        self.send(200, s)

    def put_static(self, q, path, prefix):
        self.writer()
        r = self.check_static(self.body(), prefix)
        old = self.find_static(prefix)
        if old == r:
            return self.send(200, r)
        lines = ["no " + self.route_line(old)] if old else []
        configure(lines + [self.route_line(r)])
        self.send(200 if old else 201, r)

    def delete_static(self, q, path, prefix):
        self.writer()
        old = self.find_static(prefix)
        if not old:
            raise Problem(404, f"no static route to {prefix}")
        configure(["no " + self.route_line(old)])
        self.send(204)

    def get_config(self, q, path):
        self.who()
        self.send(200, {"format": "cli", "text": vtysh("show running-config")})

    def save_config(self, q, path):
        self.writer()
        out = vtysh("write memory")
        self.send(200, {"saved": "[OK]" in out})

    def list_hooks(self, q, path):
        self.who()
        self.send(200, page(list(HOOKS.values()), q, path))

    def create_hook(self, q, path):
        self.writer()
        b = self.body()
        u = urllib.parse.urlsplit(str(b.get("url", "")))
        if u.scheme not in ("http", "https") or not u.netloc:
            raise Problem(422, "url is an http or https address", field="url")
        events = b.get("events") or []
        known = {"interface.up", "interface.down"}
        if not events or set(events) - known:
            raise Problem(422, "events is a list drawn from " + ", ".join(sorted(known)), field="events")
        if not isinstance(b.get("secret"), str) or len(b["secret"]) < 16:
            raise Problem(422, "secret is text of at least 16 characters", field="secret")
        hid = "wh-" + secrets.token_hex(4)
        HOOKS[hid] = {"id": hid, "url": b["url"], "events": events, "secret": b["secret"]}
        self.send(201, {k: v for k, v in HOOKS[hid].items() if k != "secret"},
                  [("Location", f"{path}/{hid}")])

    def delete_hook(self, q, path, hid):
        self.writer()
        if not HOOKS.pop(hid, None):
            raise Problem(404, f"no webhook {hid}")
        self.send(204)

    def list_deliveries(self, q, path, hid):
        self.who()
        with LOCK:
            items = [d for d in DELIVERIES if d["hook"] == hid]
        self.send(200, page(items, q, path))


A = Api
ROUTES = [
    (r"/api/v1/auth/login", {"POST": A.login}),
    (r"/api/v1/auth/logout", {"POST": A.logout}),
    (r"/api/v1/system", {"GET": A.system}),
    (r"/api/v1/interfaces", {"GET": A.list_interfaces}),
    (r"/api/v1/interfaces/([^/]+)", {"GET": A.get_interface, "PATCH": A.patch_interface}),
    (r"/api/v1/routes", {"GET": A.list_routes}),
    (r"/api/v1/static-routes", {"GET": A.list_static, "POST": A.create_static}),
    (r"/api/v1/static-routes/([^/]+)", {"GET": A.get_static, "PUT": A.put_static,
                                         "DELETE": A.delete_static}),
    (r"/api/v1/config", {"GET": A.get_config}),
    (r"/api/v1/config/save", {"POST": A.save_config}),
    (r"/api/v1/webhooks", {"GET": A.list_hooks, "POST": A.create_hook}),
    (r"/api/v1/webhooks/([^/]+)", {"DELETE": A.delete_hook}),
    (r"/api/v1/webhooks/([^/]+)/deliveries", {"GET": A.list_deliveries}),
]


# ------------------------------------------------------------------------ gNMI
# The versions of the published models this subset is shaped like: the ones in
# openconfig/public at the commit lesson 5 clones (release/models).
MODELS = [("openconfig-interfaces", "OpenConfig working group", "3.11.0"),
          ("openconfig-system", "OpenConfig working group", "3.3.0")]


def state_tree():
    """The part of openconfig-interfaces and openconfig-system this device serves."""
    tree = {"interfaces": {"interface": {}}, "system": {"state": {
        "hostname": HOST, "boot-time": int(STARTED * 1e9),
        "current-datetime": datetime.now().astimezone().isoformat(timespec="seconds")}}}
    for i in interfaces():
        tree["interfaces"]["interface"][i["name"]] = {
            "name": i["name"],
            "config": {"name": i["name"], "description": i["description"],
                       "enabled": i["enabled"], "mtu": i["mtu"]},
            "state": {"name": i["name"], "description": i["description"],
                      "enabled": i["enabled"], "mtu": i["mtu"],
                      "admin-status": "UP" if i["enabled"] else "DOWN",
                      "oper-status": i["oper_status"].upper(),
                      "counters": counters(i["name"])},
        }
    return tree


def elems(path):
    return [(e.name, dict(e.key)) for e in path.elem]


def join(prefix, path):
    p = gnmi_pb2.Path()
    p.elem.extend(list(prefix.elem) + list(path.elem))
    return p


def resolve(tree, es, done=()):
    """Walk the tree along the path; yield (concrete elems, value) for every match."""
    if not es:
        yield list(done), tree
        return
    (name, keys), rest = es[0], es[1:]
    if not isinstance(tree, dict) or name not in tree:
        return
    node = tree[name]
    if name == "interface":
        for key, entry in node.items():
            want = keys.get("name", "*")
            if want in ("*", key):
                yield from resolve(entry, rest, done + ((name, {"name": key}),))
    else:
        yield from resolve(node, rest, done + ((name, keys),))


def to_path(es):
    p = gnmi_pb2.Path()
    for name, keys in es:
        e = p.elem.add()
        e.name = name
        for k, v in keys.items():
            e.key[k] = v
    return p


def typed(v, encoding):
    if isinstance(v, dict):
        data = json.dumps(v).encode()
        return gnmi_pb2.TypedValue(json_ietf_val=data) if encoding == gnmi_pb2.JSON_IETF \
            else gnmi_pb2.TypedValue(json_val=data)
    if isinstance(v, bool):
        return gnmi_pb2.TypedValue(bool_val=v)
    if isinstance(v, int):
        return gnmi_pb2.TypedValue(uint_val=v)
    return gnmi_pb2.TypedValue(string_val=str(v))


def leaves(es, v):
    if isinstance(v, dict):
        for k, sub in v.items():
            if k == "interface":
                for key, entry in sub.items():
                    yield from leaves(es + [(k, {"name": key})], entry)
            else:
                yield from leaves(es + [(k, {})], sub)
    else:
        yield es, v


def authorised(context, write=False):
    md = dict(context.invocation_metadata())
    u = USERS.get(md.get("username"))
    if not u or not hmac.compare_digest(u["password"], md.get("password", "")):
        context.abort(grpc.StatusCode.UNAUTHENTICATED, "wrong or missing username and password")
    if write and u["role"] != "read-write":
        context.abort(grpc.StatusCode.PERMISSION_DENIED, f"{md['username']} may not change anything")


class Gnmi(gnmi_pb2_grpc.gNMIServicer):
    def Capabilities(self, request, context):
        authorised(context)
        return gnmi_pb2.CapabilityResponse(
            supported_models=[gnmi_pb2.ModelData(name=n, organization=o, version=v) for n, o, v in MODELS],
            supported_encodings=[gnmi_pb2.JSON, gnmi_pb2.JSON_IETF],
            gNMI_version="0.8.0")

    def Get(self, request, context):
        authorised(context)
        tree = state_tree()
        ts = time.time_ns()
        notes = []
        for path in request.path:
            found = list(resolve(tree, elems(join(request.prefix, path))))
            if not found:
                context.abort(grpc.StatusCode.NOT_FOUND, "nothing at " + path_text(join(request.prefix, path)))
            n = gnmi_pb2.Notification(timestamp=ts)
            for es, v in found:
                n.update.add(path=to_path(es), val=typed(v, request.encoding))
            notes.append(n)
        return gnmi_pb2.GetResponse(notification=notes)

    def Set(self, request, context):
        authorised(context, write=True)
        results = []
        ops = [(gnmi_pb2.UpdateResult.DELETE, p, None) for p in request.delete] + \
              [(gnmi_pb2.UpdateResult.REPLACE, u.path, u.val) for u in request.replace] + \
              [(gnmi_pb2.UpdateResult.UPDATE, u.path, u.val) for u in request.update]
        lines = []
        for op, path, val in ops:
            es = elems(join(request.prefix, path))
            names = [n for n, _ in es]
            if names[:2] != ["interfaces", "interface"] or names[2:3] != ["config"] or len(es) != 4:
                context.abort(grpc.StatusCode.INVALID_ARGUMENT,
                              "only /interfaces/interface[name=…]/config/{description,enabled} can be set")
            ifname, leaf = es[1][1].get("name"), names[3]
            if ifname not in state_tree()["interfaces"]["interface"]:
                context.abort(grpc.StatusCode.NOT_FOUND, f"no interface {ifname}")
            lines.append(f"interface {ifname}")
            if leaf == "description":
                if op == gnmi_pb2.UpdateResult.DELETE:
                    lines.append("no description")
                else:
                    v = scalar(val)
                    lines.append(f"description {v}")
            elif leaf == "enabled" and op != gnmi_pb2.UpdateResult.DELETE:
                v = scalar(val)
                if isinstance(v, str):
                    v = v.lower() == "true"
                lines.append("no shutdown" if v else "shutdown")
            else:
                context.abort(grpc.StatusCode.INVALID_ARGUMENT, f"{leaf} cannot be set here")
            lines.append("exit")
            results.append(gnmi_pb2.UpdateResult(path=path, op=op))
        try:
            configure(lines)
        except ValueError as e:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, str(e))
        return gnmi_pb2.SetResponse(prefix=request.prefix, response=results, timestamp=time.time_ns())

    def Subscribe(self, request_iterator, context):
        authorised(context)
        first = next(request_iterator)
        sl = first.subscribe
        prefix = sl.prefix
        subs = list(sl.subscription)

        def sample(paths):
            tree = state_tree()
            n = gnmi_pb2.Notification(timestamp=time.time_ns(), prefix=gnmi_pb2.Path(target=prefix.target))
            for p in paths:
                for es, v in resolve(tree, elems(join(prefix, p))):
                    for les, lv in leaves(es, v):
                        n.update.add(path=to_path(les), val=typed(lv, gnmi_pb2.JSON))
            return n

        def changes(paths, last):
            tree = state_tree()
            n = gnmi_pb2.Notification(timestamp=time.time_ns())
            for p in paths:
                for es, v in resolve(tree, elems(join(prefix, p))):
                    for les, lv in leaves(es, v):
                        key = path_text(to_path(les))
                        if last.get(key) != lv:
                            last[key] = lv
                            n.update.add(path=to_path(les), val=typed(lv, gnmi_pb2.JSON))
            return n

        all_paths = [s.path for s in subs]
        if sl.mode == gnmi_pb2.SubscriptionList.ONCE:
            yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
            yield gnmi_pb2.SubscribeResponse(sync_response=True)
            return
        if sl.mode == gnmi_pb2.SubscriptionList.POLL:
            yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
            yield gnmi_pb2.SubscribeResponse(sync_response=True)
            for req in request_iterator:
                if req.HasField("poll"):
                    yield gnmi_pb2.SubscribeResponse(update=sample(all_paths))
                    yield gnmi_pb2.SubscribeResponse(sync_response=True)
            return
        # STREAM: every subscription on its own clock
        last = {}
        timers = []
        for s in subs:
            if s.mode == gnmi_pb2.ON_CHANGE:
                timers.append(["change", s.path, 0.5, 0.0])
            else:
                iv = max((s.sample_interval or 10_000_000_000) / 1e9, 1.0)
                timers.append(["sample", s.path, iv, 0.0])
        n = changes([t[1] for t in timers if t[0] == "change"], last)
        s = sample([t[1] for t in timers if t[0] == "sample"])
        s.update.extend(n.update)
        yield gnmi_pb2.SubscribeResponse(update=s)
        yield gnmi_pb2.SubscribeResponse(sync_response=True)
        t0 = time.time()
        for t in timers:
            t[3] = t0 + t[2]
        while context.is_active():
            due = min(t[3] for t in timers)
            time.sleep(max(0.0, due - time.time()))
            for t in timers:
                if t[3] <= time.time():
                    t[3] += t[2]
                    n = sample([t[1]]) if t[0] == "sample" else changes([t[1]], last)
                    if n.update:
                        yield gnmi_pb2.SubscribeResponse(update=n)


def scalar(val):
    """The value of a TypedValue, whichever field the client chose to put it in."""
    raw = val.json_ietf_val or val.json_val
    if raw:
        try:
            return json.loads(raw)
        except ValueError:
            return raw.decode()
    return getattr(val, val.WhichOneof("value"))


def path_text(p):
    out = ""
    for e in p.elem:
        out += "/" + e.name + "".join(f"[{k}={v}]" for k, v in sorted(e.key.items()))
    return out or "/"


# ------------------------------------------------------------------------ main
def main():
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ctx.load_cert_chain(CONF["cert"], CONF["key"])
    httpd = ThreadingHTTPServer((CONF["address"], 443), Api)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    threading.Thread(target=watch_links, daemon=True).start()

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=16))
    gnmi_pb2_grpc.add_gNMIServicer_to_server(Gnmi(), server)
    creds = grpc.ssl_server_credentials([(open(CONF["key"], "rb").read(), open(CONF["cert"], "rb").read())])
    server.add_secure_port(f"{CONF['address']}:9339", creds)
    server.start()
    server.wait_for_termination()


if __name__ == "__main__":
    main()
```

O `netlab.sh` o liga nos três roteadores sempre que o arquivo existe, então reconstrua o
laboratório:

```sh
sudo ~/netlab/netlab.sh reset
```

A linha `netlab: devapi: started on core1, edge1 and edge2` no que ele imprime é a que esta aula
precisa. Daqui em diante, toda aula começa com esse mesmo `reset`, como as transcrições de toda aula
começaram.
