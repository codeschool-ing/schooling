---
title: Concurrency is requests in flight, not requests per second
version: 1
---

The number people quote about traffic is requests per second, and it is natural to assume that
Lambda's limits are written in it. They are not. **Lambda's concurrency is the number of requests
being worked on at the same instant**, and each of them occupies one execution environment for as
long as it runs. A function that receives a hundred requests a second can need ten environments or
two hundred, and which of the two depends on something the traffic figure does not mention: how
long each request takes.

## One environment, one request

An execution environment is the small, isolated machine Lambda starts for your function: the
runtime, your code loaded into it, and the memory you configured. Lesson 14 ran one on your own
computer. **An environment handles one request at a time**, which is the first thing that
surprises somebody arriving from a web server, where one process serves hundreds of connections
with threads or an event loop. When a request arrives and every environment of the function is
busy, Lambda does not queue it behind them; it starts another environment. Concurrency is the
count of those environments that are busy right now.

That makes the arithmetic short. It is called Little's law, and it holds for any system in a steady
state, where work arrives, is worked on and leaves:

> requests in flight = requests per second × seconds per request

A hundred requests a second that each take 0.1 s keep 100 × 0.1 = 10 environments busy. The same
hundred requests at 2 s each keep 200 busy. **Nothing about the traffic changed between those two
numbers**: the function got slower, perhaps because the database it calls started taking two
seconds to answer, and its concurrency went up twentyfold. This is why a slow dependency is the
commonest way a Lambda function reaches its limit on an ordinary day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A timeline from 0 to 2 seconds with three lanes, one per execution environment. Eight requests arrive 0.2 seconds apart and each lasts 0.6 seconds; request 1 goes to environment 1, 2 to environment 2, 3 to environment 3, and request 4 reuses environment 1. A vertical mark at 1.1 seconds passes through requests 4, 5 and 6, which are drawn highlighted: three running at once.\"><defs><marker id=\"cc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a request every 0.2 s, each lasting 0.6 s</text><text x=\"16\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">environment 1</text><path d=\"M130 112 L690 112\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"16\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">environment 2</text><path d=\"M130 160 L690 160\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"16\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">environment 3</text><path d=\"M130 208 L690 208\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"130\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"211\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1</text><rect x=\"186\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"267\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">2</text><rect x=\"242\" y=\"166\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"323\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">3</text><rect x=\"298\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"379\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">4</text><rect x=\"354\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"435\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">5</text><rect x=\"410\" y=\"166\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"491\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">6</text><rect x=\"466\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"547\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">7</text><rect x=\"522\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">8</text><path d=\"M130 222 L704 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cc-ah)\"></path><path d=\"M130 218 L130 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M270 218 L270 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.5 s</text><path d=\"M410 218 L410 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 s</text><path d=\"M550 218 L550 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"550\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.5 s</text><path d=\"M690 218 L690 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M438 54 L438 68\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 108 L438 116\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 156 L438 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 204 L438 220\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"438\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">at any instant: 3 running</text></svg>", "caption": "Little's law as a count. Five requests a second at 0.6 s each is 5 × 0.6 = 3 requests in flight, and three environments are enough because each is free again by the time the next request needs it. A slower function, at the same traffic, would need more lanes."}
```

The figure is the law drawn as a count. Requests arrive every 0.2 s and each lasts 0.6 s, which is
5 × 0.6 = 3, and a vertical line drawn at any instant crosses three requests. The environments are
reused: the one that finished request 1 takes request 4. Lambda never needed a fourth, because
none of the lanes was ever asked for two requests at once.

## Seeing it on your own computer

The Runtime Interface Emulator that lesson 14 used is a single execution environment, which makes
it a good instrument for the rule above. If you still have it, skip to the handler. If not, two
steps bring it back: Docker installed as the `docker` course installs it, and AWS's Lambda base
image for Python, which carries the emulator inside it.

```sh
docker pull public.ecr.aws/lambda/python:3.12
```

`docker image ls` shows it, at 725 MB once unpacked:

```
ana@laptop:~/aws$ docker image ls public.ecr.aws/lambda/python
IMAGE                               ID             DISK USAGE   CONTENT SIZE   EXTRA
public.ecr.aws/lambda/python:3.12   1965397387ba        725MB          183MB        
```

The handler sleeps for two seconds, which stands in for a slow database call. Make a directory
`~/aws/slow` and save this in it as `app.py`:

```python
# slow/app.py
import time


def handler(event, context):
    time.sleep(2)
    return {"slept": 2}
```

Then start the emulator with that directory as the function's code, and call it twice, one call
after the other. `-w` makes `curl` print how long each call took:

```
ana@laptop:~/aws$ cd slow
ana@laptop:~/aws/slow$ docker run -d --name slow -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
1412a565fbe9e2044deb5102dc855a77ce8c0e3cd04fb6623530f7fe03b803c1
ana@laptop:~/aws/slow$ curl -s -w ' %{time_total} s\n' -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'
{"slept": 2} 2.133237 s
ana@laptop:~/aws/slow$ curl -s -w ' %{time_total} s\n' -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'
{"slept": 2} 2.044136 s
```

Each call took two seconds and a little, as it should. Now the two calls at once. The `&` sends
each `curl` into the background so that both leave together.
`wait` holds the prompt until
they are done:

```
ana@laptop:~/aws/slow$ for n in 1 2; do curl -s -o /dev/null -w "call $n: HTTP %{http_code} after %{time_total} s\n" -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}' & done; wait
call 1: HTTP 000 after 0.010700 s
call 2: HTTP 000 after 0.019307 s
ana@laptop:~/aws/slow$ docker logs slow 2>&1 | grep -E "REPORT|Reserve|panic"
16 Oct 2026 16:25:50,035 [INFO] (rapid) INIT REPORT(durationMs: 75.911000)
REPORT RequestId: e59da5f6-3bba-4147-b4e5-9f4d1b67836f	Init Duration: 0.14 ms	Duration: 2122.07 ms	Billed Duration: 2123 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 5d29e751-c474-4305-8bc9-d07d23a9faa7	Duration: 2032.36 ms	Billed Duration: 2033 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
16 Oct 2026 16:25:54,162 [INFO] (rapid) ReserveFailed: AlreadyReserved
panic: runtime error: invalid memory address or nil pointer dereference
```

**Both calls failed, within two hundredths of a second.** `HTTP 000` is `curl` saying that no
answer came back at all. The two `REPORT` lines in the log are the earlier calls, made one after
the other at two seconds each; the line starting `INIT REPORT` belongs to lesson 17. Then the log
says what went wrong, in its own words: `ReserveFailed: AlreadyReserved`. One of the simultaneous
requests reserved the only environment there was, the other asked for it while it was taken, and
the emulator has no second environment to start. What happens next is a defect of the emulator
and not a behaviour of Lambda: it stops with a Go `panic`, takes the first request down with it,
and the next call would find nobody listening.

On AWS the same two calls succeed, and each takes two seconds, because Lambda answers the second
request with a second environment. Concurrency at that moment is 2. The emulator cannot show that
part, because it is one environment by design, and moto cannot either, because it runs no code at
all. What both of them leave you with is the shape of the rule: **one request per environment, and
the count of environments is the number every Lambda limit is written in.** The rest of this
lesson is those limits.

Remove what is left of the container before going on, so the port is free:

```sh
docker rm -f slow
```
