---
title: The inner function, and what it remembers
version: 1
---

```python
def shout(text):
    return text.upper()

def twice(func):
    def wrapper(text):
        return func(func(text))
    return wrapper

loud = twice(shout)
loud("ada")        # 'ADA'
```

`twice` takes a function and returns a NEW function. Nothing about that is special syntax — it
is lesson 5's "a function is a value", applied twice in one place.

## The closure

`wrapper` uses `func`, which is not its own parameter and not a global. It is the parameter of
the function `wrapper` was defined inside, and it is still there after `twice` has returned.

**That is a closure**, and it is the machinery the whole lesson rests on: the inner function
remembers the variables that were around it when it was made.

```python
a = twice(shout)
b = twice(strip)
```

Two wrappers, each remembering a different `func`. They do not interfere, because each call to
`twice` made a new inner function with its own surroundings.

## Why the inner function exists at all

Because a decorator has to give back something CALLABLE that has not been called yet. It cannot
return `func(x)` — it does not have an `x`. It returns a function that will call `func` when
somebody eventually calls IT.

## The shape, before any syntax

```python
def decorator(func):
    def wrapper(...):
        # before
        result = func(...)
        # after
        return result
    return wrapper
```

Every decorator in this lesson is that shape with the details filled in. The `@` is a shorthand
for the line that uses it, and it is the next section.
