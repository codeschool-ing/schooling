---
title: 401, 403 or 404
version: 1
---

**401 means "I do not know who you are", 403 means "I know, and no", and 404 means "there is
nothing here for you".** The first two follow from the two questions of the first section. The
choice that takes thought is between 403 and 404.

| status | the question that failed | in `orders.py` |
|---|---|---|
| 401 Unauthorized | who is asking? | no token, or one never issued; always with `WWW-Authenticate` |
| 403 Forbidden | may this caller use this function, here and now? | a permission missing from the role or from the token, or a policy |
| 404 Not Found | is there such a thing, for this caller? | no such address, no such order, or somebody else's order |

The name *Unauthorized* is a historical accident, and 401 is about authentication. A client that
receives a 401 should get a token, or a fresh one. A client that receives a 403 should not bother,
because a new token for the same person is refused the same way.

## Why somebody else's order is a 404

Ana asks for order 3, which is Bruno's, and for order 99, which does not exist:

```
ana@api:~/shelf$ curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 24

{"error": "no order 3"}
ana@api:~/shelf$ curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 25

{"error": "no order 99"}
```

The two answers have the same status and the same body apart from the number, which is also why
`Content-Length` differs by one.
**A 403 for order 3 would tell Ana that order 3 exists.** With consecutive ids, a stranger who got
403 for every number up to 1240 and 404 after it would know how many orders the shop had taken.
Checking again each week would tell them its sales. A 404 tells them nothing
they did not send.

So the rule of thumb is:

- an object the caller may not see answers 404, exactly like an object that does not exist;
- a function the caller may not use answers 403, because the function is in the documentation
  anyway, and the refusal is something the caller can act on.

GitHub's API works this way, and says so in its documentation: a private repository answers 404,
not 403, to somebody who may not see it. The price is paid in support. A customer signed in to the
wrong account is told the order does not exist, and somebody has to explain. For objects that is
worth paying.
