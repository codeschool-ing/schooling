---
title: A server on your own machine
version: 1
---

**An app that talks to a network needs something on the other end, and this lesson gives you one
that fits on a page.** The planner's server is a Python program of about seventy lines that keeps
the courses and sessions in memory and answers four requests. It uses nothing but Python's
standard library, so the Ubuntu from lesson 1 already has everything it needs, and so does a Mac.

It is a stand-in, and it says so. A real backend has a database, accounts and a deployment, and
the `backend` track is where those are built. What the app needs from it in this course is
narrower: **a URL that answers with JSON, and that can also answer badly on purpose**, because the
interesting half of networking code is what it does when the answer is not the one it hoped for.

## The program

Save this as `serve.py`, in a directory of its own, `~/server`:

```python
#!/usr/bin/env python3
# serve.py
# The study planner's server, for lessons 12 to 16 of ios-apps.
import json, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs

COURSES = [
    {"id": "sql", "title": "SQL Databases"},
    {"id": "mobile", "title": "Mobile Fundamentals"},
]
SESSIONS = [
    {"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": True},
    {"id": "s2", "courseId": "mobile", "date": "2026-10-20", "minutes": 40, "done": True},
    {"id": "s3", "courseId": "sql", "date": "2026-10-23", "minutes": 60, "done": False},
    {"id": "s4", "courseId": "mobile", "date": "2026-10-27", "minutes": 45, "done": False},
]


class Planner(BaseHTTPRequestHandler):
    def reply(self, status, body):
        data = (json.dumps(body) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            print(f"{self.command} {self.path}: the client had gone", flush=True)

    def do_GET(self):
        url = urlsplit(self.path)
        query = parse_qs(url.query, keep_blank_values=True)
        time.sleep(float(query.get("delay", ["0"])[0]))  # ?delay=3: answer slowly
        if "fail" in query:                               # ?fail: answer with an error
            return self.reply(500, {"error": "The server failed on purpose."})
        parts = url.path.strip("/").split("/")
        if parts == ["courses"]:
            return self.reply(200, COURSES)
        if len(parts) == 3 and parts[0] == "courses" and parts[2] == "sessions":
            if not any(c["id"] == parts[1] for c in COURSES):
                return self.reply(404, {"error": f"no course {parts[1]}"})
            return self.reply(200, [s for s in SESSIONS if s["courseId"] == parts[1]])
        self.reply(404, {"error": f"no such path {url.path}"})

    def do_POST(self):
        if self.path != "/sessions":
            return self.reply(404, {"error": f"no such path {self.path}"})
        try:
            s = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            fields = (s["id"], s["courseId"], s["date"], s["minutes"], s["done"])
        except (ValueError, KeyError, TypeError):
            return self.reply(400, {"error": "a session needs id, courseId, date, minutes and done"})
        if not any(c["id"] == s["courseId"] for c in COURSES):
            return self.reply(422, {"error": f"no course {s['courseId']}"})
        for kept in SESSIONS:
            if kept["id"] == s["id"]:  # the same session posted twice is kept once
                return self.reply(200, kept)
        SESSIONS.append(s)
        self.reply(201, s)

    def log_message(self, fmt, *args):  # one short line per request
        print(f"{self.command} {self.path} {args[1]}", flush=True)


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8012
print(f"the planner is on http://127.0.0.1:{port}", flush=True)
ThreadingHTTPServer(("127.0.0.1", port), Planner).serve_forever()
```

Three things in it are there for later sections. `?delay=3` makes any request wait three seconds
before answering, which is how section 07 gets a request slow enough to cancel. `?fail` turns any
request into a `500`, which is how section 06 gets an error it did not cause. A session posted
twice with the same `id` is kept once, and lesson 14 leans on that. And **it listens on
`127.0.0.1` only**, the address that means "this machine": nothing else on your network can reach
it, which is right for a program with no password that accepts anything you post to it.

## Starting it, and asking it something

The server runs until you stop it, so give it a terminal of its own. Open a second terminal, go to
`~/server` and start it there. That terminal shows one line when it starts and one line for every
request it answers, and at the end of this lesson it looked like this:

```
ana@vm:~/server$ python3 serve.py
the planner is on http://127.0.0.1:8012
GET /courses 200
GET /courses/sql/sessions 200
GET /courses/art/sessions 404
GET /courses 200
GET /courses/sql/sessions 200
GET /courses 200
GET /courses/sql/sessions 200
POST /sessions 201
GET /courses/art/sessions 404
POST /sessions 422
GET /courses 200
GET /courses?fail 500
GET /courses?delay=3 200
GET /courses?delay=3: the client had gone
GET /courses?delay=3 200
GET /courses?delay=3: the client had gone
```

In your first terminal, ask it for the courses with `curl`, which prints the body as it arrived.
`-s` keeps it quiet about its own progress, and `-i` adds the status line and the headers above the
body:

```
ana@vm:~/server$ curl -si http://127.0.0.1:8012/courses
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 30 Oct 2026 18:26:18 GMT
Content-Type: application/json
Content-Length: 92

[{"id": "sql", "title": "SQL Databases"}, {"id": "mobile", "title": "Mobile Fundamentals"}]
ana@vm:~/server$ curl -s http://127.0.0.1:8012/courses/sql/sessions
[{"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": true}, {"id": "s3", "courseId": "sql", "date": "2026-10-23", "minutes": 60, "done": false}]
ana@vm:~/server$ curl -si http://127.0.0.1:8012/courses/art/sessions
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Fri, 30 Oct 2026 18:26:18 GMT
Content-Type: application/json
Content-Length: 27

{"error": "no course art"}
```

**This is the whole contract the app is about to be written against**: a path, a status code, a
`Content-Type` that says JSON, and a body in a shape the app expects. The last request asks for a
course that does not exist and gets `404` with a body that says why. An app that only checks for
a body would try to read `{"error": …}` as a list of sessions, and section 05 is about not doing
that.

`Ctrl-C` in the server's terminal stops it. The sessions you post are kept in memory, so stopping
it also forgets them, and starting it again gives you the four sessions above. That is a feature
for a course: every run of every lesson starts from the same data.
