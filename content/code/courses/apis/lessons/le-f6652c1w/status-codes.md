---
title: Status codes
version: 1
---

**The status code is the part of the answer a program reads first, and often the only part.** A
client written against your API branches on it: retry, show an error, ask for a login, carry on. A
wrong code is therefore a bug in the contract even when the body explains everything perfectly,
because nobody's code reads the body to decide.

The first digit is the class, and the class alone tells a client most of what it needs:

| class | meaning | what the client should do |
|---|---|---|
| `2xx` | it worked | carry on |
| `3xx` | it is somewhere else | follow the `Location` |
| `4xx` | **the request is wrong** | fix the request; sending it again unchanged will fail again |
| `5xx` | **the server failed** | the request may be fine; trying later may work |

The line between 4xx and 5xx is the one that matters most, and the one most often drawn wrong. A
server that answers 500 to a malformed body tells every client to retry a request that can never
succeed; one that answers 400 when its database is down tells them to stop sending a request that
was fine.

## The codes shelf uses

Seven failures, each with the code shelf chose. The first is a body that does not say it is JSON:
curl's `-d` sends a form unless told otherwise. The next two are bodies that say they are JSON and
are not, or are JSON but not an object:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -d 'title=Quincas Borba'
{"error": "send the book as application/json"}
415
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"title": '
{"error": "the body is not valid JSON"}
400
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '["Quincas Borba"]'
{"error": "the body must be a JSON object"}
400
```

**415 Unsupported Media Type** is about the label, **400 Bad Request** about the bytes. The next
four are requests that are well formed and still cannot be accepted: a field the API does not have,
a price sent as text, a negative stock and an author who does not exist. The last two were caught by
the database, by the `CHECK` and the foreign key of `db.py`, and `rest.py` turned the database's
complaint into the same code its own checks give:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"colour": "red"}'
{"error": "unknown fields: colour"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"price_cents": "39.90"}'
{"error": "wrong type for: price_cents"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"stock": -1}'
{"error": "rejected: CHECK constraint failed: stock >= 0"}
422
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"author_id": 99}'
{"error": "rejected: FOREIGN KEY constraint failed"}
422
```

**422 Unprocessable Content** says "I understood you, and the content breaks a rule". Some APIs answer
400 for all of it, and that is a defensible choice if it is made everywhere; what is not defensible
is a mix, where the same mistake gets 400 from one endpoint and 422 from another.

Together with what the previous sections showed, that is the whole list shelf needs:

| code | name | in shelf |
|---|---|---|
| 200 | OK | a read, or a replace or change that worked |
| 201 | Created | a new book, with its `Location` |
| 204 | No Content | a delete that worked |
| 400 | Bad Request | the body is not JSON, or not an object |
| 404 | Not Found | no such address, or no such book |
| 405 | Method Not Allowed | the address exists and does not take that method; `Allow` lists the ones it does |
| 409 | Conflict | the request clashes with something that exists: a second book with the same ISBN |
| 415 | Unsupported Media Type | the body is not labelled `application/json` |
| 422 | Unprocessable Content | the JSON is fine and its content breaks a rule |

Three more belong to later lessons and are worth recognising now. **401 Unauthorized** means "I do not
know who you are" and **403 Forbidden** means "I know who you are, and no"; lessons 7 and 11 are about
the difference. **429 Too Many Requests** is lesson 12.

## A code you did not choose

shelf defines no `OPTIONS` method, so Python's library answered for it:

```
ana@api:~/shelf$ curl -si -X OPTIONS localhost:8000/v1/books
HTTP/1.1 501 Unsupported method ('OPTIONS')
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Connection: close
Content-Type: text/html;charset=utf-8
Content-Length: 360

<!DOCTYPE HTML>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: 501</p>
        <p>Message: Unsupported method ('OPTIONS').</p>
        <p>Error code explanation: 501 - Server does not support this operation.</p>
    </body>
</html>
```

Three things are wrong there, and none of them is Python's fault. **501 Not Implemented** is meant for
a method the server does not recognise at all, while `OPTIONS` is a standard method that this
address simply does not take, which is what 405 is for. The body is an HTML page in an API whose
every other answer is JSON. And the `Server` header names the exact Python version to anybody who
asks, which lesson 13 comes back to. **Every code your API sends is part of its contract, including
the ones a library sends on your behalf.** Lesson 13 also returns to `OPTIONS`, because browsers send
it before a cross-origin request and expect a real answer.
