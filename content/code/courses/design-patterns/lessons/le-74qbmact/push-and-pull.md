---
title: "Push and pull: who decides when the next value moves"
version: 1
---

**Reactive programming is often described as "asynchronous" or "fast", and neither word is the
idea.** The idea is about direction. In most code you have written, the consumer asks for the next
value when it is ready for one: that is *pull*. In reactive code the producer hands a value over
when it has one, and the consumer has to deal with it then: that is *push*. Threads, event loops
and speed are things push often travels with. None of them is what makes code reactive.

You met both shapes in lesson 6 as two separate patterns. The iterator is pull: the loop calls
`next()` and the collection answers. The observer is push: the subject calls every listener when
something happens. Erik Meijer, who designed Microsoft's Reactive Extensions around 2009, built them
on the observation that these are the same pattern turned inside out. The iterator returns values
to its caller; the observer receives values from somebody it never called.

The returns desk of the library shows both. Make `~/patterns/reactive` and work there:

```sh
mkdir -p ~/patterns/reactive
cd ~/patterns/reactive
```

```schooling-example
{"language": "python", "file": "pull_push.py", "parts": [
 {"code": "# pull_push.py\nfrom itertools import islice\n\nRETURNS = [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"]", "note": "Three books come back today. The list is fixed so that the output is the same every run."},
 {"code": "\n\ndef returned_books():\n    for title in RETURNS:\n        print(f\"  desk: {title} is back\")\n        yield title", "note": "A generator is a pull source: its body runs only as far as the next `yield`, and only when somebody asks for a value."},
 {"code": "\n\ndef pull() -> None:\n    print(\"pull: the shelver asks for two books\")\n    for title in islice(returned_books(), 2):\n        print(f\"  shelver: shelving {title}\")", "note": "The shelver asks for two books and stops. `islice` stops asking after the second, so the generator never runs a third time."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self._listeners = []\n\n    def subscribe(self, listener) -> None:\n        self._listeners.append(listener)\n\n    def book_returned(self, title: str) -> None:\n        print(f\"  desk: {title} is back\")\n        for listener in self._listeners:\n            listener(title)", "note": "The desk is a push source. It keeps a list of listeners and, when a book comes back, calls every one of them."},
 {"code": "\n\ndef push() -> None:\n    print(\"push: the desk tells whoever subscribed\")\n    desk = Desk()\n    desk.subscribe(lambda title: print(f\"  shelver: shelving {title}\"))\n    desk.subscribe(lambda title: print(f\"  catalogue: {title} available\"))\n    for title in RETURNS:\n        desk.book_returned(title)", "note": "Two listeners, and the desk decides when they run. Neither of them can say *not yet*."},
 {"code": "\n\nif __name__ == \"__main__\":\n    pull()\n    push()"}
]}
```

```
ana@laptop:~/patterns/reactive$ python3 pull_push.py
pull: the shelver asks for two books
  desk: Dom Casmurro is back
  shelver: shelving Dom Casmurro
  desk: Vidas Secas is back
  shelver: shelving Vidas Secas
push: the desk tells whoever subscribed
  desk: Dom Casmurro is back
  shelver: shelving Dom Casmurro
  catalogue: Dom Casmurro available
  desk: Vidas Secas is back
  shelver: shelving Vidas Secas
  catalogue: Vidas Secas available
  desk: Iracema is back
  shelver: shelving Iracema
  catalogue: Iracema available
```

Read the pull half first. The desk prints *Dom Casmurro is back*, the shelver shelves it, and only
then does the desk look for the next book. After two, the shelver stops asking, and the line
*Iracema is back* never appears: **in a pull design the consumer sets the pace, including the pace
zero.** The generator did not produce a third value that nobody wanted, because nobody asked.

The push half prints all three books, each followed by both listeners. The shelver and the
catalogue run inside `book_returned`, on the desk's schedule. If the shelver were slow, the desk
would wait for it here, because the call is direct; in lesson 6's observer that was the whole
story. Section 06 of this lesson is about what happens when the desk cannot wait.

## Four kinds of answer

The two shapes fit into a table that Meijer's work made popular, and it is the quickest map of
where reactive programming sits among things you already use:

| | one value | many values |
|---|---|---|
| **pull**: you ask and wait | a function call returns it | an iterator or a generator |
| **push**: it arrives when ready | a future, a promise | an observable |

A promise in JavaScript, a `Future` in Java and an `asyncio` task in Python are the push version of
a function call: one value, some time later. An observable is the push version of an iterator: any
number of values, some time later each, and then a signal that there will be no more. Section 03
builds one.

## Which shape a source wants

Some sources can be pulled. A file, a list in memory and a database cursor all wait patiently for
the next request, and pulling them is simpler: an ordinary loop, an ordinary exception, and the
consumer never has more than it asked for.

Other sources cannot be asked. A member walks up to the desk when she decides to, a barcode scanner
fires when a book passes under it, and a user clicks when they click. You can turn such a source
into a pull source by putting a queue in front of it, and that queue is exactly where the trouble
of sections 06 and 07 begins. **Reactive programming is the set of tools for sources that push**:
a way to describe what should happen to each value as it arrives, and what should happen when they
arrive faster than you can deal with them.

One word of warning about the name. The *Reactive Manifesto*, published in 2013, describes systems
that stay responsive under load and failure, and it shares a word with this lesson and very little
else. Its subject is architecture between services, which `architecture` lessons 11 and 12 covered.
This lesson stays inside one program.
