---
title: Deny by default
version: 1
---

**An API should refuse anything it was not told to allow.** The opposite design lists what is
forbidden and lets the rest through, and it fails in the worst direction: every role, route or
action somebody forgot to mention is open.

The difference is easiest to see in two versions of one check. The first is a list of refusals:

```python
def allowed(role, action):
    if role == "customer" and action in ("orders:refund", "people:read"):
        return False
    return True
```

The second is a list of grants:

```python
def allowed(role, action):
    return action in ROLES.get(role, set())
```

They agree on every case their author thought of, and disagree on everything else. A new role
`auditor` added to the database, a new action `orders:export` added to the code, a role name typed
with a mistake in it: the first function answers `True` to all three and the second answers
`False`. One of those failures is a colleague asking why they cannot export. The other is a
stranger who can, and nobody hears about it.

**Deny by default runs through every layer of `orders.py`**, and each layer has its own way of
saying no:

| what is missing | what the caller gets |
|---|---|
| a token, or a token the API never issued | 401, for every address, real or not |
| a route for that address | 404 |
| a route for that method at that address | 405 |
| the route's permission, in the caller's set | 403 |
| the caller's role, in the `ROLES` table | an empty set of permissions, so 403 everywhere |

The last row is the one most often written the other way. `ROLES.get(role, set())` gives a role
nobody wrote permissions for no permissions at all. `ROLES[role]` would have crashed the request
with a `KeyError`, which is at least loud, and a default of "everything" would have made every
misspelt role an administrator. The people table holds such a role on purpose: Eva is an
`auditor`, and "The orders API" shows what she gets.

The same rule covers a route. Each row of `ROUTES` names the permission it needs, and a row
written with the wrong name, `order:read` for `orders:read`, is a route nobody can call. That is a
bug somebody finds in the first minute. The reverse, a route that needed no permission because
nobody wrote one, is a bug nobody finds.
