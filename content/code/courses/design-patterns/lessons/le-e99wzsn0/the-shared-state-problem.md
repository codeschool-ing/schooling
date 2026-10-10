---
title: "The shared-state problem: two desks, one copy"
version: 1
---

**When two threads can read and write the same data, every rule about that data has to hold at
every instant between any two of their steps.** Most rules do not. "Lend a copy only if one is on
the shelf" is two steps, a check and an act, and a second thread can run between them. That gap is
the whole problem this lesson is about, and the actor model is one way of closing it.

The common belief is that this is rare: two threads would have to arrive within microseconds of
each other. In a library with one desk, maybe. A library system serves a desk at each entrance, the
website, the self-service kiosks and the overnight job that renews loans, and they all ask about
the same few popular books at the busiest hours. Rare per request is frequent per day.

Make `~/patterns/actors` and work there:

```sh
mkdir -p ~/patterns/actors
cd ~/patterns/actors
```

Here are two desks lending the last copy of *Iracema* at the same moment:

```schooling-example
{"language": "python", "file": "shared.py", "parts": [
 {"code": "# shared.py\nimport threading\nimport time\n\ncopies = {\"Iracema\": 1}\noutcomes: list[str] = []", "note": "One copy of *Iracema*, in a dictionary any thread can reach. `outcomes` collects what each desk did, so that the printing happens after both have finished."},
 {"code": "\n\ndef lend(desk: str, title: str) -> None:\n    if copies[title] > 0:          # check\n        time.sleep(0.01)           # the other desk gets the processor here\n        copies[title] -= 1         # act\n        outcomes.append(f\"{desk} lent {title}\")\n    else:\n        outcomes.append(f\"{desk} refused {title}\")", "note": "The rule, written the obvious way: check that a copy is there, then take it. The pause between the two steps is staged, so that the run shows every time what would otherwise happen once in a long while."},
 {"code": "\n\ndesks = [threading.Thread(target=lend, args=(name, \"Iracema\")) for name in (\"north desk\", \"south desk\")]\nfor d in desks:\n    d.start()\nfor d in desks:\n    d.join()\nfor line in sorted(outcomes):\n    print(line)\nprint(\"copies of Iracema:\", copies[\"Iracema\"])", "note": "Two threads, one per desk, started together and waited for. The outcomes are sorted before printing so the two lines come out in the same order whichever desk finished first."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 shared.py
north desk lent Iracema
south desk lent Iracema
copies of Iracema: -1
```

Both desks lent the book and the shelf now holds minus one copy. Each desk did exactly what the
code says. One desk checked, saw one copy and paused; the other checked, saw the same one copy and
paused; then each took it. **No line of `lend` is wrong; the bug lives between two
correct lines.** Without the `time.sleep`, the same thing happens whenever the operating system
switches threads at that point, which is rarely enough to pass every test and often enough to reach
production.

## Three ways out

There are three families of answer, and the next lessons of this course take one each.

| | the idea | where in the course |
|---|---|---|
| lock | let only one thread at a time into the check-and-act | lesson 18 |
| immutability | never change shared data; build new values instead | lesson 15, and lesson 18 again |
| isolation | do not share the data at all; send messages to the one thread that owns it | this lesson |

A lock keeps the shared dictionary and protects it. It works, and it puts a duty on every piece of
code that touches the data: take the lock, and take it in the same order as everybody else, or two
threads can each hold one lock and wait for the other's for ever. Lesson 18 shows both the fix and
the deadlock. Immutability removes the writes, which removes the race; it suits values better than
a shelf whose whole point is to change.

**Isolation removes the sharing.** The copies of *Iracema* belong to one owner, and nobody else can
read or write them. A desk that wants a copy sends the owner a message saying so, and the owner
deals with its messages one at a time. There is no gap between check and act, because only one
piece of code ever checks or acts, and it does nothing else in between.

That owner is an actor. Carl Hewitt, Peter Bishop and Richard Steiger described the model in 1973,
long before multi-core machines made it fashionable, and it has since become the core of Erlang,
of Akka on the JVM and of Microsoft's Orleans. The next section says what an actor is; section 04
builds one out of a thread and a queue.

## What a test would have seen

Run `shared.py` without the `sleep` and it will almost certainly print one lend, one refusal and
zero copies, every time you try it. A test that runs the two desks once passes. That is the
dangerous property of shared-state bugs, and it is why this course states the fix as a design rule:
**if only one thread can touch the data, the interleaving
that breaks it cannot happen**, whatever the scheduler decides.
