---
title: Functions only some may call
version: 1
---

**Some operations are not about one object but about the shop as a whole, and the question there is
whether the caller may use the function at all.** Listing every account, changing somebody's role,
giving money back: OWASP calls the failure to check them **API5:2023 Broken Function Level
Authorization**.

It shows up in a few recognisable ways. Administrative endpoints are left out of the documentation
and the menu, and assumed safe because nobody knows the address. They sit under `/admin` and are
protected by a check on the path prefix, which one route was added without. Or the same address
takes a GET for anybody and a DELETE meant for staff, and only the GET was ever checked.

In `orders.py` a function is a row of `ROUTES`, and the row names its permission. Carla is staff
and Dora is the administrator:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-carla' localhost:8000/admin/people
{"error": "the role staff lacks people:read"}
403
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-dora' localhost:8000/admin/people
[{"name": "ana", "role": "customer"}, {"name": "bruno", "role": "customer"}, {"name": "carla", "role": "staff"}, {"name": "dora", "role": "admin"}, {"name": "eva", "role": "auditor"}]
200
```

Carla's 403 names what she lacks, and that is safe to say. The function is no secret, since
lesson 6's OpenAPI document lists every route an API has, and the name of the permission is what
she would quote when she asks for it.

A function can be out of reach of somebody who owns the object. Order 3 is Bruno's, and refunding
it is still not his to do:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3/refund
{"error": "the role customer lacks orders:refund"}
403
```

**Ownership answers "whose is it?"; function-level authorisation answers "is this something your
kind of caller does?"** Bruno passes the first and fails the second, and neither question implies
the other.

The method is part of the function. `ROUTES` has no DELETE for an order, and `do_DELETE` goes to
the same `dispatch` as the rest. So a DELETE from the administrator herself finds no open door, only
a 405 and an `Allow` header naming the one method this address takes:

```
ana@api:~/shelf$ curl -si -X DELETE -H 'Authorization: Bearer demo-dora' localhost:8000/orders/3
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 40
Allow: GET

{"error": "DELETE is not allowed here"}
```

Had `do_DELETE` not been defined, Python's library would have answered for it with a 501 and a page
of HTML, as it did for `OPTIONS` in lesson 1. Sending every method through one function is what
makes the route table the complete list of what this API does.
