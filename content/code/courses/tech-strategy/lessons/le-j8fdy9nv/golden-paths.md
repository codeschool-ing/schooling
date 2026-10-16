---
title: The golden path: the supported way, made the easiest way
version: 1
---

A **golden path** is the supported way of doing a common task, built so that taking it is less work
than any alternative. The name is Spotify's; other companies call it a paved road. Creating a new
service, deploying it, giving it a database: each can have a path, and a team that follows one gets
the boring parts done for it.

The common misreading is that a golden path is the only permitted way. It is a recommendation with
a support promise attached. **A team may leave the path, and when it does it owns what it builds
there**: the pipeline, the alerts, the upgrades and the night when one of them breaks. The path wins
by being cheaper to stay on, and the price of leaving is paid by the team that leaves rather than
enforced by anybody.

## Coreto's service template

Rafaela's answer to the days lost at the start of every new service was a template. A team creating a
service starts from it and the result already has:

- a build and test pipeline that runs on every change;
- deploys to staging and to production, with a rollback;
- structured logs, the standard metrics and a dashboard;
- alerts routed to the team that owns the service, not to Platform;
- a health check and a runbook page with the sections an on-call engineer looks for;
- dependency updates proposed automatically when the template itself is updated.

None of that is interesting to Checkout or Catalogue, and all of it is needed. That is the test
for what belongs on a path. Lesson 8 drew Geoffrey Moore's line between core work, which sets a
company apart, and context work, which has to be done well and sets nobody apart. **A golden path
is where an organisation puts its context work once**, so that every stream-aligned team does not
do it again on its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Two stacks of six layers. On the left, a service on the golden path: only the top layer, the service's own code, belongs to the service's team; the pipeline, deploys, logs and metrics, alerts and upgrades belong to Platform. On the right, a service off the path: all six layers belong to the service's team.\"><text x=\"195\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">On the golden path</text><text x=\"525\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Off the path</text><rect x=\"60\" y=\"50\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"195\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">the service's own code</text><rect x=\"60\" y=\"90\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">build and test pipeline</text><rect x=\"60\" y=\"130\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deploys and rollback</text><rect x=\"60\" y=\"170\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">logs, metrics and a dashboard</text><rect x=\"60\" y=\"210\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">alerts to the owning team</text><rect x=\"60\" y=\"250\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">upgrades of all of the above</text><rect x=\"390\" y=\"50\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">the service's own code</text><rect x=\"390\" y=\"90\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">build and test pipeline</text><rect x=\"390\" y=\"130\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">deploys and rollback</text><rect x=\"390\" y=\"170\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">logs, metrics and a dashboard</text><rect x=\"390\" y=\"210\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">alerts to the owning team</text><rect x=\"390\" y=\"250\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"525\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--ink)\">upgrades of all of the above</text><rect x=\"60\" y=\"306\" width=\"14\" height=\"14\" fill=\"var(--amber)\"></rect><text x=\"82\" y=\"318\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">built and run by the service's team</text><rect x=\"390\" y=\"306\" width=\"14\" height=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"318\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">built and run by Platform</text></svg>", "caption": "Where the ownership line falls. On the path, the service's team owns one layer and Platform owns the rest; off the path, the team owns all six, including the upgrades nobody plans for."}
```

## The path has to stay paved

A template copied once and never touched again is a snapshot. A year later the services built from
it run several versions of the pipeline, and the promise that Platform owns those layers
has quietly become false. **The last layer in the figure is the one that makes a path golden**:
when Platform improves the pipeline or patches the logging library, every service on the path
receives the change as a proposed update, and the team reviews it rather than rebuilding it.

That is also why the template deliberately leaves things out. Every option it carries is an option
Platform has to keep working through every future upgrade. Rafaela's rule was that a feature went
into the template once more than one team had needed it, and stayed out while only one had.

## Leaving part of the path

A path that is all or nothing pushes teams off it entirely the first time one piece does not fit.
Coreto's template lets a team replace one layer and keep the rest: Payments, which has its own
audit requirements for alerts, swaps the alert routing and still takes the pipeline, the deploys
and the upgrades. **A team that leaves one layer owns that layer and nothing else.**

Some work belongs off the path entirely, and that is fine. Data's nightly jobs do not serve
requests, so a health check and request metrics mean nothing to them; forcing them into a web
service template would give them configuration to maintain and no benefit. A path is for the common
case. The uncommon case is where a team's judgement is worth more than a standard.

| | on the path | off the path |
|---|---|---|
| who builds the boring layers | Platform, once | the team, each time |
| who keeps them working through upgrades | Platform | the team |
| who is woken when the pipeline breaks | Platform | the team |
| who decides | the team, by choosing the path | the team, by choosing to leave it |
