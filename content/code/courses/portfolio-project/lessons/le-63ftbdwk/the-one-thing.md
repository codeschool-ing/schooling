---
title: The part that proves something
version: 1
---

The skeleton works. Here it is, running, with one item and two teachers who both want it:

```
ana@laptop:~/loanbook$ python3 app.py add "Projector 2"
added Projector 2
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Beatriz Nunes"}'
{"borrower": "Beatriz Nunes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Carlos Mendes"}'
{"borrower": "Carlos Mendes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s localhost:8000/api/items | python3 -m json.tool
[
    {
        "id": 1,
        "name": "Projector 2",
        "loan": {
            "borrower": "Beatriz Nunes",
            "lent_on": "2026-09-27",
            "due_on": "2026-10-04"
        }
    },
    {
        "id": 1,
        "name": "Projector 2",
        "loan": {
            "borrower": "Carlos Mendes",
            "lent_on": "2026-09-27",
            "due_on": "2026-10-04"
        }
    }
]
```

Both loans were accepted, and the list now shows **Projector 2 twice**, once for each teacher. This is
exactly Marta's first story from lesson 4, reproduced in four commands, and it is the must-not line
of the brief broken in the most direct way possible.

This is the moment the lesson is about. The skeleton proves that a page, an API and a database can
be wired together, which is what every to-do list proves. **The part of loanbook that proves
something is this refusal**, and it is not in the skeleton. If the project stopped here, it would be
lesson 2's tutorial with a different noun.

So the rule for scope is not *the smallest version that runs*. It is: **the smallest version that
contains the one thing only this project has**. For loanbook that meant the refusal went into the
milestone right after the skeleton, `v0.2.0`, ahead of styling, error pages and deploy. Lesson 2 already showed the commit
that did it, and lesson 12 shows the test that holds it.

Every project has its one thing, and the brief usually names it in the must-not line. Find it before
you cut anything, because it is the one item on the list that cannot be cut.
