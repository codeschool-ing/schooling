---
title: Documentation that runs
version: 2
---

Writing docstrings is the task people most happily hand to an assistant: it is tedious, the
assistant is fluent, and nobody reads documentation closely enough to argue with it. That last part
is the risk. **A docstring makes claims about the code, and a fluent wrong claim is believed** by
the next person, who has no reason to check it.

Python has a way to make some of those claims checkable. A docstring example written as an
interactive session (`>>>` and the expected output) is a **doctest**, and pytest can run it.

## Asking for a docstring

ana asks for three examples for the docstring of `format_price`, and asks for a negative amount
among them, because an edge case is what an example is for. A small model is far more reliable
asked for three lines than for a whole docstring, so that is what she asks for, and `--write`
keeps the block of code from the reply:

```
ana@dev:~/shop$ python scratch/assist.py ask "Write three doctest examples for format_price, one of them with a negative amount. Reply with only the >>> lines and the results, in one block of code." --open shop/money.py --write scratch/examples.txt > /dev/null
context sent (137 of 3000 tokens):
    137  shop/money.py
---
ana@dev:~/shop$ cat scratch/examples.txt
>>> format_price(1290)
'12.90'

>>> format_price(-1290)
'-12.90'

>>> format_price(1000)
'10.00'
```

Three examples, and they look like the obvious ones. ana pastes them into the docstring and,
before committing it, runs it:

```
ana@dev:~/shop$ sed -n 11,22p shop/money.py
def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90'.

    >>> format_price(1290)
    '12.90'

    >>> format_price(-1290)
    '-12.90'

    >>> format_price(1000)
    '10.00'
    """
ana@dev:~/shop$ python -m pytest -q --doctest-modules shop/money.py
F                                                                        [100%]
=================================== FAILURES ===================================
______________________ [doctest] shop.money.format_price _______________________
012 Turn cents into a price as people read it: 1290 -> '12.90'.
013 
014     >>> format_price(1290)
015     '12.90'
016 
017     >>> format_price(-1290)
Expected:
    '-12.90'
Got:
    '-13.10'

/home/ana/shop/shop/money.py:17: DocTestFailure
=========================== short test summary info ============================
FAILED shop/money.py::shop.money.format_price
1 failed in 0.74s
```

**The second example is wrong, and the code is wrong too.** The docstring says `-1290` cents
should read `'-12.90'`, which is what any person would expect. The function returns `'-13.10'`,
because Python's `//` rounds towards minus infinity: `-1290 // 100` is `-13` and `-1290 % 100` is
`10`. The example was written from what the function is for, the code does something else, and
nobody had ever asked it about a negative amount.

So the assistant's examples found a real bug, by accident, and only because they were run. If ana
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
