---
title: A reader that crashes, counted twice
version: 1
---

**This section makes a duplicate happen in a program you can run, and the next two make it
harmless.** The reader keeps each customer's running total of the payments of the last section, in
blobs in Azurite, which is where a small program of this kind would keep them; on Azure it would be
a storage account, a table or a database row, and the arithmetic of what goes wrong is the same.

Each way of writing results gets a container for them and one for its checkpoints:

```sh
for m in add guard upsert; do
  az storage container create -n "sink-$m" -o none
  az storage container create -n "checkpoints-$m" -o none
done
```

Save the reader as `totals.py`. It is long because it holds all three ways of writing, and this
section uses the first:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\n\nfrom azure.core.exceptions import ResourceNotFoundError\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\nfrom azure.storage.blob import BlobServiceClient\n\nAZURITE = (\"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;\"\n           \"AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;\"\n           \"BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;\")\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\nCHECKPOINT_EVERY = 3\nsink = BlobServiceClient.from_connection_string(AZURITE).get_container_client(f\"sink-{mode}\")\nhandled = 0\n\n", "note": "Azurite's connection string in full, as in lesson 22, because the checkpoint library refuses the short form. `mode` is how the reader writes its results, one of three, and `crash_after` makes it die on purpose after that many events. Each mode has a container of its own for its results, `sink-add` and so on, and one for its checkpoints, so that the three never see each other's work."}, {"code": "def read(name, default):\n    try:\n        return json.loads(sink.download_blob(name).readall())\n    except ResourceNotFoundError:\n        return default\n\n", "note": "Reads a small JSON blob, or a default when it is not there yet."}, {"code": "def handle(seq, p):\n    if mode == \"add\":\n        total = read(p[\"customer\"], 0)\n        sink.upload_blob(p[\"customer\"], json.dumps(total + p[\"cents\"]), overwrite=True)\n        return \"added to the total\"\n", "note": "**`add` is the obvious reader**: read the customer's total, add the payment, write the total back. Doing it twice adds twice."}, {"code": "    elif mode == \"guard\":\n        state = read(\"state\", {\"last_seq\": -1, \"totals\": {}})\n        if seq <= state[\"last_seq\"]:\n            return \"skipped, already in the state\"\n        totals = state[\"totals\"]\n        totals[p[\"customer\"]] = totals.get(p[\"customer\"], 0) + p[\"cents\"]\n        sink.upload_blob(\"state\", json.dumps({\"last_seq\": seq, \"totals\": totals}), overwrite=True)\n        return \"added, with its sequence number\"\n", "note": "`guard` keeps the totals and the last sequence number handled in one blob, written in one upload, and skips an event at or below that number. It is the subject of the last section of this lesson."}, {"code": "    elif mode == \"upsert\":\n        sink.upload_blob(p[\"order\"], json.dumps(p), overwrite=True)\n        return \"written under its order id\"\n\n", "note": "`upsert` writes each payment as a blob named by its order id, and adds nothing up while handling. It is the subject of the next section."}, {"code": "def on_event(partition, event):\n    global handled\n    p = json.loads(event.body_as_str())\n    result = handle(event.sequence_number, p)\n    handled += 1\n    print(f\"seq {event.sequence_number}  {p['order']} {p['customer']} {p['cents']:>6}  {result}\")\n    if handled % CHECKPOINT_EVERY == 0:\n        partition.update_checkpoint(event)\n        print(f\"  checkpoint at seq {event.sequence_number}\", flush=True)\n    if handled == crash_after:\n        print(\"  crash\", flush=True)\n        os._exit(1)\n\n", "note": "**The work, then the checkpoint**: at least once. A checkpoint every third event, which is the batching lesson 22 recommended for cost, and `os._exit` when `crash_after` is reached, which ends the process on the spot, as a killed process ends, without closing the client. `flush=True` makes sure the lines printed so far reach the screen first."}, {"code": "store = BlobCheckpointStore.from_connection_string(AZURITE, f\"checkpoints-{mode}\")\nclient = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\",\n    eventhub_name=\"clicks\", checkpoint_store=store)\nlistener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"partition_id\": \"0\", \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\n\n", "note": "The reader of lesson 22, on partition 0, with the checkpoint store of this mode, listening for five seconds."}, {"code": "if mode == \"upsert\":\n    totals = {}\n    for blob in sink.list_blobs():\n        p = read(blob.name, None)\n        totals[p[\"customer\"]] = totals.get(p[\"customer\"], 0) + p[\"cents\"]\nelif mode == \"guard\":\n    totals = read(\"state\", {\"totals\": {}})[\"totals\"]\nelse:\n    totals = {b.name: read(b.name, 0) for b in sink.list_blobs()}\nprint(\"totals:\", \"  \".join(f\"{c} {totals[c]}\" for c in sorted(totals)))\n", "note": "The totals, as each mode keeps them. For `upsert` they are summed at the end from the blobs, one per order."}]}
```

Run it in `add` mode and let it crash after five events, then run it again, the way a supervisor
restarts a process that died:

```
ana@laptop:~/azure$ python totals.py add 5
seq 0  o-301 c-17   4590  added to the total
seq 1  o-302 c-02  12800  added to the total
seq 2  o-303 c-17    990  added to the total
  checkpoint at seq 2
seq 3  o-303 c-17    990  added to the total
seq 4  o-304 c-05   2350  added to the total
  crash
ana@laptop:~/azure$ python totals.py add
seq 3  o-303 c-17    990  added to the total
seq 4  o-304 c-05   2350  added to the total
seq 5  o-305 c-02   1500  added to the total
  checkpoint at seq 5
seq 6  o-306 c-17   7200  added to the total
totals: c-02 14300  c-05 4700  c-17 14760
```

**The first run handled sequence numbers 0 to 4 and checkpointed at 2.** It added `o-301`, `o-302`
and the first `o-303`, wrote a checkpoint, added the second `o-303` and `o-304`, and died before its
next checkpoint. **The second run started after sequence number 2**, from the checkpoint, so
sequence numbers 3 and 4 were handled again: the second copy of `o-303`, a second time, and `o-304`, a
second time.

**Compare the totals with the correct ones**: 12,780 for `c-17`, 14,300 for `c-02`, 2,350 for
`c-05`. `c-02` is right, because none of its payments fell between the checkpoint and the crash.
`c-05` is 4,700, double, because `o-304` was replayed. `c-17` is 14,760, which is 1,980 too much:
`o-303` was counted three times, once for the producer's retry and once more for the replay. **No
error was printed by anything**, and both mistakes are of the kind that survives until somebody
reconciles the totals against the orders, if anybody does.

## Why checkpointing more often does not fix it

Checkpointing after every event shrinks the window and does not close it: a crash between the
work and the checkpoint still replays one event. And it would do nothing about the producer's
duplicate, which is two events with two sequence numbers that any reader handles twice however it
checkpoints. **The fix is not in the reader's timing; it is in what handling an event does to the
sink.** The next section changes that.
