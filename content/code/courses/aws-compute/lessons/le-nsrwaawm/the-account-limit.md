---
title: The account limit, and what a throttle does to each caller
version: 1
---

Every function in an account shares one pool. **By default an AWS account can run 1,000
execution environments at once in each Region, across all of its functions together**, and the
1,001st concurrent request is refused. The limit is per Region, so São Paulo's thousand and
Virginia's thousand are separate, and it is per account, so a test function and the production
API in the same account draw on the same thousand. That last point is the one that hurts: a load
test against one function can throttle every other function in the account.

## The numbers AWS documents

None of these can be shown against moto, which keeps no count of anything running and throttles
nothing. They are AWS's documented behaviour, described here and not run.

- **The pool is a quota, not a wall.** It appears in Service Quotas as *Concurrent executions*,
  and a request there raises it, to tens of thousands for an account that can show it needs them.
  AWS also documents that a new account can start with a lower value, raised automatically as the
  account is used, so check yours before a launch rather than during it.
- **A function grows at a bounded rate.** Each function can add up to 1,000 execution
  environments every 10 seconds. An account whose quota was raised to 5,000 still needs at least
  50 seconds to go from nothing to 5,000 for one function, and requests above the growing count
  are throttled while it grows.
- **There is a request rate as well.** Lambda allows ten times the concurrency quota in requests
  per second, so 10,000 a second on a quota of 1,000. A function that runs for 5 ms at 20,000
  requests a second needs only 20,000 × 0.005 = 100 environments by Little's law, and is
  throttled anyway, because of the rate.

What moto does answer is the question, or rather the absence of it. On AWS,
`get-account-settings` prints the account's limits, including `ConcurrentExecutions`, the pool,
and `UnreservedConcurrentExecutions`, what is left of it after the reservations of the next
section. moto 5.2.3 has not implemented that operation, and its web server answers with a page
that was meant for a browser:

```
ana@laptop:~/aws$ aws lambda get-account-settings

aws: [ERROR]: An error occurred (404) when calling the GetAccountSettings operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

The error is a `404`, and the HTML in it is moto's; AWS would have answered with JSON. Keep it in
mind as the shape of a missing operation in moto, because this lesson's last section meets the same
page again.

## A throttle is an error with a number

When Lambda refuses a request for lack of concurrency, the refusal is a `TooManyRequestsException`
with the HTTP status 429, and the message says the rate was exceeded. **What happens next is not
decided by Lambda but by whoever called it**, and lesson 15's three ways in each behave
differently:

| how the function was invoked | what the throttle does |
|---|---|
| synchronously: API Gateway, a function URL, an SDK call with `RequestResponse` | the caller receives the error at once; nothing is retried unless the caller retries, and API Gateway turns it into an error response for its own client |
| asynchronously: S3, SNS, EventBridge | the event stays in Lambda's internal queue and is retried with backoff for up to six hours, the default maximum age of an event; after that it goes to the on-failure destination or the dead-letter queue, if one is set, and is otherwise dropped |
| by an event source mapping: SQS | the poller reads more slowly; the messages stay in the queue and come back when their visibility timeout expires, and a message received too many times moves to the queue's dead-letter queue |
| by an event source mapping: Kinesis, DynamoDB Streams | the batch is retried, and the shard waits behind it until it succeeds or the records expire |

**The synchronous row is the one where a user sees the failure**, and the one where a retry in a
hurry makes things worse: a client that retries at once adds a request to a function that is
already at its limit. The asynchronous rows absorb a throttle silently, which is kinder to the
user and harder on whoever is watching, because six hours of retries look like a function that is
merely slow.

## Why a limit is good news

It is tempting to read the pool as a nuisance to be raised before anything else. It is also the
thing that stops a bug from becoming an invoice. A function that calls itself by mistake, or a
queue that floods after an outage, would otherwise scale until the bill or the database gave out.
**The account limit decides how big a mistake can get.** The next section shows how to decide it
per function instead of for the whole account, and lesson 15's dead-letter queues are where the
refused work goes to wait.
