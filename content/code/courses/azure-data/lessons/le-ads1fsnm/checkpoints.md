---
title: Checkpoints, kept by the reader in a blob
version: 1
---

**Event Hubs does not remember where a reader stopped. The reader does, and it writes that down
somewhere of its own.** A checkpoint is that note: for one consumer group and one partition, the
sequence number and offset of the last event the reader has finished with. When the reader starts
again, it reads the note and carries on from the event after it. The service plays no part in this,
which surprises people who expect a stream to behave like a queue that knows what was delivered.

The libraries keep the note in a blob container, and the lab already has one place to put a blob:
Azurite. Create a container for it:

```
ana@laptop:~/azure$ az storage container create -n checkpoints
{
  "created": true
}
```

## A reader that checkpoints

Save this as `checkpointed.py`:

```schooling-example
{"language": "python", "file": "checkpointed.py", "parts": [
{"code": "import json\nimport os\nimport threading\nimport time\n\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\n\n", "note": "`BlobCheckpointStore` comes from `azure-eventhub-checkpointstoreblob`, the fourth library lesson 1 installed. It is the piece that writes checkpoints as blobs."},
{"code": "AZURITE = (\"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;\"\n           \"AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;\"\n           \"BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;\")\nstore = BlobCheckpointStore.from_connection_string(AZURITE, \"checkpoints\")\n", "note": "**Azurite's connection string written out in full**, with its published account name and key. The short form, `UseDevelopmentStorage=true`, is refused by this library, as the run below shows."},
{"code": "client = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\",\n    eventhub_name=\"clicks\", checkpoint_store=store)\nseen = []\n\n", "note": "The only difference from `read_clicks.py` in how the client is made: it is given the store."},
{"code": "def on_event(partition, event):\n    click = json.loads(event.body_as_str())\n    seen.append((partition.partition_id, event.sequence_number, click[\"n\"], click[\"page\"]))\n    partition.update_checkpoint(event)\n\n", "note": "**`update_checkpoint` writes the note**, after the event has been handled. Here handling is appending to a list; in the fraud check it would be the whole check. The order of those two lines is the subject of lesson 24."},
{"code": "listener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\nfor pid, seq, n, page in sorted(seen):\n    print(f\"partition {pid}  seq {seq:>2}  #{n:<2} {page}\")\nprint(f\"{len(seen)} clicks read\")\n", "note": "`starting_position` still says `-1`, and it now applies only to a partition with no checkpoint. Where there is one, the checkpoint wins."}
]}
```

First the short connection string, to see what this library says about it. The `sed` writes a copy
of the program with only that line changed:

```
ana@laptop:~/azure$ sed 's/^store = .*/store = BlobCheckpointStore.from_connection_string("UseDevelopmentStorage=true", "checkpoints")/' checkpointed.py > short.py && python short.py 2>&1 | tail -1
ValueError: Connection string missing required connection details.
```

**The message is about the string, not about Azurite**: the library parses a connection string
itself, with its own copy of the storage code inside it, and that copy does not know the
development shortcut that the newer `azure-storage-blob` and the command line expand for you. The
full form is the same thing written out, and it is what the program uses. Then the real run, twice,
with ten more clicks sent between the two:

```
ana@laptop:~/azure$ python checkpointed.py
partition 0  seq  0  #4  /bakery
partition 0  seq  1  #8  /cart
partition 1  seq  0  #2  /search?q=banana
partition 1  seq  1  #5  /cart
partition 3  seq  0  #1  /fruit
partition 3  seq  1  #3  /fruit/banana
partition 3  seq  2  #6  /cart
partition 3  seq  3  #7  /dairy
partition 3  seq  4  #9  /checkout
partition 3  seq  5  #10 /cart
10 clicks read
ana@laptop:~/azure$ python send_clicks.py 11
sent clicks 11 to 20
ana@laptop:~/azure$ python checkpointed.py
partition 0  seq  2  #14 /bakery
partition 0  seq  3  #18 /cart
partition 1  seq  2  #12 /search?q=banana
partition 1  seq  3  #15 /cart
partition 3  seq  6  #11 /fruit
partition 3  seq  7  #13 /fruit/banana
partition 3  seq  8  #16 /cart
partition 3  seq  9  #17 /dairy
partition 3  seq 10  #19 /checkout
partition 3  seq 11  #20 /cart
10 clicks read
```

**The first run read the ten clicks; the second read only the ten new ones.** The second run started
with the same `starting_position` of `-1`, and found a checkpoint for each partition that had one, so
it started after it. Partition 3 continues at sequence number 6, where click 11 was put.

## What the note looks like

The checkpoints are ordinary blobs, and their content is in their metadata:

```
ana@laptop:~/azure$ az storage blob list -c checkpoints --include m --query "[].[name, metadata.sequencenumber, metadata.offset]" -o tsv
localhost/clicks/$default/checkpoint/0	3	432
localhost/clicks/$default/checkpoint/1	3	448
localhost/clicks/$default/checkpoint/3	11	1600
localhost/clicks/$default/ownership/0	None	None
localhost/clicks/$default/ownership/1	None	None
localhost/clicks/$default/ownership/2	None	None
localhost/clicks/$default/ownership/3	None	None
```

**One blob per partition per consumer group, under the namespace's host, the hub and the group**:
`localhost/clicks/$default/checkpoint/3` says that in group `$default` (the library writes the name
in lower case) partition 3 was finished up to sequence number 11, at offset 1600. Partition 2 has no
checkpoint, because nothing was ever read from it. The `ownership` blobs are the load balancing of
the last section: each one records which running reader owns a partition, and a reader that stops
renewing its claim loses the partition to another. They say `None` here because the program closed
cleanly and gave its partitions back.

On Azure these blobs go into a container of a storage account of yours, and that has two
consequences. **The checkpoints are only as safe as that container**: a lifecycle rule from lesson 5
that deleted them, or a key from lesson 6 in the wrong hands, would send every reader back to
`starting_position`. And **every checkpoint is a write to Blob Storage**, charged like any other.
This program checkpoints after every event, which is twenty writes for twenty clicks; at Quitanda's
hundreds of clicks a second, that is hundreds of storage writes a second, a cost lesson 7 counts.
The usual compromise is to checkpoint every so many events or every few seconds, and to accept that
a reader that crashes will read again whatever it handled since the last one. Lesson 24 makes that
crash happen.
