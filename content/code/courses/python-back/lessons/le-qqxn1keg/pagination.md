---
title: Pagination, and filtering the list
version: 1
---

A list that returns every row works with three events and fails with thirty thousand: the response
grows, the query grows, and a mobile client waits for data it will never show. The settings asked for
pages of two:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/ | python3 -m json.tool
{
    "count": 3,
    "next": "http://127.0.0.1:8000/api/events/?page=2",
    "previous": null,
    "results": [
        {
            "slug": "django-night",
            "title": "Django Night",
            "starts_at": "2026-11-12T19:00:00-03:00",
            "venue": "Community Centre, room 3",
            "capacity": 40,
            "description": "",
            "taken": 1
        },
        {
            "slug": "async-workshop",
            "title": "Async Python workshop",
            "starts_at": "2026-11-19T14:00:00-03:00",
            "venue": "Public Library, lab 2",
            "capacity": 12,
            "description": "",
            "taken": 12
        }
    ]
}
```

The page is wrapped in an object: **`count`**, the total across all pages; **`next`** and
**`previous`**, complete addresses a client follows without building them; and **`results`**, this
page's rows. The list came out in date order because `get_queryset` says `order_by("starts_at")`,
which matters here more than anywhere: **pages over an unordered query can repeat a row on two pages
or skip one**, and DRF warns in the server's log when it paginates one. The second page:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/api/events/?page=2" | python3 -m json.tool
{
    "count": 3,
    "next": null,
    "previous": "http://127.0.0.1:8000/api/events/",
    "results": [
        {
            "slug": "testing-dojo",
            "title": "Testing dojo",
            "starts_at": "2026-11-26T19:00:00-03:00",
            "venue": "Community Centre, room 3",
            "capacity": 20,
            "description": "",
            "taken": 2
        }
    ]
}
```

`next` is `null`: there is no third page.

## Filtering

`get_queryset` reads `venue` from the query string and filters before paginating, so `count` is the
count of the filtered list:

```
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/api/events/?venue=Public%20Library,%20lab%202" | python3 -m json.tool | head -4
{
    "count": 1,
    "next": null,
    "previous": null,
```

One event at the library. The pattern scales to every filter the API needs, and **django-filter** is
the library that declares them instead of writing an `if` per parameter, with DRF integration built
in.

## Page numbers, or a cursor

| | how a client asks | cost |
|---|---|---|
| `PageNumberPagination` | `?page=2` | a `COUNT(*)` per request, and `OFFSET`, which reads and throws away the earlier rows |
| `LimitOffsetPagination` | `?limit=20&offset=40` | the same |
| `CursorPagination` | an opaque `?cursor=…` from `next` | no count and no offset: it asks for rows after the last one seen |

Page numbers are what people expect on a screen. For a feed that only goes forward, or a table of
millions, the cursor is the one that stays fast, at the price of not being able to jump to page 50.
