---
title: "Observables: a stream you subscribe to"
version: 1
---

**An observable is a description of a source of values that does nothing until somebody
subscribes.** Subscribing hands it three callbacks: one for each value, one for an error, one for
the end. From then on the observable pushes, and the subscriber only reacts. Everything else in
a library like RxJS or Reactor is built on that one arrangement.

The usual first picture is a list that fills up over time. It is close and it misleads in one
place: a list exists before you look at it, and an observable does not. Until `subscribe` is
called there is no stream, only the instructions for making one. The program below shows that
with a print before the first subscription.

There is also a rule about the order of signals, and it is what separates an observable from the
observer of lesson 6. Any number of values may come, then **at most one ending: an error or a
completion, never both, and nothing after it**. Written as a pattern, `on_next* (on_error |
on_complete)?`. The rule means a subscriber can trust that `on_complete` is final, and the
class below keeps the rule for every producer instead of trusting each one to remember it.

```schooling-example
{"language": "python", "file": "observable.py", "parts": [
 {"code": "# observable.py\nfrom typing import Callable\n\n\nclass Sink:\n    def __init__(self, on_next, on_error, on_complete):\n        self._next, self._error, self._complete = on_next, on_error, on_complete\n        self.closed = False\n\n    def on_next(self, value) -> None:\n        if not self.closed:\n            self._next(value)\n\n    def on_error(self, err: Exception) -> None:\n        if not self.closed:\n            self.closed = True\n            self._error(err)\n\n    def on_complete(self) -> None:\n        if not self.closed:\n            self.closed = True\n            self._complete()", "note": "A `Sink` is what the producer writes to. It wraps the subscriber's three callbacks and keeps the rule about endings: once `closed` is set, every later signal is ignored."},
 {"code": "\n\ndef _ignore() -> None:\n    pass\n\n\ndef _raise(err: Exception) -> None:\n    raise err", "note": "If the subscriber gives no error handler, the error is raised again rather than dropped. A stream that failed must not look like a stream that was empty."},
 {"code": "\n\nclass Observable:\n    def __init__(self, producer: Callable[[Sink], None]):\n        self._producer = producer\n\n    def subscribe(self, on_next, on_error=_raise, on_complete=_ignore) -> Sink:\n        sink = Sink(on_next, on_error, on_complete)\n        try:\n            self._producer(sink)\n        except Exception as err:\n            sink.on_error(err)\n        return sink", "note": "An `Observable` holds a producer, a function that takes a sink. `subscribe` makes the sink, runs the producer and turns anything the producer raises into `on_error`."},
 {"code": "\n    def pipe(self, *operators) -> \"Observable\":\n        result = self\n        for operator in operators:\n            result = operator(result)\n        return result", "note": "`pipe` applies operators in order, each one turning an observable into another. Section 04 writes the first three."},
 {"code": "\n\ndef of(*values) -> Observable:\n    def produce(sink: Sink) -> None:\n        for value in values:\n            sink.on_next(value)\n        sink.on_complete()\n    return Observable(produce)", "note": "`of` makes an observable from fixed values: a value for each, then the end."},
 {"code": "\n\nif __name__ == \"__main__\":\n    returns = of(\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\")\n    print(\"built; nothing has happened yet\")\n    returns.subscribe(lambda t: print(\"next:\", t),\n                      on_complete=lambda: print(\"complete\"))", "note": "The demonstration builds a stream and subscribes to it once."},
 {"code": "\n    def careless(sink: Sink) -> None:\n        sink.on_next(\"Iracema\")\n        sink.on_complete()\n        sink.on_next(\"O Cortiço\")\n\n    def broken(sink: Sink) -> None:\n        sink.on_next(\"Memórias Póstumas\")\n        raise OSError(\"the barcode reader went away\")\n\n    Observable(careless).subscribe(lambda t: print(\"next:\", t),\n                                   on_complete=lambda: print(\"complete\"))\n    Observable(broken).subscribe(lambda t: print(\"next:\", t),\n                                 on_error=lambda e: print(\"error:\", e))", "note": "A producer that breaks the rule by sending a value after its end, and a producer that raises halfway. Neither reaches the subscriber as anything but a well-formed stream."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 observable.py
built; nothing has happened yet
next: Dom Casmurro
next: Vidas Secas
next: Iracema
complete
next: Iracema
complete
next: Memórias Póstumas
error: the barcode reader went away
```

`built; nothing has happened yet` comes first because `of(...)` only made an object. The three
titles and `complete` appear inside the call to `subscribe`. The careless producer called
`on_next("O Cortiço")` after completing, and that title is nowhere in the output: the sink had
closed. The broken producer delivered one title and then raised, and the subscriber received the
error as a signal, with the stream's message in it, instead of a traceback from somewhere inside
somebody else's code.

## What the three callbacks buy

Compare the desk of section 02. Its listeners had one callback each and no way to learn that the
day was over or that the scanner had failed. With an observable both of those are values in the
stream, delivered the same way as a title. **The end of a stream and the failure of a stream are
part of the stream**, so code downstream can react to them in order: close the day's report when
the returns complete, show an alert when they fail.

This matters most where a loop would have handled them for free. A `for` loop over a generator
ends when the generator returns, and an exception inside the generator surfaces at the loop. Push
removes the loop, so those two signals need somewhere to go, and `on_complete` and `on_error` are
where.

## Synchronous, on purpose

Every producer in this lesson runs inside `subscribe`, on the caller's thread, and that is how the
real libraries behave too unless you ask for a scheduler. RxJS's `of(1, 2, 3)` delivers all three
values before `subscribe` returns. Push does not imply a thread: the source decides when a value
moves, and here the source happens to decide *immediately*. When the source is a timer, a socket
or a scanner, the values arrive later, and the subscriber code is the same.

## What the class leaves out

Real observables also return a way to *unsubscribe*, so a subscriber can stop a source that would
otherwise run for ever: a timer, a stream of clicks. Ours returns the sink, whose `closed` flag a
producer could check, and nothing in this lesson needs more. The libraries add schedulers,
cancellation through a whole chain and dozens of ways of building a source from a timer, an event
or a promise. The shape stays the one above: a producer, a sink with three methods, and the rule
about endings.
