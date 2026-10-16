---
title: The handler, and the runtime that calls it
version: 1
---

A Lambda function looks, from the outside, like a program that starts when a request arrives and
stops when it is answered. **That picture is wrong in the part that costs money and time.** What
Lambda starts is an **execution environment**: a small isolated machine with your code and a
language runtime in it. The runtime imports your file once, and then calls one function in it, the
handler, once per event, for as long as Lambda keeps that environment alive. Everything in this
lesson, and the cold starts of lesson 17, follows from that split between the import and the call.

## A handler, piece by piece

The resizer is too much for a first function, so this one greets. Make a directory for it,
`mkdir -p ~/aws/greet`, and save this as `~/aws/greet/app.py`; the notes are not copied:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import json\nimport time\n\nLOADED = time.time()\n\n\n", "note": "Everything at module level runs **once per execution environment**, when the runtime imports the file, before the first event. `LOADED` remembers when that was, so each answer can say how long this copy of the function has been alive."}, {"code": "def handler(event, context):\n", "note": "The handler is the name you give Lambda as `app.handler`: the file `app.py` and the function `handler` in it. It is called once per event with two arguments."}, {"code": "    if event.get('fail'):\n        raise ValueError('asked to fail')\n    name = event.get('name', 'world')\n", "note": "`event` is the JSON the caller sent, already parsed into a dictionary. Its shape is whatever the caller decides; lesson 15 shows the shapes S3, SQS and the rest send. An exception raised here is the function's error, and the caller is told so."}, {"code": "    print(json.dumps({'msg': 'greeting', 'name': name}))\n", "note": "Anything printed goes to the function's log, which on AWS is CloudWatch Logs. One JSON object per line is a log a query can filter on."}, {"code": "    return {\n        'greeting': f'hello, {name}',\n        'request_id': context.aws_request_id,\n        'remaining_ms': context.get_remaining_time_in_millis(),\n        'memory_mb': context.memory_limit_in_mb,\n        'warm_for_s': round(time.time() - LOADED, 3),\n    }\n", "note": "`context` is the runtime's side of the call: this request's id, the milliseconds left before the timeout, the memory the function was given. What the handler returns is serialised to JSON and becomes the answer."}]}
```

**The contract is two arguments in and one JSON value out.** Lambda never runs `app.py` as a
script, so there is no `if __name__ == '__main__'` and nothing reads standard input. The name
`app.handler` is the configuration that joins the two: the next section gives it to `aws lambda
create-function`, and the emulator below takes it on its command line.

## Running it for real, on your laptop

moto keeps a record of a function and does not run it here, as the next section shows. To see a
handler actually called, this course uses **the image AWS publishes for building Lambda functions
as containers**, `public.ecr.aws/lambda/python:3.12`. It holds the same Python runtime Lambda uses
and the **Runtime Interface Emulator**, a small server that accepts an invocation over HTTP and
drives the runtime the way Lambda's own service does. It is the first time this course needs
Docker for Lambda, and the steps are the ones the `docker` course taught, in brief:

```sh
docker --version
docker pull public.ecr.aws/lambda/python:3.12
```

The first prints the version of the Docker you installed in that course; if it fails, that course's
installation lesson is the place to go back to. The second downloads about 180 MB, once. The image
was already on the machine these transcripts were recorded on:

```
ana@laptop:~/aws$ docker image ls public.ecr.aws/lambda/python
IMAGE                               ID             DISK USAGE   CONTENT SIZE   EXTRA
public.ecr.aws/lambda/python:3.12   1965397387ba        725MB          183MB        
ana@laptop:~/aws$ docker image inspect public.ecr.aws/lambda/python:3.12 --format '{{.Os}}/{{.Architecture}}'
linux/amd64
```

`linux/amd64` is an x86 machine's copy; on an Arm laptop, Docker pulls the `arm64` one from the
same name. Now start the function, with the directory mounted where Lambda puts your code,
`/var/task`, and the handler named as Lambda would name it. Port 9000 on your machine reaches the
emulator's 8080, and each `curl` is one invocation:

```
ana@laptop:~/aws/greet$ docker run --rm -d --name greet -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
b50acffe515f4c8da1c5b4f4a3bc0418ab31d9f7695378c73cbcd000246ea081
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"name": "ana"}'; echo
{"greeting": "hello, ana", "request_id": "1e3d5af4-31db-4163-985f-addb24aeeae1", "remaining_ms": 299949, "memory_mb": "3008", "warm_for_s": 0.002}
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"greeting": "hello, world", "request_id": "db33bb33-d270-4972-bc2c-4051478fa77b", "remaining_ms": 299999, "memory_mb": "3008", "warm_for_s": 0.014}
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"fail": true}'; echo
{"errorMessage": "asked to fail", "errorType": "ValueError", "requestId": "8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e", "stackTrace": ["  File \"/var/task/app.py\", line 9, in handler\n    raise ValueError('asked to fail')\n"]}
```

Three events, three answers. The first two came back as the dictionary the handler returned, with
a different request id each time; `memory_mb` is a string, because that is how the runtime reports
it. The third raised, and **the caller received the error as data**: a type, a message and the
stack, which is what a synchronous caller on AWS receives too, with a header on the answer saying
the function failed. `warm_for_s` went up between the first two calls, because the module was
imported once and both events were handled by the same import.

## The log, and what in it is the emulator's

```
ana@laptop:~/aws/greet$ docker logs greet 2>&1 | cut -c1-175
16 Oct 2026 16:33:11,638 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)
16 Oct 2026 16:33:13,659 [INFO] (rapid) INIT START(type: on-demand, phase: init)
16 Oct 2026 16:33:13,659 [INFO] (rapid) The extension's directory "/opt/extensions" does not exist, assuming no extensions to be loaded.
16 Oct 2026 16:33:13,659 [INFO] (rapid) Starting runtime without AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN , Expected?: false
START RequestId: 85230ba9-81fa-4d65-b202-ee31c4a097fe Version: $LATEST
16 Oct 2026 16:33:13,710 [INFO] (rapid) INIT RTDONE(status: success)
16 Oct 2026 16:33:13,710 [INFO] (rapid) INIT REPORT(durationMs: 50.490000)
16 Oct 2026 16:33:13,710 [INFO] (rapid) INVOKE START(requestId: 1e3d5af4-31db-4163-985f-addb24aeeae1)
{"msg": "greeting", "name": "ana"}
16 Oct 2026 16:33:13,711 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 1.344000ms)
END RequestId: 1e3d5af4-31db-4163-985f-addb24aeeae1
REPORT RequestId: 1e3d5af4-31db-4163-985f-addb24aeeae1	Init Duration: 0.04 ms	Duration: 52.06 ms	Billed Duration: 53 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
START RequestId: bf409612-c549-46c9-a8d9-f2ce1a73e308 Version: $LATEST
16 Oct 2026 16:33:13,722 [INFO] (rapid) INVOKE START(requestId: db33bb33-d270-4972-bc2c-4051478fa77b)
{"msg": "greeting", "name": "world"}
END RequestId: db33bb33-d270-4972-bc2c-4051478fa77b
REPORT RequestId: db33bb33-d270-4972-bc2c-4051478fa77b	Duration: 1.05 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
16 Oct 2026 16:33:13,723 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 0.922000ms)
START RequestId: 3588d8de-b215-4f4c-926b-5579950e1e11 Version: $LATEST
16 Oct 2026 16:33:13,731 [INFO] (rapid) INVOKE START(requestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e)
LAMBDA_WARNING: Unhandled exception. The most likely cause is an issue in the function code. However, in rare cases, a Lambda runtime update can cause unexpected function beha
16 Oct 2026 16:33:13,736 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 4.871000ms)
END RequestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e
REPORT RequestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e	Duration: 4.98 ms	Billed Duration: 5 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

