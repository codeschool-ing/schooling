---
title: Doing arithmetic on a tree
version: 1
---

A tree with numbers on its leaves can be evaluated, and evaluating it answers the question a
defender actually has: **if we put this control in place, what does the cheapest route to the goal
cost now?** The rule is the one under the figure in the previous section: an OR node is worth its
cheapest child, an AND node the sum of its children. A control makes a leaf impossible, which
gives it an infinite cost.

`tree.py` is the tree of the previous section, written as nested tuples, with four controls the
team was discussing:

```schooling-example
{"language": "python", "file": "tree.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"An attack tree for one goal, and what controls do to the cheapest way to reach it.\"\"\"\nimport sys\n\nNEVER = float(\"inf\")\n", "note": "Standard library only. An impossible leaf costs infinity, which every sum and every minimum handles without a special case."}, {"code": "# A node is (\"OR\" or \"AND\", name, children), or (days, name) for a leaf.\n# Days are the team's estimate of an outsider's effort, not a measurement.\nTREE = (\"OR\", \"Mark a booking paid without paying\", [\n    (\"AND\", \"Forge the gateway's webhook\", [\n        (1, \"Learn the webhook's address\"),\n        (1, \"Send a request the portal accepts\"),\n    ]),\n    (\"AND\", \"Change the status in the staff console\", [\n        (5, \"Take over a staff account\"),\n        (2, \"Reach the console\"),\n    ]),\n    (\"AND\", \"Change the row in the database\", [\n        (10, \"Take over the reminder worker\"),\n        (1, \"Use its owner account\"),\n    ]),\n])\n", "note": "The tree of the figure. A node is a kind, a name and its children; a leaf is an estimate and a name. The estimates are the team's, in days of an outsider's effort."}, {"code": "# Each control makes one leaf impossible.\nCONTROLS = {\n    \"signature\": \"Send a request the portal accepts\",\n    \"mfa\": \"Take over a staff account\",\n    \"clinic-only\": \"Reach the console\",\n    \"least-privilege\": \"Use its owner account\",\n}\n\n", "note": "Each control the team discussed, and the one leaf it makes impossible. A real control can block several leaves; these block one each."}, {"code": "def cheapest(node, blocked):\n    \"\"\"The attacker's cheapest cost for a node, and the leaves on that route.\"\"\"\n    if not isinstance(node[0], str):\n        days, name = node\n        return (NEVER if name in blocked else days), [name]\n    kind, _, children = node\n    routes = [cheapest(child, blocked) for child in children]\n    if kind == \"OR\":\n        return min(routes, key=lambda route: route[0])\n    return sum(days for days, _ in routes), [leaf for _, leaves in routes for leaf in leaves]\n\n", "note": "The whole method in one function. A leaf returns its estimate, or infinity if blocked. An OR returns its cheapest child; an AND adds its children and keeps every leaf on the way."}, {"code": "chosen = sys.argv[1:]\ndays, leaves = cheapest(TREE, {CONTROLS[c] for c in chosen})\nprint(\"controls:\", \", \".join(chosen) or \"none\")\nif days == NEVER:\n    print(\"cheapest: unreachable\")\nelse:\n    print(f\"cheapest: {days:g} days\")\n    for leaf in leaves:\n        print(\"  -\", leaf)", "note": "The controls come from the command line, and the program prints the cheapest route that is left."}]}
```

Run it with no controls, and then add them one at a time, in the order the team proposed:

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py
controls: none
cheapest: 2 days
  - Learn the webhook's address
  - Send a request the portal accepts
```

Two days, through the webhook: T01 is the cheapest way to the goal by a wide margin.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature
controls: signature
cheapest: 7 days
  - Take over a staff account
  - Reach the console
```

**Verifying the gateway's signature does not make the goal unreachable. It moves the attacker to
the next branch**, which costs seven days instead of two. That is the most common lesson an attack
tree teaches: a control is worth what it adds to the cheapest remaining path, not what it removes
from the path it blocks.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa
controls: signature, mfa
cheapest: 11 days
  - Take over the reminder worker
  - Use its owner account
```

With a second factor for staff, the console branch is gone too, and the cheapest route is the
worker, at eleven days.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa clinic-only
controls: signature, mfa, clinic-only
cheapest: 11 days
  - Take over the reminder worker
  - Use its owner account
```

**Adding `clinic-only` changed nothing.** Keeping the console off the internet is a good control,
and lesson 3's T12 is a real threat, but the console branch was already broken by `mfa`. For this
goal, that money buys nothing. For another goal, such as reading every record, it may buy a lot,
which is why a tree is drawn per goal.

```
(.venv) ana@vm:~/tm/portal-model$ python3 tree.py signature mfa least-privilege
controls: signature, mfa, least-privilege
cheapest: unreachable
```

The least-privilege database account breaks the last branch, and the goal becomes unreachable
through every route this tree knows. That last phrase matters: **the tree only knows the routes
somebody drew.** "Unreachable" means the team found no other way in the drawing, not that none
exists, and the next review should start by asking what branch is missing.

### What the numbers are

The days are estimates from the team, in a unit chosen because it was easy to argue about. They
are not measurements, and the tree's output inherits that. What survives the uncertainty is the
**comparison**: whether one control moves the cheapest path from two days to seven is robust to
the exact numbers, because the order of the branches does not change unless an estimate is badly
wrong. Lessons 9 and 10 return to estimates, and to ranges instead of single numbers.
