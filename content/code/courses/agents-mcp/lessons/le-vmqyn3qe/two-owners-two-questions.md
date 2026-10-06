---
title: Two owners, two questions
version: 1
---

A refund goes to the `refunds` server, whose tools the host never runs without a person. Declined:

```
ana@lab:~/agents$ echo n | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] n
  error: Not approved by staff; nothing was done.
answer: I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
```

The host asked, the person said `n`, and the call never reached the server. The model read *"Not approved by staff; nothing was done."* as an error result. Approved:

```
ana@lab:~/agents$ printf "y\ny\n" | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] y
  ? the server asks: Refund 3890 cents on M-1047? [y/n] y
  result: {"result": "{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}"}
answer: Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
```

The person was asked **twice**. First by the host, because its policy says every `refunds` call needs a person. Then by the server, during the call: `refund_mcp.py` returns lesson 13's `input_required` with its own question, and the `Client` handed it to `server_asks`, which put it to the person. Only after two yeses did the refund run.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Two questions about one refund, from two owners. The host asked first, because its policy says the refunds server&#x27;s tools always need a person. The server asked during the call, because its own code will not refund without an approval. Either answer no stops the refund.\"><defs><marker id=\"l15two-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15two-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the model</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refunds__refund</text><rect x=\"200\" y=\"20\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1. the host asks</text><text x=\"210\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its policy: refunds need a person</text><rect x=\"200\" y=\"120\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2. the server asks</text><text x=\"210\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its code: no approval, no refund</text><rect x=\"490\" y=\"70\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">refunded: 3890</text><text x=\"500\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only after two yeses</text><path d=\"M150 95 L200 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-amber)\"></path><path d=\"M315 70 L315 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-amber)\"></path><path d=\"M430 145 L490 95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-phosphor)\"></path></svg>", "caption": "Two rules, two owners. Neither has to trust the other to have asked."}
```

Asking twice is not a design to copy for every tool; for most, one question in the right place is enough. It shows something worth knowing: **the host's rule and the server's rule belong to different owners**. The host's owner decides which calls its users must confirm; the server's owner decides what its system will not do without an approval, whichever host is calling. Neither can see the other's code, and neither should rely on the other having asked. When both exist, a person may be asked twice, and a host can make that bearable by showing who is asking, as `ask()` does.
