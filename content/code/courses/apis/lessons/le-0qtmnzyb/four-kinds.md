---
title: Four kinds of call
version: 1
---

**A gRPC method is one of four kinds, and what tells them apart is which side may send more than one
message.** The word `stream` in front of a message type in the `rpc` line is the whole declaration.
Whatever the kind, it is still **one call**: one HTTP/2 stream, one deadline, and one status at the
end.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Four kinds of gRPC call drawn as two lanes each, the client above and the server below, time running to the right. Unary: one message down, one message up, then the status. Server streaming: one message down, several up, then the status. Client streaming: several down, one up, then the status. Bidirectional: messages in both directions, interleaved, then the status.\"><defs><marker id=\"l04-calls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unary</text><text x=\"16\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">GetStock, Reserve</text><text x=\"196\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">client</text><text x=\"196\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server</text><line x1=\"204\" y1=\"28\" x2=\"690\" y2=\"28\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"72\" x2=\"690\" y2=\"72\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"30\" x2=\"256\" y2=\"69\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"70\" x2=\"326\" y2=\"31\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"70\" x2=\"606\" y2=\"31\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server streaming</text><text x=\"16\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">WatchStock</text><text x=\"196\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">client</text><text x=\"196\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server</text><line x1=\"204\" y1=\"112\" x2=\"690\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"156\" x2=\"690\" y2=\"156\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"114\" x2=\"256\" y2=\"153\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"154\" x2=\"326\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"380\" y1=\"154\" x2=\"406\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"460\" y1=\"154\" x2=\"486\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"154\" x2=\"606\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">client streaming</text><text x=\"16\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">Restock</text><text x=\"196\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">client</text><text x=\"196\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server</text><line x1=\"204\" y1=\"196\" x2=\"690\" y2=\"196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"240\" x2=\"690\" y2=\"240\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"198\" x2=\"256\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"198\" x2=\"326\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"370\" y1=\"198\" x2=\"396\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"450\" y1=\"238\" x2=\"476\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"238\" x2=\"606\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bidirectional</text><text x=\"16\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">(none in shelf)</text><text x=\"196\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">client</text><text x=\"196\" y=\"324\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">server</text><line x1=\"204\" y1=\"280\" x2=\"690\" y2=\"280\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"324\" x2=\"690\" y2=\"324\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"282\" x2=\"256\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"280\" y1=\"322\" x2=\"306\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"330\" y1=\"282\" x2=\"356\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"380\" y1=\"282\" x2=\"406\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"430\" y1=\"322\" x2=\"456\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"470\" y1=\"322\" x2=\"496\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"322\" x2=\"606\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><line x1=\"20\" y1=\"358\" x2=\"44\" y2=\"358\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></line><text x=\"50\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a message from the client</text><line x1=\"250\" y1=\"358\" x2=\"274\" y2=\"358\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"280\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a message from the server</text><line x1=\"480\" y1=\"358\" x2=\"504\" y2=\"358\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"510\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the one status that ends the call</text></svg>", "caption": "Four kinds of call, told apart by which side may send more than one message. Every one of them is a single call, and every one ends with exactly one status."}
```

| kind | the `rpc` line | in the warehouse |
|---|---|---|
| unary | `rpc GetStock(BookRef) returns (StockLevel)` | one question, one answer |
| server streaming | `returns (stream StockLevel)` | the level now, then each change |
| client streaming | `rpc Restock(stream Delivery)` | a delivery box by box, one summary |
| bidirectional | `stream` on both sides | none here; a chat, or a till sending scans and getting running totals |

The wrong picture is that a stream is many calls made quickly, the way a page asks for something
every few seconds. **A stream is one call that stays open**, and each message rides on the
connection that is already there. Nobody asks again, and nothing arrives that the other side did not
choose to send.

## A server stream

`WatchStock` sends the level at once and then again whenever it changes. Something has to change it
while you watch, so the command below starts two reservations in the background, a second apart, and
watches in the foreground. With Americanah at four copies:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000061
isbn: "9786500000061"
title: "Americanah"
copies: 4
availability: IN_STOCK
ana@api:~/shelf$ (sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null; sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null) & python3 stock_client.py watch 9786500000061 4
4 IN_STOCK
3 LOW
2 LOW
DEADLINE_EXCEEDED Deadline Exceeded
```

Three messages on one call: the level when the watch began, then one per reservation, the first of
them taking the book from `IN_STOCK` to `LOW`. The last line is not a message. **The client asked for four
seconds, and the call ended when they ran out**, which is how a watch says how long it wants to
listen; the next section is about that status.

The stream is pushed to the client, but the server finds the changes by reading the row five times a
second, as its note says. A real warehouse would be told by whatever changes the stock. The call
the client sees would be the same.

## A client stream

`Restock` takes a delivery as a stream of boxes, and answers once, when the client says it has sent
the last one. Three boxes, two of them for the same book:

```
ana@api:~/shelf$ python3 stock_client.py restock 9786500000061 5 9786500000030 2 9786500000061 1
boxes: 3
copies: 8
isbns: "9786500000061"
isbns: "9786500000030"
```

**The client sent three messages and got one back**, with `isbns` holding each book once. The
client did not wait for an answer between the boxes, and the server did not answer until the end.
That is the shape for an upload, a batch, or anything where the useful reply needs all of the input.

## Both at once

A bidirectional method has a stream on each side, and the two run independently: each side sends
when it has something, and **the order is kept within each direction and not between them**. A till
could stream every scanned book and get a running total back after each one. The warehouse has no
such method, and the bookshop does not need one, so it is drawn above and not built.
