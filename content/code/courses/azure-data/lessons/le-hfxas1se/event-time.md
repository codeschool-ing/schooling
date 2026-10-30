---
title: Event time, and the clock that matters
version: 1
---

**Every event has two times, and counting by the wrong one gives a confident wrong answer.** The
**event time** is when the thing happened: the customer tapped "checkout" at 20:00:55, and the app
wrote that into the click. The **arrival time** is when Azure received it, the enqueued time of
lesson 22. They are close when the network is good and far apart when it is not, and the case that
matters is the phone in a tunnel: it keeps its clicks and sends them a minute later, together, so
they arrive late and out of order.

A query without `TIMESTAMP BY` counts by arrival time. That is simple and it is wrong for any
question about what customers did, because a burst of delayed clicks lands in the minute the
network recovered and is missing from the minute the customers tapped. **`TIMESTAMP BY at` makes the
event's own field the clock**, and from that moment the query has a problem arrival time never had:
it has to decide how long to wait for a minute's stragglers before it publishes that minute's count.

## A stand-in for the job, labelled

**What follows is a Python program written for this course. It is not Stream Analytics**, and it
does not reproduce everything the service does; it implements tumbling windows by event time and
one tolerance for disorder, which is enough to see the problem the service solves. It reads from
the Event Hubs emulator of lesson 22, which this lesson starts the same way:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

And in the same terminal, the variable from lesson 22:

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

First, ten checkouts from Quitanda's evening, in the order they reached Azure, each carrying the
time the app recorded. Save it as `send_checkouts.py`:

```schooling-example
{"language": "python", "file": "send_checkouts.py", "parts": [
{"code": "import json\nimport os\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "The library of lesson 22, sending to the same hub, `clicks`."},
{"code": "CHECKOUTS = [\n    (1, \"c-17\", \"20:00:05\"), (2, \"c-02\", \"20:00:20\"), (3, \"c-05\", \"20:00:50\"),\n    (4, \"c-03\", \"20:00:40\"), (5, \"c-08\", \"20:01:10\"), (6, \"c-11\", \"20:01:30\"),\n    (7, \"c-21\", \"20:00:55\"), (8, \"c-17\", \"20:02:05\"), (9, \"c-02\", \"20:01:50\"),\n    (10, \"c-05\", \"20:03:01\"),\n]\n\n", "note": "**The list is in arrival order, and the times are not.** Checkout 4 happened ten seconds before checkout 3; checkout 7, from the phone in the tunnel, happened at 20:00:55 and arrived after checkouts from 20:01:30; checkout 9 is fifteen seconds out of place."},
{"code": "hub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\nwith hub:\n    batch = hub.create_batch(partition_id=\"0\")\n    for n, customer, at in CHECKOUTS:\n        batch.add(EventData(json.dumps(\n            {\"n\": n, \"customer\": customer, \"page\": \"/checkout\", \"at\": f\"2026-10-30T{at}\"})))\n    hub.send_batch(batch)\nprint(f\"sent {len(CHECKOUTS)} checkouts to partition 0 in one batch\")\n", "note": "**One batch, to one named partition**, so that the arrival order is exactly the list's order and the runs below come out the same every time. `at` is the app's clock, São Paulo time, written as text in the event; the service never sees it as anything but bytes."}
]}
```

Then the counter. Save it as `windows.py`:

