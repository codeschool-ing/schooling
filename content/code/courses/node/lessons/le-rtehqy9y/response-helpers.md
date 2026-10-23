---
title: The response helpers
version: 1
---

**Express adds methods to the response for everything lesson 5's `send` did by hand**, and most of
them return the response, so they chain:

| helper | what it does |
|---|---|
| `res.status(201)` | sets the status, and returns `res` |
| `res.set(name, value)`, `res.type("text")` | sets a header, or the content type by a short name |
| `res.json(value)` | writes JSON, with its type and length |
| `res.send(body)` | writes a string as HTML, a Buffer as bytes, an object as JSON |
| `res.location(url)` | sets `Location`, for a 201 or a redirect |
| `res.redirect(status, url)` | sets the status and `Location`, with a short body |
| `res.sendStatus(404)` | the status, with its name as the body |
| `res.end()` | ends with no body, which a 204 needs |

## Which redirect

The links service answers its short links with a redirect, and there are four of them, which differ in
two ways:

| status | permanent? | may the client change POST to GET? |
|---|---|---|
| 301 Moved Permanently | yes, and browsers cache it | yes, and they do |
| 302 Found | no | yes, and they do |
| 307 Temporary Redirect | no | no: the same method and body |
| 308 Permanent Redirect | yes | no |

```javascript
// demo/redirects.js
import express from "express";

const app = express();
for (const status of [301, 302, 307, 308]) {
  app.all(`/r${status}`, (req, res) => res.redirect(status, "/landed"));
}
app.all("/landed", (req, res) => res.send(`landed with ${req.method}\n`));
app.listen(3000, "127.0.0.1");
```

`curl -L` follows redirects as a browser would, and `-X POST -d …` starts with a POST:

```
ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r302
landed with GET

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r307
landed with POST

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r301
landed with GET

ana@dev:~/server/links$ curl -sL -d x=1 http://127.0.0.1:3000/r308
landed with POST

ana@dev:~/server/links$ curl -si http://127.0.0.1:3000/r302 | grep -iE '^HTTP|^location'
HTTP/1.1 302 Found
Location: /landed
```

**The 302 arrived as a GET and the 307 kept its POST.** For the links service's own redirect a
302 is right: only GETs follow a short link, and **a 301 is a promise the service cannot take back**,
because a browser that has seen one may go straight to the old address for months without asking
again. A link that is deleted, or changed, has to be asked about every time, and a 302 is what makes
it be.
