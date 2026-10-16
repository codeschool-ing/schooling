---
title: "Tell and ask: getting an answer back"
version: 1
---

**There are two ways to talk to an actor.** Tell sends a message and carries on; ask sends a
message carrying a reply address and waits for an answer to arrive there. Tell is
the natural one; the actor model has nothing else built in. Ask is built out of tell, and it is
where most of the surprises in actor code come from.

The first instinct of anybody used to objects is to add a method that returns the count:
`shelf.available("Iracema")`. It would run on the caller's thread and read `_copies` while the
actor's own thread might be changing it, which is the race of section 02 again. The answer has to
come from the actor's thread, so it has to come back as a message.

Python's standard library already has a container for a value that will arrive later:
`concurrent.futures.Future`. One thread waits on `result()`; another calls `set_result()` and the
waiter wakes up with the value. That is a one-shot mailbox, and it is all ask needs.

```schooling-example
{"language": "python", "file": "ask.py", "parts": [
 {"code": "# ask.py\nfrom concurrent.futures import Future\nfrom dataclasses import dataclass\n\nfrom actor import Actor, Lend, Shelf", "note": "`actor.py` from the last section is imported, so the shelf, its messages and its mailbox are the ones you already ran."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Available:\n    title: str\n    reply: Future\n\n\ndef ask(actor: Actor, make_message, timeout: float = 1.0):\n    reply: Future = Future()\n    actor.tell(make_message(reply))\n    return reply.result(timeout=timeout)", "note": "A question carries its own reply address, a `Future`. `ask` makes the future, tells the actor a message built around it, and waits for the answer for at most `timeout` seconds."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Recount:\n    title: str\n\n\nclass CountingShelf(Shelf):\n    def receive(self, message) -> None:\n        match message:\n            case Available(title=title, reply=reply):\n                reply.set_result(self._copies.get(title, 0))\n            case Recount(title=title):\n                try:\n                    n = ask(self, lambda r: Available(title, r), timeout=0.5)\n                    print(f\"recount: {n}\")\n                except TimeoutError:\n                    print(\"recount: the shelf asked itself and gave up after 0.5 s\")\n            case _:\n                super().receive(message)", "note": "`Available` is answered by setting the future's result, on the actor's thread, from state only that thread touches. `Recount` is a mistake on purpose: while handling it, the shelf asks itself a question. Everything else goes to the parent class."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = CountingShelf({\"Iracema\": 1})\n    print(\"asked:\", ask(shelf, lambda r: Available(\"Iracema\", r)))\n    shelf.tell(Lend(\"Iracema\", \"north desk\"))\n    print(\"asked:\", ask(shelf, lambda r: Available(\"Iracema\", r)))\n    shelf.tell(Recount(\"Iracema\"))\n    shelf.stop()", "note": "The main thread asks, lends, asks again, and finally sends the recount."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 ask.py
asked: 1
Iracema: lent, 0 left
asked: 0
recount: the shelf asked itself and gave up after 0.5 s
```

The first answer is 1. Then the lend is handled and the second answer is 0, and that order is
guaranteed: the main thread's *Available* went into the mailbox after its *Lend*, and the mailbox
is first in, first out. **An ask is ordered after everything the same sender told before it**,
which is what makes the pattern "tell, then ask" safe to rely on.

## The actor that waited for itself

The last line is the trap. While the shelf was handling *Recount*, it sent itself *Available* and
waited for the reply. But the reply can only be written by the shelf's thread, and that thread was
the one waiting. Nothing would ever answer. Without the timeout, the shelf would sit in `result()`
for ever and every message behind *Recount* would wait with it: one desk's question would have
stopped the whole library.

The same deadlock happens with two actors that ask each other, A waiting on B while B waits on A,
and it is the strongest reason the libraries steer you away from ask. Akka's `ask` returns a
future rather than blocking, and its documentation treats blocking inside an actor as a bug.
Erlang's `gen_server:call` takes a timeout, five seconds by default, and crashes the caller when it
expires. **A timeout does not fix the design; it turns a hang into an error somebody can see.**
Notice also that the shelf's question did not vanish when the wait gave up. It was still in the
mailbox and was answered after *Recount* returned, to a future that nobody was holding.

## Prefer telling

Most designs that reach for ask can be turned round. Instead of the desk asking the shelf whether
a copy is free and then telling it to lend, the desk tells the shelf *lend Iracema to Bia, and
tell me how it went*, giving its own address. The shelf decides in one step, with no gap between
check and act, and sends *Lent* or *Refused* back. The desk handles the answer when it arrives, as
another message, without blocking anybody in between.

| | tell | ask |
|---|---|---|
| the sender | carries on immediately | waits, up to a timeout |
| the answer | none, or a later message to the sender | a value from a future |
| inside an actor | always safe | can deadlock, and blocks every message queued behind it |
| suits | commands, events, replies | the edge of the system, where non-actor code needs a value |

The last row is where ask belongs: a web handler or a test that is not itself an actor and needs a
value now. Between actors, tell with a reply address keeps every actor free to handle its next
message.

## In your language

A JavaScript `Promise`, a Java `CompletableFuture` and a Go channel of size one are each a reply
address in the sense used here. Go programmers write ask as "send a request that carries a `chan`
for the answer, then receive from it", which is exactly `ask` above with a channel in place of the
future. The deadlock is the same in all of them: a goroutine that sends a request to itself and
waits on the reply channel blocks for ever, and the Go runtime reports "all goroutines are asleep"
only when every goroutine is stuck.
