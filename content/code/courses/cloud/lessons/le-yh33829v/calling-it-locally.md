---
title: Calling it on a laptop
version: 1
---

A handler is an ordinary Python function, so it can be called like one. **This is the cheapest test
there is, and it shows exactly one thing: the contract between the platform and your code.** Lambda
is not involved in anything on this page. There is no account, no network and no execution
environment, only a Python process on a laptop importing `handler.py` and passing it a dictionary
written by hand.

`call_local.py` writes an event with a few fields of what an HTTP API gateway sends, enough for
this handler. The
second call passes an event with no query string at all, the case `or {}` exists for:

```python
from handler import handler

event = {
    "rawPath": "/hello",
    "queryStringParameters": {"name": "ana"},
    "requestContext": {"http": {"method": "GET"}},
}
print(handler(event, None))
print(handler({"rawPath": "/hello"}, None))
```

`None` stands in for the context, which this handler never reads. Run from the directory holding
both files:

```
ana@laptop:~/cloud$ python3 call_local.py
{'statusCode': 200, 'headers': {'Content-Type': 'application/json'}, 'body': '{"message": "hello, ana", "served_by_this_copy": 1}'}
{'statusCode': 200, 'headers': {'Content-Type': 'application/json'}, 'body': '{"message": "hello, world", "served_by_this_copy": 2}'}
```

**The return value is the whole response, before any gateway has touched it.** `statusCode` becomes
the status line, `headers` the headers, and `body` is a string holding JSON. Python prints the dict
with single quotes; the body inside it has double quotes, because `json.dumps` wrote it.

The second call answered `world`, which is the default doing its job. The counter says `2`. **Both
calls ran in the same Python process, so they shared the module and its counter.** On the platform
there is no such promise: the second request could have gone to a different execution environment
and been answered with `1`. The laptop shows the most optimistic case, one warm copy serving
everything, and nothing on it can show the other.

What this test cannot tell you:

- whether the real event looks like the one you wrote. A gateway sends many more fields, and the
  exact shape depends on the kind of gateway and its version; the fields your handler reads are the
  ones to check against the provider's documentation;
- anything about permissions, the timeout, memory, cold starts or concurrency, which only exist on
  the platform;
- whether the gateway is set up to send the request to this handler at all.

What it does tell you is whether the logic is right, and it runs in any test framework, because to
`pytest` a handler is a function like any other. Tools exist that get closer to the real thing: AWS's
SAM command line, for one, runs a handler inside a container built to imitate Lambda's environment.
It is still an imitation, and this course does not use it.
