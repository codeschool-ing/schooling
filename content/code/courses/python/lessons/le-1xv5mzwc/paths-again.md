---
title: Beside the script, not beside the terminal
version: 2
---

```python
open("data/rows.csv")
```

That path is relative to the **current working directory** — where the terminal was when you
typed `python`, not where the script is. Run it from anywhere else and it fails, and the failure
is a `FileNotFoundError` naming a path that plainly exists.

## The file that lives beside the script

```python
from pathlib import Path

HERE = Path(__file__).resolve().parent
rows = HERE / "data" / "rows.csv"
```

`__file__` is the path of the module being run. `.resolve()` makes it absolute and removes any
`..`, and `.parent` is the directory. From then on the path works from any directory.

**This is the right shape for data that ships with the code** — a template, a fixture, a small
lookup table.

## And the file that does not

Data the USER names belongs on the command line, relative to where they are:

```python
path = Path(sys.argv[1])
```

That is the opposite case, and the relative-to-the-terminal behaviour is correct there.

Config, caches and output usually belong somewhere else again, and `os.environ` or an explicit
argument is how the deployment says where.

## `resolve` and `exists`

```python
path.resolve()          # absolute, symlinks followed, `..` removed
path.expanduser()       # ~ becomes the home directory
```

`open("~/data.csv")` does NOT work: the shell expands `~`, and Python does not. `Path("~/
data.csv").expanduser()` is the version that does.

## Printing the path in the error

```python
raise FileNotFoundError(f"no rows file at {rows.resolve()}")
```

A relative path in an error message is the least useful string in programming, because the reader
does not know what it was relative to. **Resolve it before you print it**, and the message stops
being a puzzle.
