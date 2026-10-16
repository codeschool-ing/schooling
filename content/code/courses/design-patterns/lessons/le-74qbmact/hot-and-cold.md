---
title: "Hot and cold: does the stream start when you subscribe?"
version: 1
---

**A cold observable starts its source again for every subscriber. A hot one is already running,
and a subscriber gets whatever happens after it joins.** Every observable so far in this lesson was
cold: subscribing called the producer, and the producer started from the first value. The returns
desk itself is hot. Books come back whether anybody is listening, and a clerk who starts her shift
at ten has missed the nine o'clock returns.

The two kinds look identical from the outside. Both have `subscribe`, both push values and both
end. The difference is where the source lives: inside the subscription, made fresh for each
subscriber, or outside it, shared by all of them.

A hot observable needs one new class. A `Subject` is both ends at once: it has `subscribe`, like any
observable, and it has `on_next` and `on_complete`, so the code that owns it can push values into
it. It is lesson 6's observer again, with the rule about endings added.

```schooling-example
{"language": "python", "file": "hot_cold.py", "parts": [
 {"code": "# hot_cold.py\nfrom observable import Observable, Sink\n\n\ndef catalogue() -> Observable:\n    def produce(sink: Sink) -> None:\n        print(\"  (reading the catalogue from the start)\")\n        for title in [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"]:\n            sink.on_next(title)\n        sink.on_complete()\n    return Observable(produce)", "note": "A cold source. The print shows each time the producer starts, which is once per subscription."},
 {"code": "\n\nclass Subject(Observable):\n    def __init__(self):\n        self._sinks: list[Sink] = []\n        super().__init__(self._sinks.append)\n\n    def on_next(self, value) -> None:\n        for sink in list(self._sinks):\n            sink.on_next(value)\n\n    def on_complete(self) -> None:\n        for sink in list(self._sinks):\n            sink.on_complete()", "note": "The subject's producer is the `append` method of its own list. Subscribing makes a sink and appends it; nothing is pushed until somebody calls `on_next`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"cold: each subscriber gets its own run\")\n    titles = catalogue()\n    titles.subscribe(lambda t: print(\"  Ana sees\", t))\n    titles.subscribe(lambda t: print(\"  Bia sees\", t))", "note": "Two subscribers to the cold catalogue."},
 {"code": "\n    print(\"hot: one run, shared by whoever is listening\")\n    desk = Subject()\n    desk.subscribe(lambda t: print(\"  Ana sees\", t))\n    desk.on_next(\"Dom Casmurro\")\n    desk.subscribe(lambda t: print(\"  Bia sees\", t))\n    desk.on_next(\"Vidas Secas\")\n    desk.on_next(\"Iracema\")\n    desk.on_complete()", "note": "Two subscribers to the hot desk, and the second one arrives after the first book."}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 hot_cold.py
cold: each subscriber gets its own run
  (reading the catalogue from the start)
  Ana sees Dom Casmurro
  Ana sees Vidas Secas
  Ana sees Iracema
  (reading the catalogue from the start)
  Bia sees Dom Casmurro
  Bia sees Vidas Secas
  Bia sees Iracema
hot: one run, shared by whoever is listening
  Ana sees Dom Casmurro
  Ana sees Vidas Secas
  Bia sees Vidas Secas
  Ana sees Iracema
  Bia sees Iracema
```

The cold half reads the catalogue twice, and each reader sees all three titles from the start.
In the hot half, Ana was listening when *Dom Casmurro* came back and Bia was not, so Bia's first
line is *Vidas Secas*. **Nothing replays it for her: a hot stream has no memory of what it already
sent.**

## Which one a source is

The question is whether the values exist apart from the subscriber.

| cold: each subscriber starts it | hot: it runs anyway |
|---|---|
| reading a file | a barcode scanner at the desk |
| a database query | mouse clicks and key presses |
| an HTTP request | prices from an exchange |
| `of(...)` and a timer started by `subscribe` | a `Subject` somebody pushes into |

**A cold observable is a recipe and a hot one is a broadcast.** Neither is better. They answer
different questions: "give me the catalogue" wants every title from the start, every time, and
"tell me when a book comes back" only makes sense from now on.

## The bug both kinds produce

The cold kind surprises people who subscribe twice. In an Angular template, writing the same HTTP
observable in two places subscribes twice, and the server receives two identical requests. In
`hot_cold.py` the instance is the line *reading the catalogue from the start*, printed once per
reader. The libraries' answer is an operator, `share` in RxJS, that subscribes to the cold source
once and passes each value on to every subscriber of its own: a cold source made hot.

The hot kind surprises people who subscribe late. A screen that subscribes to the desk after the
first return has already happened shows nothing for it, and nothing in the stream says a value
went past. When a late subscriber needs the past, the libraries offer subjects that remember.
RxJS's `ReplaySubject` keeps the last *n* values and sends them to each newcomer.
`BehaviorSubject` keeps only the latest and requires one to start with, which suits a value that
always has a current state, such as the number of copies of *Iracema* on the shelf.

## A subject is a door left open

Our `Subject` lets any code that holds it call `on_next`. That is convenient in a demonstration and
dangerous in a program: every holder can push values that every subscriber will believe. The
common discipline is to keep the subject private to the class that owns the source and hand
everybody else the read-only side, an `Observable`. In RxJS that is `subject.asObservable()`; in
this lesson's Python, a property returning
`Observable(lambda sink: desk.subscribe(sink.on_next, sink.on_error, sink.on_complete))` would do
the same. It is lesson
1's encapsulation applied to a stream: the producer keeps the right to produce.
