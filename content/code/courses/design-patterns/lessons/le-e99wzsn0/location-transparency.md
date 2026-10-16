---
title: "Location transparency: why messages and not calls"
version: 1
---

**A sender only ever puts a message in a mailbox, so it cannot tell where the actor behind it
runs.** It may be on the same thread, in another process or on another machine. That is location
transparency, and it is the reason the actor model insists on messages even inside one program. A
design written as actors that tell each other things can be spread across processes later without
rewriting the senders.

The belief this corrects is that messages are a slower, clumsier kind of method call. Inside one
process they are, a little. But a method call assumes things a network cannot give: that the
callee shares your memory, that the call either completes or raises, and that it is quick. A
message assumes none of them. Code written against the weaker promise keeps working when the
stronger one is taken away.

The program below moves the shelf into a separate operating-system process. The senders hold a
`Ref`, an address with one method, `tell`; they never see the shelf itself.

```schooling-example
{"language": "python", "file": "location.py", "parts": [
 {"code": "# location.py\nimport multiprocessing as mp\nimport os\nimport threading\nfrom dataclasses import dataclass", "note": "`multiprocessing` starts other Python processes and connects them with pipes."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n\n\n@dataclass(frozen=True)\nclass Available:\n    title: str", "note": "The same message classes as before. To cross into another process a message is pickled, turned into bytes, and rebuilt on the other side."},
 {"code": "\n\ndef shelf(inbox, outbox) -> None:\n    copies = {\"Iracema\": 1}\n    while (message := inbox.recv()) is not None:\n        match message:\n            case Lend(title=title):\n                copies[title] -= 1\n            case Available(title=title):\n                outbox.send((title, copies[title], os.getpid()))", "note": "The shelf is a function running in its own process, with its own memory. Its `copies` exists only there. It reads messages from one pipe and writes answers, with its process id, to another."},
 {"code": "\n\nclass Ref:\n    def __init__(self, inbox):\n        self._inbox = inbox\n\n    def tell(self, message) -> None:\n        self._inbox.send(message)", "note": "A `Ref` is what senders hold: the sending end of the shelf's pipe and nothing else. There is no attribute to reach into, because the shelf's state is in another address space."},
 {"code": "\n\nif __name__ == \"__main__\":\n    ctx = mp.get_context(\"spawn\")\n    shelf_inbox, to_shelf = ctx.Pipe(duplex=False)\n    from_shelf, shelf_outbox = ctx.Pipe(duplex=False)\n    process = ctx.Process(target=shelf, args=(shelf_inbox, shelf_outbox))\n    process.start()", "note": "The `spawn` method starts a fresh interpreter for the shelf, the behaviour Windows and macOS have by default, so the run is the same on every system. `Pipe(duplex=False)` returns a receiving end and a sending end."},
 {"code": "\n    ref = Ref(to_shelf)\n    ref.tell(Lend(\"Iracema\"))\n    ref.tell(Available(\"Iracema\"))\n    title, copies, pid = from_shelf.recv()\n    print(f\"{title}: {copies} left, answered by another process: {pid != os.getpid()}\")", "note": "A tell, then an ask built by hand: send *Available*, then wait on the answer pipe."},
 {"code": "\n    try:\n        ref.tell(threading.Lock())\n    except TypeError as err:\n        print(\"a lock cannot be a message:\", err)\n    ref.tell(None)\n    process.join()\n    print(\"shelf process exit code:\", process.exitcode)", "note": "A lock is shared state by definition, and it cannot be turned into bytes, so it cannot be a message. `None` tells the shelf to stop."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 location.py
Iracema: 0 left, answered by another process: True
a lock cannot be a message: cannot pickle '_thread.lock' object
shelf process exit code: 0
```

The answer came from another process, with its own memory, and the sending code is the same
`tell` as in section 04. The lock was refused at the moment of sending, with Python's own reason:
`cannot pickle '_thread.lock' object`. **The rule of section 03, that messages are values, stops
being advice here and becomes a property the transport enforces.** Something that only makes sense
as shared memory cannot travel.

## What the network adds

Moving an actor to another machine keeps the shape of the code and changes what can go wrong. A
message to a remote actor can be lost on the way, or the machine can restart with the message
unread. A reply can be lost after the work was done. So remote actor systems state what they
guarantee, and by default it is little. Akka delivers a message *at most once*,
with no acknowledgement unless you build one. Erlang promises only that messages from one process to
another arrive in the order sent, if they arrive.

This is why the patterns of the earlier sections matter more at a distance:

| on one machine | across a network |
|---|---|
| a tell always reaches the mailbox | a tell may be lost; important messages need an acknowledgement and a retry |
| an ask without a timeout hangs only on a bug | an ask without a timeout hangs whenever a reply is lost |
| a crash is seen at once by the supervisor | a silent machine looks the same as a slow one, so failure is detected by timeout |
| a duplicate message is a bug | a retried message arrives twice, so handlers must be idempotent |

`architecture` lessons 9 and 11 covered eventual consistency and retries between services, and the
same reasoning applies to actors spread over a network. What the actor model contributes is that
the code was already written for it: no call assumed shared memory, no sender assumed an instant
answer, and every actor already had a supervisor to restart it.

## Transparent, and still a network

The phrase is sometimes read as "the network does not matter", and the table above says otherwise.
The honest reading is narrower: **the sending code does not change; the failure handling does.** A
system designed as if every actor were local, with asks and no timeouts and messages assumed to
arrive, will move to many machines and fail in all the ways the right-hand column lists. Designing
for the right-hand column from the start costs little on one machine and is what makes the move
possible at all.

Microsoft's Orleans takes the idea furthest. Its *virtual actors*, called grains, are addressed by
an identity such as a member number, and the runtime decides which server hosts each one, starting
it on first use and moving it when a server leaves. The caller never learns where the grain lives,
and does not need to.
