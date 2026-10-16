---
title: Basic authentication
version: 1
---

**Basic sends the name and the password with every request, encoded and not hidden.** It is the
oldest scheme HTTP has and the simplest to use: `curl -u name:password` and the door opens.

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/books
[{"id": 1, "title": "Dom Casmurro", "stock": 12}, {"id": 2, "title": "Memórias Póstumas de Brás Cubas", "stock": 7}, {"id": 3, "title": "A Hora da Estrela", "stock": 0}, {"id": 4, "title": "Perto do Coração Selvagem", "stock": 3}, {"id": 5, "title": "Ensaio sobre a Cegueira", "stock": 9}, {"id": 6, "title": "Americanah", "stock": 4}]
```

`-v` makes curl print the headers it sends, each line starting with `>`. Keep only the one that
matters:

```
ana@api:~/shelf$ curl -sv -u ana:river-lamp-42 localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'
> Authorization: Basic YW5hOnJpdmVyLWxhbXAtNDI=
```

The word after the scheme looks like a secret, and the common belief is that it is one. It is
**base64**, a way of writing any bytes with 64 printable characters so they survive a header. It has
no key, and anybody can turn it back:

```
ana@api:~/shelf$ echo YW5hOnJpdmVyLWxhbXAtNDI= | base64 -d; echo
ana:river-lamp-42
```

**base64 is an encoding, not encryption.** Whoever sees that header has the password, in the time it
takes to type `base64 -d`. So Basic is only ever acceptable over HTTPS, where the whole request,
headers included, is encrypted on the way; lesson 13 is about that layer. On the plain
`http://127.0.0.1` of this lab it is safe only because the request never leaves the machine.

## What "every request" costs

The password is not sent once. It travels with every request, and that has three consequences
that **no setting can remove**.

- Every request is a password check. `keys.py` runs scrypt on each one, and scrypt is slow on
  purpose. A client reading a hundred books pays for a hundred password checks, and so does the
  server.
- The client has to keep the password, in a file or in memory, for as long as it wants to make
  requests. Anything that can read that file can be ana.
- There is no logging out. The server holds nothing per client that it could delete. The only way
  to take Basic access away is to change the password, which takes it away from everything else that
  used it too.

Basic is still the right tool in a few places: a script on a server talking to an internal API over
HTTPS, or a test like the ones in this lesson. Where it fits badly is wherever a person signs in once
and makes many requests after, and that is what the next section changes.
