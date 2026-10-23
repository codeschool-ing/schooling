---
title: Intercepting a system that has no front door
version: 1
---

Most writing about the strangler fig assumes a web application: requests arrive over HTTP, a proxy
sits in front, and moving a capability is a change to a routing rule. **Enterprise legacy rarely
has that front door.** Its work arrives as files dropped in a folder, rows typed into terminal
screens and batch jobs started by a scheduler at two in the morning, and it answers by writing
more files. There is no single place where every request passes, so there is no single place to
put a facade.

The strangler still works. What changes is where you stand to intercept, and there are four
techniques for it. Three of them get you into the flow of a system you cannot change much, and the
fourth is for the code you own on the other side of it.

## What goes in and out of Coleta

Before choosing a technique, Joana drew every flow that crosses Coleta's boundary, with its
volume, because the technique depends on the shape of each flow.

- Collections from the trucks. Each driver carries a handheld that records, at every farm, the
  litres pumped, the tank temperature and the code of the sample tube. When the truck is back at
  the plant the handheld is docked, and a PC beside the dock sends the route's file to a folder on
  the IBM i. About 130 route files arrive a day across the four plants.
- Results from the laboratory. An accredited external laboratory analyses the sample tubes and
  sends one results file every working day: fat, protein, somatic cell count and bacterial count
  for each sample. A Coleta program loads it at 22:00.
- The clerks' screens. Six people in the milk payment office use green-screen terminals to
  register farms, correct a collection the handheld got wrong, suspend a farm for quality and
  release it again.
- The nightly file to SAP, about 1,900 lines, which an ABAP program loads at 02:00 to create one
  goods receipt per farm collected (lesson 1 follows that document; lesson 9 shows how a file like
  it is made safe).
- The monthly payment. Each month Coleta computes what every farm is owed and sends the amounts
  to SAP, where the farms are vendors and finance pays them on the 10th.
- The two bus flows from the previous section: farm lookup for Rota, and the collection summary
  for the quality dashboard.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l13-intercept\" aria-label=\"Coleta, on the IBM i, in the middle, with every flow that crosses its boundary. On the left, the inputs: route files from the trucks' handhelds now pass through a new intake service, which keeps a copy and forwards the file; the laboratory's results file passes through the new quality service in the same way; the clerks' green screens write straight into Coleta, with nothing in between. Above, the two bus flows, farm lookup for Rota and the collection summary, already act as a facade. On the right, the outputs: the nightly file to SAP and the monthly payment amounts to SAP. Below, Coleta's journal feeds change data capture, which sends the changes the clerks make to the new side. Each path is labelled with the technique that reaches it.\"><defs><marker id=\"l13-intercept-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-intercept-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-intercept-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"325.0\" y=\"150.0\" width=\"150.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><text x=\"400.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IBM i, RPG</text><rect x=\"10.0\" y=\"93.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handheld route files</text><rect x=\"155.0\" y=\"93.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">intake service</text><path d=\"M130.0 110.0 L153.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><path d=\"M275.0 110.0 L323.0 165.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"215.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">event interception</text><rect x=\"10.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">laboratory results</text><rect x=\"155.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quality service</text><path d=\"M130.0 190.0 L153.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><path d=\"M275.0 190.0 L323.0 205.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"215.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">event interception</text><rect x=\"10.0\" y=\"273.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">clerks' screens</text><path d=\"M130.0 290.0 L323.0 245.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-amber)\"></path><text x=\"215.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">nothing to intercept</text><rect x=\"275.0\" y=\"33.0\" width=\"250.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">bus flows: farm lookup, collection summary</text><path d=\"M400.0 67.0 L400.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"408.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">a facade already there</text><rect x=\"530.0\" y=\"148.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nightly file to SAP</text><path d=\"M477.0 165.0 L528.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"228.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">payment amounts to SAP</text><path d=\"M477.0 245.0 L528.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><text x=\"615.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">output contracts kept as they are</text><rect x=\"340.0\" y=\"320.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">journal</text><path d=\"M400.0 262.0 L400.0 318.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-paper-dim)\"></path><rect x=\"575.0\" y=\"320.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new side</text><path d=\"M462.0 335.0 L573.0 335.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-intercept-es-ah-phosphor)\"></path><text x=\"517.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">change data capture</text></svg>", "caption": "Coleta has no front door, so each flow is reached where it can be: files in their path, the bus flows at the bus, and the clerks' typing only afterwards, from the journal."}
