---
title: Instance classes, scaling and versions
version: 1
---

An App Engine application is not one program. **It is a set of services, each service a set of
versions, and each version a set of instances that App Engine starts and stops for you.** The
storefront is the `default` service, which every application has; an `api` service for the
orders could sit beside it, deployed and scaled on its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Nested boxes. The project planner-dev holds one App Engine application, whose region southamerica-east1 is fixed when it is created. The application holds two services, default and api. The default service holds two versions: v1 receives 90 per cent of the traffic and runs three instances; v2 receives 10 per cent and runs one instance. The api service holds one version, v7, with all of its traffic and two instances.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">project planner-dev</text><rect x=\"26\" y=\"42\" width=\"668\" height=\"226\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">application, region southamerica-east1, fixed at creation</text><rect x=\"42\" y=\"76\" width=\"400\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">service default</text><rect x=\"54\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v1</text><text x=\"145\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">90% of traffic</text><rect x=\"70\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"122\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"144\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"174\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"248\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"339\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v2</text><text x=\"339\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10% of traffic</text><rect x=\"264\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"286\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"456\" y=\"76\" width=\"222\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">service api</text><rect x=\"476\" y=\"108\" width=\"182\" height=\"136\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v7</text><text x=\"567\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">all of its traffic</text><rect x=\"492\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"514\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text><rect x=\"544\" y=\"166\" width=\"44\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"566\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inst.</text></svg>", "caption": "One application per project and one region per application; inside it, services, versions and the instances App Engine starts for each version."}
```

## Instance classes and their price

The standard environment sizes instances by class rather than by vCPU and memory. Classes that
start with **F** are for automatic scaling, classes that start with **B** for basic and manual
scaling, and the number doubles the size and the price. The sheet from lesson 1 carries the two
smallest:

```
ana@laptop:~/gcp$ python3 prices.py other | grep 'App Engine'
  App Engine standard F1, after 28 free hours           0.05  per instance-hour
  App Engine standard B1, after 9 free hours            0.05  per instance-hour
  App Engine flexible vCPU                            0.0526  per vCPU-hour
  App Engine flexible memory                          0.0071  per GiB-hour
```

Both are 5 cents an hour, and **both come with a free allowance every day**: 28 instance-hours of
F classes and 9 of B classes per project, which is why a small App Engine site can cost nothing
for years. An F2 is 10 cents and an F4 20, on the same page. Note the unit: an
instance-hour, counted per instance, however busy it was.

## Three ways to scale

| scaling | what it does | the classes |
|---|---|---|
| **automatic** | starts instances by request rate and latency, and can scale to zero | F |
| **basic** | starts an instance when a request arrives and stops it after it has been idle a while | B |
| **manual** | runs the number you set, all the time | B |

Automatic scaling is the default and the one the storefront uses. Its settings are the ones you
would expect, `min_instances`, `max_instances`, a target CPU utilisation, a target number of
concurrent requests, and Google's documentation says how each moves the count. **Basic scaling is
the one people forget exists**: for a back-office tool used twice a day it starts an instance on
the first request and lets it go afterwards, and the B classes' free hours often cover it.

## Versions and traffic

Every deploy creates a **version**, named by you or by the date. Versions live side by side, and
the service sends traffic to them in the proportions you set. **This command was not run**; it is
how Google documents splitting the storefront between two versions:

```sh
gcloud app services set-traffic default --splits=v1=0.9,v2=0.1 --split-by=cookie
```

Ninety per cent of visitors get `v1` and ten per cent `v2`, and `GAE_VERSION` in the page says
which one each got. `--split-by` decides how a visitor is assigned: by **IP address**, by a
**cookie** App Engine sets, or at **random**. A cookie keeps one person on one version across
requests, which matters the moment the two versions disagree about anything a person can see.

Each version also keeps its own address, `https://v2-dot-planner-dev.rj.r.appspot.com`, so a new
version can be tested at its own URL with no traffic at all before the split moves. Lesson 9 does
the same thing on Cloud Run with revisions and tags; the ideas are the same, and Cloud Run's are
the ones Google is still adding to.
