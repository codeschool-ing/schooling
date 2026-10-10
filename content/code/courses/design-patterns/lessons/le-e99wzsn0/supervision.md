---
title: "Supervision: let it crash, and start again clean"
version: 1
---

**In an actor system, an actor that meets a situation it was not written for does not try to
recover; it fails, and another actor, its supervisor, decides what happens next.** The usual
decision is to replace it with a fresh instance, built from scratch, and let it carry on with the
next message. Erlang's community calls this *let it crash*, and it sounds reckless until you look at
what the alternative usually is.

The alternative is defensive code: a `try` around every operation, a fallback for every value that
might be missing, a flag for every half-finished state. Each guard is reasonable alone. Together they
make code that keeps running in states nobody designed, where the shelf believes it holds minus one
copy and every later decision builds on that. A crash stops at the first wrong state, and a fresh
instance starts from a known good one. **Recovery is moved out of the code that failed and into
code whose only job is recovery.**

Without a supervisor, `actor.py` from section 04 shows the danger of the other extreme. If
`receive` raises, the exception ends `_run`, the thread dies with a traceback, and every message
after it sits in the mailbox for ever. Senders keep calling `tell`, which still succeeds, because a
`put` on a queue does not care whether anybody will read it. That is a silent failure: the shelf
looks alive to everybody who talks to it.

Here is a supervisor. To keep the program short, it shares a thread with the shelf it watches and
calls the shelf's `receive` itself; in Erlang and Akka the two are separate actors and the
supervisor learns of the crash from a message.

```schooling-example
{"language": "python", "file": "supervision.py", "parts": [
 {"code": "# supervision.py\nimport queue\nimport threading\nfrom dataclasses import dataclass\n\nCATALOGUE = {\"Iracema\": 2, \"Vidas Secas\": 1}\n_STOP = object()", "note": "The catalogue is where a fresh shelf gets its state. Restarting means starting from here again."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n\n\n@dataclass(frozen=True)\nclass GiveBack:\n    title: str"},
 {"code": "\n\nclass Shelf:\n    def __init__(self):\n        self.copies = dict(CATALOGUE)\n\n    def receive(self, message) -> None:\n        match message:\n            case Lend(title=title):\n                self.copies[title] -= 1\n            case GiveBack(title=title):\n                self.copies[title] += 1\n        print(f\"  {message} -> {self.copies}\")", "note": "The worker has no error handling at all. Giving back a title the shelf never held raises `KeyError`, as a dictionary does for a missing key, and that is the bug this program feeds it."},
 {"code": "\n\nclass Supervisor:\n    def __init__(self, make_child, max_restarts: int):\n        self._make_child, self._max = make_child, max_restarts\n        self._mailbox: queue.Queue = queue.Queue()\n        self._thread = threading.Thread(target=self._run)\n        self._thread.start()\n\n    def tell(self, message) -> None:\n        self._mailbox.put(message)\n\n    def stop(self) -> None:\n        self._mailbox.put(_STOP)\n        self._thread.join()", "note": "The supervisor owns the mailbox. Senders talk to it exactly as they talked to the actor in section 04: `tell` and `stop`."},
 {"code": "\n    def _run(self) -> None:\n        child, restarts = self._make_child(), 0\n        while (message := self._mailbox.get()) is not _STOP:\n            if child is None:\n                print(f\"  {message} not handled: the shelf is down\")\n                continue\n            try:\n                child.receive(message)\n            except Exception as err:\n                print(f\"  {message} crashed the shelf: {type(err).__name__} {err}\")\n                if restarts == self._max:\n                    print(f\"  {restarts} restarts already; giving up and escalating\")\n                    child = None\n                else:\n                    restarts += 1\n                    child = self._make_child()\n                    print(f\"  restarted with fresh state ({restarts} of {self._max})\")", "note": "For each message, the supervisor hands it to the current child. When the child raises, it says so, builds a new child with `make_child`, and goes on to the next message. After `max_restarts`, it stops trying and refuses everything that follows, saying so for each message."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Supervisor(Shelf, max_restarts=2)\n    for message in [Lend(\"Iracema\"), GiveBack(\"Macunaíma\"), Lend(\"Iracema\"),\n                    GiveBack(\"O Cortiço\"), GiveBack(\"Macunaíma\"), Lend(\"Vidas Secas\")]:\n        shelf.tell(message)\n    shelf.stop()", "note": "Six messages, three of them bad."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 supervision.py
  Lend(title='Iracema') -> {'Iracema': 1, 'Vidas Secas': 1}
  GiveBack(title='Macunaíma') crashed the shelf: KeyError 'Macunaíma'
  restarted with fresh state (1 of 2)
  Lend(title='Iracema') -> {'Iracema': 1, 'Vidas Secas': 1}
  GiveBack(title='O Cortiço') crashed the shelf: KeyError 'O Cortiço'
  restarted with fresh state (2 of 2)
  GiveBack(title='Macunaíma') crashed the shelf: KeyError 'Macunaíma'
  2 restarts already; giving up and escalating
  Lend(title='Vidas Secas') not handled: the shelf is down
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-restarts\" aria-label=\"A timeline of supervision.py. Six messages arrive left to right: Lend Iracema, GiveBack Macunaíma, Lend Iracema, GiveBack O Cortiço, GiveBack Macunaíma, Lend Vidas Secas. Below them, the life of each shelf instance is a bar. Shelf 1 handles the first message and crashes on the second; restart 1 starts shelf 2, which handles the third and crashes on the fourth; restart 2 starts shelf 3, which crashes on the fifth, and the supervisor gives up, so the sixth is not handled. Underneath, the copies of Iracema after each loan: 1 after the first, and 1 again after the second, because the fresh shelf forgot the first loan.\"><text x=\"10.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">message</text><text x=\"10.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">instance</text><text x=\"10.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Iracema</text><text x=\"190.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"190.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Iracema</text><path d=\"M190.0 56.0 L190.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"285.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Macunaíma</text><path d=\"M285.0 56.0 L285.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"380.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Iracema</text><path d=\"M380.0 56.0 L380.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"475.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"475.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">O Cortiço</text><path d=\"M475.0 56.0 L475.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"570.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"570.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Macunaíma</text><path d=\"M570.0 56.0 L570.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"665.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"665.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Vidas Secas</text><path d=\"M665.0 56.0 L665.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"98.0\" width=\"145.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"212.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">shelf 1</text><rect x=\"285.0\" y=\"98.0\" width=\"190.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">shelf 2</text><rect x=\"475.0\" y=\"98.0\" width=\"95.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"522.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">shelf 3</text><rect x=\"570.0\" y=\"98.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">down</text><text x=\"285.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">crash</text><text x=\"475.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">crash</text><text x=\"570.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">crash</text><text x=\"285.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restart 1</text><text x=\"475.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restart 2</text><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">gives up</text><text x=\"665.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">refused</text><text x=\"190.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"380.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"380.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">not 0: the first loan was forgotten</text></svg>", "caption": "Each restart starts from the catalogue. The shelf survives three bad messages, and the second loan shows the price: the fresh shelf knows nothing of the first."}
```