```schooling-example
{"language": "python", "file": "windows.py", "parts": [
{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\nfrom datetime import datetime, timedelta\n\nfrom azure.eventhub import EventHubConsumerClient\n\npolicy, tolerance = sys.argv[1], timedelta(seconds=int(sys.argv[2]))\nWINDOW = timedelta(minutes=1)\n\n", "note": "Two arguments: what to do with a late event, `drop` or `adjust`, and how many seconds of disorder to tolerate. Windows are one minute, like the job's `TumblingWindow(minute, 1)`."},
{"code": "client = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\", eventhub_name=\"clicks\")\narrived = []\n\ndef on_event(partition, event):\n    arrived.append((json.loads(event.body_as_str()), event.enqueued_time))\n\nlistener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"partition_id\": \"0\", \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\nprint(f\"{len(arrived)} events, enqueued from {arrived[0][1]:%H:%M:%S.%f} to {arrived[-1][1]:%H:%M:%S.%f} UTC\")\n\n", "note": "The reader of lesson 22, limited to partition 0, keeping each event with its **enqueued time**, the arrival time. It reads everything first and then replays it in arrival order, which is the order a live job would have seen."},
{"code": "counts, highest = {}, None\nfor click, _ in arrived:\n    at = datetime.fromisoformat(click[\"at\"])\n    watermark = highest - tolerance if highest else None\n", "note": "**The watermark is the latest event time seen so far, minus the tolerance.** It is the program's statement that nothing older than this is expected any more."},
{"code": "    if watermark and at < watermark:\n        behind = int((watermark - at).total_seconds())\n        if policy == \"drop\":\n            print(f\"#{click['n']:<2} at {at:%H:%M:%S}  {behind} s behind the watermark: dropped\")\n            continue\n        print(f\"#{click['n']:<2} at {at:%H:%M:%S}  {behind} s behind the watermark: adjusted to {watermark:%H:%M:%S}\")\n        at = watermark\n", "note": "An event older than the watermark is late. `drop` discards it; `adjust` keeps it and moves its time forward to the watermark, so it is counted in a window that is still open, which is not the one it happened in."},
{"code": "    start = at.replace(second=0)\n    counts[start] = counts.get(start, 0) + 1\n    highest = max(highest, at) if highest else at\n    for s in sorted(counts):\n        if s + WINDOW <= highest - tolerance:\n            print(f\"window {s:%H:%M}-{s + WINDOW:%H:%M}  {counts.pop(s)} checkouts  closed by #{click['n']}\")\n\n", "note": "Each event is counted in the minute its time falls in. Then **every window that ends at or before the new watermark is closed and printed**, with the number of the event whose arrival closed it. A closed window is final: nothing can be added to it."},
{"code": "for s in sorted(counts):\n    print(f\"window {s:%H:%M}-{s + WINDOW:%H:%M}  {counts[s]} checkouts  still open\")\n", "note": "Windows the watermark has not passed when the events run out are printed as still open. A live job would keep them open until later events moved the watermark past them."}
]}
```

Send the checkouts, then count them with a tolerance of twenty seconds:

```
ana@laptop:~/azure$ python send_checkouts.py
sent 10 checkouts to partition 0 in one batch
ana@laptop:~/azure$ python windows.py drop 20
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  4 checkouts  closed by #6
#7  at 20:00:55  15 s behind the watermark: dropped
window 20:01-20:02  3 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**Look at the first line before the windows.** All ten events were enqueued in the same millisecond,
because they were sent as one batch, and at a time of day that has nothing to do with 20:00: it is the
emulator's clock, in UTC, saying when the recording was made. **Counted by arrival
time, all ten checkouts would fall in one window**, the minute the batch arrived, and the screen in
the operations room would show ten checkouts at a moment when nobody was buying anything. Counted by
event time, they spread over the four minutes the customers actually tapped in, and that is the
count `TIMESTAMP BY at` asks for.

**The windows are printed in the order they closed**, not all at the end. The window 20:00 to 20:01
closed when checkout 6, at 20:01:30, arrived: the latest time seen became 20:01:30, the watermark
20:01:10, and nothing before 20:01:00 was expected any more. It holds four checkouts, 1 to 4,
including checkout 4, which arrived after checkout 3 though it happened earlier; twenty seconds of
tolerance was enough to absorb those ten seconds of disorder. The last two windows are still open
because no later event came to close them.

**Checkout 7 is the one the next sections are about.** It happened at 20:00:55, in a window that
was already closed when it arrived, and with `drop` it was discarded: the 20:00 window says four
checkouts and there were five. The section on late data runs the other two choices, and the one
between it and here names the windows other than tumbling ones.
