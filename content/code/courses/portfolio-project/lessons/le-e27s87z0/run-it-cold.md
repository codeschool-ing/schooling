---
title: Run it on a machine where it has never run
version: 1
---

*It needs Python 3.12 or newer and nothing else* is a claim, and the only way to know whether it is true
is to try it where nothing else is installed. Your own machine is the worst place for that test: it has
every package you ever installed, every variable you ever set, and a database left over from last week.

srv is a better place. It has Python and git from the lab, and nothing of loanbook's. Following the
README's *Run it* section, with the clone taken from the lab's own repository instead of the placeholder
address, and `python3 app.py` started in the background:

```
ana@srv:~$ python3 --version
Python 3.12.3
ana@srv:~$ git clone -q loanbook.git && cd loanbook && ls
Containerfile
LICENSE
README.md
app.py
deploy
docs
seed.py
static
test_app.py
ana@srv:~/loanbook$ python3 seed.py
seeded 8 items, 4 of them out
ana@srv:~/loanbook$ curl -s localhost:8000/api/items | python3 -c 'import json,sys; print(len(json.load(sys.stdin)), "items")'
8 items
ana@srv:~/loanbook$ python3 -m unittest 2>&1 | tail -3
Ran 7 tests in 0.003s

OK
```

Python 3.12, a clone, the seed script, a server that answers with eight items, and the tests passing. The
claim holds. If it had not, the fix would have gone into the README, or the code, before anybody else hit
it, and that is the point of running it cold.

For your own project, the clean machine can be a virtual machine, a container started from a bare image, a
friend's laptop, or a fresh user account. What matters is that **you type exactly what the README says,
nothing more**. The step you do out of habit and forgot to write down, a variable, a package, a folder
that has to exist, is the one a reviewer will be stuck on, and the one they will remember.
