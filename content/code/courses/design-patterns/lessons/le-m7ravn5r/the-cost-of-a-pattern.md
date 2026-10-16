---
title: The cost of a pattern, counted in lines and hops
version: 1
---

**Every pattern buys flexibility with indirection, and indirection is paid for by every reader,
every time.** The common view is that a pattern costs a little effort once, when it is written, and
then only gives. The effort of writing is the small part. The large part is that a question about
the code, *how much is the fine?*, now takes several files and several jumps to answer, and that
cost recurs on every reading by every person for as long as the code lives.

The cost can be counted, and counting it is more honest than arguing about taste. Make
`~/patterns/choosing` and work there:

```sh
mkdir -p ~/patterns/choosing
cd ~/patterns/choosing
```

## The same notice, written twice

A fine notice for a member who is four days late, first as plainly as it can be written:

```python
# plain.py
DAILY_FINE = 50  # cents


def notice(name: str, days_late: int) -> str:
    return f"{name}, you owe {max(days_late, 0) * DAILY_FINE} cents"


if __name__ == "__main__":
    print(notice("Bia", 4))
```

And then the way it often ends up after a few patterns have been applied in good faith: a policy
behind a protocol, a factory that picks the policy, a calculator, a formatter and a service that
holds them, wired together in one place as lesson 5 taught.

```schooling-example
{"language": "python", "file": "layered.py", "parts": [
 {"code": "# layered.py\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...\n\n\nclass DailyFine:\n    def __init__(self, cents: int):\n        self.cents = cents\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self.cents", "note": "A protocol for fine policies, and the one policy there is."},
 {"code": "\nclass PolicyFactory:\n    def for_category(self, category: str) -> FinePolicy:\n        return DailyFine(50)\n\n\nclass FineCalculator:\n    def __init__(self, factory: PolicyFactory):\n        self.factory = factory\n\n    def compute(self, category: str, days_late: int) -> int:\n        return self.factory.for_category(category).fine(days_late)", "note": "A factory that chooses a policy by category, and a calculator that asks the factory."},
 {"code": "\nclass NoticeFormatter:\n    def format(self, name: str, cents: int) -> str:\n        return f\"{name}, you owe {cents} cents\"\n\n\nclass NoticeService:\n    def __init__(self, calculator: FineCalculator, formatter: NoticeFormatter):\n        self.calculator = calculator\n        self.formatter = formatter\n\n    def notice(self, name: str, category: str, days_late: int) -> str:\n        return self.formatter.format(name, self.calculator.compute(category, days_late))", "note": "A formatter for the sentence, and a service that holds the calculator and the formatter."},
 {"code": "\ndef build() -> NoticeService:\n    return NoticeService(FineCalculator(PolicyFactory()), NoticeFormatter())\n\n\nif __name__ == \"__main__\":\n    print(build().notice(\"Bia\", \"adult\", 4))", "note": "A composition root that builds the graph, and the same notice for Bia."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 plain.py
Bia, you owe 200 cents
ana@laptop:~/patterns/choosing$ python3 layered.py
Bia, you owe 200 cents
ana@laptop:~/patterns/choosing$ wc -l plain.py layered.py
  10 plain.py
  46 layered.py
  56 total
```

