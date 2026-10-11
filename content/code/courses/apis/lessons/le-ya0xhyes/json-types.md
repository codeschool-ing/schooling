---
title: What JSON has, and what it lacks
version: 1
---

**JSON has six kinds of value and no more:** an object, an array, a string, a number, `true` or
`false`, and `null`. There is no date, no money, no binary data, and no difference between a whole
number and a fraction. Everything an API sends that is not one of those six is a convention, and a
convention only holds if the contract writes it down.

The usual picture is that JSON numbers come in two kinds, integers and floats, the way they do in
most programming languages. They do not. The grammar has one number, and **what it becomes is
decided by whoever parses it.** The same two values, read by two parsers:

```
ana@api:~$ echo '[3990, 3990.0]' | jq -c .
[3990,3990.0]
ana@api:~$ echo '[3990, 3990.0]' | jq -c 'map(. + 0)'
[3990,3990]
ana@api:~$ python3 -c 'import json; print(json.loads("[3990, 3990.0]"))'
[3990, 3990.0]
```

`jq` keeps `3990.0` as it was written while it only passes it along, and turns it into `3990` the
moment it does arithmetic on it. Python keeps the two apart, an `int` and a `float`. Neither is
wrong, because JSON never said which they were.

## Numbers that change on the way

JSON puts no limit on the size of a number. The reader does. JavaScript, and many readers written in
other languages, parse every JSON number into a 64-bit floating-point double, which holds every whole
number exactly only up to 2^53. Past that, some whole numbers have no double of their own and are
rounded to a neighbour:

```
ana@api:~$ echo '{"id": 9007199254740993}' | jq .id
9007199254740993
ana@api:~$ echo '{"id": 9007199254740993}' | jq '.id + 0'
9007199254740992
ana@api:~$ python3 -c 'print(2**53, float(9007199254740993))'
9007199254740992 9007199254740992.0
```

The id was `9007199254740993`, one past 2^53. `jq` printed it intact while it was only passing it
through; the moment it treated it as a number, it became `9007199254740992`, and so did Python's
`float`. Node is not installed on this machine, so JavaScript is not run here, but its numbers are
the same doubles, and its `JSON.parse` gives the same `...992`. **A client written in JavaScript
receives a different id from the one you sent, without an error.** Twitter's API met exactly this
when its tweet ids grew past 2^53, and added an `id_str` field carrying each id again as a string.

So an id that can grow past 2^53 travels as a string. shelf's ids are small row numbers and stay
numbers; the decision is the contract's, and it is made once, for every id.

## Money is never a float

A float holds most decimal fractions approximately, and the error shows as soon as you multiply.
Three copies of a book at 39.90:

```
ana@api:~$ jq -n '39.90 * 3'
119.69999999999999
ana@api:~$ python3 -c 'print(39.90 * 3, 3990 * 3)'
119.69999999999999 11970
```

Both `jq` and Python print `119.69999999999999`, because 39.90 has no exact binary representation.
Rounding hides it on one bill and not on the next, and a total that is a cent off is a support ticket.
**Money travels as an integer number of the currency's smallest unit, with the currency beside it**:
`3990` and `"BRL"`. The multiplication is then exact, `11970`. The currency is not optional, because
`3990` on its own does not say whether it is reais or euros, and not every currency has two decimal
places: the Japanese yen has none.

## Dates are strings by agreement

JSON has no date, so a date is a string, and the string is only a date because both sides agree:

```
ana@api:~$ echo '{"published": "1899-01-01"}' | jq '.published | type'
"string"
```

To `jq`, and to every parser, `"1899-01-01"` is text. Which text counts as a date, and what it means,
is the next section's subject.

| you want to send | JSON gives you | what the contract says |
|---|---|---|
| a count, a year, a small id | a number | an integer, and the reader keeps it whole |
| an id that may pass 2^53 | a number that may be rounded | a string |
| an amount of money | a number that may become a double | integer minor units, plus a currency code |
| a date or a time | nothing | a string in RFC 3339, with an offset |
| yes or no | `true` and `false` | a boolean, never the string `"true"` |
| binary data, such as a cover image | nothing | a link to it, or base64 in a string |
