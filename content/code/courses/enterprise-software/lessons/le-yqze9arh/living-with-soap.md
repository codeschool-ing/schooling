---
title: Living with SOAP
version: 1
---

SOAP services will outlive most of the people reading this section. FarmRegistry stays until Coleta
goes, the NF-e services stay as long as the tax authority wants them, and SAP itself exposes much
of what it does as SOAP. A team building something new at Serra Alta will call SOAP for years, and
the wrong reaction is the natural one for an engineer from a JSON world: to treat it as a nuisance
and get it over with quickly. **The goal is not to avoid SOAP but to keep it at the edge of your
system, in one place, so that nothing else in your code knows it is there.**

## What going quickly looks like

Rota's team met FarmRegistry in 2022. They needed tank sizes for route planning, the service was
there, and nobody on the team had used SOAP. So they did what looked smallest: copied a request
from the test tool into a Kotlin string template, posted it with the HTTP client they already
had, and pulled the four values out of the response with regular expressions on `<fr:tankLitres>`
and its neighbours.

It worked for fourteen months. Then the bus was patched, and FarmRegistry started answering with
`ns2:` where it had written `fr:`. The XML meant exactly the same thing, because a prefix is only a
local name for a namespace; the regular expressions found nothing, the parser fell back to a tank
size of zero, and Rota planned no collections for 37 farms that night. Three trucks went out the
next morning to farms they had not been sent to, because the drivers knew better than the plan.

Every step of that failure is common. **Text handling on XML breaks on changes that are not
changes**, a silent default turned a parsing failure into a wrong answer, and a 500 with a fault
inside would have gone the same way.

## Generate the client from the contract

The WSDL exists so that nobody has to write envelopes by hand. Every mainstream platform has a
generator: on the JVM, Apache CXF's `wsdl2java`; on .NET, `dotnet-svcutil`; in Python, the `zeep`
library reads the WSDL and builds the calls when the program runs. What comes out is a typed client:
a method per operation, a class per message, an exception per declared fault, and a real XML
parser that reads namespaces rather than prefixes.

Three habits make the generated client safe to depend on:

- **Keep a copy of the WSDL in your repository and generate at build time.** Fetching it from the
  service's `?wsdl` address when the program starts means a change on the bus becomes a change in
  your program, unreviewed, on a day you did not choose.
- Check the copy against the published one in your build, so that a changed contract fails a test
  with a diff instead of failing in production with a stack trace.
- Pin the generator's version with the rest of your dependencies; two versions of the same tool can
  generate different class names from the same WSDL.

## Wrap it in an adapter

The generated client speaks the service's language: `GetFarmTankResponse`, `farmCode` as a string,
`lastCollection` as an XML calendar type, `FarmNotFoundFault`. If those types spread through
Rota, then Rota's route planner is written in FarmRegistry's terms, and replacing FarmRegistry,
which lesson 13 plans to do, means touching the planner.

