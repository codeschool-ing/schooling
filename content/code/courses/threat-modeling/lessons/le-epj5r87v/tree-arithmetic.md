---
title: Doing arithmetic on a tree
version: 1
---

A tree with numbers on its leaves can be evaluated, and evaluating it answers the question a
defender actually has: **if we put this control in place, what does the cheapest route to the goal
cost now?** The rule is the one under the figure in the previous section: an OR node is worth its
cheapest child, an AND node the sum of its children. A control makes a leaf impossible, which
gives it an infinite cost.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l05-tree-numbers\" aria-label=\"The attack tree with the team’s estimates of an outsider’s effort, in days, on its leaves. Forging the webhook needs both the address, 1 day, and an accepted request, 1 day: an AND node, 2 days. Changing the status in the console needs a staff account, 5 days, and reaching the console, 2: 7 days. Changing the row in the database needs the reminder worker, 10 days, and its owner account, 1: 11 days. The root is an OR, worth its cheapest child: 2 days.\"><rect x=\"220.0\" y=\"10.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mark a booking paid without paying</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">OR = cheapest child: 2 days</text><path d=\"M360.0 54.0 L120.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">forge the webhook</text><text x=\"120.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 1 + 1 = 2</text><path d=\"M120.0 144.0 L65.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"13.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"65.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">address</text><text x=\"65.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 day</text><path d=\"M120.0 144.0 L175.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"123.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"175.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">accepted request</text><text x=\"175.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 day</text><path d=\"M360.0 54.0 L360.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">use the console</text><text x=\"360.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 5 + 2 = 7</text><path d=\"M360.0 144.0 L305.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"253.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"305.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">staff account</text><text x=\"305.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5 days</text><path d=\"M360.0 144.0 L415.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"363.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"415.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">reach console</text><text x=\"415.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 days</text><path d=\"M360.0 54.0 L600.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">change the row</text><text x=\"600.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AND 10 + 1 = 11</text><path d=\"M600.0 144.0 L545.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"493.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"545.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">take the worker</text><text x=\"545.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">10 days</text><path d=\"M600.0 144.0 L655.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"603.0\" y=\"200.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"655.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">owner account</text><text x=\"655.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 day</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">AND adds its children; OR takes the cheapest</text></svg>", "caption": "With no controls, the webhook is the cheapest route by a wide margin, which is why the signature check comes first."}
```

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
