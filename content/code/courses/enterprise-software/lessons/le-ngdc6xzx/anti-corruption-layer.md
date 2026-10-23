---
title: The anti-corruption layer
version: 1
---

The moment the new quality service receives its first copy of a laboratory file, it has a choice
to make about words. Coleta calls a farm `0413275`, writes the date as `1261023` and stores 1,234.5
litres as `123450`. The new service can take those as they come, or it can say what they mean in
its own terms and translate at the border. **The anti-corruption layer is the decision to
translate, made once and kept in one place, so that the new system is not built in the shape of
the old one.**

Eric Evans named it in *Domain-Driven Design* (2003), in the part of the book about how separate
models relate to each other. His description is still the clearest: an isolating layer that gives
the new system the old system's functionality in the new system's own terms, talks to the old
system through the interfaces it already has, and translates in both directions. Evans also says
what it is usually built from: facades that simplify the old interface, adapters that fit one
protocol to another, and translators that turn one model's objects into the other's.

## Why the easy path corrupts

The common idea, and the one a deadline encourages, is that the new system should simply adopt the
legacy's codes and formats. Everybody at Serra Alta knows the farm codes, every report uses them,
and keeping them means no translation to write. It feels like reducing risk.

It does the opposite over time. A new system that stores Coleta's farm code as its key, takes dates
in Coleta's format and thinks a collection belongs to the day the truck left the plant has
**copied Coleta's model into a codebase that is meant to outlive Coleta by twenty years.** Every
new feature will be designed around those choices, and when Coleta is switched off they remain,
now with nobody left who remembers why. The legacy has been migrated in name and kept in shape.

Some of what has to be translated is format, which is easy. Some of it is meaning, which is not.

| concept | in Coleta | in the new model |
|---|---|---|
| a farm's identity | `0413275`: six digits and a check digit computed modulo 11 | an opaque identifier; the Coleta code is kept as an external reference |
| a date | `1261023`: the IBM i `CYYMMDD` form, where the leading 1 means the 2000s | an ISO date, `2026-10-23` |
| a volume of milk | `123450`: a whole number of hundredths of a litre | litres as a decimal, `1234.50` |
| somatic cell count | `350`: thousands of cells per millilitre | cells per millilitre, `350000` |
| the day of a collection | the date the route left the plant | the moment the milk was pumped, and the route it was on |
| a suspended farm | status `S` | two different facts: suspended for quality, or a document missing |

The first four rows are arithmetic. The last two are where the models disagree. Coleta dates every
collection on a route by the route's departure, so milk pumped at 00:40 on the 1st by a truck that
left at 22:00 on the 31st belongs to the previous month. The new collection service records when
the milk was pumped, because that is what the quality rules and the laboratory need. And `S` has
meant two things since 2014, when farms with an expired document needed a status and Coleta had no
spare letter. The only way to tell the two apart is a free-text remark field, which the clerks fill
in by habit, mostly the same way.

