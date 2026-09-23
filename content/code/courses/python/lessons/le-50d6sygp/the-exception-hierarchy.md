---
title: Classes, and the two you must not catch
version: 2
---

Every exception is a class, and they form a tree:

```
BaseException
 ├── SystemExit           ← sys.exit()
 ├── KeyboardInterrupt    ← Ctrl-C
 └── Exception
      ├── ValueError
      ├── TypeError
      ├── LookupError
      │    ├── KeyError
      │    └── IndexError
      ├── OSError
      │    └── FileNotFoundError
      └── ...
```

`except LookupError` catches a `KeyError` and an `IndexError`, because catching a class catches
everything below it. That is the only rule you need from the picture.

## `except Exception`, and never a bare `except`

```python
try:
    ...
except:              # NO
except Exception:    # the wide net, when you want one
```

`SystemExit` and `KeyboardInterrupt` sit OUTSIDE `Exception` on purpose: they are not program
errors, they are somebody asking the program to stop. A bare `except` catches them, and then
`Ctrl-C` does not work.

**`except Exception` belongs at the top of a program**, once, where the job is to log what
happened and exit with a non-zero status. Everywhere else it is a net cast over code you have
not read.

## Catching a class catches its children

```python
except OSError:          # includes FileNotFoundError and PermissionError
except (ValueError, TypeError):    # two unrelated ones, one tuple
```

The tuple form is for unrelated classes. The base-class form says something about what you are
willing to handle, so it ages better as the code below it grows.

## What an exception carries

```python
except ValueError as e:
    print(e)             # the message
    print(type(e))       # the class
```

The object has the message, the class, and the traceback. In a log, print all three — the class
alone says `ValueError` and the message alone says `invalid literal for int()`, and neither of
them says which line.
