---
title: The cold start, and what each plan does about it
version: 1
---

The usual picture is of a function that falls asleep and is slow to wake, as if Azure itself were
taking its time. **A cold start is the work of making a new instance able to answer**, and most of
it is a program starting: Microsoft's host, then Python, then your own file. It happens whenever a
request needs an instance of the app and none is free. That is the first request after the app has
been scaled to zero, and it is also every request that arrives while the running instances are busy
and a new one is being added. The documentation describes the first case plainly. If a function app
stays idle for a few minutes, the platform might take its instances down to zero, and "the next
request experiences the added latency of scaling from zero to one."

## Five things happen before the answer

Lesson 15 showed what a function app is inside: a host, a language worker beside it, and your file
loaded into the worker. A cold request waits for all of it to be built, in this order.

1. The platform finds an instance and gives it your app. On Flex Consumption the app is a package in
   a blob container, which the documentation says the app fetches on start-up and runs from; on a
   container plan it is the image.
2. The Functions host starts. It is a .NET program, and it reads `host.json` and loads the
   extensions the bindings need.
3. The host starts the Python worker, the second process `ps` showed in lesson 15.
4. **The worker imports `function_app.py`, and every line at the top of the file runs.** This is
   also how the host learns which functions exist: in the v2 programming model the decorators are
   the configuration, so nothing is known until the import has finished. Every `import` at the top
   of the file, and every client built there, is paid here.
5. The first call: the host hands the request to the worker, the function runs, and the answer goes
   back.

A warm request is the fifth step alone. The first three are the platform's and the plan's, and the
fourth is the only one that is yours. The documentation says the same from the other
side: "The number of dependencies your function app requires can affect the cold
start time."

**Who waits matters as much as how long.** The documentation calls cold start "more of an issue for
synchronous operations, such as HTTP triggers that must return a response". A customer is behind
`take_order`. Nobody is behind `make_receipt`: a queue message that waits five seconds for an
instance is a receipt written five seconds later, which no one sees.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"A grid of five phases of a cold start, left to right: find an instance, start the host, start the Python worker, import function_app.py, and the first call. Three rows. With nothing kept ready, the request waits for all five. With a prewarmed placeholder, as the legacy Consumption plan keeps, the first three are done before the request arrives and it waits for the import and the call. With an instance kept ready, as always ready, prewarmed instances, Always On or a minimum of one replica keep, only the call is left.\"><text x=\"246.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">find an</text><text x=\"246.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instance</text><text x=\"350.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">start</text><text x=\"350.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the host</text><text x=\"454.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">start the</text><text x=\"454.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Python worker</text><text x=\"558.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">import</text><text x=\"558.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">function_app.py</text><text x=\"662.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the call</text><path d=\"M196 60 L196 66 L504 66 L504 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"350.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">the platform's</text><path d=\"M508 60 L508 66 L608 66 L608 60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"558.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\" font-style=\"italic\">your code</text><text x=\"16\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nothing kept ready</text><text x=\"16\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">scaled to zero</text><rect x=\"196\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"300\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"404\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"508\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"612\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"16\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a prewarmed placeholder</text><text x=\"16\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">legacy Consumption</text><rect x=\"196\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"300\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"404\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"508\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"612\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"16\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">an instance kept ready</text><text x=\"16\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Flex, Premium, Dedicated</text><rect x=\"196\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"300\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"404\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"508\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"612\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"16\" y=\"278\" width=\"22\" height=\"16\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the request waits for it</text><rect x=\"250\" y=\"278\" width=\"22\" height=\"16\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"280\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done before the request arrives</text><text x=\"704\" y=\"308\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">a shape, not a measurement</text></svg>", "caption": "What each kind of readiness takes off a cold start. A placeholder has the host and the worker running already, but it is not yet your app, so your imports are still paid by the request; an instance kept ready has done all of it."}
```

## What each plan does about it

**The legacy Consumption plan keeps placeholders.** The documentation says it pulls "from prewarmed
placeholder functions that already have the host and language processes running". A placeholder is
a generic instance, started before anyone needed it, that becomes your app when a request arrives,
so the first three steps are taken off. Your import is not, because the placeholder had no way of
knowing your file. The same page lists Consumption's mitigation as "None" and says cold starts are
expected in this plan.

**Flex Consumption keeps always ready instances**, if you ask for them. The count is set per scale
group, `http` for all the HTTP functions or `function:<name>` for one of the others, and an
instance in it is never taken away, so a request that lands on it waits for nothing but the call.
Beyond them, the plan adds on-demand instances, and each of those starts cold; with zone redundancy
switched on, the documentation requires at least two always ready instances per group. Without any,
the documentation still claims an "improved cold start even when scaled to zero" over Consumption,
and gives no figure for it.

**Premium never goes to zero, and keeps one instance ahead of the load.** Its always ready instances
run continuously, at least one in every plan. Its prewarmed instances are a buffer for scale-out. As
soon as the always ready ones start working on HTTP traffic, the platform starts another and keeps it
warm and idle. When load needs it, it becomes active, and the next one is started. One is the
default and, says the documentation, the right number for most apps; it suggests more for an app in
a custom container, "because custom containers have a long warm-up time". Premium also runs a
**warmup trigger**, a function named `warmup` that is called on each new instance during scale-out,
before it takes traffic: the place to open connections and load what the first request would
otherwise wait for. The documentation says it is not available on the legacy Consumption plan, and
that it runs only when the app scales out, never on a restart.

**Dedicated and Container Apps have no cold start while something keeps running.** On a Dedicated
plan, with Always On, the host runs continuously on the plan's instances, which the documentation
sums up as "cold start isn't really an issue". On Container Apps it depends on the minimum number of
replicas: one or more and the host runs all the time, zero and the app may scale to zero and pay a
start like any other.

## What is yours to shorten

The fourth step is the one the plan cannot help with, and three things in it are under your control.

**Import at the top only what every function needs.** A function app is one unit: every function in
it is loaded by the same import of the same file. If the nightly sales report and the order API live
in one app, and the report imports a data library at the top of the file, then every cold start of
`take_order` pays for a library `take_order` never uses. Two apps, or an import moved inside the
one function that needs it, keep the cost where the use is. The next section measures exactly this.

**Build clients once, at module level.** Microsoft's guidance on connections is direct: do not
create a new client on every invocation, and in Python, "create clients at module level, above the
`FunctionApp()` instance". That puts the cost of a client in the cold start, deliberately, so that
every warm call after it reuses the connection rather than opening one. A client built inside the
function would be paid on every request, and warm requests are nearly all of them.

**Keep the package small.** What the instance fetches before it can start is the package, so its
size is part of the first step. The documentation's advice for big files on Flex Consumption is to
mount an Azure Files share instead of shipping them in the package, "so you keep deployments small
and cold starts fast".

None of the three makes a cold start go away. The plan decides how often a request meets one, and
the code decides what it costs when it does.
