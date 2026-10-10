---
title: "Building one: a thread and a queue"
version: 1
---

**An actor fits in twenty lines of Python.** A `queue.Queue` is the mailbox, a thread takes one
message at a time out of it, and the thread calls a method for each message. Everything the
libraries add, from schedulers to clustering, sits around that loop. Writing the loop yourself once
makes the rules of the last section concrete, and it shows where each guarantee comes from.

The example is the shelf of section 02 again, rebuilt as an actor. The two desks still run on two
threads at the same moment, and the pause between check and act is still there.

```schooling-example
{"language": "python", "file": "actor.py", "parts": [
 {"code": "# actor.py\nimport queue\nimport threading\nimport time\nfrom dataclasses import dataclass\n\n_STOP = object()", "note": "`_STOP` is a private object that can never be confused with a real message, because nothing outside this file can make another one like it."},
 {"code": "\n\nclass Actor:\n    def __init__(self):\n        self._mailbox: queue.Queue = queue.Queue()\n        self._thread = threading.Thread(target=self._run)\n        self._thread.start()\n\n    def tell(self, message) -> None:\n        self._mailbox.put(message)\n\n    def stop(self) -> None:\n        self._mailbox.put(_STOP)\n        self._thread.join()", "note": "The constructor makes the mailbox and starts the thread. `tell` is the only way in: it puts a message in the queue and returns at once, without waiting for the actor to read it. `stop` sends `_STOP` and waits for the thread to finish what is already queued."},
 {"code": "\n    def _run(self) -> None:\n        while (message := self._mailbox.get()) is not _STOP:\n            self.receive(message)\n\n    def receive(self, message) -> None:\n        raise NotImplementedError", "note": "The loop. `queue.Queue.get` blocks until a message arrives, and the next one is not taken until `receive` has returned, which is the whole of \"one message at a time\". A subclass writes `receive` and nothing else."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n    desk: str\n\n\n@dataclass(frozen=True)\nclass GiveBack:\n    title: str\n\n\n@dataclass(frozen=True)\nclass Report:\n    pass", "note": "Messages are frozen dataclasses: values that cannot change after they are sent."},
 {"code": "\n\nclass Shelf(Actor):\n    def __init__(self, copies: dict[str, int]):\n        self._copies = dict(copies)\n        self._lent = self._refused = 0\n        super().__init__()\n\n    def receive(self, message) -> None:\n        match message:\n            case Lend(title=title):\n                if self._copies.get(title, 0) > 0:\n                    time.sleep(0.01)\n                    self._copies[title] -= 1\n                    self._lent += 1\n                    print(f\"{title}: lent, {self._copies[title]} left\")\n                else:\n                    self._refused += 1\n                    print(f\"{title}: refused, none left\")\n            case GiveBack(title=title):\n                self._copies[title] += 1\n                print(f\"{title}: back, {self._copies[title]} left\")\n            case Report():\n                print(f\"lent {self._lent}, refused {self._refused}, shelf {self._copies}\")", "note": "The shelf's state is set before `super().__init__()` starts the thread, so the thread never sees a half-built actor. `match` picks the case by the class of the message. The `time.sleep` is the same staged pause as in `shared.py`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf({\"Iracema\": 1})\n    desks = [threading.Thread(target=shelf.tell, args=(Lend(\"Iracema\", name),))\n             for name in (\"north desk\", \"south desk\")]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    shelf.tell(GiveBack(\"Iracema\"))\n    shelf.tell(Report())\n    shelf.stop()", "note": "Two desk threads tell the shelf at the same moment. Once both have sent, the main thread returns a copy and asks for a report, then stops the shelf."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 actor.py
Iracema: lent, 0 left
Iracema: refused, none left
Iracema: back, 1 left
lent 1, refused 1, shelf {'Iracema': 1}
```

One lend, one refusal, and the shelf back at one copy after the return. **The pause that broke
`shared.py` changes nothing here**, because no other code can run the check-and-act while the shelf
is asleep in the middle of it: the second *Lend* is waiting in the mailbox. Which desk got the book
depends on which `tell` reached the queue first, and the program does not print the desk's name for
that reason. The four lines above are the same on every run.

## Where each guarantee comes from

| guarantee | what provides it |
|---|---|
| one message at a time | a single thread runs `_run`, and `_run` calls `receive` in a loop |
| private state | only `receive` touches `_copies`, and `receive` runs only on the actor's thread |
| senders never wait | `tell` is a `put` on an unbounded queue |
| order from one sender | `queue.Queue` is first in, first out |
| safe puts from many threads | `queue.Queue` locks internally, which is its job |

The third row has a cost you met in lesson 16: an unbounded mailbox is an unbounded queue. A shelf
that handles ten messages a second and receives fifty will hold a growing backlog until memory runs
out. Akka's default mailbox is unbounded for the same reason this one is, convenience, and Akka
offers a bounded mailbox for the actors that need backpressure; here it would be
`queue.Queue(maxsize=n)`. Erlang leaves the mailbox unbounded
and expects you to design so that it does not fill.

The second row is a promise Python cannot enforce. Nothing stops code in the main thread from
reading `shelf._copies`, and if it did so while the actor was running it would be back in section
02's world. Erlang enforces it by giving each process its own memory. On the JVM, Akka hands
senders an `ActorRef` rather than the actor object, so there is no reference to the fields to
misuse. Section 07 does the same thing here with a separate process.

## Ordering between senders

The fourth row says *from one sender*. If the north desk sends *Lend* and then *GiveBack*, the
shelf receives them in that order. If the north desk sends *Lend* and the south desk sends
*GiveBack* at the same time, either may arrive first, and the actor model makes no promise about
which. A design that needs two senders' messages in a particular order has to make one of them
wait for the other, which in practice means asking, the subject of the next section.

## One actor or many

The shelf here holds every title. A busy library could instead have one actor per title, or per
branch, and that choice is the actor version of choosing a lock's scope. One actor is simple and
becomes a queue everybody waits in; one per title spreads the load and makes a question about two
titles at once harder, because no single actor knows both. Lesson 12's aggregates face the same
decision for transactions, and the same rule of thumb fits: draw the boundary around what has to
be consistent together, and nothing more.
