---
title: Order matters
version: 1
---

Two prompts in the lab say exactly the same thing in a different order. `v17-static-first.txt`
puts the long fixed guide first and the message last; `v17-message-first.txt` puts the message
first and the guide after it:

```
ana@lab:~/triage$ head -n 4 prompts/v17-static-first.txt
cache: on
---
You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.
ana@lab:~/triage$ head -n 6 prompts/v17-message-first.txt
cache: on
---
<message>
{{message|xml}}
</message>
```

Both turn the cache on in their header. Run each over the forty dev messages and count what the
cache did:

```
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/static.jsonl
40 calls, prompt b04095b1, written to runs/static.jsonl
ana@lab:~/triage$ pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl
40 calls, prompt 3eaa1caa, written to runs/first.jsonl
ana@lab:~/triage$ pl cost runs/static.jsonl
tokens          count   per call
input             827       20.7
cache_read       8736      218.4
cache_write       576       14.4
output           1536       38.4

cost of these 40 calls: 3.0302 cents
cost of a million calls like them: 75,755 cents
ana@lab:~/triage$ pl cost runs/first.jsonl
tokens          count   per call
input             827       20.7
cache_read          0        0.0
cache_write      9312      232.8
output           1521       38.0

cost of these 40 calls: 6.0216 cents
cost of a million calls like them: 150,540 cents
```

The plain `input` is 827 tokens in both: the remainders at the end of each prompt that never filled
a block. Everything else went through the cache, and **the two prompts used it in opposite ways**.

## Guide first

`v17-static-first` read 8736 tokens from the cache, which is 39 × 224. The first call had nothing
to read; every call after it read seven blocks of 32, the part of the guide they all share. It
wrote 576 tokens: the first call's seven blocks, 224 tokens, and eleven more blocks that reached
into a message. Those eleven were written and never read, because no other call has the same
message.

## Message first

`v17-message-first` read nothing and wrote 9312 tokens, every whole block of every call. Its first
block holds `<message>` and the start of the customer's text, so no two calls share even that one,
and **a block is only read when every block before it matched**. The guide behind it is the same on
every call, and the cache cannot reach a word of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The prompt of one call long enough for eight whole 32-token blocks and a remainder. v17-static-first: the first seven blocks are the fixed guide and are read from the cache; the eighth reaches into the message, so it is written and never read again; the remainder is plain input. v17-message-first: the message comes first, so every whole block differs from every other call&#x27;s and is written, and none is read.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one call&#x27;s prompt, in 32-token blocks</text><text x=\"168\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v17-static-first</text><rect x=\"180\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"238\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"296\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"354\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"412\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"470\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"528\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"586\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"644\" y=\"70\" width=\"26\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M604 56 L604 67\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M604 103 L604 108\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"604\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the message starts here</text><text x=\"168\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v17-message-first</text><rect x=\"180\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"238\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"296\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"354\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"412\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"470\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"528\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"586\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"644\" y=\"160\" width=\"26\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M180 146 L180 157\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M180 193 L180 198\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"180\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the message starts here</text><rect x=\"180\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"198\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read from the cache</text><rect x=\"350\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"368\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">written, never read again</text><rect x=\"520\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"538\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">plain input</text></svg>", "caption": "Seven blocks of the same guide are a prefix every call shares. Put the message in front of them and no two calls share even the first block, so the cache writes everything and reads nothing."}
```

The rule follows directly: **put what is the same on every call at the start, and what varies at
the end**. Instructions, the guide, examples and any fixed reference text go first; the customer's
message, and anything else that changes per call, goes last.
