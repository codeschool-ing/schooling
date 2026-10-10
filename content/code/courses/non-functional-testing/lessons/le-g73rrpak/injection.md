---
title: Injection, where data is read as code
version: 1
---

Four of the commonest defects on the web have one shape. **Something the user typed reaches a
program that interprets text, and the program reads part of it as instructions instead of data.**
The interpreter differs: a database reads SQL, a browser reads HTML and JavaScript, a server reads a
form as a decision somebody made, a filesystem reads a name and a type. The defence differs with it,
and each one has a test a tester can write without knowing how anybody would abuse the defect.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l20-boundaries\" aria-label=\"Text a user sent, on the left, reaches four programs that interpret text, each in its own row. The database reads SQL, and the defence is a parameterised query. The browser reads HTML, and the defence is encoding by context, with a Content-Security-Policy behind it. The service reads a form as a decision, and the defence is a CSRF token with SameSite cookies. The filesystem reads a name and a type, and the defence is a size limit, a content check, a name the server makes and storage that is never served. Each row ends in the benign probe that tests it.\"><defs><marker id=\"l20-boundaries-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"70.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">user input</text><text x=\"250.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">interpreter</text><text x=\"450.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">defence</text><text x=\"635.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">benign probe</text><rect x=\"20.0\" y=\"50.0\" width=\"100.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"70.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a search,</text><text x=\"70.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a name,</text><text x=\"70.0\" y=\"171.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a form,</text><text x=\"70.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a file</text><path d=\"M120.0 75.0 L182.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"55.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">database</text><text x=\"250.0\" y=\"81.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SQL</text><path d=\"M315.0 75.0 L372.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"55.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">parameterised query</text><path d=\"M525.0 75.0 L557.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">'</text><path d=\"M120.0 133.0 L182.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"113.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">browser</text><text x=\"250.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML</text><path d=\"M315.0 133.0 L372.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"113.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encode by context</text><text x=\"450.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ CSP</text><path d=\"M525.0 133.0 L557.0 133.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;em&gt;nft-probe&lt;/em&gt;</text><path d=\"M120.0 191.0 L182.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"171.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the service</text><text x=\"250.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a decision</text><path d=\"M315.0 191.0 L372.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"171.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">CSRF token</text><text x=\"450.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ SameSite</text><path d=\"M525.0 191.0 L557.0 191.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">form, no token</text><path d=\"M120.0 249.0 L182.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"229.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">filesystem</text><text x=\"250.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">name, type</text><path d=\"M315.0 249.0 L372.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"229.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">size, content,</text><text x=\"450.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server-made name</text><path d=\"M525.0 249.0 L557.0 249.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"249.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">CSV named .png</text></svg>", "caption": "One shape, four interpreters. Each defence sits where the text enters the program that would read it as instructions."}
```

This lesson tests those four defences on your own two services, on `127.0.0.1`, with probes that are
deliberately harmless: a quote, a percent sign, a marker string, a form sent without its token, a
file that is not an image. Sending even these to a system you do not own, without written
permission, is illegal in most countries, Brazil included; it is also unnecessary, because
everything a tester needs to know about a defence can be learnt from the service in front of them.

## The defence is the parameter

SQL injection happens when a query is built by pasting the user's text into the SQL itself. The
text then becomes part of the statement, and a quote in it ends the string the author meant it to
stay inside. **The defence is a parameterised query**: the statement is sent with placeholders,
`?` in SQLite, and the values travel separately, so the database never reads them as SQL at all.
Lesson 1's `app.py` does it in every query, `title LIKE ?` among them, and so does `account.py`.

A tester checks it from the outside with the one character SQL treats specially in a string:

```
ana@nft:~/boxoffice$ curl -s 'localhost:8000/search?q=Hamlet' | jq length
4
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' "localhost:8000/search?q='"
[{"id": 1000, "title": "A Doll's House", "day": "2027-05-21"}]
 200
ana@nft:~/boxoffice$ curl -s 'localhost:8000/search?q=%25' | jq length
20
```

The quote is answered with `200` and a show, **because to the database it was a letter**: it found
the one title that contains an apostrophe, *A Doll's House*. A query built by pasting would have
failed on that quote and answered `500`, which is why a quote returning an ordinary answer is the
evidence a tester records, and a `500` on a quote is a finding.

The last request is worth a second look. `%25` is a percent sign, and the search for it returned all
20 shows on sale. **A parameter keeps the value out of the SQL, but `LIKE` still reads `%` and `_` as
wildcards inside the value.** Here that is harmless, since `/shows` lists the same 20 shows to
anybody, and the right call is to write it down rather than fix it. On a search over somebody's
private records the same behaviour would be a finding, and the fix is `LIKE ? ESCAPE '\'` with the
wildcards escaped in the value.

## The same check on the account service

`account.py` stores what a customer types and gives it back later, which is the other half of the
question: does the quote survive the round trip as text?

```
ana@nft:~/boxoffice$ curl -s -c ~/ana.jar -X POST localhost:8001/login -d '{"name": "ana", "password": "correct horse battery"}' | jq -r .token > ~/ana.token
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 990, "seat": 12, "holder": "Ana O'\''Brien"}'
{"id": 1}
ana@nft:~/boxoffice$ curl -s localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"show_id": 990, "seat": 12, "holder": "Ana O'Brien"}
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' "localhost:8001/account?q='"
200
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar "localhost:8001/account?q='" | grep '<li>'
<ul><li>Show 990, seat 12, for Ana O&#x27;Brien
```

The holder `Ana O'Brien` went in and came back unchanged, and the search for a quote found her
booking. On the page, the apostrophe arrives as `&#x27;`, which is the next section's subject: the
database and the browser are two interpreters, and each one needs its own defence.
