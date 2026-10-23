---
title: A session in a cookie, step by step
version: 1
---

**With the server running in one terminal, `curl` in another can do what the browser will do, and
show every header on the way.** `-i` prints the response's headers before its body; `-c` and `-b`
make `curl` keep cookies in a file and send them back, as a browser keeps them in its profile.

A wrong password first:

```
ana@dev:~/planner$ curl -s -i -X POST -H 'content-type: application/json' -d '{"name":"ana","password":"hunter2"}' http://localhost:5173/api/login
HTTP/1.1 401 Unauthorized
Vary: Origin
content-type: application/json
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"error":"wrong name or password"}
```

**401, and the same sentence whichever half was wrong.** A message saying "no such user" would tell
anybody which names have accounts. Then the right one:

```
ana@dev:~/planner$ curl -s -i -c ~/cookies.txt -X POST -H 'content-type: application/json' -d '{"name":"ana","password":"correct horse battery staple"}' http://localhost:5173/api/login
HTTP/1.1 200 OK
Vary: Origin
content-type: application/json
set-cookie: sid=nWKvTbi-pkO0k2a_hq1FT-m6Nakf3rW1CWGzZF9ovIE; HttpOnly; SameSite=Lax; Path=/
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"name":"ana"}
```

The answer is `{"name":"ana"}`, and the part that matters is the header: **`Set-Cookie: sid=…`**, a
value of 43 characters made from 32 random bytes, which is far beyond guessing. `HttpOnly` keeps it
away from the page's own scripts, `SameSite=Lax` keeps the browser from sending it along with most
requests started by another site, and `Path=/` sends it with every address on this one. Lesson 6 is
about each of those words.

Now the plan, once with the cookie and once without:

```
ana@dev:~/planner$ curl -s -b ~/cookies.txt http://localhost:5173/api/plan | head -c 150; echo
{"courses":[{"id":"html-css","title":"HTML and CSS"},{"id":"javascript","title":"JavaScript"},{"id":"git","title":"Git"}],"sessions":[{"id":1,"course"
ana@dev:~/planner$ curl -s -i http://localhost:5173/api/plan
HTTP/1.1 401 Unauthorized
Vary: Origin
content-type: application/json
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"error":"sign in first"}
```

**The cookie is the whole of the proof.** Whoever sends it is ana, as far as the server knows, which
is why it must never be readable, guessable or sent anywhere but here. And without it there is
nothing but a 401.

The server remembers this login in its `logins` map, and that is the property sessions are chosen
for: the server can forget a login whenever it decides to, and the cookie stops working that instant.
The next step was supposed to show that, with sign-out, and lesson 6 starts by finding out that it
does not.
