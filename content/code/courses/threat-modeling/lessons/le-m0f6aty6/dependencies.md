---
title: Dependencies
version: 1
---

The DFD shows the portal as a circle, and the circle hides most of what is running. The portal is
Vereda's code on top of a web framework, a PDF library, the payment gateway's client library and
everything those import. It runs on a cloud provider's machines and answers a name a DNS provider
publishes. A CI service builds it from a git host, with packages pulled from public registries.
**Every one of those runs with the portal's trust**, and a mistake in any of them is a way in that
Vereda never wrote.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-dependencies\" aria-label=\"Four rings of what the portal depends on. Code Vereda wrote: the portal, the console, the worker. Code Vereda imports: a web framework, a PDF library, the gateway’s client library, and everything those import in turn. Services Vereda calls: the cloud provider, DNS, the SMS provider, the payment gateway. And what builds and ships it: the git host, the CI runner, the package registries.\"><defs><marker id=\"l06-dependencies-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">what Vereda wrote</text><text x=\"100.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the portal,</text><text x=\"100.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the console,</text><text x=\"100.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the worker</text><path d=\"M180.0 100.0 L192.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"272.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what it imports</text><text x=\"272.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a web framework,</text><text x=\"272.0\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a PDF library,</text><text x=\"272.0\" y=\"114.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the gateway client,</text><text x=\"272.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and what they import</text><path d=\"M352.0 100.0 L364.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"364.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"444.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what it calls</text><text x=\"444.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the cloud provider,</text><text x=\"444.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">DNS, the SMS provider,</text><text x=\"444.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the payment gateway</text><path d=\"M524.0 100.0 L536.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-dependencies-tm-ah-paper-dim)\"></path><rect x=\"536.0\" y=\"40.0\" width=\"160.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"616.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">what builds and ships it</text><text x=\"616.0\" y=\"95.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the git host,</text><text x=\"616.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the CI runner,</text><text x=\"616.0\" y=\"120.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">package registries</text><text x=\"360.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Each ring runs with the trust of the one before it, and you reviewed the first one only.</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">This workspace alone: 1 package installed on purpose, 5 more that came with it.</text></svg>", "caption": "The surface includes everything that runs with your trust. Most of it you did not write."}
```

### The size of it

The workspace of lesson 1 is a fair small example. One package was installed on purpose:

```
(.venv) ana@vm:~/tm$ pip list
Package           Version
----------------- -------
annotated-types   0.8.0
pip               26.2.1
pydantic          2.13.5
pydantic_core     2.46.5
pytm              1.4.0
typing_extensions 4.16.0
typing-inspection 0.4.4
```

pytm, plus five packages that came with it, plus pip itself. None of the five was chosen by anybody
at Vereda, and each one runs with the same permissions as the model. In a web application the same
ratio is typical and the numbers are larger: a framework brings dozens of packages, and each of
those brings its own.

### What the map records for each dependency

A threat model does not list every transitive package; that is a software bill of materials, and
the `secure-pipeline` course (lesson 13) generates one automatically. What the model records is the
dependencies that **sit on an entry point or hold a secret**, because those are the ones whose
failure is a threat to this design:

| dependency | why it is on the map | the question it raises |
|---|---|---|
| the PDF library in the console | parses files patients upload | what happens when it meets a malformed file? (T14) |
| the gateway's client library | holds the API key and builds every charge | who updates it, and how fast after a fix? |
| the SMS provider | receives a phone number and a message for every booking | what does its contract say about keeping them? |
| the cloud account | holds every machine and every secret | who has the owner role, and with what second factor? |
| the CI service | can deploy anything to production | which repository branches can trigger a deploy? |

### Services are entry points too

The payment gateway is drawn as an external entity, but Vereda also depends on it: if its servers
are compromised, the webhook carries whatever the attacker wants, signed with a valid key. The
model cannot fix that. It can make sure the dependency is written down, that the contract with
the gateway says who notifies whom after an incident, and that the portal checks what a
signature cannot: that the amount paid matches the booking. Lesson 8 turns that sentence into a
requirement.
