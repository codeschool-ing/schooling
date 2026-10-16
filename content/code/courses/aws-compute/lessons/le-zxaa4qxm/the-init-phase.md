---
title: What happens before the handler runs
version: 1
---

A cold start is usually described as "Lambda waking up", as if the service itself were slow to
answer. **A cold start is the work of building a new execution environment before the request can
be handed to your handler**, and most of that work is not Lambda's at all: some of it is the
runtime starting, and some of it is your own code, run once at the top of the file. It happens whenever a request needs an environment and none is free.
Lesson 16 showed that this is a question of concurrency: the first request of the day, a request that arrives while the others are busy, a
request after Lambda has retired an idle environment.

## The phases, in order

AWS documents the life of an environment in three phases, and a cold request goes through the
first two in sequence.

1. Init. Lambda finds a host with room, creates the isolated micro-VM, and fetches your
   code: the zip from Lambda's own storage, or the layers of a container image. Then it starts
   the runtime, which for Python is the interpreter and AWS's small bootstrap program, and the
   runtime imports your module. **Everything at the top level of your file runs here**: the
   `import` lines, a client built outside the handler, a configuration file read once.
2. Invoke. The runtime calls your handler with the event, and the handler's return value
   goes back to the caller. This is the phase every request has.
3. Shutdown. When Lambda decides to retire an environment, it stops the runtime. Your handler
   is not called for it, and whatever the environment held in memory is gone.

A warm request is the second phase alone. **The difference between a cold request and a warm one
is the whole of the first phase**, and the part of it you control is the part your module does when
it is imported.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Two rows on a time axis. A cold request goes through placing the environment and fetching the code, which happens on AWS only, then starting the runtime, then running your module, highlighted, and only then the handler. The first three are bracketed as the init phase and the handler as invoke. A warm request is the handler alone.\"><defs><marker id=\"ph-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 28 L704 28\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ph-ah)\"></path><text x=\"150\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text><text x=\"16\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">cold request</text><rect x=\"150\" y=\"60\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"224\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">place, fetch code</text><text x=\"224\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">on AWS only</text><rect x=\"300\" y=\"60\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"354\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">start runtime</text><rect x=\"410\" y=\"60\" width=\"178\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"499\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">run your module</text><text x=\"499\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">imports, clients</text><rect x=\"590\" y=\"60\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">handler</text><path d=\"M150 110 L150 118 L588 118 L588 110\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"369\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">init phase</text><path d=\"M590 110 L590 118 L690 118 L690 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">invoke</text><text x=\"16\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">warm request</text><rect x=\"150\" y=\"160\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">handler</text><text x=\"266\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same environment, already initialised</text><text x=\"704\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">a shape, not a measurement</text></svg>", "caption": "A cold request is the init phase and then the handler; a warm one is the handler alone. The highlighted part is your own module running at import, the one piece of the init phase that is yours to shorten."}
```

## The phases in a log

The emulator of lessons 14 and 16 goes through the same phases, so its log names them. If you
have not got it from those lessons, the image is `public.ecr.aws/lambda/python:3.12`, pulled with
`docker pull` once Docker is installed as the `docker` course installs it.

The smallest possible handler, in `~/aws/bare/app.py`, so that nothing of yours runs in the init
phase:

```python
# bare/app.py
def handler(event, context):
    return {"ok": True}
```

Start it, call it twice, and read the log. The commands are the ones lesson 16 used:

```
ana@laptop:~/aws$ docker run -d --name bare -p 9000:8080 -v "$PWD/bare":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
3776324e020191a0baf97ff4b45708b7ff49ec860f072ed1ecb2903e7d20f5cd
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"ok": true}
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"ok": true}
ana@laptop:~/aws$ docker logs bare
16 Oct 2026 16:34:35,291 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)
16 Oct 2026 16:34:37,340 [INFO] (rapid) INIT START(type: on-demand, phase: init)
16 Oct 2026 16:34:37,340 [INFO] (rapid) The extension's directory "/opt/extensions" does not exist, assuming no extensions to be loaded.
16 Oct 2026 16:34:37,340 [INFO] (rapid) Starting runtime without AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN , Expected?: false
START RequestId: 8cc8b8b1-f1ed-4621-a439-80b9d2a4791f Version: $LATEST
16 Oct 2026 16:34:37,387 [INFO] (rapid) INIT RTDONE(status: success)
16 Oct 2026 16:34:37,387 [INFO] (rapid) INIT REPORT(durationMs: 47.608000)
16 Oct 2026 16:34:37,387 [INFO] (rapid) INVOKE START(requestId: 66d75f14-983c-46a6-9202-18cd2d3a258f)
16 Oct 2026 16:34:37,388 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 1.094000ms)
END RequestId: 66d75f14-983c-46a6-9202-18cd2d3a258f
REPORT RequestId: 66d75f14-983c-46a6-9202-18cd2d3a258f	Init Duration: 0.14 ms	Duration: 48.74 ms	Billed Duration: 49 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
START RequestId: e619a9a3-8c26-43de-9dc7-e3314316d130 Version: $LATEST
16 Oct 2026 16:34:37,399 [INFO] (rapid) INVOKE START(requestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a)
16 Oct 2026 16:34:37,400 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 0.759000ms)
END RequestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a
REPORT RequestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a	Duration: 1.42 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

Read the log from the top, because the order is the lesson:

- `exec '/var/runtime/bootstrap'` is the container starting. On AWS the environment does not exist
  yet at this point; the emulator starts its process early and then waits for the first request.
- `INIT START`, `INIT RTDONE` and `INIT REPORT` are the init phase, run when the first request
  arrived. **`INIT REPORT` gives its length**, here 48 ms: the Python runtime starting
  and importing a module that does nothing.
- `START`, `END` and `REPORT` are the invoke phase, once per request. The first `REPORT` is the cold
  request and the second is warm, and the second has no `Init Duration` at all.

**One field of that log is wrong, and it is the one people read.** On AWS, the `REPORT` line of a
cold request carries `Init Duration`, and that number is the init phase. The emulator prints a few
milliseconds at most there, whatever the module does, and counts the real init
inside the first request's `Duration` instead. The next section shows the gap on a module that
does real work. **In this course, the init phase is read from `INIT REPORT`**, which the emulator
measures; on AWS, read it from `Init Duration` in `REPORT`, which is what CloudWatch queries of
`aws-operations` lessons 8 to 10 are written against.

## What the laptop cannot tell you

Every millisecond in these logs is your computer's, not AWS's. The emulator runs on a laptop CPU, alongside whatever else the laptop is doing.
It mounts the code from your disk instead of downloading it,
and it ignores the memory setting: every `REPORT` here says `Memory Size: 3008 MB` whatever the
function was given. **What the emulator measures faithfully is the shape**: which work happens in
which phase, and how much of the cold start is your own module. Those proportions carry over to
AWS; the absolute numbers do not, and AWS adds a part the laptop never pays, the placement of the
environment and the download of the code.

Two more facts from AWS's documentation, neither of which a laptop can show. The init phase has a
limit of ten seconds; a module that takes longer is stopped and its init is retried in the
invoke phase, under the function's own timeout. And since August 2025 the init phase of an
on-demand function is billed like the handler's duration, so a slow import is now a small cost on
every cold start as well as a delay.
