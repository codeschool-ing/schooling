---
title: Decorator and proxy: the same interface, wrapped
version: 1
---

**A decorator wraps an object in another with the same interface and adds behaviour on the way
through; a proxy wraps an object in another with the same interface and controls access to it.**
Structurally they are identical: a class that implements the protocol, holds an instance of the
protocol, and forwards calls to it. What separates them is intent, and the intent is what the name
tells a reader.

One warning before the code. Python's `@decorator` syntax, the line above a function, is a
different thing that shares the name. It is related, and the last reading section of this lesson
shows how, but the GoF decorator is about objects and works the same in every language.

## A decorator: stacking rules on a fine

The library charges 50 cents a day. Students get two days' grace and a cap of ten reais. Some
other group might get the cap without the grace. Written as subclasses, that is a class per
combination, the multiplication lesson 2 measured. Written as decorators, each rule is one small
class, and they stack.

```schooling-example
{"language": "python", "file": "decorator.py", "parts": [
 {"code": "# decorator.py\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...", "note": "One method is the whole protocol: how much is owed for so many days late."},
 {"code": "\n\nclass DailyFine:\n    def __init__(self, cents_per_day: int):\n        self._rate = cents_per_day\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self._rate", "note": "The plain policy. Everything else is built on top of it."},
 {"code": "\n\nclass GraceDays:\n    def __init__(self, inner: FinePolicy, days: int):\n        self._inner, self._days = inner, days\n\n    def fine(self, days_late: int) -> int:\n        return self._inner.fine(days_late - self._days)\n\n\nclass Capped:\n    def __init__(self, inner: FinePolicy, cap: int):\n        self._inner, self._cap = inner, cap\n\n    def fine(self, days_late: int) -> int:\n        return min(self._inner.fine(days_late), self._cap)", "note": "Two decorators. Each holds another policy, changes what goes in or what comes out, and forwards the rest. Neither knows what it is wrapping."},
 {"code": "\n\nif __name__ == \"__main__\":\n    plain = DailyFine(50)\n    student = Capped(GraceDays(DailyFine(50), days=2), cap=1000)\n    for days in (1, 3, 10, 40):\n        print(f\"{days:>2} day(s) late: plain {plain.fine(days):>4}, student {student.fine(days):>4}\")", "note": "The student policy is three objects nested. Swapping the order, or dropping a layer, is a change to this line and to no class."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 decorator.py
 1 day(s) late: plain   50, student    0
 3 day(s) late: plain  150, student   50
10 day(s) late: plain  500, student  400
40 day(s) late: plain 2000, student 1000
```

