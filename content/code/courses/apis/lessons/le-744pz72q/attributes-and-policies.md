---
title: Attributes and policies
version: 1
---

**Some rules are not about who you are but about the thing, the moment or the circumstances.** The
bookshop refunds an order only within 30 days of its being placed. No role says that. Carla may
refund, and whether she may refund *this* order depends on a date stored on the order and on
today's date, which change while her role stays the same.

Rules like that are **attribute-based access control**, ABAC. The decision reads attributes of the
person (role, department, country), of the object (owner, age, amount, status), of the action, and
of the environment (the time, where the request came from), and a **policy** combines them. RBAC is
the special case in which the only attribute anybody reads is the role.

`orders.py` has one such rule, in `refund_order`. Carla refunds Ana's order 2, which is 10 days old,
and then tries order 4, which is 45:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund
{"id": 2, "customer": "ana", "book_id": 5, "quantity": 2, "total_cents": 11980, "status": "refunded", "placed_on": "2026-09-30", "note": ""}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/4/refund
{"error": "refunds close 30 days after an order; order 4 is 45 days old"}
403
```

The administrator gets the same answer, because the policy is not a permission she lacks. It is a
rule about the order:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-dora' localhost:8000/orders/4/refund
{"error": "refunds close 30 days after an order; order 4 is 45 days old"}
403
```

A second refund of order 2 is a 409, since the order is no longer in a state that can be refunded:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund
{"error": "order 2 is refunded"}
409
```

Those are three different refusals. The 403 is for a rule that asking again cannot change, and the
message names the rule. The 409 is for the state of the object, as with the cancel in "Whose object
is it?". The 200 came only after every check had been asked.

## When roles stop being enough

The sign is a role whose name has started to describe a rule: `staff_refund_under_30_days`,
`manager_own_region`, `support_eu_only`. Each new condition multiplies the roles, and the table that
was meant to be readable at a glance turns into a list of exceptions. **That is the moment to keep
roles for what a kind of person does, and move the conditions into a policy that reads
attributes.**

A policy written into the handler, as here, is fine for one rule. Systems with many of them move
the policies out of the code into an engine with a language of its own: Open Policy Agent with
Rego, or Cedar from Amazon. There the rules can be read, tested and changed in one place. The idea
is the one `REFUND_DAYS` already has: the rule has a name, it is written once, and every request is
judged by it.
