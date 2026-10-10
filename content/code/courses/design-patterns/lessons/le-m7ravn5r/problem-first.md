---
title: Problem first: name what hurts before naming a pattern
version: 1
---

**A pattern is an answer, and an answer chosen before the question is a cost with a name on it.**
The habit this lesson argues against is a familiar one: you have just read about a strategy or an
event store, a piece of code looks a little like the examples, and the pattern goes in. The code
gets more classes and the problem it actually had, if it had one, is left where it was.

The catalogues were written the other way round. Each entry in the 1994 book from lesson 6 starts
with an *intent* and a section called *applicability*: the situation in which the pattern pays.
Christopher Alexander, the architect the software patterns borrowed the idea from, defined a
pattern as a problem that keeps recurring in a context, together with the core of its solution.
Strip the problem off and what is left is a shape, and a shape alone cannot tell you whether it
belongs in your code.

## A force is one sentence about change or knowledge

The word for the problem is a **force**: a pressure on the code that makes one arrangement better
than another. A useful force can be said in one sentence, and it is nearly always about one of two
things. Either something changes and the change is expensive, or some part knows something it
should not.

- *Every term the library adds a member category, and each one means editing the fine function.*
- *We are switching e-mail providers, and the provider's client is called from eleven places.*
- *The overdue report cannot be tested without a real SMTP server.*
- *Building a loan takes nine optional settings, and callers keep passing them in the wrong order.*

Each of those points at a family of answers. None of them is the name of a pattern, and that is
what makes them useful: you can check a sentence like that against the code and its history,
and you cannot check "this would be cleaner with a factory".

## One piece of code, three different answers

Here is a function the library has had for years. It is the kind of thing that attracts patterns:

```python
def fine(category: str, days_late: int) -> int:
    if category == "adult":
        return max(days_late, 0) * 50
    elif category == "student":
        return max(days_late, 0) * 25
    elif category == "staff":
        return 0
    raise ValueError(category)
```

Ask what hurts, and the answer depends on facts that are not in the code.

If a new category arrives every term and only the number differs, the force is *a rate that
varies by category*. The answer is a table, a dictionary from category to cents, and section 05
builds it. A strategy class per category would be three classes holding one number each.

If films are about to be fined differently from books, capped at the price of the item, the force
is *a rule that varies by kind of item*. Now the variation is a calculation and not a number, and
functions chosen by kind are worth it.

If the function has been edited twice in three years and nobody is planning a third, **there is no
force, and the right change is none**. An `if` with three branches that everybody can read in ten
seconds is not a problem waiting for a pattern.

The code was the same in all three cases. What decided was the history of the file and the plan
for it. In a real repository `git log --oneline -- fines.py` answers the first half in seconds:
how often the file changed, and whether the changes were all the same kind.

## Forces and the families that answer them

| when the force is... | look at | in this course |
|---|---|---|
| one rule, several versions, chosen at run time | strategy, or a dictionary of functions | lessons 6 and 15 |
| several parts must react to one event | observer | lessons 6 and 16 |
| a part you do not own has the wrong interface | adapter, anti-corruption layer | lessons 6 and 11 |
| a detail must be swappable or fakeable in tests | a port and an injected dependency | lessons 4 and 5 |
| reads and writes pull one model two ways | CQRS | lesson 8 |
| you must answer "what happened, and when" | an append-only log of events | lesson 9 |
| an invariant spans several objects | an aggregate | lesson 12 |

Read the table from the left. Starting on the right, with a pattern you would like to use, and
looking for a row to justify it, is the habit this section began with.