At ten days the student owes for eight, 400 cents. At forty days the plain policy reaches 2000 and
the student's stops at the cap of 1000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-decorator\" aria-label=\"Three nested boxes: Capped with a cap of 1000 on the outside, GraceDays with 2 days inside it, and DailyFine at 50 cents in the middle. A call fine(40) enters the outer box and is passed on unchanged as 40; GraceDays passes 40 minus 2, which is 38; DailyFine computes 38 times 50, which is 1900. On the way back GraceDays returns 1900 unchanged and Capped returns the smaller of 1900 and 1000, which is 1000.\"><defs><marker id=\"l06-decorator-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-decorator-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"46.0\" width=\"640.0\" height=\"190.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"54.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Capped(cap=1000)</text><rect x=\"140.0\" y=\"82.0\" width=\"440.0\" height=\"136.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"154.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GraceDays(days=2)</text><rect x=\"240.0\" y=\"120.0\" width=\"240.0\" height=\"78.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"320.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">DailyFine(50)</text><text x=\"320.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38 × 50 = 1900</text><text x=\"372.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fine(40)</text><path d=\"M380.0 14.0 L380.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><text x=\"372.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><path d=\"M380.0 50.0 L380.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><text x=\"372.0\" y=\"103.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40 − 2 = 38</text><path d=\"M380.0 86.0 L380.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-paper-dim)\"></path><path d=\"M460.0 118.0 L460.0 86.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1900</text><path d=\"M460.0 80.0 L460.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1900</text><path d=\"M460.0 44.0 L460.0 14.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decorator-dp-ah-amber)\"></path><text x=\"468.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">min(1900, 1000) = 1000</text></svg>", "caption": "student.fine(40), followed through the stack. Each layer changes what goes in or what comes out, and knows nothing about the others."}
```

**Order matters in a stack of decorators.** `GraceDays(Capped(DailyFine(50), 1000), 2)` puts the
cap inside the grace, which happens to give the same numbers here; a decorator that halved the fine
would not commute with the cap. The order of the nesting is part of the rule, and it is written in
one line where a reviewer can see it.

## A proxy: the same catalogue, asked less often

The national catalogue from the adapter section is slow and limits how often it can be asked. The
desk looks the same few books up all day. A caching proxy answers repeat questions itself and
passes only new ones through.

```schooling-example
{"language": "python", "file": "proxy.py", "parts": [
 {"code": "# proxy.py\nfrom adapter import Book, Catalogue, OpenShelfCatalogue, OpenShelfClient", "note": "The proxy wraps the adapter from `adapter.py`, so that file must be in the same directory."},
 {"code": "\n\nclass CachingCatalogue:\n    def __init__(self, inner: Catalogue):\n        self._inner = inner\n        self._cache: dict[str, Book | None] = {}\n        self.asked_inner = 0\n\n    def find(self, isbn: str) -> Book | None:\n        if isbn not in self._cache:\n            self.asked_inner += 1\n            self._cache[isbn] = self._inner.find(isbn)\n        return self._cache[isbn]", "note": "It is a `Catalogue`, it holds a `Catalogue`, and it decides when the real one is asked. A miss goes through and is remembered; a hit never leaves the proxy."},
 {"code": "\n\nif __name__ == \"__main__\":\n    catalogue = CachingCatalogue(OpenShelfCatalogue(OpenShelfClient()))\n    requests = [\"978-65-5555-012-3\", \"978-65-5555-014-7\", \"978-65-5555-012-3\",\n                \"978-65-5555-012-3\", \"978-65-5555-099-9\", \"978-65-5555-099-9\"]\n    for isbn in requests:\n        book = catalogue.find(isbn)\n        print(isbn, \"->\", book.title if book else \"not found\")\n    print(f\"{len(requests)} requests, the service was asked {catalogue.asked_inner} times\")", "note": "Six requests for three different ISBNs. The caller cannot tell a cached answer from a fresh one."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 proxy.py
978-65-5555-012-3 -> Vidas Secas
978-65-5555-014-7 -> Dom Casmurro
978-65-5555-012-3 -> Vidas Secas
978-65-5555-012-3 -> Vidas Secas
978-65-5555-099-9 -> not found
978-65-5555-099-9 -> not found
6 requests, the service was asked 3 times
```

The proxy remembers "not found" too, which is a decision rather than an accident: a book the
service does not know today might be added tomorrow, and this cache would never ask again. A real
one would keep each answer for a limited time. That is a cache's problem, not the pattern's; the
pattern only says where the decision lives.

## The kinds of proxy

Caching is one reason to control access. The book lists others, and you have met most of them
without the name. A **remote proxy** stands in for an object in another process: the client stub
a gRPC or RMI tool generates is one. A **virtual proxy** delays creating something expensive until
it is used, which is what an ORM does when `loan.member` loads the member from the database only
when you touch it. A **protection proxy** checks permission before forwarding, like a read-only
view of the ledger handed to the reporting code.

| | decorator | proxy |
|---|---|---|
| adds or controls | adds behaviour | controls access |
| who builds the wrapper | usually the caller, choosing a stack | usually a framework or the composition root |
| does the caller know | often, it picked the layers | usually not, by design |
| in this lesson | `GraceDays`, `Capped` | `CachingCatalogue` |

Java's `java.io` is the textbook decorator: `new BufferedReader(new InputStreamReader(stream))`
stacks behaviour on a stream. Go's `io.Reader` wrappers, such as `bufio.NewReader(r)`, are the same
idea with an interface the type satisfies without declaring it.
