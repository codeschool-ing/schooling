---
title: Read-your-writes: the person who just changed it
version: 1
---

The window is harmless to most readers, who cannot tell 12 from 11 and would not care. It is not
harmless to **the person who made the change**, because they know what the number should be. A member
of Quitanda's staff marks the coffee as sold out, then opens the product page to check:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 0; curl -s localhost:8003/product/coffee
coffee: 0 in stock, version 13
shop-b: coffee: 1 left, version 12
```

The stock service confirmed 0. The page says 1. The staff member does the reasonable thing, decides the
change did not take, and makes it again, or calls somebody, or stops trusting the admin screen. Nothing
was wrong except the order in which two true facts reached them.

The guarantee they needed is **read-your-writes**: after a person writes something, their own reads see
it, even if other people's reads do not yet. It is one of Terry's session guarantees, and it is much
cheaper than strong consistency, because it is a promise to one person about their own changes.

## The version travels with the person

The stock service answers every write with the version it created. If the next read carries that
version, the copy can tell whether it is behind, and send the read to the owner when it is. Shop `b`
does this with `?after=`:

```
ana@vm:~/lab/eventual$ curl -s 'localhost:8003/product/coffee?after=13'
shop-b: coffee: 0 in stock, version 13 (copy behind, asked the stock service)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A sequence between three participants: a member of staff, shop b and the stock service. The staff member sets coffee to 0 at the stock service and gets back version 13. They open the product page at shop b with after=13. Shop b&#x27;s copy is at version 12, older than 13, so shop b asks the stock service and answers 0 in stock, version 13.\"><defs><marker id=\"l9-ryw-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9-ryw-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">staff</text><path d=\"M110 56 L110 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"280\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shop b (copy at 12)</text><path d=\"M360 56 L360 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530\" y=\"26\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stock</text><path d=\"M610 56 L610 276\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M113 80 L607 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"230\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PUT coffee 0</text><path d=\"M607 108 L113 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"230\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">version 13</text><path d=\"M113 146 L357 146\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"235\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET coffee?after=13</text><text x=\"368\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 &lt; 13: behind</text><path d=\"M363 198 L607 198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"485\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET coffee</text><path d=\"M607 222 L363 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-amber)\"></path><text x=\"485\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">0, version 13</text><path d=\"M357 252 L113 252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l9-ryw-ah-phosphor)\"></path><text x=\"235\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">0, version 13</text></svg>", "caption": "Read-your-writes with a version: the write's answer carries the version, the next read asks for at least that one, and a copy that is behind sends the read to the owner."}
```

Shop `b`'s copy was still at 12, so it asked the stock service, and said so. A browser would keep the
version in a cookie or in the page itself; the admin screen in a real shop would do it without the staff
member ever seeing a number. **The owner is only asked when the copy is behind and the reader is the
one who wrote**, so the load the copy exists to absorb mostly stays on it.

## The other ways to get it

| approach | how | what it costs |
| --- | --- | --- |
| a version, as above | the write returns one, the read asks for at least that one | every reader of the copy has to understand versions |
| read from the owner for a while | after a person writes, send their reads to the owner for, say, the next minute | a guess about how long the window is, and it fails when the window is longer |
| show what was written | the screen shows the value the write returned, and does not read it back at all | nothing, when it fits; the next page load can still be stale |
| read from the owner always, for this screen | the admin screen talks to the stock service; only the public pages use the copy | the owner carries the admin traffic, which is usually small |

The last two are the most common in practice, and the simplest. **The fix is often to read the
person's own data from wherever they wrote it**, and keep the copies for everybody else.
