---
title: "Open/closed: extend without editing"
version: 1
---

**The open/closed principle says that a module should be open for extension and closed for
modification: a new case is added by writing new code, not by editing code that already works.**
The code that is closed keeps its tests, its reviews and its months in production; the new case
arrives beside it and plugs in at a point that was left for it.

The literal reading, that working code must never be edited, is impossible and nobody means it. A
bug is fixed by editing. A rule that changes is changed where it lives. What the principle targets
is narrower: a kind of change that **keeps happening**, where every occurrence means opening the
same function and adding one more branch to it.

## The branch that keeps growing

Here is the fine rule written the obvious way, as a function that asks what kind of member it has:

```python
# by_kind.py
def fine(kind: str, days_late: int) -> int:
    if kind == "adult":
        return max(days_late, 0) * 50
    elif kind == "student":
        return max(days_late - 3, 0) * 50


def receipt(kind: str, days_late: int) -> str:
    return f"{kind}: {fine(kind, days_late)} cents"


if __name__ == "__main__":
    print(receipt("adult", 5))
    print(receipt("student", 5))
    print(receipt("child", 40))
    print(sum(fine(k, 40) for k in ("adult", "child")))
```

The library has just introduced a child membership, and the first loans are being made before
anybody has edited `fine`:

```
ana@laptop:~/patterns/solid-1$ python3 by_kind.py
adult: 250 cents
student: 100 cents
child: None cents
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/by_kind.py", line 17, in <module>
    print(sum(fine(k, 40) for k in ("adult", "child")))
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
```

A child's receipt says `None cents`, printed to a member, and the total fails one line later. The
chain fell off its end and Python returned `None`, as it does from any function that reaches its
last line. The fix is one more `elif`, in this function and in every other function in the codebase
that asks the same question: the reminder text, the loan length, the limit on how many items can be
out. Each new kind of member is a search for every copy of the chain, and the one copy missed is a
bug like this one.

## Two versions of the principle

Meyer stated the principle in 1988 with inheritance in mind: a class is closed once it is
published, and extended by subclassing it. Lesson 2 measured what that costs. Martin's restatement,
which is the one used today, puts the extension point in an **abstraction**: the closed code
depends on a description of what it needs, a protocol or an interface, and each new case is a new
implementation of it. The closed code never learns the new case's name.

| | Meyer, 1988 | Martin, 1990s |
|---|---|---|
| closed code | a published class | code that depends on an abstraction |
| extension | a subclass | a new implementation of the abstraction |
| what the closed code knows | nothing about its subclasses | the protocol, and nothing else |

## Where to leave the opening

The catch is that an extension point has to be placed **before** the extension arrives, which
means predicting which axis will vary. Nobody can make code open to every change; a function open
along every axis is an indirection on every line. The practical rule is to let the axis show itself
first. One more `elif` in one function is a cheap fix. When the same chain turns up in a second
function, or each new kind of member has started to mean a hunt through the code, the axis has shown
itself and the opening goes there.

The next section does it for the kinds of fine: a protocol for the rule, a function that is closed
against it, and a new rule added in a new file, with the old files untouched and the program run
before and after.
