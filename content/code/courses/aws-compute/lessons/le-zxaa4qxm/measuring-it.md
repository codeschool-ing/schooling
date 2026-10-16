---
title: Measuring it, with an import that costs something
version: 1
---

The bare handler's cold start was the runtime and nothing else. A real function imports
libraries and builds clients, and **the commonest heavy thing at the top of a Python function is
the AWS SDK**: `boto3`, which the Python runtime ships, so a function can import it without
packaging it. Building a client loads the service's API description from disk and assembles the
code that signs requests, and all of it happens before the first call is made.

Two versions of the same function make the difference visible. Both return the class name of an
S3 client, which is enough to prove the client exists; neither talks to S3, so nothing here needs
the network or an account.

The first builds the client at the top of the file, in the init phase. Save it as
`~/aws/eager/app.py`:

```python
# eager/app.py
import boto3

s3 = boto3.client("s3", region_name="sa-east-1")


def handler(event, context):
    return {"client": type(s3).__name__}
```

The second builds it inside the handler, on every call. Save it as `~/aws/lazy/app.py`:

```python
# lazy/app.py
def handler(event, context):
    import boto3
    s3 = boto3.client("s3", region_name="sa-east-1")
    return {"client": type(s3).__name__}
```

## A function to measure with

Three calls to a freshly started emulator are one cold request and two warm ones, and the shell
function below does exactly that for the directory you name, then prints the lines of the log that
carry the timings. Paste it into the terminal; it lasts until the terminal closes.

```schooling-example
{"language": "sh", "file": "cold.sh", "parts": [{"code": "cold() {\n  docker run -d --name \"$1\" -p 9000:8080 ${2:+--cpus \"$2\"} \\\n    -v \"$PWD/$1\":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler > /dev/null\n  sleep 2\n", "note": "A fresh container named after the directory, with that directory as the function's code, so every run starts cold. `${2:+--cpus \"$2\"}` adds a CPU limit only when a second argument is given. The pause gives the emulator time to listen."}, {"code": "  for n in 1 2 3; do\n    curl -s -o /dev/null -w \"call $n: %{time_total} s\\n\" \\\n      -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'\n  done\n", "note": "Three calls, one after the other: the first is cold and the other two are warm. `curl` throws the answer away and prints how long each call took, as the caller saw it."}, {"code": "  docker logs \"$1\" 2>&1 | grep -E 'INIT REPORT|^REPORT'\n  docker rm -f \"$1\" > /dev/null\n}\n", "note": "The emulator's log, filtered to the line that times the init phase and the three `REPORT` lines. Then the container is removed, which frees the name and the port for the next run."}]}
```

`cold` takes the directory as its first argument, and an optional second one that the last part of
this section uses.

## Eager against lazy

```
ana@laptop:~/aws$ cold eager
call 1: 0.312086 s
call 2: 0.001804 s
call 3: 0.011283 s
16 Oct 2026 16:34:40,324 [INFO] (rapid) INIT REPORT(durationMs: 300.635000)
REPORT RequestId: 554deedb-dfef-4058-bc01-3f5c73ce7ff5	Init Duration: 0.06 ms	Duration: 306.68 ms	Billed Duration: 307 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: f62651b8-64eb-42f2-9e55-36bae95c9420	Duration: 0.93 ms	Billed Duration: 1 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 1ccb0edb-b9be-4733-ac64-ae46dba46816	Duration: 3.07 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold lazy
call 1: 0.343093 s
call 2: 0.009389 s
call 3: 0.007566 s
16 Oct 2026 16:34:43,196 [INFO] (rapid) INIT REPORT(durationMs: 67.552000)
REPORT RequestId: 207b5daf-893f-488c-98ca-1d19bcb80f54	Init Duration: 3.61 ms	Duration: 328.33 ms	Billed Duration: 329 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 5a5146b3-4f21-4f05-bfb7-851ce7665dd8	Duration: 8.07 ms	Billed Duration: 9 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 6a305a31-645e-4421-ba97-8c2c1d72392e	Duration: 6.70 ms	Billed Duration: 7 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

Put the numbers side by side, and read the init phase from `INIT REPORT` and each request from
`curl`, as the previous section said:

