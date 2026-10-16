---
title: Inversion of control: who calls whom
version: 1
---

**Inversion of control means your code stops deciding when it runs: something else holds the loop
and calls you.** The phrase is often used as a synonym for dependency injection, and that blurs
two ideas this lesson keeps apart. Inversion of control is the general shape. Dependency injection
is one particular thing that gets inverted, namely who builds the objects a class needs.

The cleanest way to see the shape is the difference between a library and a framework. You call a
library: `textwrap.shorten`, `json.dumps` and `sqlite3.connect` do their job when your code asks
and then hand control back. A framework calls you. You write a function, tell the framework when it
applies, and the framework decides when, and whether, to run it. Django calls your view when a
request arrives, `unittest` calls your test methods, a button in a GUI toolkit calls your handler
when somebody clicks it.

Make `~/patterns/injection` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/injection
cd ~/patterns/injection
```

Here is a framework small enough to read in one go: a loan desk that owns the queue of requests and
calls whichever handler was registered for each.

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom textwrap import shorten", "note": "The one library call in the file. Your code calls `shorten` and gets an answer back; nothing about `shorten` knows your program exists."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self._handlers = {}\n\n    def on(self, action):\n        def register(handler):\n            self._handlers[action] = handler\n            return handler\n        return register", "note": "The framework. It keeps a table of handlers and has no idea what any of them do."},
 {"code": "\n    def run(self, queue):\n        for action, title in queue:\n            handler = self._handlers.get(action)\n            if handler is None:\n                print(f\"desk: no handler for {action!r}, skipped\")\n                continue\n            print(f\"desk: {action} -> {handler(title)}\")", "note": "The loop belongs to the framework. It decides the order, it decides what happens when nobody handles a request, and it decides what to do with the answer."},
 {"code": "\n\ndesk = Desk()\n\n\n@desk.on(\"lend\")\ndef lend(title):\n    return f\"lent {shorten(title, width=24, placeholder='...')} for 14 days\"\n\n\n@desk.on(\"return\")\ndef give_back(title):\n    return f\"{title} is back on the shelf\"", "note": "Your code is two functions that never call each other and never call `run`. The decorator only tells the framework they exist."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk.run([(\"lend\", \"Memórias Póstumas de Brás Cubas\"),\n              (\"return\", \"Dom Casmurro\"),\n              (\"renew\", \"Vidas Secas\")])", "note": "One line hands over control. After it, the framework is in charge until the queue is empty."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 desk.py
desk: lend -> lent Memórias Póstumas de... for 14 days
desk: return -> Dom Casmurro is back on the shelf
desk: no handler for 'renew', skipped
```

Nothing in `lend` or `give_back` says when it runs. The third request found no handler, and the
framework, not your code, decided to skip it and say so.

## The Hollywood principle

The old name for this is the **Hollywood principle: don't call us, we'll call you.** An actor
leaves a number with the studio and waits; the studio decides when there is a part. Your handler
leaves a function with the framework in the same way.

What you gain is everything the framework does around your function without you writing it: the
loop, the routing, the error handling, the order. What you give up is the overview. Reading
`desk.py` from top to bottom, you cannot tell from `lend` alone when it will be called, or whether
it will be called at all. **Inverted control is easier to extend and harder to follow**, and every
framework you have used asks for exactly that trade.

| | a library | a framework |
|---|---|---|
| who holds the loop | your code | the framework |
| how your code is reached | it is not: it does the reaching | it registers, and is called back |
| example in Python | `json`, `textwrap`, `sqlite3` | `unittest`, Django, `tkinter` |
| example elsewhere | `lodash`, Java's `java.time`, Go's `strings` | Express, Spring, JUnit, Go's `net/http` handlers |

Go's `net/http` sits in the framework column even though Go people rarely call it one:
`http.HandleFunc("/loans", handler)` registers a function, and the server calls it for each request.

## What gets inverted in this lesson

Control flow is one thing a framework takes off your hands. **Construction is another.** A class
that needs a notifier can build one itself, or it can be handed one by whoever builds the class.
The second is inversion of control applied to dependencies, and it has its own name, dependency
injection. Lesson 4 made fine notices depend on a `Notifier` port instead of a concrete class;
this lesson is about the question that leaves open: if the class does not build its notifier, who
does, and where?
