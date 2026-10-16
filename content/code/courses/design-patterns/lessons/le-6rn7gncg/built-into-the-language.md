---
title: When the language already has the pattern
version: 1
---

**Several GoF patterns exist because C++ and Smalltalk in 1994 lacked a feature, and in a language
that has the feature the pattern shrinks to a line or disappears.** The book's own introduction says
its choice of language shapes what counts as a pattern. A pattern is a workaround with a name, and
a workaround stops being needed when the language does the work.

Peter Norvig made the point sharply in 1996, in a talk called *Design Patterns in Dynamic
Languages*. Looking at Lisp and Dylan, he found that 16 of the 23 patterns were either invisible or
simpler there, because those languages had first-class functions, classes that are objects
themselves, and macros. Python has the first two, and so do JavaScript and, in large part, Go and
modern Java.

## Four patterns in a dozen lines

The same ideas as earlier sections, written with what Python provides.

```schooling-example
{"language": "python", "file": "vanish.py", "parts": [
 {"code": "# vanish.py\nfrom functools import cache, partial\n\nrequests = [(\"Bia\", 1, 4), (\"Caio\", 2, 0), (\"Duda\", 3, 1)]\n\n\ndef fewest_loans(request):\n    member, placed, held = request\n    return (held, placed)\n\n\nprint(\"queue:\", [member for member, *_ in sorted(requests, key=fewest_loans)])", "note": "Strategy: the rule is a function, passed to a function that takes rules. `sorted` and its `key` have been the strategy pattern all along."},
 {"code": "\nlisteners = [lambda title: print(f\"  alert: {title} is in\"),\n             lambda title: print(f\"  count: one more return, {title}\")]\nfor listen in listeners:\n    listen(\"Vidas Secas\")", "note": "Observer: a list of callables. Any function with the right arguments is a listener, with no interface to declare."},
 {"code": "\nshelf = {\"Dom Casmurro\"}\nhistory = []\n\n\ndef lend(title):\n    shelf.remove(title)\n    history.append(partial(shelf.add, title))\n\n\nlend(\"Dom Casmurro\")\nprint(\"after lending:\", shelf)\nhistory.pop()()\nprint(\"after undo:\", shelf)", "note": "Command: the undo is a function saved for later. `partial` captures the call and its argument, which is all `Lend.undo` did."},
 {"code": "\nlookups = 0\n\n\n@cache\ndef lookup(isbn):\n    global lookups\n    lookups += 1\n    return f\"book {isbn}\"\n\n\nfor isbn in [\"012-3\", \"014-7\", \"012-3\", \"012-3\"]:\n    lookup(isbn)\nprint(\"asked 4 times, looked up\", lookups)", "note": "Decorator and proxy at once: `@cache` wraps `lookup` in a function with the same signature that answers repeat calls itself, like `CachingCatalogue`."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 vanish.py
queue: ['Caio', 'Duda', 'Bia']
  alert: Vidas Secas is in
  count: one more return, Vidas Secas
after lending: set()
after undo: {'Dom Casmurro'}
asked 4 times, looked up 2
```

The lesson's other sections already showed three more of these. The factory was a dictionary of
classes, which works because a Python class is an object you can store and call. The singleton was
a module. The iterator was a generator.

## What is left after the language

| pattern | what absorbs it in Python | in Java, Go, TypeScript |
|---|---|---|
| Strategy | a function passed as an argument | lambdas (Java 8 and later), `func` values, functions |
| Command | a closure or `partial` | a lambda or `Runnable`; a `func`; a closure |
| Observer | a list of callables | listener lambdas; channels or `func` slices; event emitters |
| Iterator | `for`, generators, `yield` | enhanced `for`; range over functions (Go 1.23); `function*` |
| Decorator (of a function) | `@` syntax, `functools.wraps` | wrappers; HTTP middleware as `func(h) h`; decorators (TS 5.0) |
| Singleton | a module-level object | an `enum`; a package variable; a module export |
| Factory | a dictionary of classes | a map of constructor functions in all three |
| Visitor | `match` with class patterns (3.10 and later) | `switch` patterns (Java 21); type switch; discriminated unions |

**What survives is the idea, not the classes.** A function passed to `sorted` is still a strategy:
the decision is still separated from the code that uses it, and everything said about when that
pays still holds. Knowing the name lets you see the design in one line of Python, and lets you
explain to a Java colleague why it needs no interface.

Some patterns survive with their structure intact. A decorator of an object with several methods,
such as a fine policy that also had to describe itself, needs a class; `@` only wraps single
functions. State, facade, adapter and builder are about how responsibilities are divided, not about
a missing feature, and they look much the same in every language. **The patterns that vanish are
the ones about passing behaviour around; the ones about where boundaries go stay.** Lesson 15 picks
up the first group again from the functional side, where passing behaviour around is the whole
programme.
