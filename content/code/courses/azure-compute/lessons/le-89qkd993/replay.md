---
title: "Replay: the orchestrator runs again from the top"
version: 1
---

The picture most people bring to an orchestrator is a Python generator paused at its `yield`,
sitting in memory until the activity's result arrives. **That is not what happens.** After each
`yield` the orchestrator's run ends and the process forgets it. When the result arrives, the
extension calls the orchestrator again, from its first line, and answers every `yield` it has
already answered out of the instance's history, until the code reaches a `yield` the history has no
answer for. That one is new work, and the run ends there again. This is **replay**, and it is the
whole reason an orchestrator can survive a restart: there is nothing in memory to lose.

It is also the reason for the rules at the end of this section. A function that is run four times
for one order must decide the same thing four times.

## Four runs for one order

The log line at the top of `order_flow` was there for this. Ask the host's log for it, and for the
three activities, in the order they happened:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E "order_flow for A-1001|Executed 'Functions\.(reserve_stock|charge|ship)'" | head -7
      order_flow for A-1001, replaying=False
      Executed 'Functions.reserve_stock' (Succeeded, Id=7db1de6a-e19d-4b02-b9b9-cf07113cf2c2, Duration=1014ms)
      order_flow for A-1001, replaying=True
      Executed 'Functions.charge' (Succeeded, Id=3c28ebe7-079f-4ee1-9a8e-9e00996c090a, Duration=1007ms)
      order_flow for A-1001, replaying=True
      Executed 'Functions.ship' (Succeeded, Id=f0a1e5c6-4ce8-4ebf-8241-f790f0be8a3f, Duration=1005ms)
      order_flow for A-1001, replaying=True
```

**One order, three activities, and the orchestrator ran four times.** The first run reached the
first `yield`, scheduled `reserve_stock` and ended. When the reservation was done, the second run
started from the top: `context.is_replaying` was `True`, the first `yield` was answered from the
history, and the run went on to schedule `charge`. The fourth run replayed all three and reached the
`return`. Each log line in an orchestrator is printed once per run, and that is the documented
behaviour, not a fault: a line that should appear once is written behind `if not context.is_replaying`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"Four runs of order_flow for A-1001. Run 1 reaches yield reserve_stock, schedules it and stops; history rows 4. Run 2 answers reserve_stock from the history and schedules charge; rows 8. Run 3 answers two and schedules ship; rows 12. Run 4 answers all three from the history and returns; rows 16. Only run 1 has replaying=False.\"><text x=\"70\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orchestrator run</text><text x=\"223.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield reserve_stock</text><text x=\"343.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield charge</text><text x=\"463.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield ship</text><text x=\"583.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">return</text><text x=\"670\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">history rows</text><text x=\"70\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">run 1</text><text x=\"70\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=False</text><rect x=\"168\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">scheduled; run ends</text><rect x=\"288\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"408\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"528\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">4</text><text x=\"70\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">run 2</text><text x=\"70\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"288\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">scheduled; run ends</text><rect x=\"408\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"528\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">8</text><text x=\"70\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">run 3</text><text x=\"70\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"288\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"408\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"463.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">scheduled; run ends</text><rect x=\"528\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">12</text><text x=\"70\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">run 4</text><text x=\"70\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"288\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"408\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"463.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from history</text><rect x=\"528\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"583.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">returns</text><text x=\"670\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">16</text><rect x=\"168\" y=\"268\" width=\"16\" height=\"14\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answered from the history, nothing runs</text><rect x=\"168\" y=\"290\" width=\"16\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new: written to the queue, and the run stops</text></svg>", "caption": "Replay, as A-1001 went through it. Each run starts from the first line; the yields already answered come out of the history, and the first one that is not is new work. Every run adds four rows to the History table."}
```

## The history is a table

The Azure Storage provider keeps an instance's history in a table of the storage account, named after
the task hub. Azurite has three:

```
ana@laptop:~/azure$ az storage table list --query "[].name" -o tsv
TestHubNameHistory
TestHubNameInstances
TestHubNamePartitions
```

`TestHubName` is the default task hub name outside Azure; in Azure it is the function app's name.
**`TestHubNameHistory` is the event log, one row per event, with the instance id as the partition
key**. Read A-1001's:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameHistory --filter "PartitionKey eq 'A-1001'" --query "items[].[RowKey, EventType, Name]" -o tsv
0000000000000000	OrchestratorStarted	None
0000000000000001	ExecutionStarted	order_flow
0000000000000002	TaskScheduled	reserve_stock
0000000000000003	OrchestratorCompleted	None
0000000000000004	OrchestratorStarted	None
0000000000000005	TaskCompleted	None
0000000000000006	TaskScheduled	charge
0000000000000007	OrchestratorCompleted	None
0000000000000008	OrchestratorStarted	None
0000000000000009	TaskCompleted	None
000000000000000A	TaskScheduled	ship
000000000000000B	OrchestratorCompleted	None
000000000000000C	OrchestratorStarted	None
000000000000000D	TaskCompleted	None
000000000000000E	ExecutionCompleted	None
000000000000000F	OrchestratorCompleted	None
sentinel	None	None
```

Sixteen events and a `sentinel` row the provider keeps for itself. Every run of the orchestrator
is bracketed by `OrchestratorStarted` and `OrchestratorCompleted`. The first run added the input
(`ExecutionStarted`) and the first `TaskScheduled`; each of the next added the result it was woken
by (`TaskCompleted`) and the next request; the last added `ExecutionCompleted`. Four events a run,
four runs. The rows are only ever added, never changed: the documentation calls it the event
sourcing pattern, and it warns that the table's columns are a debugging aid that may change between
versions of the extension.

The second table holds one row per instance, what the status address reads:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameInstances --filter "PartitionKey eq 'A-1001'" --query "items[0].{name: Name, status: RuntimeStatus, created: CreatedTime, completed: CompletedTime}"
{
  "completed": "2026-10-30T20:38:09.612420+00:00",
  "created": "2026-10-30T20:37:52.469068+00:00",
  "name": "order_flow",
  "status": "Completed"
}
```

