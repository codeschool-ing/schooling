---
title: The composition root: one place that knows everything
version: 1
---

**If no class builds its own collaborators, something has to build all of them, and the composition
root is that something: one place, as close to the program's entry point as possible, where every
concrete class is chosen and every object is wired to its neighbours.** In a script it is `main`.
In a web application it is the code that runs once at start-up. Everywhere else in the program,
objects receive and never construct.

The usual first reaction is that this moves the problem rather than solving it. It does move it,
and moving it is the point. When construction is scattered, the decision "e-mail or text message"
is made inside whichever class happened to need a notifier, and changing it means finding that
class. When construction is gathered, every decision of that kind is in one file, and the rest of
the program is written as if it did not know the answer.

## A main that only wires

`main.py` imports the job from `overdue.py`, adds the real implementations a deployment would use,
and does nothing else.

```schooling-example
{"language": "python", "file": "main.py", "parts": [
 {"code": "# main.py\nimport os\nimport sys\nfrom datetime import date\n\nfrom overdue import FixedClock, ListedLoans, Loan, OverdueNotices", "note": "The composition root imports concrete classes from everywhere. It is the only file allowed to."},
 {"code": "\n\nclass EmailNotifier:\n    def __init__(self, sender: str):\n        self._sender = sender\n\n    def send(self, member: str, text: str) -> None:\n        print(f\"e-mail from {self._sender} to {member}: {text}\")\n\n\nclass SmsNotifier:\n    def send(self, member: str, text: str) -> None:\n        print(f\"SMS to {member}: {text}\")\n\n\nclass SystemClock:\n    def today(self) -> date:\n        return date.today()", "note": "Two notifiers and a clock that reads the computer's calendar. A real `EmailNotifier` would talk to a mail server; these print, so the program runs anywhere."},
 {"code": "\n\ndef build(channel: str) -> OverdueNotices:\n    loans = ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n        Loan(\"Duda\", \"Central do Brasil\", date(2026, 3, 11)),\n    ])\n    notifiers = {\"email\": EmailNotifier(\"desk@library.example.org\"),\n                 \"sms\": SmsNotifier()}\n    fixed = os.environ.get(\"LIBRARY_TODAY\")\n    clock = FixedClock(date.fromisoformat(fixed)) if fixed else SystemClock()\n    return OverdueNotices(loans, notifiers[channel], clock)", "note": "`build` is the wiring, and it reads like a list of decisions. Configuration is read here, from the arguments and the environment, and nowhere deeper."},
 {"code": "\n\ndef main(argv: list[str]) -> None:\n    notices = build(argv[1] if len(argv) > 1 else \"email\")\n    print(\"sent:\", notices.send_all())\n\n\nif __name__ == \"__main__\":\n    main(sys.argv)", "note": "The entry point builds once and then runs. Nothing after `build` returns creates a collaborator."}
]}
```

`LIBRARY_TODAY` lets an operator replay a past day, and it lets this lesson print the same output
every time. Without it, the job uses the real date.

```
ana@laptop:~/patterns/injection$ LIBRARY_TODAY=2026-03-20 python3 main.py
e-mail from desk@library.example.org to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
e-mail from desk@library.example.org to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
ana@laptop:~/patterns/injection$ LIBRARY_TODAY=2026-03-20 python3 main.py sms
SMS to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
SMS to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
```

