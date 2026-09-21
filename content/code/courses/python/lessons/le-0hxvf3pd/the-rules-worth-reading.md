---
title: Four findings that are bugs rather than tidiness
version: 1
---

Most of what a linter reports is housekeeping. These are not, and each one has shipped.

## `B006` — a mutable default argument

```python
def load_rates(path, cache={}):
    if path in cache:
        return cache[path]
    cache[path] = read(path)
    return cache[path]
```

```sh
>>> load("a.json"); load("b.json")
>>> load.__defaults__
({'a.json': {...}, 'b.json': {...}},)
```

**The dictionary is created once, when the `def` runs.** It is not per call — it is attached to
the function object and it lives as long as the process. Written as a cache it looks like it
works, and it never empties, and it is shared by every caller including the ones in tests.

The fix is `cache=None` and `if cache is None: cache = {}` inside.

## `E722` — a bare `except`

```python
try:
    data = json.load(f)
except:
    return {}
```

`except:` catches **`BaseException`**, which includes `KeyboardInterrupt` and `SystemExit`. So
Ctrl-C inside that block is swallowed, and a `NameError` in the line above becomes an empty
dictionary that the rest of the program treats as real data.

`except Exception:` is the version that at least lets you stop the process. `except
json.JSONDecodeError:` is the one you meant.

## `B023` — a loop variable captured by a closure

```python
out = []
for i in range(3):
    out.append(lambda: i)
[f() for f in out]        # [2, 2, 2]
```

```sh
B023 Function definition does not bind loop variable `i`
```

The closures share the variable, not its value, and the loop finished with it at `2`. It arrives
in real code as a list of callbacks built in a loop that all do the last one's work.

The fix is a default argument — `lambda i=i: i` — which binds the value at definition, and is the
one case where the thing `B006` warns about is the tool for the job.

## `A002` — shadowing a built-in

```python
def summarise(rows, filter=None, id=None, type=None):
    ...
```

Less dramatic, and it bites where you cannot see it: inside that function, `filter`, `id` and
`type` are the arguments and the built-ins are unreachable. A line added later that calls
`type(x)` gets a `TypeError` about `None` not being callable, in a function that has not changed.

## And the ones that are tidiness

`F401` unused import, `I001` unsorted imports, `SIM103` returning a comparison the long way,
`UP` rewriting old syntax. Worth fixing, worth `--fix`, not worth a conversation — which is the
distinction this section exists to make.
