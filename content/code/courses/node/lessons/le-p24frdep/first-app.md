---
title: A first Express application
version: 1
---

**An Express application is a function that takes a request and a response, with a router and a
chain of middleware inside it.** `express()` makes one, `app.get` adds a route, and `app.listen` hands
it to `node:http`, which is still the server underneath. The experiments in this lesson live in a
folder `demo` inside the `links` project, so that they find the Express that lesson 4 installed:

```javascript
// demo/first.js
import express from "express";

const app = express();

app.get("/", (req, res) => {
  res.send("hello from Express\n");
});

app.get("/links/:code", (req, res) => {
  res.json({ code: req.params.code, asked: req.query });
});

app.listen(3000, "127.0.0.1", () => console.log("listening on http://127.0.0.1:3000"));
```

`res.json` writes the JSON and no newline after it, so in a terminal the next prompt would start on
the same line as the reply. One line in curl's own settings file, `~/.curlrc`, makes it print a
newline after every reply from now on:

```
ana@dev:~/server/links$ echo '-w "\n"' >> ~/.curlrc
ana@dev:~/server/links$ cat ~/.curlrc
-w "\n"
```

Start the server in one terminal, and in the other:

```
ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 19
ETag: W/"13-JrSxvmjEhU9ng05ndu7+m0clhpU"
Date: Fri, 16 Oct 2026 23:19:42 GMT
Connection: keep-alive
Keep-Alive: timeout=5

hello from Express

ana@dev:~/server/links$ curl -s 'http://127.0.0.1:3000/links/7ctxqn?visits=1'
{"code":"7ctxqn","asked":{"visits":"1"}}
```

Compare it with lesson 5's `respond.js`. **`res.send` set the type for you**, `text/html` for a
string, and `res.json` set `application/json` and wrote the body; both counted the length. Two new
headers appeared:

- **`X-Powered-By: Express`** tells every client which framework answered. It helps nobody but
  somebody looking for servers running a version with a known flaw, and lesson 7 turns it off.
- **`ETag`** is a short fingerprint of the body, which lets a client ask "has this changed?" and get a
  304 with no body if it has not. Lesson 7's section on conditional requests uses it.

`req.params` and `req.query` arrived parsed. **Both are still the client's text**: `visits` is the
string `"1"`, exactly as lesson 5's `searchParams` gave it.

`app.listen` is a shortcut for `http.createServer(app).listen(…)`, and it returns the
`http.Server`. Everything lesson 5 said about the server object, its address and its timeouts, is true
of that object.
