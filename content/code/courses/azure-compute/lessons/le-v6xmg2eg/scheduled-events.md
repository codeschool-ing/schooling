---
title: Thirty seconds of notice, through Scheduled Events
version: 1
---

It is natural to expect an eviction to arrive the way a shutdown does: the operating system is told,
services are stopped in order, and programs get a signal and a moment to finish. **Nothing in the
documentation promises the machine a signal of its own. A program on the machine has to ask, every
second, and if it asks in time it learns of an eviction at most thirty seconds before it happens.** The service it asks is
Scheduled Events, part of the Instance Metadata Service, and what the program does with the answer
decides whether the eviction loses half a minute of work or half a night of it.

Nothing in this section was run. A laptop has no metadata service, and this course does not imitate
one. What follows is Microsoft's documentation, read on 2026-10-30, and the one program here was
compiled and never run against Azure.

## Where the notice appears

The Instance Metadata Service answers at `169.254.169.254`, an address that is not routable and is
reachable only from inside the machine; the documentation says the conversation never leaves the
host. It is the same service a managed identity takes its tokens from. Scheduled Events is one path
of it, and this is the request, from a terminal on the machine:

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"
```

Three details of that line are required. The header `Metadata:true` must
be sent, or the service answers *Bad Request*. The `api-version` must be named, and
`2020-07-01` is the current one. And no proxy: the documentation says the service is not meant
to be reached through one and that a client's default proxy settings must be overridden even where
nobody knows of a proxy, which is what `--noproxy "*"` does.

The documentation adds a fourth detail that changes how the listener is run. **Scheduled Events is
switched on for a machine by its first request**, that first answer can take up to two minutes, and
events start arriving within five; a machine that asks nothing for 24 hours is switched off again.
So a listener started when trouble is suspected is already too late. It starts at boot, with the
machine, and keeps asking.

## What an eviction looks like

The answer is a document with a number, `DocumentIncarnation`, that rises every time the list of
events changes, and the list itself. An empty list means nothing is planned. Five kinds of event can
appear, and each has a minimum notice:

| `EventType` | what it means | minimum notice |
| --- | --- | --- |
| `Freeze` | the machine pauses for a few seconds | 15 minutes |
| `Reboot` | the machine restarts | 15 minutes |
| `Redeploy` | the machine moves to another host | 10 minutes |
| `Preempt` | the Spot machine is being evicted | 30 seconds |
| `Terminate` | a scale set instance is being deleted | 5 to 15 minutes, configured on the set |

`Preempt` is the Spot eviction, and its 30 seconds come with a qualification in two places. The
Scheduled Events page says the event "is made available on a best effort basis"; the Spot page says
the notice is delivered on a best-effort basis "up to 30 seconds prior to the eviction". **Read
together, that is thirty seconds at most, and possibly none.** The longer warning a scale set can
give before deleting an instance does not help either: the scale set documentation says terminate
notifications cannot be enabled on Spot instances.

Here is a Preempt. This is **the documentation's example**, quoted from Microsoft's page on deploying
Spot machines with the Azure CLI, where it is the answer after a simulated eviction, asked for with the older
version `2019-08-01`. It was not produced in this course:

```json
{"DocumentIncarnation":1,"Events":[{"EventId":"A123BC45-1234-5678-AB90-ABCDEF123456","EventStatus":"Scheduled","EventType":"Preempt","ResourceType":"VirtualMachine","Resources":["myspotvm"],"NotBefore":"Tue, 16 Mar 2021 00:58:46 GMT","Description":"","EventSource":"Platform"}]}
```

`EventStatus` is `Scheduled`, which means planned and not yet begun. `NotBefore` is the time before
which it will not start, so it is the end of the window. `Resources` names the machines the event
affects, and it is worth checking. The documentation says the events of every machine in an
availability set or a scale set placement group are delivered to all the machines in it, so a
listener that reacted to every Preempt it saw could drain a machine that was not being evicted.
There is no `Completed` status. An event that has happened simply disappears from the list, and
`2020-07-01` adds a `DurationInSeconds` field that this older example does not have.

## Saying you are ready

When the machine has finished preparing, it can say so with a `POST` to the same address, naming the
event:

```sh
curl -s -H Metadata:true --noproxy "*" -X POST -d '{"StartRequests": [{"EventId": "A123BC45-1234-5678-AB90-ABCDEF123456"}]}' "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"
```

Not run either. **Acknowledging lets the event go ahead sooner; not acknowledging does not stop
it.** At `NotBefore` the event starts whatever the machine has said. The service answers 200 to any
valid event id, even one another machine already acknowledged, and 400 to a malformed request. The
documentation warns that an acknowledgement releases the event for every machine in its
`Resources`, not only the one that sent it, so in a group it suggests one machine, a leader, does
the acknowledging. For a single Spot machine the list is just itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A timeline of a Spot eviction as Microsoft documents it. A Preempt event appears in the Scheduled Events list, and at most 30 seconds later, on a best-effort basis, comes its NotBefore time, from which the machine is evicted. The listener, which asks every second, sees the event within a second and drains: it stops taking work, writes a checkpoint and tells the report to stop with SIGTERM. Then it acknowledges with a POST of StartRequests, after which Azure may go ahead sooner; otherwise the eviction waits for NotBefore.\"><defs><marker id=\"se-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 150 L700 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#se-ah)\"></path><path d=\"M70 140 L70 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M130 140 L130 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M440 140 L440 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M610 140 L610 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 72 L70 62 L610 62 L610 72\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">at most 30 seconds, on a best-effort basis</text><text x=\"62\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">Preempt appears</text><text x=\"62\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the event list</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">NotBefore</text><text x=\"610\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evicted from here on</text><text x=\"122\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the listener sees it</text><text x=\"122\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">it asks every second</text><text x=\"432\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">acknowledged</text><text x=\"432\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">POST StartRequests</text><rect x=\"122\" y=\"212\" width=\"298\" height=\"48\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"271\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stop taking work, write a checkpoint</text><text x=\"271\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and tell the report to stop</text><rect x=\"432\" y=\"212\" width=\"258\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"561\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Azure may go ahead sooner</text><text x=\"561\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">otherwise it waits for NotBefore</text><text x=\"704\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">not to scale</text></svg>", "caption": "The thirty seconds of a Preempt, as the documentation describes them. Not to scale, and not observed in this course. Acknowledging can shorten the window; not acknowledging never lengthens it."}
```

