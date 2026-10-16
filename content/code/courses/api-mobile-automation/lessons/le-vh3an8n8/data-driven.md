---
title: One request, many cases from a file
version: 1
---

**A data-driven run sends the same requests once per row of a file, with the row's columns as
variables.** The boundaries of `seats` are the obvious case: 0, 1, 6, 7, a fraction and a string,
each with the status boxoffice should answer. Six requests that differ in one number are one request
and a table.

Write the table in your editor and save it as `postman/seats.csv`:

```
seats,expected
0,422
1,201
6,201
7,422
2.5,422
"""2""",422
```

The first line names the columns, and each line after it is one case. The last value is the string
`"2"`. In CSV a quote inside a quoted field is written twice, so `"""2"""` is a field holding `"2"`,
quotes included. It lands in the JSON body as a string rather than a number.

The `seat rules` folder holds one request, **Order seats**, whose body uses the two columns:

```json
{"show_id": "sh-101", "seats": {{seats}}}
```

and whose test reads the expected status from the same row:

```js
const expected = Number(pm.variables.get('expected'));
pm.test(`seats ${pm.variables.get('seats')} answers ${expected}`, () => {
  pm.response.to.have.status(expected);
});
```

The test's name is built from the row, so each case reports under its own name. `sh-101` is used
because it has 120 seats: the cases that should succeed must not run out of seats and fail for a
reason the test is not about.

## The run

`-d` hands Newman the file, and `--folder` limits the run to one folder:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --folder 'seat rules' -d postman/seats.csv --disable-unicode
newman

boxoffice

Iteration 1/6

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/oauth/token [200 OK, 479B, 31ms]
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 4ms]
  Pass  seats 0 answers 422

Iteration 2/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  seats 1 answers 201

Iteration 3/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 317B, 2ms]
  Pass  seats 6 answers 201

Iteration 4/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats 7 answers 422

Iteration 5/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats 2.5 answers 422

Iteration 6/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats "2" answers 422

---------------------------------------------------------------
|                         |        executed |          failed |
--------------------------+-----------------+------------------
|              iterations |               6 |               0 |
--------------------------+-----------------+------------------
|                requests |               7 |               0 |
--------------------------+-----------------+------------------
|            test-scripts |               6 |               0 |
--------------------------+-----------------+------------------
|      prerequest-scripts |              12 |               0 |
--------------------------+-----------------+------------------
|              assertions |               6 |               0 |
---------------------------------------------------------------
| total run duration: 220ms                                   |
---------------------------------------------------------------
| total data received: 1kB (approx)                           |
---------------------------------------------------------------
| average response time: 7ms [min: 2ms, max: 31ms, s.d.: 9ms] |
---------------------------------------------------------------
```

Six iterations, one per row, and six passes. The token was fetched once, before the first iteration,
by the collection's pre-request script of section 05. The later iterations found it still valid. In
Postman the same file goes into the Runner, under *Data*, which then shows each iteration.

## Where the row's values live

The data file is the **data** scope of lesson 4 section 04, narrower than collection and
environment. The collection defines `seats` as `1` and `expected` as `201`. That is why the folder
also runs in a whole-collection run without any file, as one ordinary order that should succeed. It
was the **Order seats** line at the end of section 02's run. Given a file, the row's values win,
because the data scope is narrower. A default in the wider scope and a case in the narrower one is
the precedence rule of lesson 4 doing useful work.

**Every row is a claim, so choose them as you would choose cases.** These six are the boundaries
lesson 2 derived from the contract: the lowest valid value and the one below it, the highest and the
one above it, and two values of the wrong type. A file of a hundred rows between 2 and 5 would run a
hundred times and test nothing new.
