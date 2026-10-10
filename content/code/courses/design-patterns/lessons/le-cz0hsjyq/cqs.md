---
title: "Command-query separation: change or answer, never both"
version: 1
---

**A method should either change the state of the object or return an answer about it, and never do
both.** Bertrand Meyer stated the rule in *Object-Oriented Software Construction* in 1988, and named
the two kinds *commands* and *queries*. A query can be called any number of times, in any order, from
a log line or a debugger or a test, and nothing changes. A command is called when you mean the change.
The rule is about method signatures, and CQRS two sections on is the same rule applied to whole models.

The belief to put aside is that a method returning something useful is harmless. It is harmless when
it is a query. When it is also a command, every place that only wanted the answer causes the change
as well.

```schooling-example
{"language": "python", "file": "cqs.py", "parts": [
 {"code": "# cqs.py\nclass Shelf:\n    def __init__(self, copies: list[str]):\n        self._copies = list(copies)\n\n    def take(self) -> str:\n        return self._copies.pop(0)\n\n    def count(self) -> int:\n        return len(self._copies)", "note": "`take` answers a question, which copy comes next, and changes the shelf in the same call. `list.pop` does the same thing, which is where the habit comes from."},
 {"code": "\n\nclass SeparatedShelf:\n    def __init__(self, copies: list[str]):\n        self._copies = list(copies)\n\n    def next_copy(self) -> str:\n        return self._copies[0]\n\n    def remove(self, copy_id: str) -> None:\n        self._copies.remove(copy_id)\n\n    def count(self) -> int:\n        return len(self._copies)", "note": "The same shelf with the two jobs apart. `next_copy` answers and changes nothing; `remove` changes and answers nothing."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf([\"C1\", \"C2\", \"C3\"])\n    print(\"debugging, which copy is next?\", shelf.take())\n    lent = shelf.take()\n    print(\"lent\", lent, \"| left on the shelf:\", shelf.count())\n\n    shelf = SeparatedShelf([\"C1\", \"C2\", \"C3\"])\n    print(\"debugging, which copy is next?\", shelf.next_copy())\n    lent = shelf.next_copy()\n    shelf.remove(lent)\n    print(\"lent\", lent, \"| left on the shelf:\", shelf.count())", "note": "Each half of the program asks the same question once while debugging, then lends a copy. Only the call that looks harmless differs."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 cqs.py
placeholder
```

The first half lent **C2**, not C1, and left one copy where two should be. The debugging line asked
which copy was next, and asking took it. Nobody reading `print("…", shelf.take())` in a review sees a
loan; it looks like a question. The second half asked the same question twice and lent C1, with two
copies left, because `next_copy` is a query and asking is free.

## What the rule buys

**A query is safe to call from anywhere.** You can put it in a log line, an assertion, a debugger's
watch window or a test's setup, and it means the same thing each time. Meyer's argument was exactly
this: a program whose questions are side-effect free can be reasoned about by asking it questions.

**A command's name says that something changes.** `remove(copy_id)` reads as a change and returns
`None`, so nobody calls it to find something out. In Python a method that returns `None` makes the
intent visible at every call site; the same holds for a Java `void` method or a Go function that
returns only an `error`.

**The two can be tested apart.** A query is tested by building a state and asking. A command is
tested by calling it and then asking a query whether the state moved, which keeps the assertions in
one vocabulary.

## Where the rule bends

Meyer's rule has well-known exceptions, and pretending otherwise teaches people to distrust it.

| exception | why it returns and changes | in the standard library |
|---|---|---|
| taking from a stack or a queue | the caller needs the item that was removed, and asking first then removing is two steps | `list.pop`, `queue.Queue.get`, `deque.popleft` |
| an iterator | moving forward and handing back the next element is one act | `next(it)` |
| an atomic operation under concurrency | splitting "is it free?" from "take it" lets another thread take it in between | `dict.setdefault`, a database `INSERT … RETURNING id` |

The last row matters most. With two threads or two requests, `if shelf.next_copy() == "C1":
shelf.remove("C1")` can be interleaved so that both see C1 free and both remove it. When the answer
and the change must happen together, one method that does both is correct, and lesson 18 shows races of
exactly this kind.

A softer case is a command that returns an identifier it created, such as the id of a new loan. It
is a common and reasonable bend: the caller cannot learn the id any other way without a second
query that might race. What the rule still forbids is a command returning a view of the world, the
whole member record or the screen's next rows, because then every caller that wants the view runs
the command.

## In your language

The rule is the same everywhere; what differs is how loudly the signature says it. Java and
TypeScript mark a command with `void`, and Go with a function that returns only `error`. In Python a
method annotated `-> None` says the same, and a type checker such as mypy will flag the caller that
tries to use its result. Go's `sync.Map` is a good place to see the concurrency exception named
honestly: `LoadOrStore` returns the value and whether it was already there, because asking and
storing in two calls would race.
