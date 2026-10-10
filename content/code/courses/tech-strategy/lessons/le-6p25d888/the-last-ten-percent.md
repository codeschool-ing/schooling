---
title: The last ten percent
version: 1
---

A strangler migration looks finished long before it is. Coreto's new reservation service carried 90%
of reservation traffic at the end of month 8. **The last 10% took four more months**, a third of the
whole migration spent on a tenth of the traffic.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"A bar chart of the share of reservation traffic served by the new service at the end of each month, from month 0 to month 12: 0, 5, 12, 25, 40, 58, 71, 83, 90, 94, 97, 99 and 100 percent. A dashed line marks 90 percent, reached at month 8. A bracket over months 9 to 12 marks the last 10 percent, which took four months.\"><path d=\"M70 290.0 L690 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"294.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70 232.5 L690 232.5\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"236.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">25%</text><path d=\"M70 175.0 L690 175.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"179.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70 117.5 L690 117.5\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"121.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">75%</text><path d=\"M70 60.0 L690 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"64.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100%</text><text x=\"93.8\" y=\"284.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"93.8\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><rect x=\"126.8\" y=\"278.5\" width=\"29.6\" height=\"11.5\" fill=\"var(--phosphor)\"></rect><text x=\"141.5\" y=\"272.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"141.5\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"174.4\" y=\"262.4\" width=\"29.6\" height=\"27.6\" fill=\"var(--phosphor)\"></rect><text x=\"189.2\" y=\"256.4\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"189.2\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"222.1\" y=\"232.5\" width=\"29.6\" height=\"57.5\" fill=\"var(--phosphor)\"></rect><text x=\"236.9\" y=\"226.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">25</text><text x=\"236.9\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"269.8\" y=\"198.0\" width=\"29.6\" height=\"92.0\" fill=\"var(--phosphor)\"></rect><text x=\"284.6\" y=\"192.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">40</text><text x=\"284.6\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><rect x=\"317.5\" y=\"156.6\" width=\"29.6\" height=\"133.4\" fill=\"var(--phosphor)\"></rect><text x=\"332.3\" y=\"150.6\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">58</text><text x=\"332.3\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><rect x=\"365.2\" y=\"126.7\" width=\"29.6\" height=\"163.3\" fill=\"var(--phosphor)\"></rect><text x=\"380.0\" y=\"120.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">71</text><text x=\"380.0\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"412.9\" y=\"99.1\" width=\"29.6\" height=\"190.9\" fill=\"var(--phosphor)\"></rect><text x=\"427.7\" y=\"93.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">83</text><text x=\"427.7\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><rect x=\"460.6\" y=\"83.0\" width=\"29.6\" height=\"207.0\" fill=\"var(--phosphor)\"></rect><text x=\"475.4\" y=\"77.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">90</text><text x=\"475.4\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><rect x=\"508.3\" y=\"73.8\" width=\"29.6\" height=\"216.2\" fill=\"var(--amber)\"></rect><text x=\"523.1\" y=\"67.8\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">94</text><text x=\"523.1\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><rect x=\"556.0\" y=\"66.9\" width=\"29.6\" height=\"223.1\" fill=\"var(--amber)\"></rect><text x=\"570.8\" y=\"60.9\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">97</text><text x=\"570.8\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><rect x=\"603.7\" y=\"62.3\" width=\"29.6\" height=\"227.7\" fill=\"var(--amber)\"></rect><text x=\"618.5\" y=\"56.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><text x=\"618.5\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><rect x=\"651.4\" y=\"60.0\" width=\"29.6\" height=\"230.0\" fill=\"var(--amber)\"></rect><text x=\"666.2\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">100</text><text x=\"666.2\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"380.0\" y=\"332\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">month of the migration</text><path d=\"M70 83.0 L690 83.0\" stroke=\"var(--paper)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><path d=\"M482.5 44 L482.5 36 L682.8 36 L682.8 44\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"582.7\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the last 10%: four months</text><text x=\"79.5\" y=\"40\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">the first 90%: eight months</text></svg>", "caption": "Share of reservation traffic on the new service, month by month. The curve is steep in the middle and flat at the end: a third of the migration went on a tenth of the traffic."}
```

## The shape of the curve

The first months are slow because the first slices are chosen to be safe, not big: 5% at the end of
month 1, 12% at month 2. The middle is steep. Once the seam works and a few weekends have gone cleanly,
moving an event is a row in a table, and the share climbs from 25% at month 3 to 83% at month 7. Then
it flattens: 90, 94, 97, 99, and 100 only at month 12.

Lesson 1 gave the team its first two quarters on the hold path, starting with the row locks. At the end of month 6 the new service, which
holds seats without them, carried 71% of reservation traffic, and the other 29% still went through
the locks. A plan written as "two quarters" was reasonable for the bulk of the traffic and had nothing
to say about the end.

## What lives in the tail

The last 10% was not more of the same events. It was the paths nobody had listed when the migration
was planned, each of them small in traffic and large in work:

- holds the Box Office staff place by hand at the door, for a buyer standing at the counter;
- group bookings for schools, which hold a block of seats for days instead of minutes;
- festival passes that hold one seat across several days at once;
- a partner integration that reads the old hold tables directly, under a contract nobody at Coreto
  could change on their own;
- the two reports that the seam work in month 1 had found, still reading the old tables.

**Each one is rare, each one needs its own work, and most of them belong to somebody other than the
team doing the migration.** Group bookings needed a new kind of hold in the service. The partner
integration needed a conversation with the partner. None of them moved the chart by more than a
point or two, which made each one easy to postpone.

## Stopping at ninety

The trap is to stop. At 90%, the urgent problem looks solved: the big on-sales run on the new service,
the incident rate has fallen, the team that did the work is wanted elsewhere. What is left is a tail of
awkward paths and a migration that everybody considers done.

**It is the most expensive place to stop.** Coreto would be running both seat-hold systems
indefinitely: the facade, two stores, the publishing path into the old tables, the nightly
reconciliation, and the old row-lock code still live for the last few paths. Every engineer who
touches seat holds would need to know which side a case lands on. And the seat-hold debt from lesson 5
would not be paid off. Its interest would shrink with the traffic and never reach zero, because the
tax on changes is paid whenever someone has to understand the old path, however few requests still
use it.

## Deleting the old code is the finish line

**The measure of a strangler migration is how much of the old code is gone.** Share of traffic is the
measure people watch, because it moves every month and it goes on a slide, and it reports 90% for a
system that still runs twice. Coreto's migration finished when the seat-hold code, the lock tables,
the publishing path and the reconciliation job were deleted from `coreto-core`, after month 12 had
taken the share to 100%.

Three habits make the end happen instead of hoping for it:

- list the tail early: at around half the traffic, write down every remaining caller of the old
  path, with an owner for each. The paths in the tail are found by looking, and looking is cheap
  while the team is still on the work;
- put a date on deleting the old code, and treat a missed date the way a missed delivery is treated,
  with a reason and a new date;
- report two numbers instead of one: the share of traffic, and the parts of the old system still in
  use. The second only falls when something is deleted.

The strangler pattern's whole promise was that production keeps running while the system changes
under it. It keeps that promise all the way through, and it asks for one thing in return: that
somebody finishes it.
