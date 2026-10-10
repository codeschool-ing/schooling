---
title: A header, never a URL
version: 1
---

**A credential travels in a header, never in the address.** Some APIs accept a token as a query
parameter, `?access_token=…` or `?api_key=…`, because it is convenient: a link that works on its own,
pasted into a browser. The convenience is the problem. An address is written down in more places than
anybody keeps track of, and a header is not.

`keys.py` does not accept a token in the URL. Here is the same valid token sent both ways, with a
fresh server so its log holds only these requests:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' -o login.json
ana@api:~/shelf$ curl -s -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/books/1
{"id": 1, "title": "Dom Casmurro", "stock": 12}
ana@api:~/shelf$ curl -s "localhost:8000/v1/books/1?access_token=$(jq -r .token login.json)"
{"error": "authentication required"}
```

The first request works and the second is refused, which looks like the end of the matter. It is not.
This is what the second terminal printed:

```
keys on http://127.0.0.1:8000
auth: login ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:07] "POST /v1/login HTTP/1.1" 200 -
auth: bearer ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:08] "GET /v1/books/1 HTTP/1.1" 200 -
127.0.0.1 - - [10/Oct/2026 01:26:08] "GET /v1/books/1?access_token=kvtHDkMYde-nVBH0REgczY99ZtzqEC-Q53SoZ8zOYHc HTTP/1.1" 401 -
```

**The refused request put the token in the server's own log.** The server writes the request line
before it has decided anything, and the request line includes the query string. The header version
left nothing: `GET /v1/books/1`. The token in that line was valid when it was logged, and it stays
valid for the rest of its hour, sitting in a file that more people can read than can read the
database.

`keys.py` could scrub its own request line, and it would still be the only one that did. The same URL
also lands in:

- the access log of every proxy in front of the server, such as the reverse proxy that the next
  course, Web Servers and Caching, puts in front of an application;
- the browser's history, if anybody opened it there, and the `Referer` header the browser sends to
  the next site the page links to;
- the chat message, ticket or screenshot somebody pastes it into, because an address looks safe to
  share.

So the defence is at the source: **the server refuses credentials in the URL, and the documentation
never shows one there.** A token that has been in a URL is treated as leaked, and the fix is the one
the section on bearer tokens showed: revoke it with `/v1/logout` and log in again.
