---
title: Choosing one of the three
version: 1
---

The choice is often put as "REST is the full product, HTTP is the cheap one", which makes REST
sound like the safe default. **The safer default is the HTTP API, and a REST API is chosen for a
named feature it alone has.** If nobody on the team can name the feature, the API is paying 4.25
instead of 1.59 per million requests for nothing. A WebSocket API is a third question altogether:
whether the server has to speak first.

## What each one has

The rows are the ones that decide a choice, from AWS's own comparison of the two request APIs. A
dash means the API does not offer it.

| | REST API | HTTP API |
|---|---|---|
| price per million requests, first tier (16 October 2026) | 4.25 | 1.59 |
| deploys | by hand, to a named stage | on its own with `$default` |
| JWT authoriser built in | — | yes |
| IAM and Lambda authorisers | yes | yes |
| API keys and usage plans per client | yes | — |
| response cache | yes | — |
| mapping templates and request validation | yes | — |
| AWS WAF in front | yes | — |
| private endpoint, reachable only from a VPC | yes | — |

Three rows send most teams to REST: **a usage plan per client**, for an API sold to partners with
a quota each; **AWS WAF**, for rules against abusive traffic in front of a public API; and a
**private endpoint**, for an API that must not have a public address at all. The cache is the
fourth, and the next part of this section says what it costs to try. If none of the four applies,
an HTTP API does the job.

## Throttling, which every API has

**All three kinds share one limit per account and region**: on AWS, by default, 10,000 requests a
second in a steady state, with bursts of up to 5,000 requests absorbed at once. That limit belongs
to the account, so a load test against one API can throttle every other API in São Paulo.
Underneath it you can set lower limits on a stage or a route, and a REST API adds the per-client
limits of usage plans. A request over any limit is answered `429 Too Many Requests` and the
integration never sees it. What the client does next is the same question lesson 16 asked about
Lambda's own throttling: retry with backoff, or fail.

moto keeps the settings and counts nothing, so no request here was ever throttled.

## A timeout, and where long work goes

An integration has to answer quickly. **A REST API waits 29 seconds by default and an HTTP API at
most 30**; past that the client gets a `504` even if the function is still working and finishes a
minute later. Since 2024, a regional or private REST API can ask AWS for a longer wait through a
quota increase, at the cost of fewer requests per second for the account. Neither number is
moto's: it never calls the integration.

So a request that starts a job of minutes should not wait for the job. The API takes the request,
hands the work to something that runs it, and answers `202 Accepted` with an id the client can
ask about later. Lesson 20 builds the something with Step Functions, and lesson 21 the queue in
front of it.

## The cache, which only REST has

A REST stage can keep responses in a cache of its own for a time to live you choose, 300 seconds
by default, so repeated `GET`s never reach the integration. It is turned on per stage, with a size:

```
ana@laptop:~/aws$ aws apigateway update-stage --rest-api-id "$API" --stage-name prod --patch-operations op=replace,path=/cacheClusterEnabled,value=true op=replace,path=/cacheClusterSize,value=0.5 --query "{cacheClusterEnabled: cacheClusterEnabled, cacheClusterSize: cacheClusterSize, cacheClusterStatus: cacheClusterStatus}"
{
    "cacheClusterEnabled": true,
    "cacheClusterSize": "0.5",
    "cacheClusterStatus": "AVAILABLE"
}
```

moto says `AVAILABLE` at once. **AWS documents about four minutes to create a cache**, during which
the status is `CREATE_IN_PROGRESS`, and the sizes run from 0.5 GB to 237 GB. A cache is billed by
the hour for as long as it exists, whether a request hits it or not, and its price is not on this
course's sheet: look it up on the API Gateway pricing page before turning one on. A cache in front
of a function that answers in 50 ms saves a few invocations and little time; in front of a slow
database it saves seconds on every hit, and that is where it earns its hourly price.

## WebSocket, or not

The question for a WebSocket API is not about features. **Does the server need to tell the client
something the client did not ask for, within seconds?** A live order status, a chat, a dashboard
of prices: yes. A form that saves and a page that loads: no, and an HTTP API is simpler to build,
to test with `curl` and to cache in a browser. The previous section's arithmetic is the other half
of the decision: a WebSocket pays per message and per minute, polling pays per request, and which
one is cheaper depends on how often there is news.
