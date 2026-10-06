---
title: Errors and retries
version: 1
---

A RAG pipeline calls a provider twice per question, once to embed it and once to answer it, and each
call can fail: too many requests, a provider overloaded, a network that drops the connection. Lesson 5
met the first while indexing. At query time it matters more, because a customer is waiting.

## A refusal the SDK absorbs

labgen can be told to refuse the next requests, the same way labembed was in lesson 5:

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo
{"fail": 2, "status": 429}
ana@lab:~/rag$ python rag.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
  [1] Gift card terms > Validity, updated 2025-10-27
  [2] Payments, invoices and gift cards > Gift cards, updated 2026-03-30
ana@lab:~/rag$ python statuses.py
/v1/embeddings 200
/v1/chat/completions 200
/v1/embeddings 429
/v1/embeddings 429
/v1/embeddings 200
/v1/chat/completions 200
```

`statuses.py` prints the last six requests labgen received. The first two are the previous query. Then
**the embedding request was refused twice and succeeded on the third attempt**, and the chat request
went through. The customer saw an answer; the program never knew. `rag.py` built its client with
`max_retries=3`, and the SDK spent two of them, waiting a little longer before each.

## A refusal it does not

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 5, \"status\": 429}"; echo
{"fail": 5, "status": 429}
ana@lab:~/rag$ python fragile.py "How long is a gift card valid?"
gave up after retries: 429
Our assistant is busy right now. Please try again in a minute.
ana@lab:~/rag$ python statuses.py
/v1/embeddings 429
/v1/embeddings 200
/v1/chat/completions 200
/v1/embeddings 429
/v1/embeddings 429
/v1/embeddings 429
```

`fragile.py` replaces the client with one allowed only two retries, and five refusals are waiting.
**Three attempts, three refusals, and the SDK raised `RateLimitError`.** The program caught it and
showed the customer a sentence instead of a stack trace. The last six lines of the log show the
previous query's three requests and then the three refused attempts at this one; the chat endpoint was
never reached, because there was no vector to search with.

```
ana@lab:~/rag$ curl -s -X POST localhost:8600/lab/config -d "{\"fail\": 0}"; echo
{"fail": 0, "status": 429}
```

## The rules worth having

**Set the retry budget and the timeout on the client.** `rag.py` sets three retries and twenty
seconds. The defaults of most SDKs are two retries and ten minutes, and ten minutes is not a timeout
anybody waiting at a chat window would choose.

**Retry what can succeed, not what cannot.** The SDKs retry rate limits, overloads and connection
errors, and do not retry a bad request or a refused key, because repeating those cannot help. Code that
wraps the SDK in its own retry loop usually undoes that distinction.

**Decide what the customer sees when everything fails.** A sentence saying the assistant is busy is a
product decision; an exception is an accident. For a support assistant, the better fallback is often
the plain search results, the help centre's articles, without a generated answer: retrieval needs only
the embedding call, and the documents themselves are useful.

**Separate the two calls' failures.** The embedding call failing means no search at all; the chat call
failing after a search means the sources are known and can be shown. A pipeline that treats both as
one error throws away the half that worked.

**And count them.** Every retry is a request the provider bills or rate-limits, and a rising rate of
429s is the first sign of a quota about to be outgrown. The log of the last section of this lesson is
the place to record them.
