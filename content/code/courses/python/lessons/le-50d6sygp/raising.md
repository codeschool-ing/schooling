---
title: `raise`, and the message somebody will read
version: 1
---

```python
if port < 1 or port > 65535:
    raise ValueError(f"port out of range: {port}")
```

`raise` makes the failure and hands it up. Two things are your choice: the class, and the
message.

## Choosing the class

| when | class |
| --- | --- |
| the value is wrong | `ValueError` |
| the type is wrong | `TypeError` |
| a key is missing | `KeyError` |
| the file is not there | `FileNotFoundError` |
| you have not written it yet | `NotImplementedError` |
| nothing above fits, and a caller may want to catch YOUR failure | your own class |

**Do not raise `Exception("something went wrong")`.** A caller can only catch it by catching
everything, which is the situation this whole lesson is trying to avoid.

## The message

It is read by a person, at three in the morning, in a log. So it names the value:

```python
raise ValueError("invalid config")                       # useless
raise ValueError(f"{path}: port must be a number, not {raw!r}")   # actionable
```

**Which file, which field, what was there, and what was expected.** The `!r` keeps the quotes,
so an empty string and a string of spaces are distinguishable — which is exactly the case you
will be staring at.

## `raise … from e`

```python
try:
    port = int(raw)
except ValueError as e:
    raise ConfigError(f"{path}: bad port {raw!r}") from e
```

This is how you translate a low-level failure into one that means something to your caller
without losing what actually happened. The traceback then prints both, with **"The above
exception was the direct cause of the following exception"** between them.

Without the `from`, Python still chains them — as "During handling of the above exception,
another exception occurred", which reads as an accident. `from e` says it was deliberate, and
`from None` hides the original entirely, which is occasionally right and usually a loss.

## `raise` with nothing

```python
except OSError:
    log.warning("retrying")
    raise                     # the same exception, same traceback
```

A bare `raise` inside a handler re-raises what you caught. That is how you do something on the
way past without swallowing it — and it keeps the original traceback, which `raise e` would
truncate.
