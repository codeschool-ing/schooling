---
title: The observer under threads: a list that changes while you walk it
version: 1
---

**An observer's subject walks its list of listeners, and lesson 6 assumed the list would hold still
while it did.** With threads, another thread can subscribe or unsubscribe in the middle of a
notification. Sometimes Python notices and raises; with a plain list it does not notice at all,
and a listener simply misses the event.

The library publishes an event when a book comes back. Three listeners care: the fines desk, an
e-mail to the member, and the statistics. While the e-mail listener is talking to the mail server,
another thread closes the fines desk for the night and unsubscribes it.

```schooling-example
{"language": "python", "file": "observers.py", "parts": [
 {"code": "# observers.py\nimport threading\nimport time\nfrom typing import Callable\n\nListener = Callable[[str], None]\n\n\nclass LoanEvents:\n    def __init__(self):\n        self._listeners: list[Listener] = []\n\n    def subscribe(self, listener: Listener) -> None:\n        self._listeners.append(listener)\n\n    def unsubscribe(self, listener: Listener) -> None:\n        self._listeners.remove(listener)\n\n    def publish(self, event: str) -> None:\n        for listener in self._listeners:\n            listener(event)", "note": "A subject in the shape lesson 6 gave it: a list of callables, and `publish` walks it."},
 {"code": "\nreceived: dict[str, list[str]] = {\"fines\": [], \"e-mail\": [], \"stats\": []}\nemailing = threading.Event()\n\n\ndef fines(event: str) -> None:\n    received[\"fines\"].append(event)\n\n\ndef email(event: str) -> None:\n    received[\"e-mail\"].append(event)\n    emailing.set()\n    time.sleep(0.1)  # talking to the mail server\n\n\ndef stats(event: str) -> None:\n    received[\"stats\"].append(event)", "note": "Three listeners that record what they were told. `emailing` is an event the e-mail listener sets, so the other thread acts at a known moment instead of a lucky one."},
 {"code": "\nif __name__ == \"__main__\":\n    events = LoanEvents()\n    for listener in (fines, email, stats):\n        events.subscribe(listener)\n\n    def closing_the_fines_desk() -> None:\n        emailing.wait()\n        events.unsubscribe(fines)\n\n    other = threading.Thread(target=closing_the_fines_desk)\n    other.start()\n    events.publish(\"Dom Casmurro returned\")\n    other.join()\n    for name, got in received.items():\n        print(f\"{name:<7} {got}\")", "note": "The second thread waits until the e-mail is being sent, then unsubscribes the fines desk. The main thread publishes one event."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 observers.py
fines   ['Dom Casmurro returned']
e-mail  ['Dom Casmurro returned']
stats   []
```

The statistics never heard about the return, and nothing said so. The loop in `publish` keeps a
position, not a list of who is left. It had handled position 0 and was inside position 1 when the
fines desk was removed from position 0, so the e-mail listener slid down to 0 and the statistics
to 1. The loop then asked for position 2, found the end of the list and stopped. **One listener
skipped, no exception, and a monthly report that is quietly short.**

Had the listeners been in a dictionary or a set, Python would have raised `RuntimeError` with the
words *changed size during iteration*. That is the better failure. A plain list gives no such
warning, and an append in the middle of a walk is just as quiet in the other direction: a listener
added during a publish can receive an event that happened before it subscribed.

## Copy under the lock, call outside it

The fix has two halves, and both matter.

```schooling-example
{"language": "python", "file": "observers.py", "parts": [
 {"code": "# observers.py\nimport threading\nimport time\nfrom typing import Callable\n\nListener = Callable[[str], None]\n\n\nclass LoanEvents:\n    def __init__(self):\n        self._listeners: list[Listener] = []\n        self._lock = threading.Lock()\n\n    def subscribe(self, listener: Listener) -> None:\n        with self._lock:\n            self._listeners.append(listener)\n\n    def unsubscribe(self, listener: Listener) -> None:\n        with self._lock:\n            self._listeners.remove(listener)", "note": "A lock guards the list. Subscribing and unsubscribing take it, so the list is never half-changed."},
 {"code": "\n    def publish(self, event: str) -> None:\n        with self._lock:\n            listeners = list(self._listeners)\n        for listener in listeners:\n            listener(event)", "note": "`publish` copies the list while holding the lock, lets go, and only then calls the listeners. The walk is over a snapshot that nobody else can change."},
 {"code": "\nreceived: dict[str, list[str]] = {\"fines\": [], \"e-mail\": [], \"stats\": []}\nemailing = threading.Event()\n\n\ndef fines(event: str) -> None:\n    received[\"fines\"].append(event)\n\n\ndef email(event: str) -> None:\n    received[\"e-mail\"].append(event)\n    emailing.set()\n    time.sleep(0.1)  # talking to the mail server\n\n\ndef stats(event: str) -> None:\n    received[\"stats\"].append(event)\n\n\nif __name__ == \"__main__\":\n    events = LoanEvents()\n    for listener in (fines, email, stats):\n        events.subscribe(listener)\n\n    def closing_the_fines_desk() -> None:\n        emailing.wait()\n        events.unsubscribe(fines)\n\n    other = threading.Thread(target=closing_the_fines_desk)\n    other.start()\n    events.publish(\"Dom Casmurro returned\")\n    other.join()\n    for name, got in received.items():\n        print(f\"{name:<7} {got}\")", "note": "Everything below is the same program as before."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 observers.py
fines   ['Dom Casmurro returned']
e-mail  ['Dom Casmurro returned']
stats   ['Dom Casmurro returned']
```

All three heard. Why not simply hold the lock for the whole `publish`? Because the listeners are
code the subject does not control. One that takes 0.1 seconds to send an e-mail would hold up
every subscribe and unsubscribe for that long. Worse, one that subscribes another listener from
inside its callback would ask for a lock its own thread already holds, and with a plain `Lock`
that thread deadlocks against itself. **Hold a lock around your own data, never around a call into
somebody else's code.**

The snapshot has a cost worth stating: a listener unsubscribed during a publish can still receive
that one event, because it was in the copy. For a library's notifications that is harmless. Where
it is not, the listener has to check whether it still wants events, and the subject cannot do that
for it.

## What the pattern did not say

The observer of lesson 6 also runs every listener on the publisher's thread, one after another. The
e-mail's 0.1 seconds were 0.1 seconds the returning desk spent waiting. Java's
`CopyOnWriteArrayList` exists for exactly this snapshot-then-iterate shape. Reactive streams in
lesson 16 and actors in lesson 17 are, among other things, two different answers to *on whose
thread does the listener run?*, which is the question this pattern never had to ask.
