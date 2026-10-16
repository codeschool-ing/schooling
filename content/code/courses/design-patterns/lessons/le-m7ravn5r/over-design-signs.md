---
title: Signs of over-design, and the opposite signs
version: 1
---

**Over-design is structure built for a change that has not arrived.** It is easy to mistake for
good design, because it looks like the examples: interfaces, factories, small classes with one job
each. What gives it away is that the flexibility is never used. Kent Beck's name for the habit of
not building it is *you aren't gonna need it*, and Martin Fowler's catalogue of smells calls the
result **speculative generality**: hooks, parameters and abstract classes that exist for a future
nobody can point to.

The signs are concrete enough that a program can look for some of them.

## Four signs you can see in the code

**A protocol or interface with exactly one implementation, and no test double either.** An
interface is a promise that several things can stand in one place. With one thing standing there,
it is a second name for a class. The exception is a port to something you do not control, such as
a payment gateway, where the second implementation is the fake in the tests.

**A parameter nobody reads.** `for_category(category)` in `layered.py` takes a category and returns
the same policy whatever it is. The parameter was put there for the day categories differ, and
until then every caller has to supply a value that changes nothing.

**A method that only hands the work on.** `FineCalculator.compute` asks the factory and calls the
policy; `NoticeService.notice` asks the calculator and calls the formatter. A layer that adds no
rule, no check and no translation is a hop with nothing at the end of it.

**A factory that can only make one thing**, or a builder for an object with two fields. The
creational patterns of lesson 6 pay when construction is complicated or the class is chosen at run
time. A constructor with two arguments is neither.

Here is a short program that looks for the first three in a Python file. It reads the source with
the standard library's `ast` module, which turns code into a tree of nodes, and walks the tree:

```schooling-example
{"language": "python", "file": "smells.py", "parts": [
 {"code": "# smells.py\nimport ast\nimport sys\n\n\ndef protocols(tree: ast.Module) -> dict[str, set[str]]:\n    found = {}\n    for node in tree.body:\n        if isinstance(node, ast.ClassDef) and any(\n                isinstance(b, ast.Name) and b.id == \"Protocol\" for b in node.bases):\n            found[node.name] = {f.name for f in node.body if isinstance(f, ast.FunctionDef)}\n    return found\n\n\ndef methods(cls: ast.ClassDef) -> list[ast.FunctionDef]:\n    return [f for f in cls.body if isinstance(f, ast.FunctionDef)]", "note": "`protocols` finds the classes that inherit from `Protocol` and records the methods each one asks for."},
 {"code": "\ndef report(path: str) -> None:\n    tree = ast.parse(open(path).read())\n    classes = [n for n in tree.body if isinstance(n, ast.ClassDef)]\n    protos = protocols(tree)\n    print(path)\n    for name, needed in protos.items():\n        impls = [c.name for c in classes\n                 if c.name not in protos and needed <= {m.name for m in methods(c)}]\n        if len(impls) == 1:\n            print(f\"  {name}: a protocol with one implementation, {impls[0]}\")", "note": "A class implements a protocol here if it has every method the protocol names. One such class is the first sign."},
 {"code": "\n    for cls in classes:\n        if cls.name in protos:\n            continue\n        for fn in methods(cls):\n            used = {n.id for n in ast.walk(fn) if isinstance(n, ast.Name)}\n            for arg in fn.args.args[1:]:\n                if arg.arg not in used:\n                    print(f\"  {cls.name}.{fn.name}: never reads its argument {arg.arg!r}\")\n            body = fn.body\n            if (len(body) == 1 and isinstance(body[0], ast.Return)\n                    and isinstance(body[0].value, ast.Call)\n                    and isinstance(body[0].value.func, ast.Attribute)):\n                print(f\"  {cls.name}.{fn.name}: one line that hands the work to another object\")", "note": "For every method: an argument that never appears as a name in the body, and a body that is one `return` of a method called on another object."},
 {"code": "\nfor path in sys.argv[1:]:\n    report(path)", "note": "Every file named on the command line gets a report."}
]}
```

Run it on both versions of the notice from the previous section:

```
ana@laptop:~/patterns/choosing$ python3 smells.py layered.py plain.py
layered.py
  FinePolicy: a protocol with one implementation, DailyFine
  PolicyFactory.for_category: never reads its argument 'category'
  FineCalculator.compute: one line that hands the work to another object
  NoticeService.notice: one line that hands the work to another object
plain.py
```

Four lines for `layered.py` and none under `plain.py`. **Read every line as a question, never as
a verdict.** A forwarding method is exactly right in a facade or an adapter, where the forwarding
is the point. A protocol with one implementation is right where the second one is the fake in a
test file this program never opened. What the report does is put the question in front of
somebody, which is more than a design review usually manages.

## The opposite signs

Under-design is real too, and the same honesty applies in the other direction. These are signs
that a force has arrived and the code has not answered it:

- the same `if` over the same categories appears in several places, and adding a category means
  finding them all;
- one kind of change, such as a new channel, keeps touching the same five files;
- a test needs a real database or a real mail server because a detail is built inside the code it
  tests;
- two parts of the system keep breaking each other through a shared object neither owns.

Each of these is a force you can state in one sentence, which is the test section 02 set. The rule
of three, usually credited to Don Roberts, is a fair default between the two kinds of mistake: the
first time, write it plainly; the second time, notice the copy; the third time, extract the
structure, because by then you know which part varies.

## Why over-design happens anyway

It is rarely carelessness. A pattern looks like competence in a review, and a plain function looks
like something nobody thought about. Interviews ask about patterns by name, and nobody is asked to
explain the one they removed. And speculative structure feels cheap at the moment it is written,
because its cost falls on readers later, which is the arithmetic of the previous section. Knowing
these pressures exist does not make them go away. It does make it easier to ask, in a review, which
force a new interface answers.
