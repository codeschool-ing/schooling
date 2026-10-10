---
title: API keys
version: 1
---

**An API key identifies an application, not a person.** A partner bookshop that shows shelf's stock
on its own site has a program calling the API at three in the morning, and no one is there to type a
password. It needs a credential that belongs to the program, that lasts until somebody decides
otherwise, and that can be taken away without touching anybody's password.

A person creates it. Ana, signed in with Basic, asks for a key named after the partner:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{"name": "Livraria Parceira"}' | tee partner.json
{"key": "shelf_2ff69109_yOyZM1dhEnBovsmbwPZYBT6yAZJQYimsG5297JFqa2U", "prefix": "shelf_2ff69109", "name": "Livraria Parceira", "note": "shown once: store it now"}
```

**That reply is the only time the key exists outside the partner's hands.** The server answers with
the whole key once, and the `note` says so; ana passes it to the partner, and from then on the server
can only recognise it, never show it again. The partner sends it in `X-API-Key`:

```
ana@api:~/shelf$ curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/whoami
{"kind": "application", "name": "Livraria Parceira"}
ana@api:~/shelf$ curl -s -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/books/6
{"id": 6, "title": "Americanah", "stock": 4}
```

`/v1/whoami` says `application`, and the name is the one ana gave the key. Every request the partner
makes from now on is traceable to "Livraria Parceira", whichever employee wrote the code.

## The prefix and the hash

Here is what the server kept:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM api_keys'
shelf_2ff69109|22beab89b426a9d53de806590b74ced4eace1267072b17489cc2fbdd46899614|Livraria Parceira|2026-10-10T04:26:06Z|2026-10-10T04:26:06Z
```

The key has two parts, and the server treats them differently. **`shelf_2ff69109` is the prefix, and
it is not secret.** It is stored as it is, it is the row's primary key, and it is what `keys.py` uses
to find the row before comparing anything. It is also what makes a key recognisable: in a log line,
in a support ticket, or pasted by mistake into a public repository, where secret-scanning services
search for exactly such patterns and warn the owner. A key that is 43 random characters and nothing
else looks like any other random string to all of them.

The second column is the SHA-256 of the whole key, for the same reason as a token's: the key is
random, so a fast hash is enough, and a leaked table cannot be used to call the API. The last two
columns are when the key was made and when it was last used.

Managing keys is for people, and a key that tries is refused with the code the section on the 401
promised:

```
ana@api:~/shelf$ curl -si -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/keys
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Type: application/json
Content-Length: 43

{"error": "an API key cannot manage keys"}
```

**403, not 401.** The key authenticated perfectly; `keys.py` knows it is talking to Livraria Parceira.
What it refuses is the action. That is authorisation, in its smallest form, and lesson 11 builds the
rest of it.

## Rotation with two live keys

Keys leak, and people who knew them leave, so a key is replaced on a schedule and whenever there is a
doubt. Replacing one in place would break the partner at the moment of the switch, between the old
key dying and the new one reaching their configuration. **So for a while there are two.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"A timeline of two API keys. The old key is created with POST /v1/keys, its secret is shown once in that reply, and it is used, with last_used moving. A new key is created while the old one still works, so for a while both are live and the partner switches its configuration. When last_used of the old key stops moving, it is revoked with DELETE, and from then on it gets 401. The new key carries on.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">old key</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">new key</text><rect x=\"100\" y=\"55\" width=\"216\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in use: last_used moves</text><rect x=\"323\" y=\"45\" width=\"184\" height=\"120\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><rect x=\"330\" y=\"55\" width=\"170\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">both live</text><rect x=\"330\" y=\"125\" width=\"170\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"415.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">both live</text><rect x=\"514\" y=\"55\" width=\"166\" height=\"30\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"597.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">401</text><rect x=\"514\" y=\"125\" width=\"166\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"597.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in use</text><line x1=\"20\" y1=\"200\" x2=\"680\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"100\" y1=\"45\" x2=\"100\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"100\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">created, shown once</text><text x=\"100\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /v1/keys</text><line x1=\"330\" y1=\"45\" x2=\"330\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"330\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">second key created</text><text x=\"330\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /v1/keys</text><line x1=\"507\" y1=\"45\" x2=\"507\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"507\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">old key revoked</text><text x=\"507\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DELETE /v1/keys/…</text><text x=\"415\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the partner switches</text><text x=\"680\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Rotation without an outage: the second key exists before the first one goes, and the old one is revoked only when nothing uses it."}
```

Ana creates the second key and passes it on:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys -H 'Content-Type: application/json' -d '{"name": "Livraria Parceira, rotated"}' -o partner-new.json
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'
{"prefix":"shelf_2ff69109","name":"Livraria Parceira","created":"2026-10-10T04:26:06Z","last_used":"2026-10-10T04:26:06Z"}
{"prefix":"shelf_2ba45638","name":"Livraria Parceira, rotated","created":"2026-10-10T04:26:06Z","last_used":null}
ana@api:~/shelf$ for f in partner.json partner-new.json; do curl -s -H "X-API-Key: $(jq -r .key $f)" localhost:8000/v1/whoami; done
{"kind": "application", "name": "Livraria Parceira"}
{"kind": "application", "name": "Livraria Parceira, rotated"}
```

Both keys work, both are listed, and the new one has never been used. The partner switches its
configuration to the new key; on the server, ana watches `last_used`. When the old key's stops moving,
nothing uses it any more, and she revokes it by its prefix:

```
ana@api:~/shelf$ curl -si -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner.json)
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:07 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H "X-API-Key: $(jq -r .key partner.json)" localhost:8000/v1/whoami
{"error": "authentication required"}
401
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 localhost:8000/v1/keys | jq -c '.[]'
{"prefix":"shelf_2ba45638","name":"Livraria Parceira, rotated","created":"2026-10-10T04:26:06Z","last_used":"2026-10-10T04:26:07Z"}
```

The old key now gets a 401 like any stranger, and one key is left, with a fresh `last_used`.

One more thing belongs to a key and not to a person: **how often it may be used**. A partner whose
program has a bug that asks for every book once a second should be slowed down by its own key, without
slowing down anybody else. Lesson 12 counts requests per key.
