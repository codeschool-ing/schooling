---
title: Concurrency and parallelism: two words for two things
version: 1
---

**The common picture is that concurrency means doing several things at the same instant. That is
parallelism, and it is the narrower of the two words.** Concurrency is a way of structuring a
program so that several tasks are in progress at once: one waits for a disk while another formats a
receipt. Parallelism is a way of running a program so that two instructions execute at the same
moment, on two cores. A program can be concurrent on a single core, and it can be parallel only if
the work and the runtime both allow it.

Every pattern in lessons 2 to 15 was written as if one thread of control walked through the code.
A loan checked its own rules, a subject notified its observers, a repository handed back an
aggregate, and nothing else ran in between. This lesson takes that assumption away and looks at
what survives.

Make `~/patterns/concurrency` and work there:

```sh
mkdir -p ~/patterns/concurrency
cd ~/patterns/concurrency
```

## Two kinds of slow

The library's software is slow in two different ways. Looking a book up in a remote catalogue is
slow because it **waits**: the program sends a request and does nothing until the answer arrives.
Building the overdue report is slow because it **computes**: the processor is busy the whole time.
This program does four of each, three ways.

```schooling-example
{"language": "python", "file": "models.py", "parts": [
 {"code": "# models.py\nimport asyncio\nimport time\nfrom concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor\n\nISBNS = [\"978-85-01\", \"978-85-02\", \"978-85-03\", \"978-85-04\"]\n\n\ndef lookup(isbn: str) -> str:\n    time.sleep(0.25)  # waiting on a remote catalogue\n    return isbn", "note": "`lookup` stands in for a call to another library's catalogue over the network. `time.sleep` is waiting, and so is reading a socket: the thread is parked and the processor is free."},
 {"code": "\nasync def lookup_async(isbn: str) -> str:\n    await asyncio.sleep(0.25)\n    return isbn", "note": "The same lookup for `asyncio`. `await` marks the one place this function lets something else run, which is what makes `asyncio` cooperative."},
 {"code": "\ndef overdue_report(n: int) -> int:\n    total = 0\n    for day in range(n):\n        total += (day * 50) % 7\n    return total", "note": "The other kind of slow: pure arithmetic, three million steps of it, with nothing to wait for."},
 {"code": "\ndef timed(label: str, job) -> None:\n    start = time.perf_counter()\n    job()\n    print(f\"{label:<28} {time.perf_counter() - start:.2f} s\")\n\n\nasync def all_lookups() -> None:\n    await asyncio.gather(*(lookup_async(i) for i in ISBNS))", "note": "`timed` prints how long a job took. `perf_counter` is the clock meant for measuring intervals."},
 {"code": "\nif __name__ == \"__main__\":\n    print(\"-- waiting: 4 lookups of 0.25 s\")\n    timed(\"one after another\", lambda: [lookup(i) for i in ISBNS])\n    with ThreadPoolExecutor(4) as pool:\n        timed(\"4 threads\", lambda: list(pool.map(lookup, ISBNS)))\n    timed(\"asyncio, 1 thread\", lambda: asyncio.run(all_lookups()))", "note": "Waiting, three ways: in a row, on four threads, and as four coroutines on one thread."},
 {"code": "\n    print(\"-- computing: 4 reports\")\n    WORK = [3_000_000] * 4\n    timed(\"one after another\", lambda: [overdue_report(n) for n in WORK])\n    with ThreadPoolExecutor(4) as pool:\n        timed(\"4 threads\", lambda: list(pool.map(overdue_report, WORK)))\n    with ProcessPoolExecutor(4) as pool:\n        timed(\"4 processes\", lambda: list(pool.map(overdue_report, WORK)))", "note": "Computing, three ways. The process pool starts four separate Python interpreters, and the time includes starting them."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 models.py
-- waiting: 4 lookups of 0.25 s
one after another            1.00 s
4 threads                    0.25 s
asyncio, 1 thread            0.25 s
-- computing: 4 reports
one after another            0.61 s
4 threads                    0.61 s
4 processes                  0.17 s
```

Your timings will differ from these, and they move a little on every run; the shape does not.
Waiting goes from a second to a quarter of a second with threads, and to the same quarter with
`asyncio` on a single thread, because four waits overlap whoever does the overlapping. Computing
is another story. **Four threads computed no faster than one, and four processes took about a third
of the time** on this four-core laptop.

## The lock inside the interpreter

The reason is the **global interpreter lock**, the GIL. The ordinary CPython interpreter lets only
one thread at a time execute Python bytecode in a process. A thread gives the lock up when it
waits, in `sleep`, on a socket or reading a file, which is why the four lookups overlapped. A
thread doing arithmetic holds it and hands it over every few milliseconds, so four of them take
turns on one core and add the cost of switching. Separate processes each have their own
interpreter and their own GIL, and run truly in parallel; the price is that they share no memory,
and everything sent between them is copied.

Python 3.13 shipped an optional **free-threaded build**, usually installed as `python3.13t`, with
no GIL at all, and 3.14 kept it as a supported option. With it, the four threads above would use
four cores. This course runs the ordinary build, and the next sections show why that changes less
than it seems: the GIL never protected *your* data, only the interpreter's own.

## Three models, and what each one shares

| model in Python | runs at the same instant? | shares memory? | where a switch can happen |
|---|---|---|---|
| `asyncio` | no, one thread | yes | only at an `await` |
| `threading` | not for Python code on the ordinary build | yes | between almost any two bytecodes |
| `multiprocessing` | yes | no, messages are copied | not applicable: nothing is shared |

The last column is the one this lesson is about. In `asyncio` you can read a value, compute, and
write it back with no risk, because nothing else runs until you write `await`. With threads, the
operating system can pause you between the read and the write. That gap is where lessons 2 to 15
quietly assumed nobody would be standing, and the next section puts somebody there.