So the second version of Rota's integration put a boundary in. Rota defines what it needs in its
own words — an interface `FarmTanks` with one method that takes a Rota `FarmId` and returns a
`Tank` with a capacity, an average daily volume and a last-emptied time, or "this farm is not
known". One class implements that interface using the generated client, and it is the only class
in Rota that imports anything generated. **The adapter is where SOAP ends: generated types go in on
one side, Rota's own types come out of the other, and the rest of the program cannot tell.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-adapter\" aria-label=\"Rota calling FarmRegistry, left to right. Inside Rota: the route planner calls the interface FarmTanks, which is implemented by an adapter holding the generated client, the mapping of faults to answers, the timeouts with one retry, and the fallback to yesterday's answer. A dashed line marks the boundary: to its left everything is in Rota's own types, to its right everything is SOAP. Past the boundary the call goes to the FarmRegistry service on the bus and on to Coleta on the IBM i. Below the bus, a dashed box shows the stub with recorded envelopes that replaces the bus in Rota's tests.\"><defs><marker id=\"l08-adapter-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"232.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Rota's own types</text><text x=\"598.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SOAP</text><rect x=\"18.0\" y=\"98.0\" width=\"104.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">route</text><text x=\"70.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner</text><rect x=\"146.0\" y=\"98.0\" width=\"104.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FarmTanks</text><text x=\"198.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">interface</text><path d=\"M122.0 120.0 L144.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"272.0\" y=\"52.0\" width=\"176.0\" height=\"150.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">adapter</text><rect x=\"280.0\" y=\"82.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">generated client</text><rect x=\"280.0\" y=\"112.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">faults → answers</text><rect x=\"280.0\" y=\"142.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">timeouts, one retry</text><rect x=\"280.0\" y=\"172.0\" width=\"160.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">yesterday's answer</text><path d=\"M250.0 120.0 L270.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><path d=\"M466.0 40.0 L466.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"466.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the boundary</text><rect x=\"488.0\" y=\"98.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FarmRegistry</text><text x=\"548.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">on the bus</text><path d=\"M448.0 120.0 L486.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"626.0\" y=\"98.0\" width=\"84.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><text x=\"668.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM i</text><path d=\"M608.0 120.0 L624.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path><rect x=\"488.0\" y=\"206.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"568.0\" y=\"219.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stub with recorded</text><text x=\"568.0\" y=\"232.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">envelopes, in tests</text><path d=\"M448.0 190.0 L486.0 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-adapter-es-ah-paper-dim)\"></path></svg>", "caption": "SOAP ends at the adapter. Everything to the left of the line is written in Rota's terms, so a change on the bus, or the end of FarmRegistry, touches one class."}
```

That boundary has a name in domain-driven design, the anti-corruption layer, and it can be much more
than a type conversion: Coleta's farm codes carry a check digit, its volumes are in whole litres,
and its times carry an offset Rota does not want. Lesson 13 builds the layer properly, because it
becomes the seam along which Coleta is replaced. Here the point is smaller: put every SOAP detail
in one class, and the next change to the bus touches one class.

## Faults are answers with meaning

A fault is not one kind of error. The adapter's most important job is to turn each kind into the
right reaction, and the right reaction depends on whose fault it is and whether trying again could
help:

| what came back | what it means | what Rota's adapter does |
|---|---|---|
| `soap:Client` with a `FarmNotFound` detail | the farm is not in Coleta: it left, or the code is wrong | returns "unknown farm", which the planner drops from the route and reports to farm relations; never retries |
| `soap:Client` with no known detail | Rota sent something the service cannot read: a bug on Rota's side | raises an error, alerts the Rota team; never retries |
| `soap:Server` | FarmRegistry or Coleta behind it failed | retries once after two seconds, then falls back |
| HTTP 502, 503 or 504 with no envelope | something between the two failed: a proxy, the bus's own front | treated like `soap:Server` |
| no answer within the timeout | unknown: the request may or may not have been processed | for this read, the same as `soap:Server` |

**The fallback is a decision about the business, not about the protocol.** A farm's tank does not
change size between yesterday and today, so when FarmRegistry is down, Rota plans from yesterday's
answer and marks the plan as built on cached data. Lesson 12 calls this a degraded mode and asks
the question for every integration.

The last row hides the trap. `GetFarmTank` only reads, so asking twice is harmless. A SOAP
operation that writes — `RegisterBankAccount` in the farm-onboarding process is one — must not be
retried blindly after a timeout, because the first call may have succeeded and the second will do
the work again. Whether a write can be repeated safely is a property the operation has to be given,
and lesson 10 is about how.

## Timeouts are numbers somebody chose

The HTTP client Rota started with waited for a reply indefinitely. On the night of a slow Coleta
batch, a planning run hung for forty minutes waiting on one call. A timeout is a statement about
how long the caller can afford to wait, and it should be set from measurements of the service, not
left at a library default.

Joana's numbers for FarmRegistry, from a month of the bus's statistics: the median call takes
0.3 seconds, the 99th percentile 1.8 seconds, because some calls wait for Coleta behind MQ. Rota now
sets a connection timeout of 2 seconds and a read timeout of 5: long enough that a slow but healthy
call finishes, short enough that a dead one costs a planning run seconds rather than minutes. With
one retry, a farm whose calls both hang costs 5 + 2 + 5 = 12 seconds before the fallback, and the planner
asks for tanks in parallel, eight at a time.

## Test against recorded envelopes

A test that needs the bus is a test that waits in the integration team's queue and fails when the
shared environment is busy. **Rota's adapter tests run against recorded envelopes**: real request
and response pairs captured once from the test bus, with farm data replaced by invented values,
stored beside the code, and replayed by a small local stub that answers like FarmRegistry.

The recordings that matter most are not the happy ones. The team captured a `FarmNotFound` fault by asking for a code that does not exist. It captured a
`soap:Server` fault by asking the bus team to stop the Coleta queue for ten minutes in the test
environment. And it kept a response with `ns2:` prefixes, and one with an extra element the WSDL
does not declare yet. Each one is a test, and each test
checks what the adapter returns, not what XML it sent. When the bus team announces a change, the
Rota team records the new envelopes and runs the tests before the change reaches production.

None of this is particular to SOAP. It is what any team should do when it depends on a system it
does not control. SOAP makes it easier than most, because the contract is in a file and the faults
are declared in it.
