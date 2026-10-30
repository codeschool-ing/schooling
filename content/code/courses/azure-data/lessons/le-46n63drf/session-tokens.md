---
title: The session token, watched on the wire
version: 1
---

**Session consistency is kept by a token, and the token is just a header.** Every write to a
container answers with `x-ms-session-token`, a short string naming the partition the item is in and
how far that partition's log had got when the write was applied. A read that sends the token back
can only be served by a copy whose log has reached that point. Nothing else is involved: no lock, no
connection held open, no server remembering who you are. That is why the session can cross processes,
and why it is lost the moment a program forgets the string.

This section is practised. Start the Cosmos DB emulator as lesson 1 showed, and save the program
below as `session.py` in `~/azure`:

```sh
docker compose --profile cosmos up -d
```

```schooling-example
{"language": "python", "file": "session.py", "parts": [
{"code": "from azure.cosmos import CosmosClient, PartitionKey, exceptions\n\nURL = \"http://localhost:8081\"\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\n\n\ndef sent(request):\n    print(\"   sent:\", request.http_request.headers.get(\"x-ms-session-token\", \"no token\"))\n\n\ndef orders(client):\n    db = client.create_database_if_not_exists(\"quitanda\")\n    return db.create_container_if_not_exists(\"orders\", PartitionKey(\"/customerId\"))\n", "note": "The emulator's address and its published key, as in lesson 1's `ru.py`. `sent` is called by the library just before each request leaves, and prints the session token it carries, if any. Every client opens the same container."},
{"code": "\napp = orders(CosmosClient(URL, KEY, consistency_level=\"Session\"))\nfor n in (\"o-1001\", \"o-1002\"):\n    app.upsert_item({\"id\": n, \"customerId\": \"c-7\", \"status\": \"paid\"})\n    answer = app.client_connection.last_response_headers\n    print(\"the app wrote\", n, \"and was given\", answer[\"x-ms-session-token\"])\ntoken = answer[\"x-ms-session-token\"]\nprint(\"the answer names the item's path:\", \"x-ms-alt-content-path\" in answer)\n", "note": "The app is a client at session consistency. It writes two orders, and each answer carries a token in the header `x-ms-session-token`. The last line asks whether the answer also carried `x-ms-alt-content-path`, which is the header the Python library files a token under."},
{"code": "\nprint(\"the app reads o-1002 back\")\napp.read_item(\"o-1002\", \"c-7\", raw_request_hook=sent)\n", "note": "The app reads back what it wrote. On Azure the library attaches the token from its own write here, without being asked."},
{"code": "\nreport = orders(CosmosClient(URL, KEY, consistency_level=\"Session\"))\nprint(\"a second client reads it with the app's token\")\nreport.read_item(\"o-1002\", \"c-7\", session_token=token, raw_request_hook=sent)\n", "note": "A second client, which is how a background worker or another web server looks to Cosmos DB, reads the same order with the app's token passed by hand."},
{"code": "\nprint(\"the second client reads with a token nobody was given\")\ntry:\n    report.read_item(\"o-1002\", \"c-7\", session_token=\"0:0#999\", raw_request_hook=sent)\nexcept exceptions.CosmosHttpResponseError as e:\n    print(\"  \", e.status_code, e.sub_status, e.message.splitlines()[0])\n", "note": "A token naming a write the copy has not applied. Here it names one that never happened, which is the only way to get a stale copy out of an emulator that has one."}
]}
```

```
ana@laptop:~/azure$ python session.py
the app wrote o-1001 and was given 0:0#1
the app wrote o-1002 and was given 0:0#2
the answer names the item's path: False
the app reads o-1002 back
   sent: no token
a second client reads it with the app's token
   sent: 0:0#2
the second client reads with a token nobody was given
   sent: 0:0#999
   sent: 0:0#999
   404 1002 (NotFound) The read session is not available for the input session token.
```

**Each write moved the token on by one: `0:0#1`, then `0:0#2`.** The number before the colon names
the partition key range the item is in, and the emulator has a single range, `0`. The number after
`#` is the position in that range's log. A token is therefore a claim about one partition and says
nothing about the others, which is why the libraries keep one per range and merge them.

**Then the line that is not about Azure at all: the answer did not name the item's path.** The
Python library files a token it was handed under the container it came from, and it learns which
container from a response header, `x-ms-alt-content-path`, which this emulator does not send. So the
library never stored either token, and the app's own read went out with `no token`. Against Azure
the same line sends `0:0#2` without being asked; that comes from reading the library's source, in
`azure/cosmos/_session.py`, and was not observed, since nothing in this course reaches Azure. On
this emulator a session is only ever what you carry by hand, which turns out to be the more useful
thing to have practised.

**The second client read with the app's token and was answered.** That is the pattern for a session
that crosses processes: the web server that took the payment puts the token in the customer's
browser session, and whichever server answers the next page passes it on the read. A courier app
that never saw the token gets no promise about the customer's write, only about its own.

**And the token from the future was refused, with 404 and sub-status 1002**: *the read session is
not available for the input session token*. The library sent it twice before giving up, because on
Azure this answer is ordinary and momentary. With four copies in a partition, a read can land on the
one that has not applied the write yet, and the request is retried until a copy that has can answer:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 332\" role=\"img\" aria-label=\"A sequence between the app and two copies of the same partition. The app writes o-1002 to a copy, which answers with the session token 0:0#2. The app then reads o-1002 carrying that token, and the read reaches a copy still at #1, which answers 404 with sub-status 1002 because it has not applied that write yet. The same read is retried, reaches the copy at #2, and gets the order back with status paid.\" data-fig=\"l12-token\"><defs><marker id=\"l12-tk-ah-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--phosphor)\"/></marker><marker id=\"l12-tk-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--amber)\"/></marker></defs><rect x=\"30\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"110\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the app</text><line x1=\"110\" y1=\"44\" x2=\"110\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><rect x=\"300\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"380\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a copy at #2</text><line x1=\"380\" y1=\"44\" x2=\"380\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><rect x=\"540\" y=\"14\" width=\"160\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"620\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a copy still at #1</text><line x1=\"620\" y1=\"44\" x2=\"620\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"/><line x1=\"114\" y1=\"70\" x2=\"376\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">write o-1002</text><line x1=\"376\" y1=\"104\" x2=\"114\" y2=\"104\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">x-ms-session-token: 0:0#2</text><line x1=\"114\" y1=\"150\" x2=\"616\" y2=\"150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"365.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read o-1002, token 0:0#2</text><line x1=\"616\" y1=\"184\" x2=\"114\" y2=\"184\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-a)\"/><text x=\"365.0\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">404, sub-status 1002: not there yet</text><line x1=\"114\" y1=\"230\" x2=\"376\" y2=\"230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the same read, retried</text><line x1=\"376\" y1=\"264\" x2=\"114\" y2=\"264\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12-tk-ah-p)\"/><text x=\"245.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o-1002, status paid</text><text x=\"370\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A copy answers only once it has applied the write the token names.</text></svg>", "caption": "Session consistency on Azure, where a partition has several copies. The emulator has one, which is why the program above needed a token from the future to see a refusal."}
```

A 404 that means *not yet* rather than *not found* is worth recognising on sight. If it persists,
the token did not come from a write to this container: it was copied from somewhere else, or
invented, as it was here.
