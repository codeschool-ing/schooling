---
title: When a service ignores the flag
version: 2
---

Head sampling works only if every service obeys the decision it receives. **The trace is kept or
dropped whole because the flag travels with it**; one service with its own idea breaks that.

Here `orders` is given `always_on`, a sampler that records everything and ignores any parent. The
override grows by three lines:

`~/shop/compose.override.yaml`

```yaml
services:
  storefront:
    environment:
      OTEL_TRACES_SAMPLER: parentbased_traceidratio
      OTEL_TRACES_SAMPLER_ARG: "0.1"
  orders:
    environment:
      OTEL_TRACES_SAMPLER: always_on
```

```sh
docker compose up -d orders
sleep 45
```

And the same ten traces' worth of lookup:

```
ana@obs:~/shop$ for t in $(docker compose logs --no-log-prefix --since 40s --until 15s storefront | grep "checkout finished" | jq -r .trace_id | tail -10); do printf "%s  " $t; curl -s localhost:16686/api/traces/$t | jq -r 'if .data then (.data[0] as $d | ($d.spans | map(.spanID)) as $ids | $d.spans | "\(length) spans, top: " + (map(select(.references == [] or (.references[0].spanID | IN($ids[]) | not))) | map($d.processes[.processID].serviceName + " " + .operationName) | join(", "))) else .errors[0].msg end'; done
508c536069559a630384c004c21965ac  8 spans, top: storefront POST /checkout
343519c740aad67188ebce4635a71211  7 spans, top: orders POST /orders
45d9681906d360b154286e13f2878494  7 spans, top: orders POST /orders
258b73709656841616ed9cb3725dd61a  6 spans, top: storefront POST /checkout
0b899824acab3c9e5fe60223898a2f4b  7 spans, top: orders POST /orders
ca6fc4c07fdec6205252047301f1f2bd  7 spans, top: orders POST /orders
ee87d19b1acc0bf336c7dda29d4f9cf1  7 spans, top: orders POST /orders
608bb9f2ca58bbcccb4448176950ee23  7 spans, top: orders POST /orders
a077ec50a8c43066fff61ebfd2b6bb52  7 spans, top: orders POST /orders
d327f72414490d1217784a591cbcb57e  8 spans, top: storefront POST /checkout
```

Seven of the ten are **traces with no root**: the storefront dropped them, and `orders` recorded
them anyway, seven spans from `POST /orders` down. The other three are whole, eight spans from the
storefront down, or six for a checkout whose card was declined and so sent no e-mail. The storefront
kept those, and every service obeyed.

Nothing failed and no service logged a complaint. The store simply fills with traces that start in
the middle: their top span is `orders`' `POST /orders`, and it points at a parent span that was
never exported. Jaeger warns about the missing parent in its interface. A dashboard counting traces
counts these as whole, and a tail sampler, in the next section, would judge them without their root.

This happens in practice in three ways:

- **A service sets its own sampler**, as here, usually `always_on` by somebody debugging it.
- **A service drops the incoming context**, which lesson 4 showed as a broken trace, and then makes a
  root decision of its own.
- **Two services use different fractions with a sampler that does not follow its parent.** With
  `TraceIdRatioBased` alone in each, a downstream service keeping 10% and an upstream one keeping
  50% agree on the traces below 10% and split on the rest.

The rule that avoids all three: **sample at the root, and use a parent-based sampler everywhere
else.** It is the default in every SDK for a reason, and overriding it in one service is a decision
about every trace that passes through it.
