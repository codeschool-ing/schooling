---
title: Properties a caller may read and write
version: 1
---

**Between "may see this order" and "may see everything about this order" there is a third
question: which fields.** OWASP's **API3:2023 Broken Object Property Level Authorization** joins
two older entries that are the same mistake in opposite directions. Sending a property the caller
should not read was called *excessive data exposure*, and accepting a property the caller should
not write was called *mass assignment*.

## Writing: mass assignment

The tempting handler takes the JSON body and stores whatever it names. It is short and generic, and
it lets a customer send this:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 2, "status": "shipped", "total_cents": 1}' localhost:8000/orders
{"error": "fields you may not set: status, total_cents"}
422
```

`orders.py` refuses it, because `create_order` accepts `book_id` and `quantity` and nothing else. A
customer chooses a book and how many copies. The price, the status, the customer and the date are
facts the server knows better, and it sets them itself:

```
ana@api:~/shelf$ curl -si -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 2}' localhost:8000/orders
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 126
Location: /orders/5

{"id": 5, "customer": "ana", "book_id": 1, "quantity": 2, "total_cents": 7980, "status": "placed", "placed_on": "2026-10-10"}
```

The total is 7980, two copies at 3990, computed from the `books` table rather than believed from the
body. **The fields a caller may write are an allow-list in the handler, and a field outside it is
refused, not quietly dropped.** Dropping it would also keep the status safe, and it would leave the
client believing it had set something it had not. The 422 is lesson 1's code for content that
breaks a rule, and the message names the fields, so the mistake can be found and fixed. `rest.py`
already did the same for books: its `FIELDS` table is why lesson 1's PATCH with `colour` was a 422.

## Reading: what the representation leaves out

Every order has a `note` for the shop's eyes, and order 3's says Bruno phoned with a new address.
Ana cannot see the order at all, Bruno sees it without the note, and Carla sees it with the note:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
{"error": "no order 3"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-carla' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09", "note": "phoned: new address"}
```

`show` builds the answer from a list of fields and adds `note` only for a caller holding
`orders:read_all`. **The representation is an allow-list too, and never the row.** An API that sends
`SELECT *` as JSON and trusts the client not to display some of it has sent the note to the
customer's browser, where the developer tools show it to anybody who opens them. A column added to
the table next year goes out the same way, without anybody deciding that it should.