| | init phase | first call | second call | third call |
|---|---|---|---|---|
| `eager` | 301 ms | 0.312086 s | 0.001804 s | 0.011283 s |
| `lazy` | 68 ms | 0.343093 s | 0.009389 s | 0.007566 s |

Three things are in that table.

**The client is the expensive part, and it is paid once.** `eager` spends 301 ms in its init
phase against 48 ms for the bare handler of the previous section, and the
difference is `import boto3` and one client. Its warm calls are then a matter of milliseconds,
because the client already exists.

**Moving the work into the handler does not remove it.** `lazy` has a short init phase, about the
bare runtime's, and its first call pays almost everything instead: the cold request is about as
slow either way, because the same import happened, only later. And look at the `Duration` of its
warm requests in `REPORT`: 8.07 and 6.70 ms, against 0.93 and
3.07 for `eager`. Python keeps an imported module, so the second `import boto3` is
free, but the client is built again on every call. **Lazy work is repaid on every warm request,
and the warm requests are nearly all of them.**

**The emulator's `Init Duration` says neither.** The first `REPORT` of `eager` gives a fraction of
a millisecond as its `Init Duration` and puts the init phase into `Duration` instead. On AWS the
first would carry the real figure, and the second only the handler's own time.

The rule that follows is the one AWS's documentation states and every measurement here supports:
**do once, outside the handler, whatever every request needs**, so that the cost is paid at init
and reused by each warm request in that environment. A client, a connection pool, a configuration
read from a file. Lazy initialisation inside the handler has one legitimate use: a dependency only
some requests need, built on first use and kept in a global for the next one.

## CPU is what init is made of

Building a client is computation, and computation runs at the speed of the CPU the environment
gets. **On Lambda that CPU is proportional to the memory you configure**: AWS documents one full
vCPU at 1,769 MB, and a 128 MB function gets a small fraction of one. The emulator ignores the
memory setting, but Docker can limit the CPU a container gets, which is the closest a laptop
comes. This is an analogue, run with Docker's `--cpus`, and not Lambda's own allocation:

```
ana@laptop:~/aws$ cold eager 1
call 1: 0.346706 s
call 2: 0.002653 s
call 3: 0.004523 s
16 Oct 2026 16:34:46,967 [INFO] (rapid) INIT REPORT(durationMs: 342.851000)
REPORT RequestId: 603cba49-8cd3-46fa-81ad-55c5dcae865b	Init Duration: 0.07 ms	Duration: 345.24 ms	Billed Duration: 346 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 74fcd1d6-fd1b-4a34-889b-dcd295e85762	Duration: 1.78 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 06e66ea3-5556-4a73-a523-2c336f372471	Duration: 3.76 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold eager 0.5
call 1: 0.643410 s
call 2: 0.006040 s
call 3: 0.016945 s
16 Oct 2026 16:34:50,272 [INFO] (rapid) INIT REPORT(durationMs: 610.819000)
REPORT RequestId: 80221845-6ca6-4bbd-ba6e-91e61977ff92	Init Duration: 0.06 ms	Duration: 618.45 ms	Billed Duration: 619 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 63e70195-480d-4d0d-8537-6525b06cacdf	Duration: 5.16 ms	Billed Duration: 6 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 153eaefb-992b-4580-afe7-bd2c0c8763f0	Duration: 3.54 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold eager 0.25
call 1: 1.362279 s
call 2: 0.033606 s
call 3: 0.008431 s
16 Oct 2026 16:34:54,569 [INFO] (rapid) INIT REPORT(durationMs: 1336.616000)
REPORT RequestId: d40b5567-fd82-46de-b8f8-c258fa3a5ec2	Init Duration: 0.10 ms	Duration: 1343.82 ms	Billed Duration: 1344 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 1b5d41cc-fd79-4415-8db1-08ca167a9bb4	Duration: 6.26 ms	Billed Duration: 7 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 3914e56c-f183-4093-8a47-453e46229d31	Duration: 1.00 ms	Billed Duration: 1 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

The same `eager` module, the same machine. With a whole CPU its init phase takes
343 ms, with half of one 611 ms, and with a quarter 1337 ms. Timings on a shared laptop move by
tens of milliseconds from one run to the next.
Read the trend and not the last digit: **an init
phase that is mostly computation gets slower in proportion as the CPU shrinks.** On Lambda, the
memory setting is therefore also a cold-start setting, and the next section weighs what raising it
costs.
