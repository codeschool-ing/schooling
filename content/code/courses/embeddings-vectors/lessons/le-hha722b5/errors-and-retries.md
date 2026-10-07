---
title: Errors and retries
version: 1
---

An API is a service somebody else runs, and some of its refusals are about the moment rather than
the request. The commonest is **429, Too Many Requests**: the account has sent more requests or
tokens per minute than its limit allows. Nothing is wrong with the request; it will succeed if it
is sent again a little later.

The wrong idea is to wrap every call in a retry loop of your own. The `openai` SDK already retries,
and a second loop around it multiplies the attempts: three of yours times three of its is nine
requests for one text, all landing on a provider that just said it was busy.

## Watching the SDK retry

labembed has a switch the real service does not: `POST /lab/config` with `{"fail": 2}` makes it
refuse the next two requests with 429, so a rate limit can be produced on demand.

```schooling-example
{
  "language": "python",
  "file": "retry.py",
  "parts": [
    {
      "code": "import time\nimport httpx\nimport openai\nfrom openai import OpenAI\n\nclient = OpenAI()\nprint(\"max_retries\", client.max_retries, \" timeout\", client.timeout)\n\n\ndef fail_next(n):  # the lab's switch, not OpenAI's\n    httpx.post(\"http://127.0.0.1:8500/lab/config\", json={\"fail\": n, \"status\": 429})",
      "note": "The client's defaults, and a helper that tells labembed to answer the next requests with 429, as a provider does when you send too much too fast."
    },
    {
      "code": "fail_next(2)\nstart = time.monotonic()\nr = client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nprint(f\"answered after {time.monotonic() - start:.1f} s with {len(r.data[0].embedding)} numbers\")",
      "note": "Two failures, then an answer. The SDK retries on its own; the program only sees the success, a little late."
    },
    {
      "code": "fail_next(3)\nstart = time.monotonic()\ntry:\n    client.embeddings.create(model=\"lab-minilm\", input=\"When your refund arrives\")\nexcept openai.RateLimitError as e:\n    print(f\"gave up after {time.monotonic() - start:.1f} s:\", type(e).__name__, e.status_code)",
      "note": "Three failures: the first attempt and both retries are refused, and the SDK raises `RateLimitError`."
    },
    {
      "code": "try:\n    client.embeddings.create(model=\"lab-minilm\", input=\"\")\nexcept openai.BadRequestError as e:\n    print(\"not retried:\", type(e).__name__, e.status_code)",
      "note": "An empty string is a 400. Asking again cannot fix the request, so the SDK raises at once."
    }
  ]
}
```

```
ana@lab:~/emb$ python retry.py
max_retries 2  timeout Timeout(connect=5.0, read=600, write=600, pool=600)
answered after 2.1 s with 384 numbers
gave up after 2.0 s: RateLimitError 429
not retried: BadRequestError 400
ana@lab:~/emb$ jq -c '{at, status}' labembed.jsonl | tail -n 7
{"at":"2026-10-07T12:42:43-03:00","status":429}
{"at":"2026-10-07T12:42:44-03:00","status":429}
{"at":"2026-10-07T12:42:45-03:00","status":200}
{"at":"2026-10-07T12:42:45-03:00","status":429}
{"at":"2026-10-07T12:42:46-03:00","status":429}
{"at":"2026-10-07T12:42:47-03:00","status":429}
{"at":"2026-10-07T12:42:47-03:00","status":400}
```

The first line is the client's defaults: **`max_retries` 2**, and a timeout of 600 seconds for
reading the answer and 5 for connecting.

With two failures queued, the call **returned normally**. The program never saw the 429s; it only
took longer, because the SDK waited between attempts. labembed sends a `retry-after: 1` header
with each 429, as providers do, and the SDK waited about that long each time. The log shows the
three requests behind one call.

With three failures queued, the first attempt and both retries were refused, and only then did the
SDK give up and raise **`RateLimitError`**. That exception is the one to handle in your own code,
and handling it means slowing down: wait, send less per minute, or queue the work for later, not
an immediate fourth attempt.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 530\" role=\"img\" aria-label=\"A sequence diagram of two calls to embeddings.create, with the program on the left and labembed on the right, time running down. First call: the SDK sends a request at 12:42:43 and gets 429, waits, sends again at 12:42:44 and gets 429, waits, sends a third time at 12:42:45 and gets 200; the program receives the vector after 2.1 seconds and never sees the refusals. Second call: three requests at 12:42:45, 12:42:46 and 12:42:47, all refused with 429; after 2.0 seconds the SDK raises RateLimitError.\"><defs><marker id=\"seqen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"seqen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"seqen-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"seqen-ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">your program</text><path d=\"M90 44 L90 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"260\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">openai SDK</text><path d=\"M330 44 L330 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530\" y=\"14\" width=\"140\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">labembed</text><path d=\"M600 44 L600 520\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">two failures queued</text><path d=\"M90 86 L326 86\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah0)\"></path><text x=\"210\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">embeddings.create(...)</text><path d=\"M330 104 L596 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:43</text><path d=\"M600 126 L334 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"465\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"140\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waits</text><path d=\"M330 170 L596 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:44</text><path d=\"M600 192 L334 192\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"465\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"206\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waits</text><path d=\"M330 236 L596 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:45</text><path d=\"M600 258 L334 258\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah3)\"></path><text x=\"465\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">200</text><path d=\"M330 272 L94 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah3)\"></path><text x=\"210\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a vector, 2.1 s later</text><text x=\"20\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">three failures queued</text><path d=\"M90 322 L326 322\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah0)\"></path><text x=\"210\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">embeddings.create(...)</text><path d=\"M330 340 L596 340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"340\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:45</text><path d=\"M600 362 L334 362\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"465\" y=\"353\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"376\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"386\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waits</text><path d=\"M330 406 L596 406\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"406\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:46</text><path d=\"M600 428 L334 428\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"465\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><rect x=\"290\" y=\"442\" width=\"80\" height=\"20\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"452\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waits</text><path d=\"M330 472 L596 472\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah1)\"></path><text x=\"608\" y=\"472\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:42:47</text><path d=\"M600 494 L334 494\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"465\" y=\"485\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">429</text><path d=\"M330 508 L94 508\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#seqen-ah2)\"></path><text x=\"210\" y=\"499\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">RateLimitError, 2.0 s later</text></svg>", "caption": "Behind one call, the SDK sends up to three requests. With two failures queued the program receives a vector and never learns of the 429s; with three, the SDK gives up and raises. The times on the right are labembed's log."}
```

The empty string was refused with 400 and raised at once, after a single request. OpenAI's SDK
documents which failures it retries: connection errors, 408, 409, 429 and any 5xx. A 400, 401 or
404 says the request itself is wrong, and sending it again would get the same answer.

## Settings worth choosing

Both defaults can be changed per client or per call, with `OpenAI(max_retries=5, timeout=30)` or
`client.with_options(...)`. Two cases where you would:

- **A background job** that embeds a corpus overnight can afford more retries and longer waits;
  failing at three in the morning because of a brief rate limit wastes the whole run.
- **A search box** cannot. A user is waiting for the query's vector, and ten minutes of read
  timeout is not a wait anybody makes. A short timeout and few retries, with a message to the
  user, is better than a page that hangs.

## Safe to repeat

Retrying is only safe when sending a request twice does no harm. For embeddings it does none:
the request changes nothing on the server, and lesson 1 showed that the same text through the
same model gives the same vector. A retried embedding call that succeeds twice, because the first
answer was lost on the way back, costs its tokens twice and nothing else. That is not true of every
API, and it is why the SDK's habit of retrying on its own is harmless here.
