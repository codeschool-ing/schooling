---
title: The interface the language already knows how to call
version: 2
---

Python calls certain methods by name. Writing one plugs your class into syntax that already
exists.

## `__repr__` and `__str__`

```python
class Student:
    def __repr__(self):
        return f"Student(name={self.name!r}, city={self.city!r})"
```

`__repr__` is for a developer: the interpreter, a log line, a list printed while debugging.
**Write one for every class you define.** Without it you get `<__main__.Student object at
0x7f3c…>`, which tells you the type and nothing else, at the exact moment you wanted the contents.

`__str__` is for a person — `print(x)` and `f"{x}"` use it. If you only write one, write
`__repr__`: `str` falls back to it, and the other direction does not.

The `!r` in the f-string asks for the `repr` of each field, which is what keeps the quotes on a
string and makes the line something you could paste back.

## `__eq__`

```python
    def __eq__(self, other):
        if not isinstance(other, Student):
            return NotImplemented
        return (self.name, self.city) == (other.name, other.city)
```

Now `==` compares values rather than identity. Returning `NotImplemented` for an unrelated type
is the correct refusal — Python then tries the other object's `__eq__` before deciding.

**Defining `__eq__` sets `__hash__` to `None`**, which makes the class unhashable and unusable as a
dictionary key. That is deliberate: something that can change and compares by value would break
the dictionary it is in. Add `__hash__` back only for something immutable.

## `__len__`, `__bool__`, `__contains__`, `__getitem__`

```python
    def __len__(self):  return len(self.grades)
```

`len(x)` calls `__len__`. `if x:` calls `__bool__`, and falls back to `__len__` — so **a class
with a `__len__` and no grades is false**, which surprises people who expected an object to be
truthy for existing. `in` calls `__contains__`; `x[i]` calls `__getitem__`.

## `__lt__`, and `functools.total_ordering`

`<` calls `__lt__`, and `sorted` needs only that one. Writing all six comparisons by hand is
where mistakes live; `@total_ordering` derives the rest from `__lt__` and `__eq__`.

## The rule

**Write the ones that make your class behave like what it already is.** A class that is a
collection deserves `__len__` and `__iter__`. A class that is a value deserves `__eq__`. One that
is neither needs only `__repr__` — and `__repr__` is the one that is never wasted.
