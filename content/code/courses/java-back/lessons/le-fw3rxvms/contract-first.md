---
title: Code first or contract first
version: 1
---

Everything in this lesson so far was **code first**: the controllers came first and the document
was derived from them. The opposite is **contract first**: the team writes the OpenAPI document,
agrees on it with the people who will call the API, and only then writes code that keeps to it.
Both are common, and the difference is which of the two is allowed to change the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 316\" role=\"img\" aria-label=\"Code first: your controllers, annotated, are read by springdoc at run time, and the OpenAPI document follows whatever the code does. Contract first: openapi.yaml is written and reviewed first, and OpenAPI Generator turns it into server interfaces that your controllers implement and into a client library in the caller's language. In each row the box with an amber border is where a change starts.\"><defs><marker id=\"l17b-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Code first</text><rect x=\"20\" y=\"48\" width=\"170\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your controllers</text><text x=\"105.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">@GetMapping, @Operation</text><rect x=\"250\" y=\"48\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">springdoc</text><text x=\"325.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">at run time</text><rect x=\"460\" y=\"48\" width=\"220\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the OpenAPI document</text><text x=\"570.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">follows whatever the code does</text><path d=\"M 190 76 L 248 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 76 L 458 76\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Contract first</text><rect x=\"20\" y=\"190\" width=\"170\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">openapi.yaml</text><text x=\"105.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">written and reviewed first</text><rect x=\"250\" y=\"190\" width=\"150\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"325.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OpenAPI Generator</text><text x=\"325.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">generates code</text><rect x=\"460\" y=\"168\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server interfaces</text><text x=\"570.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">your controllers implement them</text><rect x=\"460\" y=\"226\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a client library</text><text x=\"570.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in the caller's language</text><path d=\"M 190 218 L 248 218\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 210 C 430 210, 430 190, 458 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><path d=\"M 400 226 C 430 226, 430 248, 458 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l17b-ah)\"></path><rect x=\"20\" y=\"292\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">where a change starts</text></svg>", "caption": "The same two artefacts in both rows. What changes is which one comes first, and so which one a change has to start from."}
```

## What code first cannot catch

A document derived from the code always matches the code, including when the code changes
something it should not have. Rename the search parameter from `q` to `text`, a change that reads like tidying:

```
ana@vm:~/bookshop$ sed -i 's/String q)/String text)/; s/search(q)/search(text)/; s/@param q the/@param text the/' src/main/java/com/example/bookshop/catalogue/BookController.java && grep -n 'text' src/main/java/com/example/bookshop/catalogue/BookController.java
57:     * Books whose title contains the text, ignoring case.
59:     * @param text the text to look for
64:    public List<BookResponse> search(@RequestParam String text) {
65:        return books.search(text);
```

Build, restart, and fetch the document into a second file. `~/api.json` still holds the one saved in
the section on annotations, so `diff` can compare the two:

```
ana@vm:~/bookshop$ curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api-renamed.json
ana@vm:~/bookshop$ diff ~/api.json ~/api-renamed.json
262c262
<                         "name": "q",
---
>                         "name": "text",
```

One line of the document changed, and the application started without a word about it. Every
client that searches with `?q=` is now broken:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8080/books/search?q=time'
400
ana@vm:~/bookshop$ curl -s -w '\n' 'localhost:8080/books/search?text=time'
[{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950,"stock":5}]
```

Nothing in code first refuses this, because the document follows whatever the code does. What
turns it into something a reviewer sees is keeping the document beside the code: save it into the
repository, regenerate it on every change, and let the review show its diff, as the `diff` above
did. A changed parameter name in a pull request's document is a question somebody asks before the
merge rather than after the release.

Put the parameter back before going on: replace `BookController.java` with the version from the
previous section again, build and restart.

## Contract first

A contract-first team starts from a file, usually `openapi.yaml`, written by hand and reviewed like
code by the people on both sides. A generator, most often **OpenAPI Generator**, reads it and
writes the parts that must agree with it. On the server those are Java interfaces with the mapping
annotations already on them, which your controllers implement. On the client side it is a library
in whatever language calls the API. Renaming `q` is now a change to the contract, made on purpose and
reviewed, and a controller that still says `q` no longer matches the interface it implements.

It costs something. The generator is one more tool to configure and upgrade, and the code it writes
is in its style and not yours. A rule like the ISBN check digit is still written by hand on the
server, because a schema can describe a string of thirteen digits but not the arithmetic on them.

Which way suits a team depends on who calls the API. An API with one client, written by the same
people in the same week, is well served by code first and a document kept in the repository. An
API that several teams, or other companies, build against before it exists needs the contract
first, because they cannot wait for your code to find out what it will say. `apis` lesson 6 takes
the specification and the contract-first workflow much further.
