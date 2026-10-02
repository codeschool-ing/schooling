---
title: Documentation that runs
version: 1
---

Writing docstrings is the task people most happily hand to an assistant: it is tedious, the
assistant is fluent, and nobody reads documentation closely enough to argue with it. That last part
is the risk. **A docstring makes claims about the code, and a fluent wrong claim is believed** by
the next person, who has no reason to check it.

Python has a way to make some of those claims checkable. A docstring example written as an
interactive session (`>>>` and the expected output) is a **doctest**, and pytest can run it.

## Asking for a docstring

ana asks for a docstring with examples for `format_price`. The reply was written by the course:

```
ana@dev:~/shop$ assist ask "Write a docstring with examples for format_price." --open shop/money.py
context sent (137 of 3000 tokens):
    137  shop/money.py
---
    """Turn cents into a price as people read it.

    >>> format_price(1290)
    '12.90'
    >>> format_price(5)
    '0.05'
    >>> format_price(-5)
    '-0.05'
    """

```

Three examples, and they look like the obvious ones. ana puts the docstring into `shop/money.py`
and, before committing it, runs it:

```
ana@dev:~/shop$ python -m pytest -q --doctest-modules shop/money.py
F                                                                        [100%]
=================================== FAILURES ===================================
______________________ [doctest] shop.money.format_price _______________________
012 Turn cents into a price as people read it.
013 
014     >>> format_price(1290)
015     '12.90'
016     >>> format_price(5)
017     '0.05'
018     >>> format_price(-5)
Expected:
    '-0.05'
Got:
    '-1.95'

/home/ana/shop/shop/money.py:18: DocTestFailure
=========================== short test summary info ============================
FAILED shop/money.py::shop.money.format_price
1 failed in 0.55s
```

**The third example is wrong, and the code is wrong too.** The docstring says `-5` cents should
read `'-0.05'`, which is what any person would expect. The function returns `'-1.95'`, because
Python's `//` rounds towards minus infinity: `-5 // 100` is `-1` and `-5 % 100` is `95`. The
example was written from what the function is for, the code does something else, and nobody had
ever asked it about a negative amount.

So the assistant's docstring found a real bug, by accident, and only because it was run. If ana
had read the three examples and committed them, the documentation would now state something false
about the code, in the one place people look to find out what it does. Lesson 4 comes back to this
function and finds the whole class of inputs it gets wrong.

## Rules for generated documentation

- **Run every example.** A doctest, a snippet in the README that a test executes, an API sample
  that CI calls. Documentation that is executed cannot drift from the code without failing.
- **Check every claim that is not an example** against the code: the exceptions it raises, the
  units of its arguments, what it does with an empty list. These are exactly the details a fluent
  writer fills in by plausibility.
- **Prefer the reason over the paraphrase.** `"""Return the total."""` above `def total()` says
  nothing the name did not. What a reader needs from a docstring is what the code cannot say: the
  unit, the rounding rule, why the threshold is after the discount. That is knowledge about the
  project, and the assistant only has it if you put it in the context.
