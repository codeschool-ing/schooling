---
title: A request is a piece of text
version: 1
---

Here is everything your browser sent to ask for a page. Not a summary of it — these are the
characters that went down the stack, through the envelopes of the last lesson, and onto the wire.

```
GET /courses/web-fundamentals HTTP/1.1
Host: codeschool.ing
User-Agent: Mozilla/5.0 (X11; Linux x86_64)
Accept: text/html,application/xhtml+xml
Accept-Language: pt-BR,pt;q=0.9,en;q=0.8
Connection: keep-alive

```

That is the whole request. It is plain text, it has four parts, and one of them is invisible.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A request broken into its four parts: one start line carrying the method, the path and the version; several header lines; a blank line that marks the end of the headers; and a body, absent in this request.\"> <rect x=\"20\" y=\"30\" width=\"470\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">GET /courses/web-fundamentals HTTP/1.1</text> <text x=\"510\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">the start line — one, always</text> <rect x=\"20\" y=\"72\" width=\"470\" height=\"86\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Host: codeschool.ing</text> <text x=\"34\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">User-Agent: Mozilla/5.0 (X11; Linux x86_64)</text> <text x=\"34\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">Accept-Language: pt-BR,pt;q=0.9</text> <text x=\"510\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">headers — any number, any order</text> <rect x=\"20\" y=\"166\" width=\"470\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"510\" y=\"179\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">the blank line — the headers end here</text> <rect x=\"20\" y=\"200\" width=\"470\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"255\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the body, and a GET has none</text> <text x=\"510\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">present on POST, PUT, PATCH</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a response has the same four parts, with a number where the method was</text> </svg>", "caption": "Four parts, and the one doing the most work is the one you cannot see."}
```

## The four parts

The **start line** is one line with three things on it: what you want done (`GET`), what you want
it done to (`/courses/web-fundamentals`), and which version of the protocol you are speaking
(`HTTP/1.1`). Nothing else on the line, ever.

The **headers** are lines of `Name: value`, one per line, in no particular order. They describe the
request rather than being it: who is asking, what they can accept, how long the body is. The names
do not care about case — `host`, `Host` and `HOST` are the same header — because different
software has capitalised them differently for thirty years.

The **blank line** is the third part, and it is doing real work. It is how the far end knows the
headers have finished and whatever follows is content. Take it away and the server keeps waiting
for a header that is not coming.

The **body** is the fourth part, and this request does not have one. A `GET` asks for something and
has nothing to send. A form submission would have the form's fields down here, after the blank
line.

## The answer has the same shape

```
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 5218
Date: Tue, 16 Sep 2025 09:41:02 GMT

<!doctype html><html lang="pt-BR">...
```

Start line, headers, blank line, body — the same four parts, with the first line carrying
different things: the version, a three-digit number, and a word or two of explanation.

That explanation is decoration. `200 OK`, `200 Fine`, `200 Everything is well` are the same
response, because nothing reads the words: the **number** is the contract and the phrase is for
whoever is looking. Some newer versions of the protocol do not send the phrase at all.

## How the far end knows where the body ends

A connection is a stream of bytes, so something has to say where the content stops. There are two
answers and you will see both.

`Content-Length` says it up front, in bytes, and the receiver counts. Simple, and it requires the
sender to know the size before sending anything — which a server generating a page as it goes does
not.

The alternative is to send the body in pieces, each announcing its own size, ending with a piece of
size zero. That is called chunked, and it is how anything generated on the fly arrives.

Getting the length wrong is worth knowing about because the failure is strange rather than loud: a
length larger than the body leaves the receiver waiting for bytes that never come, and a length
smaller than the body leaves the leftovers to be read as the beginning of the next response.

## The server remembers nothing

Read the request again and notice what is in it. The host, the language, what formats are
acceptable, the whole path. All of it, on every single request.

That is not waste. HTTP is **stateless**: each request is complete on its own, and the server
between two of them is not obliged to remember anything at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three requests from the same browser arrive at three different servers. Each request carries everything needed to answer it, and no server keeps anything between requests.\"> <rect x=\"20\" y=\"40\" width=\"150\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"95\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one browser</text> <text x=\"95\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">request 1</text> <text x=\"95\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">request 2</text> <text x=\"95\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">request 3</text> <text x=\"95\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">each one complete</text> <path d=\"M176 96 L446 60\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 122 L446 122\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 148 L446 184\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"452\" y=\"36\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server A</text> <text x=\"576\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">keeps nothing afterwards</text> <rect x=\"452\" y=\"98\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server B</text> <text x=\"576\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">keeps nothing afterwards</text> <rect x=\"452\" y=\"160\" width=\"248\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"576\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server C</text> <text x=\"576\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">keeps nothing afterwards</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">three requests of one visit, answered by three machines, and none the wiser</text> </svg>", "caption": "Because no server holds anything between requests, any of them can answer the next one."}
```

It is an unusual choice and it is why the web scaled. A server that remembers nothing can be
replaced mid-conversation by another server, and the next request lands on whichever machine is
free — which is exactly what the load balancer of the last lesson is doing. If each connection had
carried a memory, the same visitor would have had to return to the same machine for as long as they
were browsing, and one machine's failure would have ended everybody's session on it.

The price arrives immediately: a shop needs to know what is in your basket, and the protocol has
just declined to remember. Everything in the next lesson — cookies, sessions, tokens — exists to
put state back on top of a protocol that refuses to hold any. Statelessness is not an absence of
the feature; it is the feature, with the cost pushed upwards where you can choose how to pay it.

## Which is why `Host` is mandatory

One header in that request is required by the version it claims, and the reason is worth a moment.

`Host: codeschool.ing` tells the server which site is wanted. The address got the packet to a
machine, but one machine commonly answers for hundreds of names — that is what shared hosting is —
and by the time the request arrives the address is no longer enough to tell them apart.

Before this header existed, a server could host exactly one site per address, and addresses were
already running short. One line of text turned one machine into as many sites as you like, and the
economics of putting something on the web changed with it.
