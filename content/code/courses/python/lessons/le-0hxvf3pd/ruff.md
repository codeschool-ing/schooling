---
title: `ruff`, the rule families, and what `--fix` may change
version: 1
---

```sh
ruff check app/
```

```sh
F401 [*] `os` imported but unused
B006 Do not use mutable data structures for argument defaults
E722 Do not use bare `except`
A002 Function argument `filter` is shadowing a Python builtin
Found 4 errors.
[*] 3 fixable with the `--fix` option (1 hidden fix can be enabled with the `--unsafe-fixes` option).
```

**One tool where there used to be six.** `flake8`, `isort`, `pyupgrade`, `pydocstyle`,
`autoflake` and most of `pylint` are all inside it, reimplemented rather than wrapped, which is
why it runs over a large repository in under a second.

## The families

Each rule has a letter prefix naming where it came from:

- **`F`** — pyflakes: unused imports, undefined names, unused variables. Almost all real.
- **`E`** and **`W`** — pycodestyle: whitespace and layout. Mostly the formatter's job now.
- **`B`** — flake8-bugbear: **the family with the bugs in it.** Mutable defaults, a loop variable
  captured by a closure, an `assert` on a tuple.
- **`I`** — isort: import ordering, which `--fix` settles.
- **`UP`** — pyupgrade: syntax that is older than your `target-version`.
- **`SIM`** — simplifications: `if a == b: return True else: return False`.
- **`A`** — shadowed built-ins.

`ruff linter` lists all of them, and there are dozens more — `S` for security, `ANN` for missing
annotations, `PT` for pytest style.

## `[*]` and what `--fix` is allowed to do

```sh
ruff check --fix app/
```

```sh
Found 7 errors (4 fixed, 3 remaining).
```

`[*]` marks a rule with a fix `ruff` considers **safe**: one that cannot change what the program
does. Removing an unused import is safe. Sorting imports is safe.

```sh
1 hidden fix can be enabled with the `--unsafe-fixes` option
```

An unsafe fix is one that could change behaviour. `result.ok == True` becoming `result.ok` is the
example here, and it is unsafe because the two differ for anything whose `__eq__` is unusual —
`1 == True` is true and `1` is not `True`. Read an unsafe fix's diff before you take it.

## Two more flags worth knowing

```sh
ruff check --statistics app/    # a count per rule, rather than every instance
ruff check --diff app/          # what --fix would change, without changing it
```

`--statistics` is what to run first on a codebase that has never been linted, because the full
output is thousands of lines and the summary is twenty.
