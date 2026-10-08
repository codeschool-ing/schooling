---
title: Errors and retries
version: 2
---

A RAG pipeline calls a provider twice per question, once to embed it and once to answer it, and each
call can fail: too many requests, a provider overloaded, a network that drops the connection. Lesson 5
met the first while indexing. At query time it matters more, because a customer is waiting.

## What the SDK retries

The SDKs retry, by themselves, the failures that can succeed a moment later: a 429 for too many
requests, a 500-something from an overloaded provider, a connection that dropped, and a request that
took longer than the client's timeout. Lesson 5 watched the loop against a port where nothing
listened. Ollama on your own machine never rate-limits and is rarely overloaded, so the failure a
local pipeline meets is the last one: a model on a processor with no graphics card can take longer
than the timeout to answer.

## A failure it does not absorb

`fragile.py` gives `rag.py` a client that waits one second for any reply, and lets it retry twice:

```schooling-example
{
  "language": "python",
  "file": "fragile.py",
  "parts": [
    {
      "code": "import sys\n\nimport openai\nimport rag\n\n# A client that gives a reply one second, and gives up after two retries.\nrag.client = openai.OpenAI(max_retries=2, timeout=1)\ntry:\n    print(rag.ask(sys.argv[1])[0])\nexcept (openai.APITimeoutError, openai.APIConnectionError) as e:\n    print(\"gave up after retries:\", type(e).__name__)\n    print(\"Our assistant is busy right now. Please try again in a minute.\")",
      "note": "`rag.py`'s client replaced by one that waits one second for any reply, and the failure caught where a customer would otherwise see a stack trace."
    }
  ]
}
```

```
ana@vm:~/rag$ OPENAI_LOG=info python fragile.py "How long is a gift card valid?" 2>&1
[2026-10-07 22:17:27 - httpx:1025 - INFO] HTTP Request: POST http://localhost:11434/v1/embeddings "HTTP/1.1 200 OK"
[2026-10-07 22:17:28 - openai._base_client:1172 - INFO] Retrying request to /chat/completions in 0.394029 seconds
[2026-10-07 22:17:29 - openai._base_client:1172 - INFO] Retrying request to /chat/completions in 0.835753 seconds
gave up after retries: APITimeoutError
Our assistant is busy right now. Please try again in a minute.
```

The embedding request answered within the second, `200 OK`. **The chat request did not, three times:
one attempt, two retries with a growing wait between them, and the SDK raised `APITimeoutError`.** The
program caught it and showed the customer a sentence instead of a stack trace. Each retry started the
generation again from nothing, so a timeout that is too short does not only fail: it spends three
generations' worth of the machine on an answer nobody receives.

`rag.py` itself sets twenty seconds, which on the machine this course was recorded on was enough for
every run in this lesson.
A model behind a commercial API answers a question this size in a second or two, and a timeout of ten
or twenty seconds there catches a stuck request rather than a slow one.

## The rules worth having

**Set the retry budget and the timeout on the client**, and measure the timeout against the model you
actually run. `rag.py` sets three retries and twenty seconds. The defaults of most SDKs are two retries and ten minutes, and ten minutes is not a timeout
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

**And count them.** Every retry is a request the provider bills or rate-limits, and with a commercial provider a
rising rate of 429s is the first sign of a quota about to be outgrown. The log of the last section of this lesson is
the place to record them.