The lines without `(rapid)` are the ones a function's log on AWS also carries, in CloudWatch Logs:
`START`, whatever the handler printed, `END` and a `REPORT` per invocation. The `(rapid)` lines are
the emulator's own, and they show the split this section began with: one `INIT` phase, taking
50.49 ms on this laptop, then an `INVOKE` per event, with no second `INIT`.

**Several numbers in that log are the emulator's and not Lambda's, and are worth knowing as such.**
`Memory Size` is 3008 MB because the emulator gives every function that much unless told otherwise;
a real function has what its configuration says, 128 MB by default. `Max Memory Used` merely
repeats the size, where Lambda measures it. The first `REPORT` puts the initialisation inside
`Duration` and prints an `Init Duration` of 0.04 ms, where Lambda reports the import in `Init
Duration` and the handler alone in `Duration`. And `remaining_ms` started near 300,000 because the
emulator's timeout is five minutes, where a function created with the defaults has three seconds.
The timings themselves are this laptop's. **What does carry over is the shape**, and one rule:
`Billed Duration` is `Duration` rounded up to the next millisecond, 1.05 ms billed as 2 ms, which is
how Lambda bills.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two execution environments on a time axis. The first runs INIT once, where the runtime starts and module-level code runs, then three INVOKE phases for events 1, 2 and 3, frozen between them, and is shut down at a time Lambda chooses. The second environment starts later, for an event that arrived while the first was busy, and runs its own INIT before its INVOKE.\"><defs><marker id=\"life-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one execution environment</text><rect x=\"20\" y=\"36\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">INIT</text><text x=\"105\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runtime starts, module runs</text><rect x=\"210\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"260\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">event 1</text><rect x=\"350\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"400\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">event 2</text><rect x=\"490\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"540\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">event 3</text><path d=\"M314 62 L346 62\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" fill=\"none\"></path><path d=\"M454 62 L486 62\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" fill=\"none\"></path><text x=\"380\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">frozen between events</text><rect x=\"598\" y=\"36\" width=\"114\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"655\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shut down</text><text x=\"655\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">when Lambda decides</text><text x=\"105\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">LOADED is set here,</text><text x=\"105\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">and only here</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a second one, for an event that arrived while the first was busy</text><rect x=\"350\" y=\"174\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">INIT</text><text x=\"435\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own import, from scratch</text><rect x=\"540\" y=\"174\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"590\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">event 4</text><path d=\"M20 250 L700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><text x=\"690\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "An execution environment imports the code once and then handles events one at a time. A second environment, started for an event that overlapped, imports everything again; that repeated INIT is lesson 17's cold start, and how many environments run at once is lesson 16's concurrency."}
```

Stop the function before going on:

```
ana@laptop:~/aws/greet$ docker stop greet
greet
```