## A listener, whole

Here is a listener for the report machine, in Python with nothing but the standard library. It reads
the event list every second, and on a Preempt for this machine it tells the report to stop and then
acknowledges. Copy it with the button on the block and save it as `spot-watch.py`:

```schooling-example
{"language": "python", "file": "spot-watch.py", "parts": [{"code": "# spot-watch.py: watch Scheduled Events, and drain the worker on a Preempt\nimport json\nimport os\nimport signal\nimport time\nimport urllib.request\n\nMD = 'http://169.254.169.254/metadata'\nEVENTS = MD + '/scheduledevents?api-version=2020-07-01'\nNAME = MD + '/instance/compute/name?api-version=2025-04-07&format=text'\nPIDFILE = os.environ.get('PIDFILE', '/run/worker.pid')\nDIRECT = urllib.request.build_opener(urllib.request.ProxyHandler({}))\nHANDLED = set()\n\n\n", "note": "The two addresses the listener asks: the event list, at the current version, and the machine's own name, which is how an event names it. `PIDFILE` is where the report writes its process id. `DIRECT` is an opener with no proxy at all, as the metadata service requires, whatever proxy the machine's environment names. `HANDLED` remembers the events already acted on."}, {"code": "def ask(url, body=None):\n    request = urllib.request.Request(url, data=body, headers={'Metadata': 'true'})\n    with DIRECT.open(request, timeout=5) as answer:\n        return answer.read().decode()\n\n\n", "note": "Every request carries `Metadata: true`, or the service refuses it. A body turns the request into a `POST`, which is how an event is acknowledged. Five seconds is the longest it waits, so one stuck request cannot use up the whole notice."}, {"code": "def log(**fields):\n    print(json.dumps(fields), flush=True)\n\n\n", "note": "One JSON line for each thing that happens, the habit the shop's own log already has."}, {"code": "def handle(event, me):\n    mine = me.lower() in [r.lower() for r in event['Resources']]\n    if event['EventType'] != 'Preempt' or not mine or event['EventId'] in HANDLED:\n        return\n    HANDLED.add(event['EventId'])\n    log(msg='preempt', not_before=event['NotBefore'])\n    with open(PIDFILE) as f:\n        os.kill(int(f.read()), signal.SIGTERM)\n    body = json.dumps({'StartRequests': [{'EventId': event['EventId']}]})\n    ask(EVENTS, body.encode())\n    log(msg='acknowledged', event=event['EventId'])\n\n\n", "note": "Only a Preempt that names this machine matters, compared without regard to case, and only once. Then drain: `SIGTERM` tells the report to write a checkpoint and exit. Then acknowledge, so the eviction may go ahead sooner. If anything here fails, the eviction still happens at `NotBefore`."}, {"code": "me, seen = None, None\nwhile True:\n    try:\n        me = me or ask(NAME)\n        doc = json.loads(ask(EVENTS))\n        if doc['DocumentIncarnation'] != seen:\n            seen = doc['DocumentIncarnation']\n            log(msg='document', incarnation=seen, events=len(doc['Events']))\n            for event in doc['Events']:\n                handle(event, me)\n    except (OSError, ValueError, KeyError) as err:\n        log(msg='no usable answer', error=repr(err))\n    time.sleep(1)\n", "note": "Ask once a second. The name is asked for once and kept. A new `DocumentIncarnation` means the list changed and is read again; the same number means nothing new. Whatever goes wrong is logged, and the loop goes round again."}]}
```

On the machine it would run as a service started at boot, beside the report. Once a second is the
documentation's recommendation, and it stays inside the service's own limit of five requests a
second per machine, above which the service answers 429. **Every failure in it is logged and the loop carries on**, because a listener that crashes on an
answer it did not expect stops listening at the one moment it is needed.

Testing it needs a subscription, and Microsoft provides a way to provoke the event. Against a real
Spot machine, this asks Azure to simulate an eviction of it, and the listener on the machine should
then see a Preempt like the documentation's example above. It was not run in this course:

```sh
az vm simulate-eviction --resource-group shop --name shop-report-1
```

## What thirty seconds is for

Thirty seconds is enough to stop and too short to finish anything. Draining is therefore a short
list of things to stop doing:

1. stop taking new work: leave the load balancer's pool, stop reading the queue;
2. write down how far the work in hand has got, somewhere that outlives the machine. The guide says
   to keep checkpoints outside the Spot machine, in a storage account for instance;
3. let go of what is unfinished, so that another machine takes it up. A queue does that by itself
   when a message is not completed, as lesson 20 shows.

The report does the second of those, and that is why its machine's disk does not matter: it writes a
checkpoint to Blob Storage every half hour, and its `SIGTERM` handler writes one more and exits. The
guide also warns that a Spot machine can be evicted as soon as it is created, before any listener is
running, so nothing that replaces machines may depend on the notice arriving. **Work that is safe to
stop at any moment needs none of this section**, and that is the strongest argument for writing it
that way.
