---
title: HTTP/2 underneath
version: 1
---

**A gRPC call is an HTTP/2 `POST` to the method's full name, with the messages in the body and the
status in trailers**, headers that arrive after the body has ended. Nothing in it is hidden, and
with the server running again you can make a call with `curl` and the bytes from the section on the
wire.

The wrong idea is that gRPC is a protocol of its own beside HTTP. It is a way of using HTTP/2, and
**HTTP/2 only**. Ask in HTTP/1.1, which is what `curl` speaks unless told otherwise:

```
ana@api:~/shelf$ curl -sS http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock
curl: (1) Received HTTP/0.9 when not allowed
```

The server answered in HTTP/2's binary framing, and `curl`, expecting a status line in text, could
not read what came back. Nothing about the warehouse was wrong; the two programs did not share a
protocol.

## A call made by hand

The request message is a `BookRef`, encoded the same way as before:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016"' | protoc --encode=shelf.stock.v1.BookRef stock.proto > ask.bin
ana@api:~/shelf$ od -An -tx1 ask.bin
 0a 0d 39 37 38 36 35 30 30 30 30 30 30 31 36
```

Fifteen bytes. In the body of the request **each message is preceded by five bytes**: one that says
whether the message is compressed, here `00`, and four that give its length, here `00 00 00 0f`,
which is 15. `printf` writes the five and `cat` adds the message:

```
ana@api:~/shelf$ { printf '\x00\x00\x00\x00\x0f'; cat ask.bin; } > ask.grpc
```

Then the call itself: `--http2-prior-knowledge` makes `curl` speak HTTP/2 from the first byte,
`-D -` prints the headers, the body goes to a file, and the two `-H` give the content type gRPC
expects and the `te: trailers` its specification asks for:

```
ana@api:~/shelf$ curl -sS --http2-prior-knowledge -D - -o reply.grpc -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetStock
HTTP/2 200 
content-type: application/grpc
grpc-accept-encoding: identity, deflate, gzip

grpc-status: 0
```

**The status line says 200 and the real result comes last.** The empty line is the end of the
headers; everything after it arrived once the body was over, and `grpc-status: 0` is `OK`. The body
holds one message with the same five-byte prefix, `21` being 33:

```
ana@api:~/shelf$ od -An -tx1 reply.grpc
 00 00 00 00 21 0a 0d 39 37 38 36 35 30 30 30 30
 30 30 31 36 12 0c 44 6f 6d 20 43 61 73 6d 75 72
 72 6f 18 0a 20 01
ana@api:~/shelf$ tail -c +6 reply.grpc | protoc --decode=shelf.stock.v1.StockLevel stock.proto
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 10
availability: IN_STOCK
```

Ten copies, because two were reserved in the section on the server. Now ask for a method the service
does not have:

```
ana@api:~/shelf$ curl -sS --http2-prior-knowledge -D - -o /dev/null -H 'content-type: application/grpc' -H 'te: trailers' --data-binary @ask.grpc http://127.0.0.1:50051/shelf.stock.v1.Stock/GetPrice
HTTP/2 200 
content-type: application/grpc
grpc-status: 12
grpc-message: Method not found!
```

HTTP still says 200, because the HTTP exchange worked. **The call failed with code 12,
`UNIMPLEMENTED`**, and the message came in the trailers. A tool that judged gRPC traffic by its HTTP
status would count this as a success.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"One gRPC call inside one HTTP/2 stream, on a connection other calls share. The client sends a HEADERS frame with :method POST, :path /shelf.stock.v1.Stock/GetStock, content-type application/grpc and te trailers, then a DATA frame holding a flag byte 00, a four-byte length 00 00 00 0f and the 15-byte message. The server answers with HEADERS carrying :status 200, a DATA frame with 00, 00 00 00 21 and the 33-byte message, and a final HEADERS frame, the trailers, with grpc-status 0.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"22\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one TCP connection: other calls run beside this one on streams of their own</text><rect x=\"24\" y=\"40\" width=\"672\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one HTTP/2 stream = one call</text><text x=\"190\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client → server</text><text x=\"530\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server → client</text><rect x=\"40\" y=\"94\" width=\"300\" height=\"92\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">HEADERS</text><text x=\"52\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:method: POST</text><text x=\"52\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:path: /shelf.stock.v1.Stock/GetStock</text><text x=\"52\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">content-type: application/grpc</text><text x=\"52\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">te: trailers</text><rect x=\"40\" y=\"198\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"52\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">DATA</text><text x=\"52\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">00 | 00 00 00 0f | 0a 0d 39 37 …</text><text x=\"52\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">flag | length 15 | the BookRef</text><rect x=\"380\" y=\"94\" width=\"300\" height=\"52\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">HEADERS</text><text x=\"392\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:status: 200</text><text x=\"500\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">content-type: application/grpc</text><rect x=\"380\" y=\"158\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">DATA</text><text x=\"392\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">00 | 00 00 00 21 | 0a 0d 39 37 …</text><text x=\"392\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">flag | length 33 | the StockLevel</text><rect x=\"380\" y=\"232\" width=\"300\" height=\"62\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">HEADERS, after the body: the trailers</text><text x=\"392\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">grpc-status: 0</text><text x=\"392\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the call&#x27;s real result</text></svg>", "caption": "A gRPC call is an HTTP/2 POST to the method's full name. Its result arrives last, in trailers, which is the part a browser's fetch() cannot read."}
```

## What HTTP/2 gives it

HTTP/2 carries many **streams** on one connection, each with its own frames, and a gRPC call is one
stream. So a watch that stays open for an hour does not hold up the reservations made on the same
connection, and a client's channel opens one TCP connection to the warehouse and sends every call
on it. The same framing
is what makes a stream in either direction possible: data frames keep coming until one side says it
has finished.

## Why a browser cannot call it

A page's JavaScript asks the browser for a request with `fetch()`, and the browser chooses the
protocol. **`fetch()` gives a page no way to read trailers**, and no control over HTTP/2 framing, so
the status of every call would be out of reach. Two arrangements get around it, and both put
something between the browser and the service.

**gRPC-Web** is a variant of the protocol that moves the trailers into the end of the body, where a
browser can read them. The page uses a gRPC-Web client library, and a proxy in front of the service,
Envoy being the common one, translates to real gRPC.

**JSON transcoding** puts a gateway in front of the service that accepts ordinary REST requests with
JSON bodies and turns each into a gRPC call. The `.proto` says which path maps to which method,
through annotations the gateway reads; `grpc-gateway` and Envoy's transcoding filter are the two you
will meet most.

Neither is run in this lesson, because each needs a proxy the course does not install. And the
warehouse listens without TLS, on 127.0.0.1 only; a gRPC service between machines runs over TLS
like any other HTTP, and lesson 13 is about HTTPS.
