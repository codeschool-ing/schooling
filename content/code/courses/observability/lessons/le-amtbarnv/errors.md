---
title: Following an error to where it began
version: 1
---

A failed request rarely fails in one span. **The error starts in one place and every caller above
it reports a failure of its own**, so a trace of a failure is a column of red, and the work is
finding the bottom of it.

For one minute, every tenth charge fails, as the lab's payments service is told to in its fault
file. Then Zipkin is asked for the traces in the last two minutes where payments carries an error:

```
ana@obs:~/shop$ curl -sG localhost:9411/api/v2/traces --data-urlencode serviceName=payments --data-urlencode annotationQuery=error --data-urlencode lookback=120000 --data-urlencode limit=3 | jq -r '.[] | .[] | select(.tags.error) | [.traceId, .localEndpoint.serviceName, .name, .tags.error] | @tsv'
70a7acd463caea04147d020de13d469b	payments	post /charge	true
70a7acd463caea04147d020de13d469b	orders	post	true
70a7acd463caea04147d020de13d469b	orders	post /orders	true
70a7acd463caea04147d020de13d469b	storefront	post /checkout	true
71f1310c041b565a43af2c6e8cc17d74	payments	post /charge	true
71f1310c041b565a43af2c6e8cc17d74	orders	post	true
71f1310c041b565a43af2c6e8cc17d74	orders	post /orders	true
71f1310c041b565a43af2c6e8cc17d74	storefront	post /checkout	true
ae566ae9a7ae0a72437884091daea92c	payments	post /charge	true
ae566ae9a7ae0a72437884091daea92c	orders	post	true
ae566ae9a7ae0a72437884091daea92c	orders	post /orders	true
ae566ae9a7ae0a72437884091daea92c	storefront	post /checkout	true
```

Three failed checkouts, and **four spans marked as errors in each**. Read them by depth rather than
by the order they print in:

| span | why it is red |
|---|---|
| payments `post /charge` | it set the error status: *card network unavailable*, and answered 503 |
| orders `post` | the client side of that call, which received the 503 |
| orders `post /orders` | it gave up on the order and answered with an error of its own |
| storefront `post /checkout` | it received that error and passed it to the customer |

**The origin is the deepest error span with no erroring child**, here payments' `POST /charge`. Every
span above it is accurate and none of them is the cause. In Jaeger's interface the same search is
the tag `error=true`, and the trace view draws an icon on every failing span; the bottom one is
where to start reading, and its attributes and its log lines are where the reason is.

Two cautions:

- **A red span is a span somebody marked red.** The storefront, orders and payments set an error
  status on failure because their instrumentation does: Flask's automatic instrumentation marks
  every 5xx in `orders`, and the hand-written spans of the storefront and payments set the status
  explicitly. A service that catches an
  exception and returns 200 leaves no red anywhere.
- **The error can be outside the trace.** Payments' span names a card network it cannot reach, and
  the card network is not instrumented by anybody here. The deepest red span is the deepest place
  *you* can see, and the fault may be one step beyond it.
