---
title: "Reserved concurrency: a ceiling and a floor at once"
version: 1
---

The name suggests booking capacity in advance, something paid for and kept warm. **Reserved
concurrency is neither: it costs nothing and starts nothing.** It is a line drawn inside the
account's pool. Setting it to 100 on a function does two things at the same time, and they are
the same number seen from two sides:

- a floor: 100 of the pool belong to that function, and no other function can use them, so a
  runaway neighbour cannot starve it;
- a ceiling: the function can never run more than 100 environments, and its 101st concurrent
  request is throttled even when the rest of the pool is idle.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"A bar of 1,000 concurrent executions for one account in one Region. From the left: 200 reserved for checkout, 100 reserved for orders, 600 unreserved and shared, and a dashed final 100 that AWS keeps unreserved. A bracket under the first 900 says that is the most that can be reserved; a bracket under the last 700 says those are shared by every function without a reservation.\"><defs><marker id=\"pool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">One account, one Region: 1,000 concurrent executions</text><text x=\"60\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"660\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1,000</text><rect x=\"60\" y=\"84\" width=\"120\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">checkout</text><text x=\"120\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">200 reserved</text><rect x=\"180\" y=\"84\" width=\"60\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">orders</text><text x=\"210\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">100</text><rect x=\"240\" y=\"84\" width=\"360\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shared</text><text x=\"420\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">600, any function without a reservation</text><rect x=\"600\" y=\"84\" width=\"60\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"630\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">kept</text><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">100</text><path d=\"M60 160 L60 168 L600 168 L600 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">reservable, all functions together: 900 at most</text><path d=\"M240 206 L240 214 L660 214 L660 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"450\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">unreserved: 700, the floor of 100 included</text></svg>", "caption": "Reserving divides the pool rather than adding to it. checkout can always reach 200 and never more; orders the same at 100; everything else in the account shares what is left, and AWS refuses any reservation that would leave less than 100 unreserved."}
```

## Two reasons to reserve, and they point opposite ways

The first is to guarantee. The checkout function must answer even on the day the image-resizing function
is flooded by a bulk upload. Reserving 200 for checkout means the flood can take everything else
and checkout still has its 200.

The second is to limit. The function writes to a PostgreSQL database that accepts 100 connections, and each
environment holds one. Without a cap, a spike starts 300 environments, 200 of them fail to
connect, and the database spends the spike refusing people. With a reservation of 80, Lambda throttles the 81st request before it reaches the database.
The throttle then goes wherever the
previous section said it goes for that trigger: back to the caller, into Lambda's retry queue, or
back onto the SQS queue. **A throttle at the function is cheaper than a failure at the database**,
because nothing was half done.

The limit has an extreme case worth knowing. A reservation of 0 throttles every request. That
makes it the switch that stops a function at once, without deleting it or changing its code:
during an incident, while a bad deployment is rolled back, or to stop a function that is calling
itself in a loop.

## Doing it against moto

A function needs a role and a package before it can be given anything. The role is the one
`aws-foundations` lesson 9 explains, with a trust policy that lets the Lambda service assume it.
The package is the slow handler of this lesson's first section, zipped:

```
ana@laptop:~/aws$ aws iam create-role --role-name orders-role --query Role.Arn --output text --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
arn:aws:iam::123456789012:role/orders-role
ana@laptop:~/aws$ zip -j orders.zip slow/app.py
  adding: app.py (deflated 9%)
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --memory-size 1024 --role arn:aws:iam::123456789012:role/orders-role --zip-file fileb://orders.zip --query "{Name: FunctionName, Memory: MemorySize, State: State}"
{
    "Name": "orders",
    "Memory": 1024,
    "State": "Active"
}
```

`1024` megabytes is 1 GB, which keeps the arithmetic of the next section simple. Now the
reservation, and reading it back. The function's own record carries it under `Concurrency`:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 100
{
    "ReservedConcurrentExecutions": 100
}
ana@laptop:~/aws$ aws lambda get-function --function-name orders --query Concurrency
{
    "ReservedConcurrentExecutions": 100
}
```

That is everything Lambda stores: one number on the function. There is no capacity behind it and
nothing was started.

## The floor under everybody else

AWS keeps the last 100 of the pool for the functions with no reservation, so that they always
have somewhere to run. **On an account with the default 1,000, the reservations of all functions
together can add up to 900 at most**, and a reservation that would push the unreserved part below
100 is refused with an `InvalidParameterValueException` naming that minimum. moto knows nothing
of the floor or of the pool. Ask it for twice the pool and it agrees:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 2000
{
    "ReservedConcurrentExecutions": 2000
}
```

On AWS that command fails, and nothing changes. It is the clearest case in this lesson of moto
answering like AWS and enforcing much less: a script that worked here proves the call is well
formed, and nothing about whether AWS would accept the number.

The off switch and the way back, which removes the reservation and returns the function to the
shared pool. `delete-function-concurrency` prints nothing when it succeeds, and so does the read
that follows, because there is no longer a value to show:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 0
{
    "ReservedConcurrentExecutions": 0
}
ana@laptop:~/aws$ aws lambda delete-function-concurrency --function-name orders
ana@laptop:~/aws$ aws lambda get-function-concurrency --function-name orders
```

## What reserving costs the other functions

Every unit reserved is a unit nobody else can use, whether or not the function needs it at that
moment. Reserving 600 for a function that peaks at 50 leaves 400 for the rest of the account, and
550 of the reservation idle. **Reserve for a measured peak, plus a margin, and not for a
round number**; lesson 8 of `aws-operations` reads that peak from CloudWatch's
`ConcurrentExecutions` metric, which is per function and per account.

Reserved concurrency decides how many environments a function may have. It says nothing about
whether any of them exist before a request arrives, and the first request into a new one still
waits for it to start. Keeping environments ready in advance is a different setting, with a
different bill, and it is the next section.
