---
id: affiliate-api
title: Affiliate API reference
audience: developers
owner: platform
updated: 2026-02-10
version: 2.3
status: current
---

# Affiliate API reference

The affiliate API lets partner sites look up books, build tracked links and read their commission
reports. This is version 2.3 of the reference.

## Base URL and authentication

Every request goes to the base URL below and carries the affiliate key in a header:

    https://api.marginalia.example/affiliate/v2
    X-Affiliate-Key: <your key>

Keys are issued in the partner dashboard. A key belongs to one partner site; a request with a key
from another site is refused with E-4101. Keys do not expire, but can be revoked from the dashboard
at any time.

## Rate limits

A key may make 120 requests per minute. A request over the limit is refused with HTTP 429 and the
error E-4102, and the header Retry-After says how many seconds to wait. Report requests count
double.

## Endpoints

### GET /products/{isbn}

Returns one book by its ISBN-13: title, authors, price, availability and the URL of its cover. An
ISBN that is not in the catalogue returns E-4103.

    GET /products/9780141439518

### GET /search

Searches the catalogue. Parameters: q, the text to search for; lang, a two-letter language code;
page, starting at 1. Each page holds 20 results, and at most 50 pages are returned.

    GET /search?q=persuasion&lang=en&page=1

### POST /links

Builds a tracked link to a product page. The body names the ISBN and an optional campaign label of
at most 40 characters:

    {"isbn": "9780141439518", "campaign": "spring-newsletter"}

The link carries the partner's identifier and the campaign, and is valid for as long as the key.

### GET /reports/commissions

Returns the commissions earned in one calendar month. Parameter: month, as YYYY-MM. Months more
than 24 months in the past, or in the future, return E-4104.

    GET /reports/commissions?month=2026-01

## Commission

A partner earns 6% of the price of printed books and 3% of the price of e-books and audiobooks
bought through a tracked link. A purchase counts when it happens within 30 days of the click, from
the same browser. Commissions on orders that are returned or refunded are cancelled.

Commissions are paid monthly, 45 days after the end of the month in which the order was placed, when
the amount owed is at least 25.

## Errors

Errors are returned as JSON with a code and a message:

    {"error": {"code": "E-4103", "message": "unknown ISBN"}}

| code | HTTP | meaning |
| --- | --- | --- |
| E-4101 | 401 | the key is missing, revoked or belongs to another site |
| E-4102 | 429 | more than 120 requests in the last minute |
| E-4103 | 404 | the ISBN is not in the catalogue |
| E-4104 | 400 | the month is out of range or not in the form YYYY-MM |
| E-4105 | 400 | the campaign label is longer than 40 characters |
| E-5001 | 500 | an error on our side; retry after a few seconds |

## Changes in 2.3

Version 2.3, released on 10 February 2026, added the lang parameter to /search and the error E-4105.
Version 2.2 is still served at the same URL and ignores lang.
