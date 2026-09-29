---
title: When the device says "too fast"
version: 1
---

A device's API runs on the device's processor, the same one that runs routing. **Most APIs
therefore limit how fast one client may ask**, and the lab's routers allow 30 requests in any 10
seconds per token. A script that loops over a busy device meets that limit sooner or later.

What happens then is `429 Too Many Requests`, with a `Retry-After` header giving the number of
seconds to wait. `Device.request` handles it: it sleeps for that long and sends the same request
again, three times at most. Forty requests in a tight loop:

```schooling-example
{
  "language": "python",
  "file": "burst.py",
  "parts": [
    {
      "code": "from devapi import Device\n\ncore1 = Device(\"core1\")"
    },
    {
      "code": "for i in range(40):\n    core1.request(\"GET\", \"/system\")\nprint(\"40 requests answered\")",
      "note": "**Forty requests as fast as Python can send them.** The server allows 30 in any 10 seconds, so some of these are refused and retried."
    }
  ]
}
```

```
ana@ctl:~$ time python burst.py
  429 on /system: waiting 8 s
  429 on /system: waiting 1 s
40 requests answered

real	0m11.831s
user	0m0.141s
sys	0m0.012s
```

The server refused somewhere past the thirtieth request, the client waited as long as it was
told, and all forty were answered. The whole run took under twelve seconds, most of it waiting.

**Waiting is the right answer to a 429 and the wrong answer to almost everything else.** A 401
will not become a 200 by being sent again, and a script that retries it forever is a script that
hides the fact that its password was changed. A 5xx may be worth one or two retries with a
growing pause, which is called **exponential backoff**, and then a clear failure.

Three habits keep a script from meeting the limit at all:

- **Reuse one session.** `requests.Session` keeps the TCP and TLS connection open between
  requests, and logging in once instead of per request saves the login.
- **Ask for what you need.** One request for a page of 50 is cheaper for the device than 50
  requests for one item each.
- **Spread the work.** Fifty scripts that start at the same minute are fifty clients arriving
  together; a random delay of a few seconds at the start smooths them out.