Switching every notice from e-mail to text message took one word on the command line and touched no
class. `OverdueNotices` is byte for byte the file from two sections ago.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-root\" aria-label=\"A class diagram of the overdue-notices program. OverdueNotices, at the top, holds three collaborators, drawn as lines with a filled diamond at its end: a LoanStore, a Notifier and a Clock, each a protocol. Below them, five concrete classes implement the protocols: ListedLoans implements LoanStore; EmailNotifier and SmsNotifier implement Notifier; SystemClock and FixedClock implement Clock. A dashed boundary encloses the five concrete classes and is labelled main.py, the composition root: the only file that names them.\"><rect x=\"270.0\" y=\"14.0\" width=\"180.0\" height=\"96.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"25.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M270.0 36.5 L450.0 36.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"47.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">loans</text><text x=\"278.0\" y=\"62.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notifier</text><text x=\"278.0\" y=\"76.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">clock</text><path d=\"M270.0 88.0 L450.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"99.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send_all()</text><text x=\"462.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">asks for three protocols,</text><text x=\"462.0\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">builds none of them</text><rect x=\"40.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"130.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoanStore</text><path d=\"M40.0 187.0 L220.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">open_loans()</text><rect x=\"270.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"360.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Notifier</text><path d=\"M270.0 187.0 L450.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"278.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"500.0\" y=\"150.0\" width=\"180.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"161.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"590.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Clock</text><path d=\"M500.0 187.0 L680.0 187.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"508.0\" y=\"198.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">today()</text><path d=\"M300.0 110.5 L300.0 130.0 L130.0 130.0 L130.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M300.0 110.5 L294.5 119.5 L300.0 128.5 L305.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M360.0 110.5 L360.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M360.0 110.5 L354.5 119.5 L360.0 128.5 L365.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M420.0 110.5 L420.0 130.0 L590.0 130.0 L590.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M420.0 110.5 L414.5 119.5 L420.0 128.5 L425.5 119.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><rect x=\"20.0\" y=\"228.0\" width=\"680.0\" height=\"92.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"70.0\" y=\"250.0\" width=\"120.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">ListedLoans</text><path d=\"M130.0 250.0 L130.0 238.0 L130.0 238.0 L130.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M130.0 209.5 L137.0 221.5 L123.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"245.0\" y=\"250.0\" width=\"110.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">EmailNotifier</text><path d=\"M300.0 250.0 L300.0 238.0 L360.0 238.0 L360.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360.0 209.5 L367.0 221.5 L353.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"365.0\" y=\"250.0\" width=\"110.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M420.0 250.0 L420.0 238.0 L360.0 238.0 L360.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360.0 209.5 L367.0 221.5 L353.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"490.0\" y=\"250.0\" width=\"95.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"537.5\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">SystemClock</text><path d=\"M537.5 250.0 L537.5 238.0 L590.0 238.0 L590.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 209.5 L597.0 221.5 L583.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><rect x=\"595.0\" y=\"250.0\" width=\"95.0\" height=\"21.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"642.5\" y=\"260.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">FixedClock</text><path d=\"M642.5 250.0 L642.5 238.0 L590.0 238.0 L590.0 209.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 209.5 L597.0 221.5 L583.0 221.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">main.py, the composition root: the only file that names these classes</text></svg>", "caption": "The job depends on three protocols. Which classes stand behind them is decided in one file."}
```

## Rules that keep it a root

**Only the composition root may name a concrete class that another object depends on.** A class
deep in the program that writes `SmsNotifier()` has reopened the problem this section closed,
however convenient it was on the day.

Build everything before anything runs. If wiring fails, because a setting is missing or a file
cannot be opened, it should fail at start-up with the program doing nothing yet, rather than on the
first overdue loan at three in the morning.

Keep the root dull. It decides and connects; it holds no rules about fines or loans. A root that
starts computing things is a class that has grown a second job, and its logic cannot be tested
without building the whole program.

## How large it gets

For this lesson's program, `build` is nine lines. A service with forty classes has a root of a
hundred lines or so, and that is still fine: it is long the way a table of contents is long, with
nothing hidden in it. Go projects are known for doing exactly this, a `main.go` that constructs
every dependency by hand and passes it down, and many large Go services have no other mechanism.

When the wiring itself starts to be repetitive — the same store handed to twenty classes, objects
that must be created once per web request and thrown away after it — a container can take over the
mechanical part. The next section builds one, and is honest about how rarely Python needs it.
