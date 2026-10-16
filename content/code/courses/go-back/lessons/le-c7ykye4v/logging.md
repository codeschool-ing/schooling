---
title: Logging every request
version: 1
---

The first middleware answers the question every incident starts with: **what did the server
receive, and what did it answer?** One line per request with the method, the path, the status,
the size of the body and how long it took. Four of those five are easy, because the request
carries them and a clock measures the last. The status is the hard one.

## The status is not readable afterwards

`ResponseWriter` has methods for writing a status and none for reading one back. A middleware
calls `next.ServeHTTP(w, r)`, the handler writes whatever it writes, and when it returns the
middleware has no way to ask `w` what went out. **So the middleware hands the handler a different
writer**: one that passes everything through to the real one and remembers what passed.

```schooling-example
{
  "language": "go",
  "file": "boxoffice/middleware.go",
  "parts": [
    {
      "code": "// boxoffice/middleware.go\npackage main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\t\"slices\"\n\t\"time\"\n)\n\n// chain wraps h in the middlewares given, the first one outermost.\nfunc chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {\n\tfor _, mw := range slices.Backward(mws) {\n\t\th = mw(h)\n\t}\n\treturn h\n}\n\n",
      "note": "The helper from section 02, in the file it will live in."
    },
    {
      "code": "// statusRecorder remembers the status and the size of what a handler wrote.\ntype statusRecorder struct {\n\thttp.ResponseWriter\n\tstatus int\n\tbytes  int\n}\n\n",
      "note": "**Embedding the interface gives `statusRecorder` every method of the writer it holds**, `Header` included, without writing them. The two fields are what it remembers."
    },
    {
      "code": "func (s *statusRecorder) WriteHeader(code int) {\n\tif s.status == 0 {\n\t\ts.status = code\n\t}\n\ts.ResponseWriter.WriteHeader(code)\n}\n\n",
      "note": "It overrides `WriteHeader`: note the code, then pass the call on. Only the first code is kept, because only the first one reaches the client, as lesson 1 section 07 showed."
    },
    {
      "code": "func (s *statusRecorder) Write(b []byte) (int, error) {\n\tif s.status == 0 {\n\t\ts.status = http.StatusOK\n\t}\n\tn, err := s.ResponseWriter.Write(b)\n\ts.bytes += n\n\treturn n, err\n}\n\n",
      "note": "And `Write`: **a write with no status before it means 200**, because that is what the real writer will send. The byte count is what was actually written, `n`, not what was asked for."
    },
    {
      "code": "// Unwrap lets http.ResponseController reach the writer underneath.\nfunc (s *statusRecorder) Unwrap() http.ResponseWriter {\n\treturn s.ResponseWriter\n}\n\n",
      "note": "**A wrapper hides the methods its type does not declare.** The real writer can flush a half-finished response to the client, and `statusRecorder` cannot. `Unwrap` is the convention `http.ResponseController` follows to dig through wrappers to the writer that can; lesson 13 needs it."
    },
    {
      "code": "func logRequests(next http.Handler) http.Handler {\n\treturn http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {\n\t\tstart := time.Now()\n\t\trec := &statusRecorder{ResponseWriter: w}\n\t\tnext.ServeHTTP(rec, r)\n\t\tif rec.status == 0 {\n\t\t\trec.status = http.StatusOK\n\t\t}\n\t\tlog.Printf(\"%s %s %d %dB %s\", r.Method, r.URL.Path, rec.status, rec.bytes,\n\t\t\ttime.Since(start).Round(time.Microsecond))\n\t})\n}\n",
      "note": "The middleware itself. The handler inside receives `rec` rather than `w`, writes through it, and returns; the line is logged after. A handler that writes nothing at all gets a 200 from the server, so the log says 200 too."
    }
  ]
}
```

## What it prints

Three requests against boxoffice, and what the server's terminal printed for them:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
1	Jazz at the Docks	120 of 120 seats left
2	Chamber Choir	0 of 80 seats left
ana@vm:~/boxoffice$ curl -s localhost:8080/events/9
no such event
ana@vm:~/boxoffice$ curl -s -X POST localhost:8080/events
Method Not Allowed
```

```
2026/10/16 19:29:24 GET /events 200 77B 25µs
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
2026/10/16 19:29:24 POST /events 405 19B 29µs
```

**The 405 was written by the mux, not by any handler of boxoffice**, and it is logged all the
same, because the middleware wraps the mux. Durations of twenty-odd microseconds are what an
in-memory map and a loopback connection cost; they become a number worth watching in lesson 6,
when a database is behind the handler.

## What stays out of the line

The line holds the path and not the query string, and nothing from the headers. That is a choice.
**An access log is read by more people and kept for longer than anything it records**, so a
token in an `Authorization` header or an e-mail address in a query string would leak into it the
first time somebody logged "everything, to be safe". Section 06 sends a secret in a header on every
staff request, and none of it reaches this log. Lesson 12 replaces `log.Printf` with structured
logging and comes back to what a log may hold.
