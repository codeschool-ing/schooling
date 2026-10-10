---
title: Whose object is it?
version: 1
---

**The most common authorisation flaw in APIs is an object handed to somebody it does not belong
to.** OWASP, the open project that publishes lists of the commonest web security failures, puts it
first in its API Security Top 10 of 2023, as **API1:2023 Broken Object Level Authorization**, or
BOLA. Lesson 13 comes back to the list; this is its first entry.

The shape is always the same. The address carries an id, `/orders/3`, and the handler reads row 3
because the address asked for it. The caller has a valid token, holds `orders:read`, and the route
lets them in. Every check in the dispatcher passed, and none of them asked whose order 3 is.

In `orders.py` that question is `find`. Bruno placed order 3, so he reads it. Ana asks for the same
address and is told there is no such order:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09"}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
{"error": "no order 3"}
404
```

Writing goes through the same function, because `cancel_order` finds the order before it touches
it. Bruno cannot cancel Ana's order 1, and Ana can, once:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/1/cancel
{"error": "no order 1"}
404
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel
{"id": 1, "customer": "ana", "book_id": 1, "quantity": 1, "total_cents": 3990, "status": "cancelled", "placed_on": "2026-10-08"}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel
{"error": "order 1 is cancelled; only a placed order can be cancelled"}
409
```

The second cancel is a 409, because a cancelled order cannot be cancelled again. That is a rule
about the order's state, not about who may ask, and 409 is the code lesson 1 gave to a request that
clashes with what already exists.

## What a missing check looks like

The flaw looks like this handler, which is right in every way but one:

```python
def get_order(self, me, perms, ident):
    with db.connect() as conn:
        order = conn.execute("SELECT * FROM orders WHERE id = ?", (ident,)).fetchone()
    if order is None:
        return self.error(404, f"no order {ident}")
    self.reply(200, show(order, perms))
```

`me` arrives as an argument and is never used. Nothing fails, every test written by somebody
thinking about their own orders passes, and since the ids are consecutive, every other customer's
orders are one number away. **A handler that reads by id and never uses the caller is the thing to
look for in a review.**

Three habits make the flaw hard to write:

- look objects up through one function that takes the caller, as `find` does, so a handler cannot
  fetch an order without saying who wants it;
- filter in the query when listing: `list_orders` puts `WHERE customer = ?` in the SQL, so
  somebody else's rows are never read, rather than read and then dropped;
- test with at least two people, because a test that only ever signs in as one cannot see this.
  "Testing the matrix" builds that test.

Random ids, a UUID in place of 3, make the neighbours harder to guess, and they are worth having.
They are not the check. An id ends up in logs, links and screenshots, and once somebody has it, the
ownership check is the only thing between them and the order.
