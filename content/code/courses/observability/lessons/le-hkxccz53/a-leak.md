---
title: A leak, made on purpose
version: 1
---

Leaks are rarely somebody deciding to log a password. **They are a helpful debug line that logs a
whole object**, written while chasing a bug and left behind. Here is one, added to the storefront the
way it usually happens, right after the request's body is read:

```
ana@obs:~/shop$ sed -i 's/^        body = request.get_json()$/&\n        log.debug("request", extra={"fields": {"headers": dict(request.headers), "body": body}})/' services/storefront/app.py && grep -n 'log.debug' services/storefront/app.py
35:        log.debug("request", extra={"fields": {"headers": dict(request.headers), "body": body}})
```

The line logs every header and the whole body at `DEBUG`, which lesson 8 showed is off by default.
Somebody then turns `DEBUG` on to investigate, in the override file that already points the Collector
at Loki and Elasticsearch:

```yaml
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
  storefront:
    environment:
      LOG_LEVEL: DEBUG
```

And a customer checks out. Their client sends an access token in the `Authorization` header, as an API client does; it is made
up and works nowhere:

```
ana@obs:~/shop$ docker compose up -d storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json
{"id":2701,"qty":1,"sku":"kettle","status":"paid"}
```

The checkout worked; nothing failed and nothing warned. And in Loki, found by searching for the word
`Bearer`:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} |= "Bearer"' --data-urlencode since=5m | jq -r '.data.result[].values[][1]' | jq -c '{message, card: .body.card, auth: .headers.Authorization}'
{"message":"request","card":"4111 1111 1111 1111","auth":"Bearer sk_live_9f8e7d6c5b4a"}
```

**The full card number and the token, stored, indexed and readable by everybody with access to the
logs**, and copied to Elasticsearch on the same trip. Every line between this moment and somebody
noticing adds another customer's card. The test card charges nobody; a real one in the same place is
a reportable security incident, and the LGPD and the card industry's rules each have something to
say about it.

Note what made it possible: not the debug line alone, but **the debug line plus a level that turns it
on in production**. Which is why the defences that follow do not rely on the level being right.
