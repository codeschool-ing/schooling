---
title: HTTP functions, and the framework under them
version: 1
---

The picture most people arrive with is that a function is a tiny server you upload: you write
something that listens on a port, and the cloud keeps it running. **On Google Cloud a function is
the opposite: a handler you write, and a web server Google wraps around it.** You write one Python
function that takes a request and returns a response. The server, the port and the container are
the platform's.

## What wraps it

The wrapper is the **Functions Framework**, an open-source library Google publishes for each
language it supports. When you deploy a Python function, Google's build installs the framework,
points it at your function by name, and runs the result as a container on Cloud Run; lesson 8
opens that container. The framework you installed in lesson 1 is the same library, so **a function
that answers on your laptop under the framework answers the same way after deployment**. What
differs is everything around it: who may call it, how many copies run, and what it costs.

That is also why this course can practise functions properly when it cannot practise Compute
Engine at all. Nothing here imitates Google. The code path from the request to your function is
Google's own.

## A function for the shop

The shop's checkout needs a quote before it takes payment: a list of products and quantities in,
a total in cents out. **Create `~/gcp/quote` and save this as `main.py` in it:**

```schooling-example
{"language": "python", "file": "main.py", "parts": [{"code": "import functions_framework\n\nPRICES = {'mug': 3500, 'tee': 7900, 'poster': 2500}  # in cents\n\n\n", "note": "The Functions Framework, and the shop's three products with their prices in cents. Money is an integer here for the same reason it is anywhere: a float cannot hold 0.10 exactly."}, {"code": "@functions_framework.http\ndef quote(request):\n    if request.method != 'POST':\n        return {'error': 'POST a list of items'}, 405\n", "note": "The decorator registers `quote` as an HTTP function, and the framework hands it a Flask request. A dictionary returned with a number becomes a JSON body with that status."}, {"code": "    items = (request.get_json(silent=True) or {}).get('items', [])\n    unknown = [i['sku'] for i in items if i['sku'] not in PRICES]\n    if unknown:\n        return {'error': 'unknown sku: ' + ', '.join(unknown)}, 400\n", "note": "The body is read without trusting it: `silent=True` gives `None` for a body that is not JSON instead of an exception, and an unknown product is refused by name."}, {"code": "    total = sum(PRICES[i['sku']] * i['qty'] for i in items)\n    return {'items': len(items), 'total_cents': total}\n", "note": "The arithmetic, and the answer. Nothing is kept between calls: the next request may land on another instance, and the function must not care."}]}
```

Then open a **second terminal**, type the lines from lesson 1 section 02 that every terminal
needs, and start the framework there. `--target` names the function inside `main.py`; the port is
8080 unless you say otherwise:

```
ana@laptop:~/gcp/quote$ functions-framework --target quote
```

It prints nothing and waits on port 8080, which is the framework working, not failing. Leave it
running, go back to the first terminal, and call it:

```
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{"items": [{"sku": "mug", "qty": 2}, {"sku": "tee", "qty": 1}]}'
{"items":2,"total_cents":14900}
200
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' localhost:8080
{"error":"POST a list of items"}
405
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{"items": [{"sku": "hat", "qty": 1}]}'
{"error":"unknown sku: hat"}
400
```

Three answers, three statuses. **The function decided each of them**: 200 with the total for a
correct order, 405 for a `GET`, which it refuses by name, and 400 for a product it does not sell.
The framework only turned the returned dictionaries into JSON and the numbers into statuses.

## Statelessness is not a style

Notice what the function does not do. It keeps no counter, writes no file and remembers nothing
from one call to the next. That is not tidiness. **Two calls a second apart may reach two
different instances**, and an instance with no requests is shut down without warning; lesson 11
measures what that costs. Anything that must survive a call goes to something built to keep it: a
database, a bucket, a queue.

The one exception is work that is expensive to repeat and safe to share, such as a client
connection or a table read at start-up. Put it at module level, outside the function, and every
call that lands on the same instance reuses it. `PRICES` above is the smallest example of that.

Stop the framework with Ctrl+C in its terminal when you are done.
