---
title: What the early version did
version: 1
---

At step 7, loanbook had its rules and its tests, and nobody had yet tried the paths off to the side.
Two requests show it. An address that does not exist, and a body that is not JSON:

```
ana@laptop:~/loanbook$ curl -s -i localhost:8000/api/nothing
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sun, 27 Sep 2026 06:34:30 GMT
Connection: close
Content-Type: text/html;charset=utf-8
Content-Length: 330

<!DOCTYPE HTML>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: 404</p>
        <p>Message: Not Found.</p>
        <p>Error code explanation: 404 - Nothing matches the given URI.</p>
    </body>
</html>

ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d 'not json'
```

The first answers with **an HTML page**, which is what Python's library sends by default. The page is
correct, and useless: loanbook's page expects JSON and reads an `error` field, so it would fail to parse
the answer and show nothing. The second answers with **nothing at all**. `curl` printed no output
because the server closed the connection without replying. The server's log says why:

```
ana@laptop:~/loanbook$ cat app.log
loanbook on http://127.0.0.1:8000
GET /api/nothing Not Found
GET /api/nothing 404
----------------------------------------
Exception occurred during processing of request from ('127.0.0.1', 56956)
Traceback (most recent call last):
  File "/usr/lib/python3.12/socketserver.py", line 692, in process_request_thread
    self.finish_request(request, client_address)
  File "/usr/lib/python3.12/socketserver.py", line 362, in finish_request
    self.RequestHandlerClass(request, client_address, self)
  File "/usr/lib/python3.12/socketserver.py", line 761, in __init__
    self.handle()
  File "/usr/lib/python3.12/http/server.py", line 436, in handle
    self.handle_one_request()
  File "/usr/lib/python3.12/http/server.py", line 424, in handle_one_request
    method()
  File "/home/ana/loanbook/app.py", line 115, in do_POST
    body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
----------------------------------------
```

`json.loads` raised an exception that nothing caught, the request handler died, and the library wrote
the traceback to the log and hung up. **To the user this is indistinguishable from a server that is
down.** To a reviewer who tried it, it says the author tested only the path they meant.

Neither of these would have been found by the tests of step 7, which call `lend` and `give_back`
directly and never send a malformed request. Those tests do their job, which is the
rules. The unhappy paths of the HTTP layer are only found by sending HTTP.
