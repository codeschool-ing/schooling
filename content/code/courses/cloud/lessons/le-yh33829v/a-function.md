---
title: "A function: an event in, a result out"
version: 1
---

A function on a serverless platform is smaller than an application. **It is one entry point that
receives an event, does its work and returns a result**, and the platform owns everything around
it: the process, the web server if there is one, the retry if it fails. On Lambda that entry point
is called the handler, and in Python it is an ordinary function with two parameters.

This one answers an HTTP request that arrives through an API gateway, in the shape AWS documents
for that integration. It reads `name` from the query string and answers with a greeting in JSON:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "import json\n\nGREETING = \"hello\"\nserved = 0\n\n", "note": "**Module-level code runs once**, when a new execution environment loads the file, and not on every call. Anything expensive to create belongs here: a database client, a configuration read. `served` is a counter kept here on purpose, to show what state between calls looks like."}, {"code": "def handler(event, context):\n    global served\n    served += 1", "note": "The entry point. The platform is told its name as `handler.handler`: the file, then the function. `event` is the request as a Python dict, and `context` carries facts about this call, such as how much time is left; this handler does not use it."}, {"code": "    params = event.get(\"queryStringParameters\") or {}\n    name = params.get(\"name\", \"world\")", "note": "With an API gateway, the query string arrives already parsed under `queryStringParameters`. When the request has none, the key is missing or `null` depending on the kind of gateway, and `or {}` covers both."}, {"code": "    body = {\"message\": f\"{GREETING}, {name}\", \"served_by_this_copy\": served}", "note": "What the answer says. `served_by_this_copy` reports the counter, which only ever counts the calls this one copy of the function has served."}, {"code": "    return {\n        \"statusCode\": 200,\n        \"headers\": {\"Content-Type\": \"application/json\"},\n        \"body\": json.dumps(body),\n    }", "note": "The shape the gateway expects back: a status code, headers, and a body that is a **string**, which is why the dict goes through `json.dumps`. The gateway turns this into the HTTP response the browser receives."}]}
```

Three properties of the contract matter more than the code.

**The event is data, and its shape belongs to whoever sent it.** An HTTP request through a gateway
arrives with a path, headers and a query string. A batch of messages from a queue arrives as a list
of records, and a file landing in a bucket arrives as a notice naming the bucket and the key. The
handler is the same kind of function in every case, and it has to know which shape it will be given.
Two sections on, the common sources sit side by side.

**Nothing is promised to survive between calls.** The counter `served` is there to make this
visible. Inside one execution environment it keeps its value from one call to the next, because the
Python process stays alive while the environment is kept. But the platform starts as many
environments as the traffic needs and discards them when it chooses, so two requests from the same
person can land in two different copies, each with its own counter. **Anything that must survive — a
session, a basket or a count — goes into a database or a store outside the function.**

**Every call has a timeout.** The function runs until it returns or until the time you configured
runs out, and then the platform stops it. **On Lambda the setting defaults to 3 seconds and can be
raised as far as 15 minutes, never beyond.** A handler still waiting on a slow database when the
time runs out does not get to handle the error: it is cut off, and the caller sees a failure.

To deploy it, you would tell the platform four things: the runtime (a Python version), the handler
as `handler.handler` (the file, then the function), the memory and the timeout. This course does
none of that, because it has no account; `aws-foundations` does it with the console and the command
line.