## What the layer does, in both directions

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-acl\" aria-label=\"Three columns. On the left, the new context: the collection service and the quality service, which speak the new model. In the middle, the anti-corruption layer, owned by the new team, with an inbound translator and an outbound translator. On the right, Coleta, with its journal and its 22:00 laboratory loader. Inbound, journal rows travel by change data capture to the inbound translator, which turns 0413275 into a farm with an opaque id, 1261023 into 2026-10-23, 123450 into 1234.50 litres, and status S plus a remark into either suspended for quality or document pending, before they reach the new services. Outbound, laboratory results owned by the quality service go to the outbound translator, which writes them as a file in the laboratory's old layout, in thousands of cells per millilitre, for Coleta's loader. Anything the layer cannot classify goes to a queue for a person.\"><defs><marker id=\"l13-acl-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-acl-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"100.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">new context</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">anti-corruption layer</text><text x=\"625.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><rect x=\"230.0\" y=\"36.0\" width=\"260.0\" height=\"262.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"20.0\" y=\"75.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">collection service</text><rect x=\"20.0\" y=\"205.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quality service</text><rect x=\"550.0\" y=\"75.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">journal</text><rect x=\"550.0\" y=\"205.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">22:00 lab loader</text><rect x=\"242.0\" y=\"49.0\" width=\"236.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">inbound translator</text><text x=\"252.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0413275</text><text x=\"338.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">farm, opaque id</text><text x=\"252.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1261023</text><text x=\"338.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2026-10-23</text><text x=\"252.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">123450</text><text x=\"338.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1234.50 litres</text><text x=\"252.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">S + remark</text><text x=\"338.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→</text><text x=\"354.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quality or document</text><path d=\"M550.0 95.0 L480.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-amber)\"></path><text x=\"515.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CDC</text><path d=\"M242.0 95.0 L182.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><rect x=\"260.0\" y=\"200.0\" width=\"200.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">outbound translator</text><text x=\"360.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cells per mL ÷ 1000, old layout</text><path d=\"M182.0 225.0 L258.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><path d=\"M462.0 225.0 L548.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-phosphor)\"></path><text x=\"520.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lab file</text><rect x=\"275.0\" y=\"154.0\" width=\"170.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"360.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">queue for a person</text><path d=\"M360.0 141.0 L360.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-acl-es-ah-amber)\"></path><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the legacy's formats appear here and nowhere else</text></svg>", "caption": "The layer belongs to the new side and translates in both directions: what Coleta knows becomes the new model's facts, and what the new side owns is written back in Coleta's own forms."}
```

The figure shows the two directions the layer works in at Serra Alta. Inbound, it takes what
Coleta knows (the journal rows CDC publishes, the replies of the bus flows) and turns them into the
new model's concepts. A row whose status changed to `S` with a remark mentioning a document becomes
"document pending" for that farm; the same change with any other remark becomes "suspended for
quality". Outbound, it takes what the new system owns and writes it in the form Coleta expects. The
new quality service is the owner of laboratory results, and every evening the layer writes them
as a file in the laboratory's old layout, in thousands of cells per millilitre, for Coleta's 22:00
program to load. The payment calculation still running in Coleta finds them exactly where it
always did.

**The layer belongs to the new system's team and lives on the new system's side.** Coleta is not
asked to change, which is the point: its owner is leaving and every change to it is a risk. The
new side pays for the translation because the new side is the one that wants to stay clean.

## Four rules that keep it honest

**It is the only place the legacy's words appear.** If `CYYMMDD` or the status letters show up in
the collection service's own code, the layer has leaked. Joana's team enforces this the cheap way:
the legacy's formats are parsed in one module, and a test fails if anything outside that module
refers to them.

**Every rule is a test written with real values.** The modulo-11 check, the date in the 1900s and
in the 2000s, the route that crosses midnight at the end of a month, the `S` with each kind of
remark: each is a test whose input was copied from Coleta. These tests are the most valuable
documentation of Coleta that will ever exist, because they are the rules stated in a form that
fails when it stops being true.

**It refuses what it does not understand.** A farm code whose check digit does not match, a status
letter nobody has seen, a remark the rule cannot classify: the layer puts the record in a queue for
a person to look at and says so, instead of guessing. A layer that guessed would put a wrong fact
into the new system with a clean format, which is worse than a visible error.

**It is temporary, and parts of it are not.** When Coleta goes, the code that reads its journals
and writes its tables goes too. The Coleta farm code survives as an attribute of the farm, because
farmers quote it on the phone and thirty years of paper records carry it, but it is an attribute
and never a key.

## Sebastião and the tests

The translation rules come from one source in the end. The manual is old, the clerks know what they
see on the screen, and Sebastião knows what the code does and why. **The anti-corruption layer is
where his knowledge is turned into something that does not retire.** Joana's plan gives him one
afternoon a week with the team for the rest of his time at Serra Alta, and the output of each
afternoon is a set of tests: a rule he explains, written down as an input and the answer Coleta
gives.

It was in one of those afternoons that the month boundary came up. Nobody on the new team had
thought about a route that leaves before midnight on the last day of a month. Sebastião had
written the rule in 1997, after a farmer complained, and it was in no document. The test went in
that day. Whether the new system should follow Coleta's rule or its own is a business decision,
and the next section shows decisions of that kind being made with numbers in front of the people
who make them.
