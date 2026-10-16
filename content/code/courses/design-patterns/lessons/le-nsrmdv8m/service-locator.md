---
title: The service locator, and what it hides
version: 1
---

**A service locator is a global registry that a class asks for its collaborators when it needs
them, and it looks so much like injection that it is often mistaken for it.** Both keep `new
SmtpNotifier()` out of the job. The difference is the direction: with injection the object is
handed what it needs, and with a locator the object goes and fetches it. That one reversal undoes
most of what the earlier sections bought.

The container of the last section can be used either way. Passed to the composition root and
asked once, at start-up, for the top object, it is a wiring tool. Imported into every class and
asked from inside methods, it is a service locator, whatever the documentation calls it.

## A job that fetches

```schooling-example
{"language": "python", "file": "locator.py", "parts": [
 {"code": "# locator.py\nfrom datetime import date\n\nfrom overdue import ListedLoans, Loan, PrintNotifier\n\n\nclass Services:\n    _registry = {}\n\n    @classmethod\n    def provide(cls, key: str, service) -> None:\n        cls._registry[key] = service\n\n    @classmethod\n    def get(cls, key: str):\n        return cls._registry[key]", "note": "The registry is a class with a dictionary and two methods. Being global is the point: any code anywhere can reach it."},
 {"code": "\n\nclass LocatedNotices:\n    DAILY_FINE = 50  # cents\n\n    def send_all(self) -> int:\n        sent = 0\n        for loan in Services.get(\"loans\").open_loans():\n            late = (Services.get(\"clock\").today() - loan.due).days\n            if late > 0:\n                Services.get(\"notifier\").send(\n                    loan.member, f\"'{loan.title}' is {late} days late\")\n                sent += 1\n        return sent", "note": "The job's constructor takes nothing. Its three dependencies are still there; they have moved inside the method, where only somebody reading every line will find them."},
 {"code": "\n\nif __name__ == \"__main__\":\n    Services.provide(\"loans\", ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))]))\n    Services.provide(\"notifier\", PrintNotifier())\n    notices = LocatedNotices()\n    print(\"built:\", type(notices).__name__)\n    notices.send_all()", "note": "Set-up registers two services and forgets the clock. Building the job succeeds anyway, because nothing about `LocatedNotices()` says a clock is needed."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 locator.py
built: LocatedNotices
Traceback (most recent call last):
  File "/home/ana/patterns/injection/locator.py", line 39, in <module>
    notices.send_all()
  File "/home/ana/patterns/injection/locator.py", line 25, in send_all
    late = (Services.get("clock").today() - loan.due).days
            ^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/injection/locator.py", line 16, in get
    return cls._registry[key]
           ~~~~~~~~~~~~~^^^^^
KeyError: 'clock'
```

The object was built and announced. The failure came later, from the middle of the loop, as a
`KeyError` naming a string. In this program the two are a couple of lines apart; in a service
it is the gap between deployment and the first overdue loan.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-locator\" aria-label=\"Two versions of the same job side by side. On the left, injected: OverdueNotices has a constructor that takes loans, notifier and clock, and three boxes, LoanStore, Notifier and Clock, each send an arrow up into it, labelled handed in, visible in the signature. On the right, located: LocatedNotices has a constructor that takes nothing; an arrow goes from it down to a Services registry, and from the registry to three keys, loans, notifier and clock. The clock key is drawn dashed in amber and labelled never provided, found only when send_all runs.\"><defs><marker id=\"l05-locator-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">injected</text><rect x=\"55.0\" y=\"34.0\" width=\"240.0\" height=\"57.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"44.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M55.0 55.8 L295.0 55.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"63.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">__init__(loans, notifier, clock)</text><text x=\"63.0\" y=\"80.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">send_all()</text><rect x=\"30.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">LoanStore</text><path d=\"M75.0 163.0 L75.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"130.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Notifier</text><path d=\"M175.0 163.0 L175.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"163.0\" width=\"90.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Clock</text><path d=\"M275.0 163.0 L275.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"175.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">handed in, visible in the signature</text><path d=\"M360.0 12.0 L360.0 258.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"545.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">located</text><rect x=\"425.0\" y=\"34.0\" width=\"240.0\" height=\"57.3\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"44.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">LocatedNotices</text><path d=\"M425.0 55.8 L665.0 55.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"433.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">__init__()</text><text x=\"433.0\" y=\"80.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">send_all()</text><rect x=\"485.0\" y=\"112.0\" width=\"120.0\" height=\"43.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"122.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.0\" font-weight=\"600\" fill=\"var(--paper)\">Services</text><path d=\"M485.0 133.8 L605.0 133.8\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"493.0\" y=\"144.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.0\" fill=\"var(--paper)\">get(key)</text><path d=\"M545.0 91.3 L545.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"555.0\" y=\"103.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">from inside send_all</text><rect x=\"400.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loans</text><path d=\"M545.0 155.6 L545.0 165.6 L440.0 165.6 L440.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notifier</text><path d=\"M545.0 155.6 L545.0 165.6 L540.0 165.6 L540.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><rect x=\"600.0\" y=\"184.0\" width=\"80.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">clock</text><path d=\"M545.0 155.6 L545.0 165.6 L640.0 165.6 L640.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l05-locator-dp-ah-paper-dim)\"></path><text x=\"640.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">never provided:</text><text x=\"640.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">found when send_all runs</text></svg>", "caption": "The same three dependencies, declared on the left and fetched on the right. Only the left one can be checked before the job runs."}
```

## Three things it hides

**The constructor stops telling the truth.** `OverdueNotices(loans, notifier, clock)` lists its
needs; `LocatedNotices()` claims to need nothing. To learn what it really uses you read every
method, and every method each of those calls, because any of them may call `Services.get`.

**A missing service is found late.** The container in the last section refused at `resolve`,
before a single notice went out, because the constructor declared the clock. The locator found out
inside the loop. With injection Python itself does the check: build `OverdueNotices` with two
arguments and it fails on that line.

**Tests share global state.** One test provides a fake notifier, and the next test, which forgot to
provide its own, silently uses the fake from the previous one. The tests then pass or fail
depending on the order they run in, which is the kind of failure that costs an afternoon.

## Where it turns up anyway

Locators are not rare. Android's `getSystemService(...)` is one; so is reaching for
`app.config` or a global `settings` object from deep inside a request handler. Logging is the
case most people accept: `logging.getLogger(__name__)` is a locator call in almost every Python
file, and passing a logger to every constructor is a price few teams pay.

So the rule is narrower than "never". **A locator is tolerable for cross-cutting services that
change no behaviour a test cares about, and wrong for the collaborators that decide what the code
does.** A notifier, a store and a clock decide what `OverdueNotices` does. They belong in its
constructor, where the next reader and the test both see them.