The same sentence, from more than four times the lines. None of the classes in `layered.py` is wrong on its
own, and each is a pattern you have met in this course. Together they are an answer to forces this
program does not have.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l19-two-arrangements\" aria-label=\"Two arrangements of the same fine notice. On the left, plain.py: one module with a constant, DAILY_FINE, and one function, notice. On the right, layered.py as a class diagram: NoticeService holds a FineCalculator and a NoticeFormatter; FineCalculator holds a PolicyFactory and calls fine on a FinePolicy protocol; PolicyFactory creates a DailyFine, the only class that implements FinePolicy. The left is 10 lines; the right is 46 lines with six classes.\"><defs><marker id=\"l19-two-arrangements-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"105.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">plain.py</text><rect x=\"25.0\" y=\"70.0\" width=\"160.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«module»</text><text x=\"105.0\" y=\"95.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plain.py</text><path d=\"M25.0 107.0 L185.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"33.0\" y=\"118.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">DAILY_FINE = 50</text><path d=\"M25.0 129.5 L185.0 129.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"33.0\" y=\"140.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notice()</text><text x=\"105.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10 lines, 1 function</text><path d=\"M212.0 10.0 L212.0 266.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"470.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">layered.py</text><rect x=\"235.0\" y=\"40.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NoticeService</text><path d=\"M235.0 62.5 L375.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"243.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notice()</text><rect x=\"235.0\" y=\"170.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NoticeFormatter</text><path d=\"M235.0 192.5 L375.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"243.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">format()</text><rect x=\"415.0\" y=\"40.0\" width=\"135.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.5\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FineCalculator</text><path d=\"M415.0 62.5 L550.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">compute()</text><rect x=\"415.0\" y=\"170.0\" width=\"135.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.5\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PolicyFactory</text><path d=\"M415.0 192.5 L550.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">for_category()</text><rect x=\"600.0\" y=\"40.0\" width=\"110.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"655.0\" y=\"65.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FinePolicy</text><path d=\"M600.0 77.0 L710.0 77.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"88.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"600.0\" y=\"170.0\" width=\"110.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DailyFine</text><path d=\"M600.0 192.5 L710.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><path d=\"M375.0 62.0 L415.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M375.0 62.0 L384.0 67.5 L393.0 62.0 L384.0 56.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M305.0 85.0 L305.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M305.0 85.0 L299.5 94.0 L305.0 103.0 L310.5 94.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M482.0 85.0 L482.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M482.0 85.0 L476.5 94.0 L482.0 103.0 L487.5 94.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M550.0 62.0 L598.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-two-arrangements-dp-ah-paper-dim)\"></path><text x=\"574.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">calls</text><path d=\"M550.0 192.0 L598.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l19-two-arrangements-dp-ah-paper-dim)\"></path><text x=\"574.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">creates</text><path d=\"M655.0 170.0 L655.0 99.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M655.0 99.5 L662.0 111.5 L648.0 111.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"470.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">46 lines, 6 classes, 1 function</text></svg>", "caption": "The same sentence, from one function or from six classes. Every box on the right is a place a reader may have to visit."}
```

## Counting the hops

Lines are the cheap measure. The expensive one is how many places a reader has to visit to follow
one request, and Python can count that for you. `sys.setprofile` calls a function of yours every
time any Python function starts or returns, and this program uses it to write down every call made
inside the two files while one notice is produced:

```schooling-example
{"language": "python", "file": "hops.py", "parts": [
 {"code": "# hops.py\nimport sys\n\nimport layered\nimport plain\n\nMINE = (\"plain.py\", \"layered.py\")", "note": "The two versions are imported as modules. Only calls to functions defined in those two files are counted."},
 {"code": "\ndef trace(job) -> list[str]:\n    lines: list[str] = []\n    depth = 0\n\n    def watch(frame, event, arg):\n        nonlocal depth\n        if not frame.f_code.co_filename.endswith(MINE):\n            return\n        if event == \"call\":\n            lines.append(\"  \" * depth + frame.f_code.co_qualname)\n            depth += 1\n        elif event == \"return\":\n            depth -= 1\n\n    sys.setprofile(watch)\n    answer = job()\n    sys.setprofile(None)\n    return [answer] + lines", "note": "`watch` is called on every call and return. It indents by depth, so the output shows who called whom."},
 {"code": "\nfor label, job in ((\"plain.py\", lambda: plain.notice(\"Bia\", 4)),\n                   (\"layered.py\", lambda: layered.build().notice(\"Bia\", \"adult\", 4))):\n    answer, *calls = trace(job)\n    print(f\"{label}: {answer!r}\")\n    print(f\"  function calls: {len(calls)}\")\n    for line in calls:\n        print(\"    \" + line)", "note": "One notice from each version, with the answer first, to show that both say the same thing."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 hops.py
plain.py: 'Bia, you owe 200 cents'
  function calls: 1
    notice
layered.py: 'Bia, you owe 200 cents'
  function calls: 9
    build
      FineCalculator.__init__
      NoticeService.__init__
    NoticeService.notice
      FineCalculator.compute
        PolicyFactory.for_category
          DailyFine.__init__
        DailyFine.fine
      NoticeFormatter.format
```

One call against nine, four levels deep. **To answer *how much is the fine?* in the layered version,
a reader opens `NoticeService.notice`, then `FineCalculator.compute`, then
`PolicyFactory.for_category`, and only then reaches the multiplication in `DailyFine.fine`.** In a
real codebase those four are in four files, and an editor's *go to definition* lands on the
protocol rather than the class, which adds a search to each jump.

## What the indirection would have bought

The layers are not useless; they are early. The factory is where a second policy would be chosen.
The protocol is where a test would substitute a fake policy. The service is where a second channel
would be added. Each of those is a real force in some library. The cost is worth paying on the day
one of them arrives, and section 05 shows the smallest structure that pays for the force it was
given.

The measure to keep is this: **a pattern earns its indirection when the change it absorbs costs
more than every reader's extra hops**. A change that happens weekly to code read monthly earns a
lot of indirection. A change that might happen one day, to code read every day, earns none.

The same arithmetic applies in every language, with a different weight per hop. Java and
TypeScript editors jump through interfaces well, and an interface costs a file. In Go, interfaces
are small and declared by the code that uses them, so a one-method interface beside its single
caller is cheap. In Python, a protocol nobody checks with mypy is documentation that can drift from
the code it describes.
