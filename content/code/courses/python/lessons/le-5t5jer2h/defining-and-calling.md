---
title: `def`, the body, and what comes back when nothing does
version: 2
---

```python
def greet(name):
    return f"hello, {name}"

print(greet("ada"))
```

`def`, a name, the parameters in parentheses, a colon, and an indented body — the same block rule
as lesson 4. Nothing runs when the `def` line runs; it binds a name to the body, and the body
waits for a call.

## Defining and calling are different moments

```python
greet          # the function itself
greet("ada")   # the call
```

**The parentheses are the call.** A name with no parentheses is the function as a value, which
looks like a mistake right up to the section that uses it on purpose.

## A function with no `return`

```python
def shout(text):
    print(text.upper())

result = shout("ada")     # result is None
```

Every function returns something. A body that falls off the end returns `None` — which is a
value, not the absence of one, and `if shout("ada"):` is therefore a test that never passes.

**The commonest version of this is `sorted` against `sort` from lesson 3**, one layer up: a
function that does its work by printing has nothing to give the next line.

## Naming

A verb, and what it acts on: `load_rows`, `is_valid`, `send_invoice`. `process_data` says
nothing at all; `get_` in front of everything says nothing either.

**A function that needs "and" in its name is two functions.** `validate_and_save` is the shape
that makes testing awkward, and lesson 16 is where that bill arrives.

## Calling before defining

```python
def main():
    helper()          # fine — this line runs later

def helper():
    ...

main()
```

The name is resolved when the call runs, not when the body is read. So order inside a file is
for whoever reads it, with one exception: a call at module level can only reach what has already
been defined above it.
