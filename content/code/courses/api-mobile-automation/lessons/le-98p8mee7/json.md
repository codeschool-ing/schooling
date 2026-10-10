---
title: JSON, and the three things it gets wrong for you
version: 1
---

**JSON has six kinds of value: string, number, boolean, null, array and object.** That is the
whole format, and every answer boxoffice gives is built from those six. Its simplicity is the
trap: the format cannot say *money*, *date* or *identifier*, so an API has to choose how to spell
each one in the six, and each choice is something a tester checks.

jq's `type` names the kind of each field, which is the first thing to look at in an unfamiliar
answer:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq -r 'to_entries[] | "\(.key): \(.value | type)"'
id: string
title: string
starts_at: string
price_cents: number
seats_left: number
```

Three strings and two numbers. `starts_at` is a date and `id` looks like a code, and JSON calls
both of them strings; what they mean is a promise the API makes elsewhere, which section 04 writes
down.

## Missing is not null

A field can be absent, or present with the value `null`, and **the two mean different things**: an
order with no `payment` field has not been charged, while `"payment": null` would say somebody
looked and found nothing. jq hides the difference. Asked for a field that is not there, it answers
`null`, and only `has` tells the cases apart:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq '.discount, has("discount")'
null
false
ana@laptop:~/boxoffice$ echo '{"discount": null}' | jq '.discount, has("discount")'
null
true
```

The first answer has no `discount` at all; the second has one whose value is `null`. Both print
`null`. **A test that checks `.discount == null` passes for both**, so a server that dropped a
required field would sail through it. When the contract says a field is required, check that it is
present, not only what it holds.

## There is one kind of number

JSON does not separate whole numbers from fractions. `2`, `2.0` and `2e0` are three spellings of
the same number:

```
ana@laptop:~/boxoffice$ echo '[2, 2.0, 2e0]' | jq -c 'map(. == 2)'
[true,true,true]
```

So "an integer" in an API is a rule about the value, not a type the format can carry. That matters
in section 06, where boxoffice is sent `2.0` seats.

## Money travels in cents

A JSON number is read, in JavaScript and in most languages, as binary floating point, and binary
floating point cannot hold one tenth exactly. The error is small and real:

```
ana@laptop:~/boxoffice$ node -e 'console.log(0.1 + 0.2)'
0.30000000000000004
ana@laptop:~/boxoffice$ node -e 'console.log(80.10 * 3)'
240.29999999999998
ana@laptop:~/boxoffice$ node -e 'console.log(8010 * 3)'
24030
```

Three tickets at R$ 80,10 come out as 240.29999999999998 reais. Rounded for a screen it looks fine;
compared with `===` in a test, or added up over a thousand orders in a report, it does not.
**boxoffice sends every amount as a whole number of centavos**, `price_cents: 8000` for R$ 80,00,
and whole numbers of that size are exact. The last line is the same sum in cents, and it is exactly
24030.

What a tester checks: amounts are integers, the field name says the unit, and a total is the price
times the quantity to the cent. The order in section 02 holds 2 seats of an 8000-cent show and says
`"total_cents":16000`, which is right.

## Dates carry their offset

`starts_at` is written in ISO 8601, `2026-11-08T18:00:00-03:00`: the date, a `T`, the time, and the
**offset** from UTC, here three hours behind, which is São Paulo's. Leave the offset off and the
same text means a different moment on every machine that reads it. Here is the start of the
8 November show read three times, with `TZ` setting the time zone the computer believes it is in:

```
ana@laptop:~/boxoffice$ TZ=UTC node -e 'console.log(new Date("2026-11-08T18:00:00").toISOString())'
2026-11-08T18:00:00.000Z
ana@laptop:~/boxoffice$ TZ=America/Sao_Paulo node -e 'console.log(new Date("2026-11-08T18:00:00").toISOString())'
2026-11-08T21:00:00.000Z
ana@laptop:~/boxoffice$ TZ=UTC node -e 'console.log(new Date("2026-11-08T18:00:00-03:00").toISOString())'
2026-11-08T21:00:00.000Z
```

The first reading believes it is in UTC and the second in São Paulo. Given the date with no
offset, they disagree by three hours about the same text. The third gets the offset and lands on
the right moment whatever the computer's own zone. **A date without an offset is a defect waiting
for a user in another time zone**, and every date in boxoffice carries one.

## Identifiers are strings

boxoffice's ids are `sh-103` and `ord-1001`, which could never be numbers. An API whose ids are
large numbers has a quieter problem: JavaScript reads every JSON number as floating point with 53 bits of
precision, and a larger integer is silently changed to the nearest one it can hold:

```
ana@laptop:~/boxoffice$ node -e 'console.log(JSON.parse("{\"id\": 9007199254740993}").id)'
9007199254740992
```

The id ends in 993 in the text and in 992 once parsed. An app written in JavaScript would ask for
the wrong order and get somebody else's, or nothing. Ids sent as strings cannot be rounded, which is
why an API that cares writes them that way even when they are made of digits.
