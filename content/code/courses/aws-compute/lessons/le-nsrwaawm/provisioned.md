---
title: "Provisioned concurrency: environments kept ready, and billed while they wait"
version: 1
---

**Provisioned concurrency is a number of execution environments that Lambda starts in advance
and keeps initialised**, with your code loaded and the code outside the handler already run.
A request that lands on one of them skips the start-up that lesson 17 measures, the cold start.
It is not a cap and not a guarantee in the sense of the previous section: requests beyond the
provisioned number are still served, by ordinary environments started on demand, with a cold
start each. And unlike a reservation, **it is billed for every second it is configured**, whether
a single request arrives or not.

## A version or an alias, never `$LATEST`

Provisioned concurrency is set on a fixed piece of code, because what Lambda keeps ready is that
code already initialised. `$LATEST` is the function's editable copy and can change under it, so
AWS refuses it there. The configuration goes on a **version**, which is an immutable snapshot of
the code and settings, or on an **alias**, a name that points at a version and can be moved. An
alias is the usual choice: a deployment moves `live` from version 3 to version 4, and the
provisioned environments are prepared for version 4 as part of the move.

moto does versions and aliases, so the first two steps run against it:

```
ana@laptop:~/aws$ aws lambda publish-version --function-name orders --query "{Version: Version, Arn: FunctionArn}"
{
    "Version": "1",
    "Arn": "arn:aws:lambda:sa-east-1:123456789012:function:orders:1"
}
ana@laptop:~/aws$ aws lambda create-alias --function-name orders --name live --function-version 1 --query "{Alias: Name, Version: FunctionVersion}"
{
    "Alias": "live",
    "Version": "1"
}
```

The third step is the configuration itself, ten environments kept ready behind `live`. moto
5.2.3 has not implemented it, and it answers with the same HTML page as `get-account-settings`
did:

```
ana@laptop:~/aws$ aws lambda put-provisioned-concurrency-config --function-name orders --qualifier live --provisioned-concurrent-executions 10

aws: [ERROR]: An error occurred (404) when calling the PutProvisionedConcurrencyConfig operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

On AWS the call returns a status of `IN_PROGRESS` while Lambda starts the ten environments and
runs their initialisation, and `READY` when they are serving, which takes minutes rather than
seconds. Nothing in this paragraph was run. Two more facts from AWS's documentation shape how it
is used. The ten come out of the pool of this lesson's second section, from the function's own
reservation if it has one and from the unreserved part if not. And the number can follow a
schedule or a target through Application Auto Scaling: twenty environments from eight in the
morning and two overnight, which is how a team pays for readiness only during the hours when
somebody is waiting.

## The bill, from the sheet

Three lines of the price sheet decide it. These are the prices of 16 October 2026 for x86 in
sa-east-1:

```
ana@laptop:~/aws$ python3 prices.py lambda
AWS public price list, sa-east-1, USD, excluding tax

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second
```

On demand, a function pays for **duration**: 0.0000166667 USD for every gigabyte-second it
actually runs. Provisioned splits that in two. **Provisioned concurrency** is 0.0000066372 USD
per gigabyte-second that an environment is kept ready, busy or idle; **duration on provisioned**
is 0.0000154867 USD per gigabyte-second it runs on one of them, a little less than on demand.
Requests cost 0.2 USD per million either way, so they cancel out of the comparison.

The program below compares a month of the two for ten environments of 1 GB, at four levels of
use. Save it as `~/aws/provisioned.py`:

```schooling-example
{"language": "python", "file": "provisioned.py", "parts": [{"code": "# A month of one function in sa-east-1: on demand against provisioned\n# concurrency. Prices from prices.py, 16 October 2026, x86, USD.\nON_DEMAND = 0.0000166667        # per GB-second of running\nPROVISIONED = 0.0000066372      # per GB-second an environment is kept ready\nON_PROVISIONED = 0.0000154867   # per GB-second of running on one of them\n\n", "note": "The three prices, copied from the sheet. Requests are left out because they cost the same on both sides."}, {"code": "MEMORY_GB = 1.0\nENVIRONMENTS = 10\nSECONDS = 730 * 3600            # a month of 730 hours\n\n", "note": "The function: ten environments of 1 GB, for a month of 730 hours, which is 2,628,000 seconds."}, {"code": "kept = ENVIRONMENTS * MEMORY_GB * SECONDS * PROVISIONED\n\nfor busy in (0.25, 0.50, 0.75, 1.00):\n    used = ENVIRONMENTS * MEMORY_GB * SECONDS * busy      # GB-seconds of running\n    on_demand = used * ON_DEMAND\n    provisioned = kept + used * ON_PROVISIONED\n    print(f'{busy:4.0%} busy   on demand {on_demand:7.2f}   provisioned {provisioned:7.2f} USD')\n\n", "note": "`kept` is the price of readiness, the same whatever happens. Then each level of use: `busy` is the share of the month the ten environments spend running requests, and both bills are computed for the same work."}, {"code": "break_even = PROVISIONED / (ON_DEMAND - ON_PROVISIONED)\nprint(f'break-even: the environments would have to be {break_even:.0%} busy')\n", "note": "Where the two lines would cross. Provisioned saves 0.0000011800 USD per GB-second of running and costs 0.0000066372 per GB-second of being kept ready, so it pays for itself only if the seconds of running outnumber the seconds kept ready by that ratio."}]}
```

Run it:

```
ana@laptop:~/aws$ python3 provisioned.py
 25% busy   on demand  109.50   provisioned  276.17 USD
 50% busy   on demand  219.00   provisioned  377.92 USD
 75% busy   on demand  328.50   provisioned  479.67 USD
100% busy   on demand  438.00   provisioned  581.42 USD
break-even: the environments would have to be 562% busy
```

**At these prices, in this Region, provisioned concurrency never costs less than on demand.** The
break-even would need the environments to be busy 562% of the time, five and a half months of
work in one month, which no month allows. Even at 100% use it costs 581.42 USD against 438.00, and the
`kept` part alone is 174.43 USD a month for ten idle gigabytes. Articles about provisioned
concurrency often name a level of use above which it becomes the cheaper option. That point is
arithmetic on one Region's prices, and São Paulo's sheet does not have one: here the discount on
running is too small to repay the charge for waiting.

So in sa-east-1 provisioned concurrency is **bought for latency and never for savings**, and the
question to ask is what a cold start costs the people who meet it. For an API where a user waits
on a checkout button, ten environments kept ready may be worth their 174 USD a month many
times over. For a queue consumer that nobody watches, it is money spent on a delay nobody sees.
The other discount on Lambda, a Compute Savings Plan, is not on the sheet; `aws-operations`
lesson 22 is where it is weighed.

Lesson 17 measures what a cold start actually is, and returns to provisioned concurrency as one of
the ways of removing it, beside cheaper ones that should be tried first.
