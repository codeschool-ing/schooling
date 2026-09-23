---
title: `print`, and the `input` that always gives you a string
version: 2
---

`print` takes as many things as you give it, puts a space between them and a newline at the end.

```python
print("Hello,", "Ada")
```
```
Hello, Ada
```

You do not have to convert anything. `print(2 + 2)` prints `4`; `print` turns whatever it is given
into text on the way out.

## Two arguments worth knowing

`sep` is what goes between:

```python
print("2026", "09", "21", sep="-")
```
```
2026-09-21
```

`end` is what goes at the end, and `end=""` is how you print several things on one line from
inside a loop:

```python
print("working", end="")
print("...", end="")
print(" done")
```
```
working... done
```

## `input` reads a line, and it is always a string

```python
age = input("How old are you? ")
```

The text you pass is the prompt. What comes back is **always a `str`**, even when the person typed
digits — which is why this does not do what it looks like:

```python
age = input("How old are you? ")
print(age + 1)
```
```
TypeError: can only concatenate str (not "int") to str
```

Read the traceback: `str` and `int` are not things `+` knows how to put together. The fix is to
convert, and to do it where you can see it:

```python
age = int(input("How old are you? "))
```

**And `int()` refuses what is not a number**, with a `ValueError` naming what it was given. That is
lesson 8's material, and it is the correct behaviour: a program that silently turned `"twelve"`
into `0` would be worse.

## Print is not how you look at things later

`print` is how you see something now, while you are writing. It is the right tool for that and
nearly every Python programmer uses it daily.

It is not a way to record what happened — that is logging, and it is not in this course. And it is
not how a function gives a value back to the code that called it, which is the distinction lesson 5
spends a section on, because it is the one beginners most often get backwards.
