---
title: The other one, and where they disagree on purpose
version: 2
---

```sh
mypy:    error: Incompatible types in assignment (expression has type "str",
                variable has type "int")  [assignment]
pyright: error: Type "Literal['no']" is not assignable to declared type "int"
                (reportAssignmentType)
```

The same two lines of code, the same verdict, two sentences. `pyright` is Microsoft's checker,
it is what runs inside the editor as Pylance, and it reports `line:column` rather than a line —
which is why an error lands on the right half of a long line rather than on the whole of it.

## Its modes

```json
{
  "include": ["app"],
  "typeCheckingMode": "strict",
  "pythonVersion": "3.12"
}
```

`pyrightconfig.json`, or a `[tool.pyright]` table in `pyproject.toml`. The mode is one of `off`,
`basic`, `standard` or `strict`, and `standard` is the default. Each rule underneath has a name
of its own — `reportAssignmentType`, `reportArgumentType` — and can be set to `"error"`,
`"warning"` or `"none"` individually.

## The disagreement that matters

```python
def total(items):
    n: int = "zero"
    return n
```

`mypy` emits a note saying it skipped the body. `pyright` reports the error. **Pyright checks
unannotated functions and mypy does not**, which is why the same codebase can be clean under one
and loud under the other — and why `check_untyped_defs` is the flag that makes them agree.

`pyright` also narrows harder in its messages: `Literal[42]` where `mypy` says `int`. Both are
right; one is telling you more.

## Ignore comments are not interchangeable

```python
n: int = "a"  # pyright: ignore[reportAssignmentType]
m: int = "b"  # type: ignore
```

`pyright` accepts both. `mypy` does not know what `# pyright: ignore` means and still reports
line 1. **If a project runs both, the portable comment is `# type: ignore[code]`** — and
`# pyright: ignore` is for the rule only `pyright` has.

## Which to run

In the editor, `pyright`, because it is fast enough to answer while you type and you are probably
already running it without having chosen to. In CI, whichever one the project's config file
names — and one of them, not both, unless somebody is willing to keep two sets of ignore comments
honest.
