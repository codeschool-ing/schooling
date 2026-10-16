---
title: Why documentation rots, and what keeps it true
version: 1
---

**Documentation decays because the system changes and the page does not, and a stale page does more
harm than a missing one, because it is believed.** What keeps documentation true is not effort but
arrangement: fewer pages, each with an owner and a date, updated by the changes that make it wrong,
and deleted when nobody will keep it.

The tempting conclusion from a wiki full of stale pages is that the team needs to be more
disciplined, and a documentation sprint follows. It produces a few hundred accurate pages on the day
it ends, and the same decay starts the next morning, because nothing about the arrangement changed.

## The stale page that is believed

In September, Ícaro was asked for a report of payouts per carrier. He found the wiki page "Payments
architecture", which was clear, well drawn, and said that the payout job reads delivery status from
the monolith's `deliveries` table. He wrote his queries against that table.

The page had been true when it was written in March 2023. In 2024 Tracking moved into its own
service with its own database, and the `deliveries` table stopped receiving new deliveries for most
carriers. **Ícaro's report showed several large carriers with no deliveries at all**, and he spent six
working days looking for the bug in his queries before Bruno, reviewing the report, recognised the
table.

Nothing about this was Ícaro's fault, and that is the lesson. If the page had not existed, he would
have asked Bruno on the first morning, and the answer would have taken five minutes. **A missing
document produces a question; a wrong one produces confidence.** The page did not fail to help him;
it actively sent him the wrong way, with a diagram that looked authoritative and nothing on it to say
it was three years old.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A two by two grid. Columns: accurate, out of date. Rows: trusted, doubted. Accurate and trusted is what documentation is for, kept true by its owner. Out of date and trusted is highlighted as the damage, Ícaro&#x27;s six days, reached with nobody acting. Accurate and doubted is wasted: it is true, but people ask anyway. Out of date and doubted is harmless if marked with a date, a banner or an archive. A dashed arrow labelled time moves a page from accurate to out of date; arrows out of the damaged corner are labelled update, back to accurate, and mark or delete, down to doubted.\"><defs><marker id=\"l8quad-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"280\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">accurate</text><text x=\"590\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">out of date</text><text x=\"140\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">trusted</text><text x=\"140\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">doubted</text><rect x=\"150\" y=\"50\" width=\"260\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what documentation is for</text><text x=\"280.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">kept true by its owner</text><rect x=\"470\" y=\"50\" width=\"240\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"590.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the damage: Ícaro&#x27;s six days</text><text x=\"590.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">reached with nobody acting</text><rect x=\"150\" y=\"230\" width=\"260\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">wasted: it is true,</text><text x=\"280.0\" y=\"289.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">but people ask anyway</text><rect x=\"470\" y=\"230\" width=\"240\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">harmless, if marked:</text><text x=\"590.0\" y=\"289.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a date, a banner, an archive</text><path d=\"M412 132 L466 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"440\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><path d=\"M468 82 L414 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"440\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">update</text><path d=\"M590 172 L590 226\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l8quad-ah)\"></path><text x=\"580\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mark or delete</text></svg>", "caption": "A page has two properties: whether it is accurate, and whether readers trust it. Time moves a trusted page into the costly corner with nobody touching it; the ways out are updating it, or marking it so that nobody trusts it by mistake."}
```

The corner that costs is the top-right one: wrong and trusted. A page moves into it without anybody
doing anything, simply by the system changing around it. The ways out are the two arrows: make it
true again, or make it impossible to trust by mistake — a date on it, a banner, or its deletion.

## Why documentation rots

Five causes account for most of it, and each one has a fix that is about arrangement rather than
willpower.

- **It was written once, as a deliverable.** A project ends with "write the documentation", the pages
  are written in the last week, and nobody is assigned to them after the project closes.
- **It lives away from the change.** The previous section's wiki: nothing in a developer's day passes
  through it.
- **Nobody owns it.** "The team" or "everyone" owns the page, which means that when it is wrong, it is
  nobody's job to notice.
- **It is too detailed.** A page listing every endpoint of Payments is wrong after every new endpoint.
  A page saying that Payments owns payouts and Tracking owns delivery proof changes about once a year.
  **Write at the level that changes slowly, and generate the rest** — an API reference from the OpenAPI
  file, a code-level diagram from the code.
- **It carries no date.** A reader cannot tell a page from 2023 from one written last week, so they
  trust both equally.

## What keeps it alive

Renata's rules for Carreto fit on an index card, and each one answers one of the causes above.

**Every page has an owner and a date.** The owner is a team with a named person, written at the top.
The date is when the page was last checked against the system, not merely edited, and the page says
how often it should be checked: six months for a container diagram, a year for a README. A small job
in the pipeline lists every page past its date and puts a banner on its published copy saying so. The
banner does not make the page right; it stops it being trusted by mistake.

**Changes trigger updates.** The pull request template from the previous section is one trigger.
The architecture forum, which lesson 10 describes, walks through the container diagram once a quarter
and asks each team whether its part is still true. Onboarding is the third: every new engineer fixes
the pages that misled them in their first month, while they still remember which ones did. Ícaro's
first pull request after the report rewrote the Payments page, with a date and an owner on it, which
turned six lost days into the fix.

**What can be checked is checked.** A diagram that claims Payments does not call Matching is a
statement a program can test against the code, and lesson 9 shows the program. A claim held by a test
cannot go stale silently.

**Fewer pages.** Every page is a promise to keep something true, and the promises have to be paid in
someone's time. The cheapest page to maintain is the one that was never written because the code or a
generated reference already answered the question.

## Records and descriptions

Two kinds of document look alike and must be treated in opposite ways.

**A record is true as of a date, and is never updated.** An ADR, a postmortem, the minutes of the
meeting where the harvest deadline was agreed. Its value is that it says what was known and decided
then. When the decision changes, a new record supersedes the old one, as lesson 5 described for ADRs;
editing the old one to match today would destroy exactly what made it worth keeping.

**A description claims to be true now, and must be kept that way.** The container diagram, a README,
a runbook, lesson 7's requirements page. A description that is not maintained is not a historical
record; it is simply wrong.

**The mistake is to treat one as the other.** Rewriting an ADR to match today's system erases why the
system was built as it was. Leaving a description untouched for three years, as if it were a record,
produced Ícaro's six days. Carreto marks each document with its kind at the top, so a reader knows
whether "March 2023" means "this is history" or "this may be out of date".

## Deleting

**Deleting a page is maintenance.** A page that is wrong and has no owner willing to fix it should go,
or be archived with a banner that points to whatever replaced it. Most teams never delete anything,
because deleting feels like losing information, when the information was lost the day the page stopped
being true.

Renata ran one sweep of the 640-page wiki. The 230 pages edited in the last two years stayed. Each team
went through the other 410 that touched its area and chose one of two things for each: fix it and give
it an owner and a date, or archive it. Any page that was really a record of a decision was copied into
the repository first. They fixed 90 and archived 320. Half the wiki, by page count, went in one month, and nobody has asked for an archived page
back yet. **A wiki of 320 pages that are true is far more useful than one of 640 where a reader cannot
tell which are.**

`architecture-modeling` lesson 11 goes further into where living documentation should sit and how
long it lives.