```

## Event interception: stand in the path of what flows in

Where work arrives as a message or a file, you can put the new system in its path. Fowler calls
this event interception, and the idea is simple: **the new system receives the input first, keeps
what it needs, and passes it on to the legacy unchanged.** The legacy does not know anything
happened. The new system now has a complete, live copy of that input without touching a line of
the old code.

The handheld files are the clearest case at Serra Alta. Today the docking PC writes to a folder on
the IBM i. After the change it sends the same file to an intake service, which stores it, records
it, and writes it on to the same folder on the IBM i, byte for byte. Coleta loads it as before. The
new collection service has every route file from that day on, and nothing about Coleta changed.

Interception is only safe if the forwarding is as reliable as the original path was. A file that
the intake service received but failed to forward is a farm that is not paid for that day, and a
file forwarded twice is a farm paid twice unless Coleta refuses duplicates. Lesson 10 covers the
machinery for this, delivery guarantees and idempotent consumers; here it is enough that the
intercepting component needs the same care as the system it stands in front of.

**Interception changes direction during the migration.** At first the new system copies and the
legacy decides. Later, when the new collection service becomes the owner of collections, the
intake service stops forwarding the raw file and instead sends Coleta a translated version of what
the new service has accepted, so that the parts of Coleta that have not moved yet still see the
collections they need. The physical path is the same; who is in charge is the opposite.

## Change data capture: read what the legacy wrote

The clerks' screens cannot be intercepted that way. A clerk types into a terminal session on the
IBM i, and the change exists nowhere until Coleta writes it to its own tables. The only place to
pick it up is afterwards, in the database.

**Change data capture reads the database's own record of changes and turns each one into an event
that another system can consume.** Lesson 9 introduced it as the safer alternative to reading
somebody else's tables. On IBM i the database records changes to a table in a journal, which
exists for recovery and auditing, and replication products read those journals and publish the
changes elsewhere. Coleta's tables are already journalled, because Sebastião's backup procedure
depends on it, so the raw material is there.

CDC has two limits that matter for a strangler. It gives you rows, not intentions: the journal says
that farm 041327's status changed from `A` to `S` at 14:02, and nothing about why, so the new side
has to infer that a clerk suspended the farm for quality, and must know what `S` means. That
inference is the anti-corruption layer's job, in the next section. And it runs in one direction
only, from the legacy outwards. It keeps a copy in step with Coleta; it does not let anything else
change Coleta.

## Asset capture: move one kind of thing at a time

Interception and CDC get data out. The decision about what to move first is a different one, and
Fowler's name for the usual answer is asset capture: **choose one type of entity and move its
ownership to the new system completely, before touching the next.** Not "some of the farms" and
not "the farms' history", but one kind of thing: lab results, or collections, or the farm register.

Joana's first asset was the laboratory results, for four reasons she wrote into the plan.

1. They arrive from outside as one file a day, which is the easiest flow to intercept.
2. Nobody edits them in Coleta's screens. A result is what the laboratory measured, so there is no
   second source of changes to synchronise back.
3. Coleta uses them in only one place, the monthly payment calculation, so a translated copy fed
   back to Coleta keeps it working.
4. The quality team wants them sooner. Today a result that arrives at noon reaches Cláudia's team
   the next morning, after the 22:00 load; a farm with a bad count keeps delivering milk for a day
   nobody needed to lose.

The fourth reason is why the first slice pays for itself. The new quality service will show each
result within minutes of the file arriving, and that will be the first thing the migration gives
anybody outside IT.

## Branch by abstraction: for the code you do own

Some of Coleta's dependents are Serra Alta's own code. Rota is a Kotlin application with a team of
five, and its route planner calls farm lookup through a class that knows it is talking to the bus.
Moving farm lookup could be done entirely in the bus, but Rota's team also wants to use fields the
new service has and Coleta never had, such as the farm's GPS position.

For that, the technique is branch by abstraction, which Paul Hammant described in 2007. **Inside a
codebase you control, put an interface in front of the thing being replaced, move every caller to
the interface, build the new implementation behind it, switch over, and delete the old one** — all
on the main branch, with the code releasable at every step. Rota gets a `FarmDirectory` interface
with two implementations, one calling the bus and one calling the new service, and a configuration
flag that chooses between them. The team can switch, compare and switch back without a long-lived
branch.

Branch by abstraction is the same idea as the facade, moved inside one program. It does not work
inside Coleta itself, because changing Coleta is exactly what the migration is trying to keep to a
minimum, and the one person who changes it safely is the one who is leaving.

## What none of these reach

The screens are the one thing no technique moves on its own. **When a capability whose input is
typed by people moves, the people move with it.** The six clerks will register farms in the new
system on a given Monday, and from that day the Coleta screen for it must refuse changes, or two
places will accept them. That is a training plan and a date as much as a technical step, and it
belongs to coexistence, the section after next.
