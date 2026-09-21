---
title: `self` is the instance, and nothing else is unusual
version: 1
---

```python
class Student:
    def __init__(self, name, city):
        self.name = name
        self.city = city

ada = Student("Ada", "Porto")
ada.name          # 'Ada'
```

`class` makes a type. Calling it makes an INSTANCE — `Student(...)` builds one and hands it back.
`__init__` runs on the new object and sets its attributes.

## `self`

`self` is the instance, passed as the first argument. It is a parameter name, not a keyword:
Python fills it in when you call a method on an object.

```python
ada.greet()          # Python calls Student.greet(ada)
Student.greet(ada)   # the same call, written out
```

**That sentence is the whole of object orientation in Python.** `self` is called `self` by
convention and nothing would break if you called it something else — except every reader's
expectation, which is reason enough.

## Set every attribute in `__init__`

```python
class Student:
    def __init__(self, name):
        self.name = name
        self.grades = []        # even though it starts empty
```

An attribute created later, inside some other method, is an attribute a reader cannot find by
looking at the top. **`__init__` is where the shape of the object is written down**, and an empty
list assigned there is cheaper than a `hasattr` check somewhere else.

## There is no `new`, and there are no private attributes

`Student("Ada", "Porto")` is the construction; no keyword in front of it. And nothing is private:
a leading underscore — `self._cache` — is a convention meaning "this is mine, do not touch", and
Python will not stop you. **It is a message to a person, enforced by nobody.**

## Two instances are two objects

```python
a = Student("Ada", "Porto")
b = Student("Ada", "Porto")
a == b            # False, until __eq__ says otherwise
```

Same values, different objects — lesson 4's `==` against `is`, one layer up. The section on
special methods is where `==` is taught what equality means here.
