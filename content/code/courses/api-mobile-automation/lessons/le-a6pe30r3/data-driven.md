---
title: One scenario, six rows
version: 1
---

**A Scenario Outline is a scenario with blanks, and a table of Examples that fills them, one run
per row.** Boundary testing produces exactly that shape: the same request with a different value
each time, and a different expected answer. Lesson 2 derived the cases for the number of seats from
the rule "a whole number from 1 to 6"; here they become a table.

Save it as `karate/src/test/java/boxoffice/seats.feature`:

```
Feature: How many seats one order may ask for

  Background:
    * def ci = callonce read('token.feature') { clientId: 'ci-tests', clientSecret: 'ci-secret' }
    * url baseUrl
    * configure headers = { Authorization: '#("Bearer " + ci.token)' }

  Scenario Outline: <seats> seats is answered <status>
    Given path 'v1', 'orders'
    And request { show_id: 'sh-102', seats: <seats> }
    When method post
    Then status <status>

    Examples:
      | seats | status |
      | 0     | 422    |
      | 1     | 201    |
      | 6     | 201    |
      | 7     | 422    |
      | 2.5   | 422    |
      | '2'   | 422    |
```

`<seats>` and `<status>` are filled from the columns of the same name. The scenario's name has them
too, so each row reports under a name of its own, `7 seats is answered 422`, rather than six
failures under one title. The rows, and what each one is for:

| seats | expected | why it is in the table |
|---|---|---|
| `0` | `422` | just below the lowest allowed |
| `1` | `201` | the lowest allowed |
| `6` | `201` | the highest allowed |
| `7` | `422` | just above the highest |
| `2.5` | `422` | a number, and not a whole one |
| `'2'` | `422` | a whole number written as text: `"2"` in the JSON |

**The quotes in the last row matter.** The cell is pasted into the request as it is written, so
`2` would send the number and `'2'` sends the string, and the two are different inputs to the
server. Lesson 2 asked which of them boxoffice should accept; this table says what it does.

The rows use `sh-102`, which none of the other features buys from, so this file and `orders.feature`
cannot run each other out of seats. Each run buys seven seats of it, one and six, so the 120 seats
last seventeen runs and the eighteenth sees a `409` on its six-seat row. A restart of boxoffice puts
them back.

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/seats.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
ana@laptop:~/boxoffice/karate$ echo $?
0
```

```
POST /oauth/token 200
POST /v1/orders 422
POST /v1/orders 201
POST /v1/orders 201
POST /v1/orders 422
POST /v1/orders 422
POST /v1/orders 422
```

One token, then six orders, one per row, with the statuses of the table. **Karate ran the rows in
the order of the table**, so the log reads like the table read down. That makes it easy to match a
line of the server's log to a row of a failed run.
