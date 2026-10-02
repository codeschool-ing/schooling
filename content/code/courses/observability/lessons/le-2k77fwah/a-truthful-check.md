---
title: A readiness check that tells the truth
version: 1
---

The fix for a lying `/health` is not to make it check everything. **It is to ask, for each service,
what it needs in order to do its job**, and to check exactly that. `orders` needs the database to
store an order and the broker to announce it, so its readiness checks those two:

```schooling-example
{
  "language": "python",
  "file": "orders/app.py",
  "parts": [
    {
      "code": "@app.get(\"/ready\")\ndef ready():\n    \"\"\"Ready to take an order: the database answers and the broker takes a connection.\"\"\"\n",
      "note": "A second endpoint beside `/health`, which is left as it was. The docstring is the contract: what *ready* means for this service."
    },
    {
      "code": "    checks = {}\n    try:\n        with psycopg.connect(DB, connect_timeout=2) as conn:\n            conn.execute(\"SELECT 1\")\n        checks[\"postgres\"] = \"ok\"\n    except psycopg.Error as e:\n        checks[\"postgres\"] = type(e).__name__\n",
      "note": "**The same thing an order needs, done for real**: a connection and a query. `connect_timeout` keeps a probe from hanging longer than the prober waits for it."
    },
    {
      "code": "    try:\n        params = pika.ConnectionParameters(RABBIT, socket_timeout=2, connection_attempts=1)\n        with pika.BlockingConnection(params):\n            checks[\"rabbitmq\"] = \"ok\"\n    except pika.exceptions.AMQPError as e:\n        checks[\"rabbitmq\"] = type(e).__name__\n",
      "note": "The broker too, since an order that cannot be announced leaves its customer without a confirmation. One attempt, two seconds."
    },
    {
      "code": "    ok = all(v == \"ok\" for v in checks.values())\n    return {\"ready\": ok, \"checks\": checks}, 200 if ok else 503\n",
      "note": "**A failed check names itself** in the body, and the status code carries the verdict: 503 is what every prober understands as *not now*."
    }
  ]
}
```

`/health` stays as it was, and now it has a name it deserves: it says the process is up and
answering, which is what a liveness probe should ask. `/ready` says whether an order would go
through. Docker uses it in the next section, and it answers like this with the database stopped:
`503`, `{"checks": {"postgres": "OperationalError", "rabbitmq": "ok"}, "ready": false}`.

Four rules keep a readiness check from causing the trouble it is meant to report:

- **Check your own dependencies, never another service's readiness.** If the storefront's readiness
  asked `orders`' readiness, the database going down would take the storefront out of rotation too,
  including the pages that never touch the database.
- **Keep it cheap.** A probe runs every few seconds on every copy; this one opens a database
  connection and a broker connection each time, which is fine for two copies and worth measuring for
  two hundred. A pool's existing connection, or a result cached for a few seconds, is the usual
  answer.
- **Time out before the prober does.** A check that hangs is reported as a timeout, and the body
  that names the failing dependency is lost.
- **Exclude it from traces and metrics, or know that it is there.** The lab excludes `/health` from
  `orders`' traces but not `/ready`, so every probe now appears in Jaeger and in the request rate.
  A dashboard of requests per second that suddenly rises by one every five seconds is a probe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two ways to write readiness for a chain: the storefront calls orders, and orders uses the database. Above, each service checks only what it uses directly, so when the database is down only orders goes unready. Below, the storefront's readiness asks orders' readiness, so the database being down makes the storefront unready too, and the load balancer has nowhere to send even the pages that do not need the database.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">own dependencies</text><rect x=\"200\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"260.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ready</text><rect x=\"360\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"420.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not ready</text><rect x=\"520\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">database</text><text x=\"580.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">down</text><path d=\"M322 60 L358 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M482 60 L518 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chained readiness</text><rect x=\"200\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"260.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not ready</text><rect x=\"360\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"420.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not ready</text><rect x=\"520\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">database</text><text x=\"580.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">down</text><path d=\"M322 170 L358 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M482 170 L518 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">only orders leaves the rotation</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the storefront leaves too, for a database it never calls</text></svg>", "caption": "Readiness that checks its own dependencies isolates a failure; readiness that asks other services' readiness spreads it to everything upstream."}
```

**A check that says *not ready* has to be acted on by something.** Docker records it and does
nothing; Kubernetes takes the pod out of the Service; a load balancer stops sending to it. The next
two sections watch the first two.