## What the run shows

The first loan takes *Iracema* from two copies to one. Giving back *Macunaíma*, which the shelf
never had, crashes it, and the supervisor starts a fresh shelf. The next loan of *Iracema* leaves
**one copy, not zero**: the fresh shelf began from the catalogue and knows nothing of the first
loan. The second bad return crashes the shelf again and the supervisor restarts it a second time.
The third crash finds the limit reached, so the supervisor gives up, and the loan of *Vidas Secas*
is refused out loud.

Two lessons sit in those nine lines. The first is that a restart is not free: **fresh state means
forgotten state**, and anything that must survive a crash cannot live only inside the actor. The
shelf's copies belong in a database or, as in lesson 9, in an event log the new instance replays
when it starts. Erlang programmers divide state the same way: what can be rebuilt lives in the
process, and what cannot is written somewhere a restart cannot touch.

The second is that restarting has to stop. A message that crashes the shelf will crash every fresh
shelf too, and a supervisor that restarted for ever would spin on it. Erlang's supervisors count
restarts within a time window, for instance at most three in five seconds, and past that limit the
supervisor itself fails, passing the problem to *its* supervisor. Here, giving up only prints a
line. In a real system it would escalate to the next level up, which might restart a whole group of
actors, or stop the application and let the operating system or the container platform start it
again.

## A tree of supervisors

Because supervisors are actors, they can be supervised, and an application becomes a tree: a root
supervisor over a few subsystems, each subsystem's supervisor over its workers. A failure travels
up the tree only as far as the first supervisor that can deal with it. Erlang's OTP names the usual
strategies: *one for one* restarts only the child that failed, *one for all* restarts all of a
supervisor's children when one fails, for children that cannot work without each other, and *rest
for one* restarts the failed child and every child started after it.

## When not to let it crash

The slogan is about unexpected failures, the ones a programmer did not foresee. A member typing an
unknown title is expected, and the shelf should answer *no such title* as an ordinary message. A
crash there would turn a typo into lost state and a restart counted against the limit. Validate at
the edges, where input arrives; let the inside crash on what should be impossible. Lesson 15's
errors-as-values and this section's crashes divide the work along exactly that line.