The documentation describes the two tables as kept eventually consistent with each other, the
history being the truth. And the queues are where the work waits:

```
ana@laptop:~/azure$ az storage queue list --only-show-errors --query "[].name" -o tsv
testhubname-control-00
testhubname-control-01
testhubname-control-02
testhubname-control-03
testhubname-workitems
```

Four **control queues** carry the messages for orchestrators (a start, an activity's result, a
timer, an event), and each instance belongs to one of them by a hash of its id. The **work-item
queue** carries the activities. They are the same Azure queues lesson 15's trigger read, which is why
an orchestration on this provider costs storage transactions as well as executions.

## Where the time comes from

Replace the log line of `order_flow` with one that prints two clocks. The import goes under
`import time`:

```python
from datetime import datetime, timezone
```

and the line, two lines now, in place of the old one:

```python
    logging.info('order_flow for %s, replaying=%s, now=%s, context=%s', order['order'], context.is_replaying,
                 datetime.now(timezone.utc).time(), context.current_utc_datetime.time())
```

Build, replace the container and send an order:

```
ana@laptop:~/azure$ grep -n -E "^from datetime|now=|current_utc_datetime.time" shopfn/function_app.py
4:from datetime import datetime, timezone
24:    logging.info('order_flow for %s, replaying=%s, now=%s, context=%s', order['order'], context.is_replaying,
25:                 datetime.now(timezone.utc).time(), context.current_utc_datetime.time())
ana@laptop:~/azure$ docker build -q -t shopfn:df1b shopfn
sha256:f5a46d22ccecac3a324669cfbff46dd7bcb2f09f8c05819d1d20d500a392e271
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1b
3cf20270f8fe453c9a90db5e27ade9867a938f06b48897fb5ccd97e21ee1c5a8
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1003", "sku": "cap", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -o "order_flow for A-1003.*"
order_flow for A-1003, replaying=False, now=20:38:56.266326, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:57.544898, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:58.609477, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:59.663855, context=20:38:56.159828
```

**`now` moved on every run; `context` did not.** The machine's clock gives each replay a different
answer, so any decision made from it can come out differently on the second run than on the first.
`context.current_utc_datetime` is read from the history: at the top of the function it is the time
of the run that first got there, every time. It moves forward as the code passes each `yield`, by
the same amounts on every replay.

If the orchestrator had said "after 18:00, ship tomorrow" with `datetime.now()`, an order placed at
17:59:59 could schedule `ship` on its first run and, replayed one second later, take the other
branch. The extension compares what a replay asks for with what the history says was asked for,
and when they differ it fails the instance with `Non-Deterministic workflow detected`. The section
`timers-and-events` makes that happen on purpose.

## The rules, and why each one exists

The documentation's list is long, and every item comes from the same fact: **an orchestrator must
make the same requests in the same order every time it runs.** These are the ones a Python
orchestrator meets:

- **No clock**: `datetime.now()` or `gmtime()`; use `context.current_utc_datetime`.
- **No random number and no `uuid4()`**: take a random value from an activity, whose result is
  stored, or use `context.new_guid()`.
- **No input or output**: no HTTP call, no database, no file, and no binding other than the
  orchestration trigger. Those go in activities, which run once per step rather than once per
  replay; the orchestrator is run on one thread for every orchestration on the instance, so a slow
  call there delays them all.
- **No environment variable and no global that can change**: pass configuration in the input, or
  have an activity return it.
- **No `time.sleep()`**: a durable timer instead, the subject of the section `timers-and-events`.
- **No `async def`**: the orchestrator is a generator, and `yield` replaces `await`.

Activities have none of these rules. They run their code for real every time they are called,
which brings its own rule: the documentation describes the messages behind them as delivered at
least once, so **an activity must be safe to run twice** for the same input.

## The task hub, and the other places it can live

Not run in this course: everything in this part needs a subscription.

**A task hub is the state of one app's orchestrations in one backend.** Its name comes from
`host.json`, under `extensions.durableTask.hubName`; without one, the extension takes the app's name
in Azure and `TestHubName` elsewhere. The documentation insists that two apps sharing a storage
account each have their own hub, deployment slots included (lesson 18), because two apps on one hub
take each other's messages.

The storage provider decides where the hub lives, and the documentation, read on 2026-10-30, lists
four:

| | where the state is | what to know |
|---|---|---|
| Azure Storage | tables, queues and blobs of a storage account you own | the default, and the one this lesson ran; no setup; at most 16 partitions |
| Durable Task Scheduler | a managed Azure resource, `Microsoft.DurableTask/schedulers`, reached over gRPC | the documentation's recommendation; a dashboard; identity-based access; an emulator for local work, not used here |
| Netherite | Event Hubs and page blobs | Microsoft ends support for it on 31 March 2028 and points to the Scheduler |
| MSSQL | a SQL Server or Azure SQL database | runs where there is no Azure at all |

Two facts decide more than the rest. **A hub cannot be moved from one provider to another**: the
documentation's answer is a new app on the new provider. And the provider is a setting in
`host.json` (`storageProvider` with a `type`), not a change to the orchestrator: the same
`order_flow` runs on all four. For a Python app, the Scheduler's quickstart asks for the extension
bundle at 4.32.0 or later.

On the Consumption plan, the documentation adds, **each replay is billed as an execution**, and the
time an orchestrator spends waiting at a `yield` is not billed at all. The other plans do not charge
for replays.
