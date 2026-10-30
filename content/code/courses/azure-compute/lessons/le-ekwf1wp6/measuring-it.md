---
title: Measuring it on the laptop, from docker run to the first 200
version: 1
---

Nothing on a laptop reproduces Azure's half of a cold start: finding an instance, handing it the
package, a placeholder becoming your app. What does run here is the other half, the same host and
the same worker in Microsoft's image, started from nothing. **So this section measures the
laptop's cold start of lesson 15's app, and every number in it is the laptop's**: a machine with
four processors shared with other work, where a run differs from the one before it by a second.
Read the shape and the ratios, never the milliseconds, and never as Azure's figures.

## The app, and something to time it with

This starts from lesson 15's files in `~/azure/shopfn`, the first version of `function_app.py` with
`take_order` alone, and `storage.sh`. If lesson 15's containers are still running, remove its app with
`docker rm -f shopfn`, keep `azurite` and the network, and skip the middle two commands below:

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
67226d4ff1b3613350e09271538bb508510007bba7a8ad5e9cbf8d59c7b66d13
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
c3a748caa58f377b115d37be2c76ca040704d9e865ed3865ef021dfcdeb54f62
ana@laptop:~/azure$ docker build -q -t shopfn:1 shopfn
sha256:911fba7bb4dbff87c5c954c4f852eac7f90676cd232c0c65d997e512c8df909a
```

A cold start here is a `docker run` of an image nobody has started yet, and the end of it is the
first order answered with `200`. The shell function below times exactly that, from just before
`docker run` to the answer. Paste it into the terminal; it lasts until the terminal closes.

```schooling-example
{"language": "sh", "file": "first200.sh", "parts": [{"code": "first200() {\n  docker rm -f cold > /dev/null 2>&1\n  local start=$(date +%s%N) code= seen= tries=0\n  docker run -d --name cold --network functions -p 7071:80 ${2:+--cpus \"$2\"} \\\n    -e AzureWebJobsStorage=\"$FN_STORAGE\" \"$1\" > /dev/null\n", "note": "Removes the container of the last run, so every run starts from no instance at all, and notes the time in nanoseconds. Then it starts the image named by the first argument on lesson 15's network, with its port 80 published as 7071 so it cannot collide with lesson 15's app on 8080. `${2:+--cpus \"$2\"}` adds a processor limit only when a second argument is given."}, {"code": "  until [ \"$code\" = 200 ]; do\n    code=$(curl -s -o /dev/null -w '%{http_code}' -XPOST localhost:7071/api/orders \\\n      -d '{\"order\": \"A-1001\", \"sku\": \"mug\", \"qty\": 2}')\n    seen=\"$seen $code\"\n    tries=$((tries + 1))\n    [ $tries -lt 600 ] || { echo \"$1: no answer after $tries tries\"; return 1; }\n    [ \"$code\" = 200 ] || sleep 0.1\n  done\n", "note": "Asks for an order every tenth of a second until one is answered with 200, and keeps every status code it got. `curl` prints `000` when nothing answered at all. After 600 tries, about a minute, it gives up rather than spin for ever on an app that will never start."}, {"code": "  echo \"$1: first 200 after $(( ($(date +%s%N) - start) / 1000000 )) ms\"\n  echo $seen | tr ' ' '\\n' | uniq -c\n  curl -s -o /dev/null -w 'next request: %{time_total} s\\n' -XPOST localhost:7071/api/orders \\\n    -d '{\"order\": \"A-1002\", \"sku\": \"mug\", \"qty\": 1}'\n}\n", "note": "Prints how long the first 200 took, from before `docker run` to the answer, and the codes counted in runs. Then one more order, timed by `curl`: the same instance, now warm. The container is left running, so its log can be read."}]}
```

## Three cold starts

```
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 5823 ms
     42 000
      1 200
next request: 0.020162 s
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 5662 ms
     41 000
      1 200
next request: 0.027548 s
ana@laptop:~/azure$ first200 shopfn:1
shopfn:1: first 200 after 6796 ms
     46 000
      1 200
