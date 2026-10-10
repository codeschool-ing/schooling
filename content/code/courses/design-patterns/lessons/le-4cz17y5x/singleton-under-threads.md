---
title: The singleton under threads: one becomes four
version: 1
---

**A lazily created singleton is a check-then-act race with a design pattern's name on it.** Lesson
6 showed the singleton and gave reasons to distrust it; here is one more, and it is the most
concrete. The usual Python version checks whether the instance exists and creates it if not. Two
threads can both find that it does not.

The library's catalogue takes a moment to load, 40,000 records from disk, so the program creates
it the first time somebody asks:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nimport threading\nimport time\n\n\nclass Catalogue:\n    created = 0\n\n    def __init__(self):\n        Catalogue.created += 1\n        time.sleep(0.1)  # loading 40,000 records from disk\n        self.records = 40_000", "note": "`created` counts how many times the constructor has run. A singleton promises that number never passes one."},
 {"code": "\n_instance: Catalogue | None = None\n\n\ndef get_catalogue() -> Catalogue:\n    global _instance\n    if _instance is None:\n        _instance = Catalogue()\n    return _instance", "note": "The textbook lazy singleton: check, then create. Between the check and the assignment sits the whole slow constructor."},
 {"code": "\nif __name__ == \"__main__\":\n    got: list[Catalogue] = []\n    desks = [threading.Thread(target=lambda: got.append(get_catalogue())) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"catalogues created:\", Catalogue.created)\n    print(\"distinct objects handed out:\", len({id(c) for c in got}))", "note": "Four desks ask for the catalogue at once, as four request threads in a web server would on the first page load after a restart."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 catalogue.py
catalogues created: 4
distinct objects handed out: 4
```

All four desks saw `_instance is None`, because none of them had finished building one. Four
catalogues were loaded, four objects handed out, and the last assignment won. Here that costs three
wasted loads. **When the singleton holds a connection pool, a cache or a counter, the threads that
got the losing copies keep using them**, writing to objects nobody else will ever read.

## Fixed with a lock, and checked twice

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nimport threading\nimport time\n\n\nclass Catalogue:\n    created = 0\n\n    def __init__(self):\n        Catalogue.created += 1\n        time.sleep(0.1)  # loading 40,000 records from disk\n        self.records = 40_000", "note": "Unchanged: the constructor is as slow as before."},
 {"code": "\n_instance: Catalogue | None = None\n_lock = threading.Lock()\n\n\ndef get_catalogue() -> Catalogue:\n    global _instance\n    if _instance is None:\n        with _lock:\n            if _instance is None:\n                _instance = Catalogue()\n    return _instance", "note": "The first check is outside the lock, so once the catalogue exists no caller pays for locking. The second check is inside: a thread that waited at the lock finds the instance a winner already made."},
 {"code": "\nif __name__ == \"__main__\":\n    got: list[Catalogue] = []\n    desks = [threading.Thread(target=lambda: got.append(get_catalogue())) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"catalogues created:\", Catalogue.created)\n    print(\"distinct objects handed out:\", len({id(c) for c in got}))", "note": "The same four desks."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 catalogue.py
catalogues created: 1
distinct objects handed out: 1
```

One catalogue. The pattern is called **double-checked locking**, and it has a history worth
knowing. In Java before version 5 it was broken even with the lock: another thread could see the
reference to the new object before the constructor's writes to its fields were visible, and use a
half-built catalogue. The fix there is to declare the field `volatile`. The lesson underneath is
that a clever lock pattern is a claim about a memory model, and most people who write one have
never read theirs.

## Or do not be lazy

The simplest fix is to create the object before any thread exists. In Python a module is executed
once, under the import system's own lock, so this is safe however many threads import it:

```python
CATALOGUE = Catalogue()  # built when the module is first imported
```

That is lesson 6's advice about singletons in Python, and threads give it a second reason. The
same idea in other languages: Go has `sync.Once`, which runs a function exactly once however many
goroutines call it; Java has the holder-class idiom, where the JVM's class loading does the
locking. JavaScript modules are evaluated once per realm, so a module-level object is one per
event loop, but a worker thread has a realm of its own and gets its own copy.

Better still is the advice lesson 5 gave about dependency injection: build the catalogue once in
`main.py` and pass it to whoever needs it. A composition root runs before the threads start, so
there is no race to win.
