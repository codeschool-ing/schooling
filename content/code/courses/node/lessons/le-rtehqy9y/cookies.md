---
title: Cookies
version: 1
---

**A cookie is a small value a server asks a browser to keep and send back with every later request
to the same site.** It is how a site remembers a browser between requests: a session, a preference, a
language. The server sets one with a `Set-Cookie` header, and the browser returns it in `Cookie`.

The links service has no browser users, so this section uses a demo that remembers how many times a
browser has visited:

```javascript
// demo/cookies.js
import express from "express";

function cookiesOf(req) {
  const out = {};
  for (const pair of (req.get("cookie") ?? "").split(";")) {
    const [name, ...rest] = pair.trim().split("=");
    if (name) out[name] = decodeURIComponent(rest.join("="));
  }
  return out;
}

const app = express();
app.get("/", (req, res) => {
  const visits = Number(cookiesOf(req).visits ?? 0) + 1;
  res.cookie("visits", String(visits), { httpOnly: true, secure: true, sameSite: "lax", maxAge: 24 * 3600 * 1000 });
  res.send(`visit number ${visits}\n`);
});
app.listen(3000, "127.0.0.1");
```

`res.cookie` writes the header. Reading one has no helper in Express, so `cookiesOf` splits the
`Cookie` header by hand; the `cookie-parser` package does the same, and you would install it in a real
service. curl keeps cookies in a file with `-c` and sends them back with `-b`, which is enough to play
the browser:

```
ana@dev:~/server/links$ curl -si -c jar.txt http://127.0.0.1:3000/ | grep -iE '^set-cookie|visit'
Set-Cookie: visits=1; Max-Age=86400; Path=/; Expires=Sat, 17 Oct 2026 23:30:23 GMT; HttpOnly; Secure; SameSite=Lax
visit number 1
ana@dev:~/server/links$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/
visit number 2

ana@dev:~/server/links$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/
visit number 3
```

**Every attribute on that `Set-Cookie` is a defence**, and each one closes a different door:

| attribute | what it stops |
|---|---|
| `HttpOnly` | the page's own JavaScript cannot read the cookie, so a script injected into the page cannot steal it |
| `Secure` | the browser sends it only over HTTPS, never in clear text |
| `SameSite=Lax` | another site cannot make the browser send it with a form posted from there |
| `Max-Age` | it expires, instead of living as long as the browser does |

The cookie came back over plain `http://`, though it says `Secure`, because curl, like browsers,
treats the computer's own address as safe; to any other address it would travel only over HTTPS.
**And a cookie is the client's text like everything
else**: a browser stores it, a person can edit it, so `visits=1000000` arrives as easily as the real
value. A cookie that must not be forged carries a signature the server checks, or is only a random
session id that means something on the server alone, which is how sign-in sessions work.
