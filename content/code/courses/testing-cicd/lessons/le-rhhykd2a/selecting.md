---
title: Running part of the suite
version: 1
---

A suite grows, and soon you want to run part of it: the unit tests on every save, the slow layers
before a push, one test while you fix it. pytest gives two selectors, and both are worth knowing
because a pipeline uses them too.

**Markers** select by label. A marker is declared once in `pyproject.toml`, with a sentence saying
what it means:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"
markers = [
    "integration: talks to a real SQLite file",
    "functional: starts the HTTP server",
    "acceptance: a promise the shop makes, checked from outside",
]
```

and attached to a test or, with `pytestmark`, to a whole file. `-m` then takes an expression over
marker names, with `and`, `or` and `not`.

**Keywords** select by name: `-k free` runs every test whose name contains `free`. That makes test
names part of the interface, one more reason to name them after the rule.

```
ana@laptop:~/shipquote$ python -m pytest --collect-only -q -m "not functional and not acceptance" | tail -1
27/31 tests collected (4 deselected) in 0.14s
ana@laptop:~/shipquote$ python -m pytest -q -k free
.....                                                                    [100%]
5 passed, 26 deselected in 0.69s
ana@laptop:~/shipquote$ python -m pytest -q -m smoke; echo "exit status $?"

31 deselected in 0.14s
exit status 5
```

The first command asks how many tests a run would pick without running them: 27 of 31, four
deselected. The second runs the five tests with `free` in the name, and they come from three files.

## The selector that selects nothing

The third command is the one to remember. `smoke` is not a marker this project declares. pytest ran
nothing, printed `31 deselected`, and **did not complain about the name**. The
`--strict-markers` option in the configuration refuses an undeclared marker *on a test*, and it
does nothing for a typo in `-m`.

What saves you is the exit status. pytest exits with **5** when no test was collected, which is
different from 0 for "all passed" and 1 for "some failed". A pipeline step that runs
`pytest -m smoke` fails on a 5, as long as nobody wraps the command in something that throws the
status away. Lesson 5 shows how often that happens in a pipeline, with `|| true` and with pipes.

**A green run that ran nothing is the most dangerous result a suite can give**, because it looks
exactly like success. When a selected run matters, check the count as well as the colour: a
pipeline that used to run 31 tests and now runs 0 has broken, whatever the exit status says.

## Fast first, then the rest

The usual arrangement, locally and in a pipeline, is two passes:

1. the fast layer, `-m "not integration and not functional and not acceptance"`, on every change,
   because it answers in well under a second;
2. everything, before the change is shared.

The order matters for the feedback, not for the result: a mistake in a pricing rule shows up in
the first pass, before the slower layers have started. Lesson 5 builds exactly this into the
course's pipeline.
