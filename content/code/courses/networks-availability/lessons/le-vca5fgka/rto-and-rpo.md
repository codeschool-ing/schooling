---
title: RTO and RPO, forwards and backwards from the incident
version: 1
---

Availability describes a month. Two other numbers describe one bad day, and they are the ones a plan for
that day is written around. **RTO**, the recovery time objective, is how long the service may be down
after an incident. **RPO**, the recovery point objective, is how much data may be lost, measured as
time: how far before the incident the restored data is allowed to end.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 208\" role=\"img\" aria-label=\"A time axis. A dot marks the last good copy of the data; later a line marks the incident; later still a line marks the service coming back. Between the last good copy and the incident, a bracket reads: RPO, writes made here are lost. Between the incident and the service coming back, a bracket reads: RTO, the service is down, divided into notice, decide and restore.\"><defs><marker id=\"rr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 110 L700 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rr-ah)\"></path><text x=\"700\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><circle cx=\"150\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"150\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">last good copy</text><path d=\"M380 40 L380 118\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the incident</text><path d=\"M610 40 L610 118\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"610\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">service back</text><path d=\"M150 76 L150 70 L380 70 L380 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"265.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RPO: writes made here are lost</text><path d=\"M380 146 L380 152 L610 152 L610 146\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"495.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">RTO: the service is down</text><text x=\"418.3333333333333\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">notice</text><text x=\"495.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decide</text><text x=\"571.6666666666666\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restore</text><path d=\"M456.6666666666667 182 L456.6666666666667 198\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M533.3333333333334 182 L533.3333333333334 198\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "RPO looks backwards from the incident and RTO forwards. How often the data is copied sets the first; how fast the failure is noticed and the service moved sets the second."}
```

The common mistake with RTO is to read it as the time to fix what broke. **RTO is the time to restore the
service, which is often somewhere else entirely.** When `lb1`'s HAProxy died in lesson 16, the service was
back in 2.694 seconds, on `lb2`, while `lb1` stayed broken for as long as nobody restarted it. The repair
and the recovery are separate clocks, and only the second one is in the promise.

The common mistake with RPO is to forget it applies at all. A system that holds no data has an RPO of
zero for free, and that is why the failovers measured so far looked so clean. Anything that stores what
users do has to answer the question explicitly, and the answer is set by how often the data is copied
somewhere else, which is the last section of this lesson.

## The two numbers for the systems in this course

| system and failure | RTO | RPO |
|---|---|---|
| office gateway, router's cable pulled (lesson 15) | 3.264 s measured | nothing to lose: a router holds no data |
| balancer, HAProxy killed (lesson 16) | 2.694 s measured | connections in progress through `lb1` were lost |
| a database with a nightly backup, restored by hand | hours: fetch, restore, check | up to 24 hours of writes |
| a database with a synchronous replica, promoted automatically | seconds to minutes | nothing committed is lost |

The second row shows that an RPO is not only about databases. Whatever lived in the memory
of the failed machine, a half-finished download or a session kept in RAM, is gone, and lesson 16 ended on
what it takes to keep that kind of state somewhere that survives.

**An RTO and an RPO belong to a failure, not to a system.** The same database has one pair of answers for
a disk that dies, another for a data centre that floods, and another for a person who deletes a table by
mistake. Replication handles the first two, if the copy lives in another place, and does nothing for the third, since it copies the
deletion as faithfully as it copies everything else. A plan that lists one RTO and one RPO for "the
database" has answered one of those three questions and assumed the others.
