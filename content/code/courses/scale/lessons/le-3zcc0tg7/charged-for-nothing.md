---
title: Never charged for nothing
version: 1
---

Planning this lesson's failures turned up a defect that every lesson since 8 had carried. The sale
charged the buyer first and then ran the `UPDATE ... WHERE sold < capacity` that finds a seat. On a
sold-out show, the `UPDATE` found none and the sale answered `409 Sold out`, **after the buyer had
been charged**. It never showed up in a capture because no show in the lab had ever sold out.

The box office now asks the primary how many seats are left before charging, and refuses a sold-out
show with nothing charged. Sell out show 7 by hand, and try:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'UPDATE events SET sold = capacity WHERE id = 7'
UPDATE 1
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 0}
ana@lab:~/tickets$ curl -s -X POST -H 'X-Buyer: fan-20' localhost:8080/events/7/tickets; echo
{"error": "sold out"}
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 0}
```

`409`, and payments' count did not move.

The check narrows the window without closing it. Between the check and the `UPDATE`, somebody else
can take the last seat: two buyers see one seat left, both are charged, and one gets the seat. The
box office now logs that case as an error, *charged but sold out*, because somebody has to refund
that buyer. Closing the window completely means changing the order: **reserve the seat first**, with
an expiry, **then charge**, then confirm the reservation, and release it if the charge fails. Each
step is undone by a compensating one if a later step fails, which is the pattern called a
**saga**. It is how ticketing, travel and every other business that sells something scarce through
a payment it does not control actually works.

The general lesson is about degraded paths. **A failure path that nobody has run is a failure path
that has not been tested**, and the sold-out path had not been run once in eight lessons.
