---
title: An SLI is a ratio of good events, measured where the user is
version: 1
---

**A service level indicator is the share of events that were good, out of all the events that counted.**
Good requests out of all requests; checkouts finished in under a second out of all checkouts. It is a ratio
between 0 and 1, so it reads the same at forty requests a minute and at four thousand, and it is written from
the user's side: what would somebody using the shop call a failure? The answer is narrower than "anything that
went wrong inside" and wider than "the server returned 500".

The wrong SLI is the one that is easy to measure. CPU at 90% is not a failure anybody experiences; a checkout
that took eight seconds is, whatever the CPU said. A database replica falling behind matters to the user only
if it makes their order disappear. So the shop's indicators come from the requests, not from the machines:

| SLI | good event | all events |
|---|---|---|
| availability | a request answered without a `5xx` | every request to `shop-api` |
| latency | a checkout answered in under 1 second | every checkout |
| freshness | a price list less than 10 minutes old when read | every read of the price list |

## Choosing what counts

Three decisions hide in each row, and each one changes the number:

- **Is a `4xx` good?** A `404` for a product that does not exist is the shop answering correctly; a `429`
  from the shop's own rate limiter is the shop refusing a customer. The shop counts `4xx` as good, and lesson
  16's rate limiting is measured separately.
- **Which requests count at all?** The health checks of lesson 8 are requests too, and always succeed. Counted,
  they dilute every failure; the shop's filter is on the service, and the uptime check's requests are a small
  share, but a health check every second from many places would not be.
- **Where is it measured?** At the load balancer, a request that never reached the API because the API was
  down is counted as a failure. Measured inside the API, it is not counted at all, and the SLI looks perfect
  during an outage. The shop measures at Cloud Run's front end, which `run.googleapis.com/request_count` is.

## Indicator, objective, agreement

| | what it is | for the shop |
|---|---|---|
| SLI | the measured ratio | the share of requests without a `5xx` |
| SLO | the target for it, over a window | 99.5% over 28 days |
| SLA | a promise to customers, with a consequence | none: the shop sells no guarantee |

**An SLO is internal and an SLA is a contract**, and the SLO is set tighter than any SLA, so that the team
notices it is missing its own target long before a customer is owed anything. 99.5% is not a law of nature:
it is the shop's decision that one failed request in two hundred is acceptable and one in a hundred is not,
and it is revisited when customers' behaviour says otherwise.
