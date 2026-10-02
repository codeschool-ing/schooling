---
title: When a mesh is worth it
version: 1
---

A mesh is often adopted for the wrong reason, which is that it is what serious platforms run. Its
costs are concrete, and lesson 13's question applies again: **who runs it, and what does it cost in
the unit that grows?**

The lab's Envoy, measured after the retries section, beside two of the shop's services:

```
ana@obs:~/shop$ docker stats --no-stream --format '{{.Name}}  {{.CPUPerc}}  {{.MemUsage}}' shop-envoy-1 shop-storefront-1 shop-orders-1
shop-envoy-1  0.47%  16.93MiB / 15.72GiB
shop-storefront-1  3.61%  35.69MiB / 15.72GiB
shop-orders-1  65.35%  48.06MiB / 15.72GiB
```

Seventeen megabytes and under half a per cent of a CPU, against 36 megabytes for the storefront it fronts. One proxy is cheap. The mesh's version of it is one per pod.

The costs come in four kinds:

- **Resources.** One proxy per pod, so the overhead grows with the number of pods rather than with
  traffic. A few tens of megabytes each is small for one service and large for a thousand.
- **Latency.** Every call crosses two more proxies. A millisecond or less each, which matters for a
  chain of twenty calls and not for a checkout of four.
- **Operations.** The control plane is a critical system of its own: certificates rotate, upgrades
  replace every sidecar, and a mistake in a routing rule fails traffic for every service at once.
- **A second source of truth for failures.** As the retries section showed, the proxy and the
  application can disagree about whether a request failed, and the team has to know which to read.

Against that, a mesh pays when several of these are true at once:

- **Many services, written by many teams, in several languages.** One proxy gives every one of them
  the same telemetry and the same retry and timeout rules, with no library to agree on.
- **Encryption between services is required**, by a regulator or a customer. Mutual TLS in a mesh is
  one policy; without one it is a certificate setup in every service.
- **Traffic control is needed**: canaries by percentage, mirroring, failover between regions.

For a handful of services in one language, the shop's situation, the honest answer is usually no.
OpenTelemetry in the code gives richer signals than a proxy can. Timeouts and retries are a few
lines each, and they live beside the logic that knows whether a call is safe to repeat. A team that
outgrows that will know: it is the day the same retry bug is fixed in the fifth language.

**Ambient mode** changes part of the trade. Istio's newer data plane replaces the sidecar with one
proxy per node for encryption and identity, plus optional proxies per service for HTTP features, so
the cost no longer grows with every pod. It is a newer design with its own operational questions,
and it is worth an evaluation of its own rather than a default.
