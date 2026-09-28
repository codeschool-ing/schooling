---
title: Errors as part of the contract
version: 1
---

Step 8, *Answer every error as JSON*, made every row of the table answer. Here are all of them, one
after the other:

```
ana@laptop:~/loanbook$ curl -s -i localhost:8000/api/nothing
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sun, 27 Sep 2026 06:34:31 GMT
Content-Type: application/json
Content-Length: 43

{"error": "Nothing lives at /api/nothing."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d 'not json'
{"error": "The body is not JSON."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/9/loan -d '{"borrower": "Beatriz Nunes"}'
{"error": "There is no item 9."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": ""}'
{"error": "Say who is borrowing it."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Beatriz Nunes"}'
{"item": "Projector 2", "borrower": "Beatriz Nunes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Carlos Mendes"}'
{"error": "Projector 2 is already lent to Beatriz Nunes until 2026-10-04."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/return
{"item": "Projector 2", "returned_on": "2026-09-27"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/return
{"error": "Projector 2 is not out, so it cannot come back."}
```

Every answer is JSON, and every error has the same shape: **one field, `error`, holding a sentence a
person can read.** The page shows that sentence as it is, so the server decides what the user sees, and
there is one place to change it. The status code carries the kind of error for programs: 400 for a
request that is wrong, 404 for something that does not exist, 409 for a rule that says no.

The code that does it is the POST handler, annotated:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "    def do_POST(self):\n        m = re.fullmatch(r\"/api/items/(\\d+)/(loan|return)\", self.path)\n        if not m:\n            return self.reply(HTTPStatus.NOT_FOUND, {\"error\": f\"Nothing lives at {self.path}.\"})", "note": "An address that matches no route gets a 404 in the same shape as every other error, instead of the library's HTML page."}, {"code": "        item_id, action = int(m[1]), m[2]\n        try:\n            body = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\") or 0)) or b\"{}\")", "note": "Reading the body is inside the `try`. A body that is not JSON is the client's mistake, and it gets a 400, not a dropped connection."}, {"code": "            with closing(connect()) as db:\n                if action == \"loan\":\n                    result = lend(db, item_id, body.get(\"borrower\"), date.today())\n                    return self.reply(HTTPStatus.CREATED, result)\n                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))", "note": "The happy path. `lend` and `give_back` know nothing about HTTP: when the rules say no, they raise `Refused` with a status and a sentence."}, {"code": "        except json.JSONDecodeError:\n            self.reply(HTTPStatus.BAD_REQUEST, {\"error\": \"The body is not JSON.\"})\n        except Refused as r:\n            self.reply(r.status, {\"error\": r.message})", "note": "Two kinds of no, each turned into an answer. Nothing else is caught, on purpose: an error nobody expected is a bug, and it belongs in the server's log."}]}
```

Two things in it are decisions worth being able to explain. **The rules live in `lend` and
`give_back`, which raise `Refused`, and only the handler knows about HTTP.** That is why the tests of
lesson 12 can check every rule without a server. And **only the errors that were expected are
caught.** A `KeyError` or a full disk is not a user's mistake, and turning it into a friendly sentence
would hide a bug from the one person who could fix it.

What loanbook does not do, and could: an unexpected error still closes the connection. A better answer
is a 500 with a sentence that says nothing specific, *something went wrong on our side*, while the
details go to the log. It is written down in lesson 21's retrospective as the next change.
