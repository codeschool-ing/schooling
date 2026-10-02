---
title: First queries: selecting series
version: 1
---

PromQL, Prometheus's query language, is asked through an HTTP API, and its answers are JSON. A short
script, `promq`, sends one expression and prints each series it got back on one line, its labels and
then its value:

```
ana@obs:~/shop$ cat promq
#!/bin/sh
# promq 'EXPRESSION': ask Prometheus for the value of an expression, now.
curl -sG localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | (.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) + "  " + .value[1]'
```

The simplest expression is a metric's name with labels to match, a **selector**. `up` for one job:

```
ana@obs:~/shop$ ./promq 'up{job="payments"}'
__name__=up instance=payments:8082 job=payments  1
```

And the storefront's request counter, every series of it:

```
ana@obs:~/shop$ ./promq 'http_server_requests_total{job="storefront"}'
__name__=http_server_requests_total code=200 instance=storefront:8080 job=storefront method=GET route=/health  7
__name__=http_server_requests_total code=200 instance=storefront:8080 job=storefront method=GET route=/products  34
__name__=http_server_requests_total code=201 instance=storefront:8080 job=storefront method=POST route=/checkout  281
__name__=http_server_requests_total code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  17
```

Four series, one per combination of labels the storefront has answered. The result is an **instant
vector**: one value per series, taken at the moment of the query. Labels can be matched exactly with
`=`, excluded with `!=`, or matched against a regular expression with `=~`, which is how *every 4xx*
is written:

```
ana@obs:~/shop$ ./promq 'http_server_requests_total{job="storefront", code=~"4.."}'
__name__=http_server_requests_total code=402 instance=storefront:8080 job=storefront method=POST route=/checkout  17
```

**These numbers alone answer almost nothing.** 281 checkouts answered `201` since the storefront
started, and that start could have been a minute or a month ago. A counter only grows, and its value
depends mostly on how long the process has been running. A counter becomes a useful number when it
is asked how fast it is growing, which is the next section.