next request: 0.027155 s
```

**Between five and seven seconds to the first answer, and two or three hundredths of a second for
the next.** The first run took 5823 ms, the second 5662, the third 6796; the warm order after each
took between 0.020162 and 0.027548 s. Forty-odd tries came back `000`, which is `curl` saying that
nothing answered at all: the container was running, and nothing listened on its port until the host
was ready. In Azure a request is not refused like this: the documentation describes it as waiting, through
"the added latency of scaling from zero to one". Here nothing in front of the container waits, so
the function asks again every tenth of a second.

## Where the seconds go

The container of the last run is still there. `docker logs -t` puts the time on every line, and a
few of the host's lines mark the steps of the previous section:

```
ana@laptop:~/azure$ docker inspect -f '{{.State.StartedAt}}' cold
2026-10-30T19:24:37.662452365Z
ana@laptop:~/azure$ docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125
2026-10-30T19:24:37.908453393Z WEBSITES_INCLUDE_CLOUD_CERTS is not set to true.
2026-10-30T19:24:42.998519231Z       Initializing Host. OperationId: 'fc679771-b5fd-4f28-bb97-4c61e79798bc'.
2026-10-30T19:24:43.091792156Z       Loading functions metadata
2026-10-30T19:24:43.147283144Z       1 functions loaded
2026-10-30T19:24:43.256121276Z       Host started (165ms)
2026-10-30T19:24:44.143060434Z       Executed 'Functions.take_order' (Succeeded, Id=8cb3b0ee-8976-469d-bb47-d68a416adb3d, Dur
2026-10-30T19:24:44.324549985Z       Executed 'Functions.take_order' (Succeeded, Id=cb47b4af-b563-449f-b8b8-3362fcc2b57f, Dur
```

Read the times against each other, not against the clock:

| from | to | on this run |
|---|---|---|
| the container starts | the start script's first line | 0.25 s |
| the start script | `Initializing Host` | 5.09 s |
| `Initializing Host` | `Host started` | 0.26 s |
| `Host started` | the first order executed | 0.89 s |

The start script's line, about `CLOUD_CERTS`, is the image's own and harmless. **Then five seconds
pass with nothing in the log**: the .NET host starting, loading its extensions, and the Python worker
starting beside it and importing `function_app.py`. Only then does the host say it is initialising,
and from there to a running host takes a quarter of a second. Loading the function, `1 functions
loaded`, is a few hundredths of it. From `Host started` to the first order executed is most of a
second more, which covers the port opening, the function's next try and the first call through the
new worker; the log does not separate them. The second `Executed` line, the warm order, comes 0.18 s
after the first, and most of that is the shell printing the counts and starting `curl` again.

## An import that costs something

The previous section said that the import of `function_app.py` is paid by every cold start. To see
it above the run-to-run spread, make a copy of the app whose import takes eight seconds. A sleep at
the top of the file stands in for a slow library:

```
ana@laptop:~/azure$ cp -r shopfn slow
ana@laptop:~/azure$ sed -i 's/^import logging$/&\nimport time\ntime.sleep(8)/' slow/function_app.py
ana@laptop:~/azure$ head -6 slow/function_app.py
# function_app.py
import json
import logging
import time
time.sleep(8)

ana@laptop:~/azure$ docker build -q -t shopfn:slow slow
sha256:a3cbae2b3afa1a63a07b561eb0e2df9e855c11774223bede7e1a53b912349302
```

`time.sleep(8)` at module level runs once, when the worker imports the file, exactly where a heavy
`import` or a client built at the top would run. Then three cold starts of it, and its log:

```
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 16508 ms
    114 000
      1 200
next request: 0.017081 s
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 13827 ms
    109 000
      1 200
next request: 0.043927 s
ana@laptop:~/azure$ first200 shopfn:slow
shopfn:slow: first 200 after 13463 ms
    111 000
      1 200
next request: 0.040339 s
ana@laptop:~/azure$ docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125
2026-10-30T19:25:18.307011409Z WEBSITES_INCLUDE_CLOUD_CERTS is not set to true.
2026-10-30T19:25:30.739022227Z       Initializing Host. OperationId: '872582c5-1243-4b06-814b-574cf3f03a57'.
2026-10-30T19:25:30.802460788Z       Loading functions metadata
2026-10-30T19:25:30.844476836Z       1 functions loaded
2026-10-30T19:25:30.925340531Z       Host started (125ms)
2026-10-30T19:25:31.288105105Z       Executed 'Functions.take_order' (Succeeded, Id=fafacecd-c871-4199-b34c-47600992bb64, Dur
2026-10-30T19:25:31.394272807Z       Executed 'Functions.take_order' (Succeeded, Id=4852892a-f720-4bb9-89f0-24e1e4d8549e, Dur
```

**The first answer moved from about six seconds to between 13.4 and 16.5**, and the warm order after
it did not move at all: 0.017081 s, 0.043927, 0.040339, a few hundredths as before. The log says
where the time went. From the start script to `Initializing Host` took 12.43 s here, against 5.09
for the plain app, 7.34 s more; everything after it is as fast as before. The difference is a little
less than the eight seconds of the sleep. What that suggests, and the laptop cannot prove, is that
the worker starts importing while the host is still starting, so part of a short import is hidden
behind the host's own start, and a long one is not. On a placeholder in Azure, which already has the
host running, there is nothing for the import to hide behind.

Two things follow for the shop. A cold start pays for the module once and a warm request pays
nothing for it, so a heavy import is a cold-start problem only. And it is paid by every function in
the app, which is why the nightly report's library does not belong in the order API's file.

## A quarter of a core

Flex Consumption's smallest instance, 512 MB, comes with a quarter of a core, and its default,
2,048 MB, with one. Docker can limit how much processor a container gets, which is the nearest the
laptop comes to that. **This is an analogue, run with Docker's `--cpus`, and not Azure's
allocation**:

```
ana@laptop:~/azure$ nproc
4
ana@laptop:~/azure$ first200 shopfn:1 1
shopfn:1: first 200 after 5638 ms
     42 000
      1 200
next request: 0.021042 s
ana@laptop:~/azure$ first200 shopfn:1 0.5
shopfn:1: first 200 after 8698 ms
     65 000
      1 200
next request: 0.024337 s
ana@laptop:~/azure$ first200 shopfn:1 0.25
shopfn:1: first 200 after 16316 ms
    120 000
      1 200
next request: 0.084776 s
```

The same image, the same machine: 5638 ms with a whole processor, 8698 with half of one, 16316 with
a quarter, nearly three times as long as with one. Starting the host is computation, and computation
runs at the speed of the processor it is given. On the laptop, at least, **a smaller instance is a
slower cold start**, and the next section puts the price of each size beside it.

Remove the last container and the slow image. Keep the network and Azurite: lesson 17 starts from
them.

```sh
docker rm -f cold
docker image rm shopfn:slow
```
