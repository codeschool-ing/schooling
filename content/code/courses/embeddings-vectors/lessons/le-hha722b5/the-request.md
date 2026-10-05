---
title: The request
version: 1
---

Every vector so far came from a model running on Ana's laptop. Most teams do not run their own: they
send text to a provider over HTTP and get vectors back, and pay per token. OpenAI's embeddings
endpoint is the most widely copied of these, and this lesson calls it with OpenAI's own Python
library, `openai`.

## What is answering on this machine

**The server in this lesson is not OpenAI.** No provider's API could be reached from the machine
the course was recorded on, and an API key is a bill that a course cannot hand out. So the lab runs
**labembed**, a small server written for the course (`lab/labembed.py`), on `127.0.0.1:8500`. It
answers OpenAI's `/v1/embeddings` request in OpenAI's format closely enough that the real SDK
accepts its answers unmodified. The vectors are real: they come from all-MiniLM-L6-v2 and
WordLlama, the two models the earlier lessons ran, served under the lab's own names `lab-minilm`
and `lab-wordllama`.

The SDK is pointed at it by two environment variables, the ones it reads on its own:

```
ana@lab:~/emb$ env | grep ^OPENAI
OPENAI_API_KEY=lab-openai-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8500/v1
```

Against the real service you would delete `OPENAI_BASE_URL`, set your own key, and write
`text-embedding-3-small` where this lesson writes `lab-minilm`. Nothing else in the code changes.
What does change is everything the lab cannot imitate: OpenAI's prices, its rate limits, its
latency and the model's own vectors. Where this lesson says something about those, it quotes
OpenAI's documentation or the price sheet and says so.

## One call

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from openai import OpenAI\n\nclient = OpenAI()",
      "note": "`OpenAI()` reads `OPENAI_API_KEY` and `OPENAI_BASE_URL` from the environment. On this machine the base URL points at labembed; without it, the SDK talks to `https://api.openai.com/v1`."
    },
    {
      "code": "response = client.embeddings.create(\n    model=\"lab-minilm\",\n    input=\"When your refund arrives\",\n)",
      "note": "One call, two arguments: which model, and the text. `input` takes a string or a list of strings."
    },
    {
      "code": "vector = response.data[0].embedding\nprint(type(vector).__name__, len(vector), [round(x, 4) for x in vector[:4]])\nprint(response.usage)",
      "note": "The vector is in `data[0].embedding`, a plain Python list of floats. `usage` says how many tokens the request was billed for."
    }
  ]
}
```

```
ana@lab:~/emb$ python first.py
list 384 [-0.0865, -0.0142, -0.0045, 0.0386]
Usage(prompt_tokens=5, total_tokens=5)
ana@lab:~/emb$ tail -n 1 /var/log/labembed/requests.jsonl
{"at": "2026-10-05T14:19:26-03:00", "path": "/v1/embeddings", "provider": "openai", "model": "lab-minilm", "inputs": 1, "tokens": 5, "dims": 384, "encoding_format": "base64", "status": 200}
```

The first four numbers are the ones lesson 1 printed for the same title from the same model,
rounded the same way. A vector from an API is the same object as a vector from a local model:
384 floats, length 1, comparable with other vectors from that model and no other.

The last line of the transcript is labembed's own log of the request, one JSON line per call. It
records what the SDK sent, and one field in it, `encoding_format`, is a detail the next section
comes back to.

## The same request without the SDK

The SDK is a convenience over one HTTP request, and it helps to see that request bare. It is a
`POST` with the key in an `Authorization: Bearer` header and a JSON body:

```json
{"model": "lab-minilm", "input": "When your refund arrives"}
```

```
ana@lab:~/emb$ curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | cut -c 1-150
{"object": "list", "data": [{"object": "embedding", "index": 0, "embedding": [-0.08653447031974792, -0.014246996492147446, -0.004477363079786301, 0.03
```

That is the whole protocol: a model name, an input, and a list of numbers back. Any language with
an HTTP client can call it, which is why so many other providers copy its shape; lesson 10 meets
one that does.

## When the request is refused

Two refusals come up on the first day: a wrong key, and a model name the server does not know.

```python
import openai
from openai import OpenAI

attempts = [
    (OpenAI(api_key="sk-not-the-lab-key"), "lab-minilm"),
    (OpenAI(), "text-embedding-3-small"),
]
for client, model in attempts:
    try:
        client.embeddings.create(model=model, input="When your refund arrives")
    except openai.APIStatusError as e:
        print(type(e).__name__, e.status_code, e.code)
        print("   ", e.body["message"])
```

```
ana@lab:~/emb$ python refused.py
AuthenticationError 401 invalid_api_key
    Incorrect API key provided.
NotFoundError 404 model_not_found
    The model `text-embedding-3-small` does not exist or you do not have access to it. This lab serves lab-minilm and lab-wordllama.
```

The SDK turns each HTTP status into its own exception class, `AuthenticationError` for 401 and
`NotFoundError` for 404, and keeps the server's JSON in `e.body`. Note the second one: labembed
refuses `text-embedding-3-small` **on purpose**, so that nothing in this course can pass a lab
model off as OpenAI's. Against the real service that name is the one to use, and the lab's names
mean nothing there.
