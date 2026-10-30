---
title: A sink that does not mind seeing an event twice
version: 1
---

**An operation is idempotent when doing it twice leaves the same result as doing it once.** "Add
990 to the total" is not: twice is 1,980. "The payment for order `o-303` is 990" is: written twice,
it still says 990. At-least-once delivery is harmless to a sink whose writes are of the second kind,
and the whole of this section is how to turn the first kind into the second.

## A key that names the payment, not the moment

**The `upsert` mode of `totals.py` writes each payment as a blob named by its order id**, overwriting
whatever is there, and works out the totals at the end by adding up the blobs. The same crash, the
same restart:

```
ana@laptop:~/azure$ python totals.py upsert 5
seq 0  o-301 c-17   4590  written under its order id
seq 1  o-302 c-02  12800  written under its order id
seq 2  o-303 c-17    990  written under its order id
  checkpoint at seq 2
seq 3  o-303 c-17    990  written under its order id
seq 4  o-304 c-05   2350  written under its order id
  crash
ana@laptop:~/azure$ python totals.py upsert
seq 3  o-303 c-17    990  written under its order id
seq 4  o-304 c-05   2350  written under its order id
seq 5  o-305 c-02   1500  written under its order id
  checkpoint at seq 5
seq 6  o-306 c-17   7200  written under its order id
totals: c-02 14300  c-05 2350  c-17 12780
```

**The replay happened exactly as before**: the second run started after the checkpoint at sequence
number 2 and handled 3 and 4 again. This time it did no harm. The second copy of `o-303` and the
replayed `o-304` were written over blobs of the same name with the same content, and the producer's
duplicate went to the same place as the original. **The totals are the correct ones**: 12,780, 14,300
and 2,350. Nothing in the reader detected a duplicate; the shape of the write made detecting one
unnecessary.

The idea carries over to every sink Quitanda has. In Azure SQL Database it is a `MERGE` or an
insert into a table whose primary key is the order id, where the second insert is refused by the key.
In Cosmos DB it is an upsert of a document whose `id` is the order id, the operation the program of
lesson 1 used. Microsoft documents the Stream Analytics output to Cosmos DB as writing that way, by
the document's id, which is what makes that output safe to retry. In the lake it is a file named by
what it contains, such as the range of sequence numbers it holds, rather than by the time it was
written: a file named by the time gets a new name on every replay and is in the lake twice.

## Refusing the second write instead

**Overwriting is one way to be idempotent; refusing is the other.** Blob Storage can be told to
create a blob only if no blob of that name exists, with the condition `If-None-Match: *`, which the
command line spells `--if-none-match '*'`. Writing `o-301` again that way, after the run above:

```
ana@laptop:~/azure$ echo 4590 > o-301.json && az storage blob upload -c sink-upsert -n o-301 -f o-301.json --if-none-match '*' 2>&1 | tail -2
ErrorCode:BlobAlreadyExists
If you want to overwrite the existing one, please add --overwrite in your command.
```

**Refused, with `BlobAlreadyExists`**, and a reader that catches that error and moves on has handled
the duplicate by doing nothing. The two ways differ when the second copy is not identical: an
overwrite keeps the last version written, a refusal keeps the first. For a payment, which never
changes, either is right; for a record that is corrected after it is sent, the choice is a decision
about which copy is the truth.

## An overwrite, not an increment

**Where a sink must hold a running number, store what it is computed from.** The `add` mode kept a
total and incremented it, which is the one shape no replay survives. The `upsert` mode keeps the
payments and computes the total when asked. That costs a sum over the payments at read time, which
for Quitanda is a few thousand rows a customer, and buys a total that is right however many times
the stream is replayed.

**And design the events to make the sink easy.** An event that carries the new state, "the order
`o-303` is paid, 990 cents", is idempotent to apply; an event that carries a change, "add 990 to
`c-17`", is not. When the producer is yours to design, the first kind is the cheaper fix by far.
