---
title: A setting in the code that decides what a buyer sees
version: 1
---

The usual division of labour sounds tidy: product decides what gets built, engineering decides how. It holds for most decisions. Which index a table gets, which queue library a service uses,
how a module is split — nobody outside engineering notices the answer, and nobody should be asked.

Some decisions look exactly like those and are not. They are made in a code review or a
configuration file, by engineers, in engineering words, and they change what a buyer experiences or
what the business risks. **A technical decision is a product decision when its outcome is felt by a
user or carried by the business, whoever types it in.** Made by engineering alone, it is a product
decision taken by people who were not asked to take it and who may not see what it costs.

## The seat hold

Lesson 1 traced Coreto's worst failures to the reservation module, which holds a seat while a buyer
pays. Under an on-sale's load the row locks behind those holds queue, checkout times out and buyers
watch seats vanish. One proposal in the Checkout team's backlog, from Mateus Araújo, was to shorten
the hold: each seat would be locked for less time, fewer locks would pile up at 10:00, and the
database would breathe.

As an engineering change it is one number in a configuration file. As a product change it decides
two things that have nothing to do with databases.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"A horizontal line from a shorter seat hold on the left to a longer one on the right. Under the shorter end: what gets better is fewer seats stuck under a lock when the 10:00 rush peaks; what gets worse is that a buyer still typing a card number loses the seat before paying. Under the longer end: what gets better is that a slow buyer, or one whose bank asks for a confirmation, keeps the seat; what gets worse is seats held by buyers who walked away, so the show looks sold out and then is not.\"><defs><marker id=\"hold16-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">The seat-hold length: one setting in the reservation module</text><path d=\"M64 60 L656 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-start=\"url(#hold16-ah)\" marker-end=\"url(#hold16-ah)\"></path><text x=\"40\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">shorter hold</text><text x=\"680\" y=\"86\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">longer hold</text><rect x=\"20\" y=\"102\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"124\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">gets better</text><text x=\"36\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">fewer seats stuck under a lock</text><text x=\"36\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">when the 10:00 rush peaks</text><rect x=\"20\" y=\"190\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"212\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">gets worse</text><text x=\"36\" y=\"234\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a buyer still typing a card number</text><text x=\"36\" y=\"252\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">loses the seat before paying</text><rect x=\"370\" y=\"102\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"124\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">gets better</text><text x=\"386\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a slow buyer, or one whose bank asks</text><text x=\"386\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">for a confirmation, keeps the seat</text><rect x=\"370\" y=\"190\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"212\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">gets worse</text><text x=\"386\" y=\"234\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">seats held by buyers who walked away:</text><text x=\"386\" y=\"252\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the show looks sold out, then is not</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">every point on the line is technically sound; choosing one decides who loses</text></svg>", "caption": "One setting, two failures. Every point on the line is technically sound; choosing a point decides which buyers lose, and that is not a database question."}
```

**A shorter hold** means fewer seats stuck under a lock when the rush peaks. It also means a buyer
who is still typing a card number, or whose bank asks for an extra confirmation, can lose the seat
before paying — and on a popular show, the seat is gone for good by the time they try again.

**A longer hold** protects that slow buyer. It also means seats sit held by people who opened a
checkout and walked away. The seat map shows the show as sold out, fans give up, and then the seats
come back on sale when the holds expire, to whoever happens to be refreshing at that moment. The
venue sees a sell-out that was not one, followed by a trickle of late sales it did not plan for.

Neither end is wrong in engineering terms. Choosing between them decides **which buyer Coreto
disappoints, and how a venue's on-sale looks from the outside** — and that is a question for Júlia
Sato, the head of product, as much as for Mateus.

## Four more in the same disguise

The seat hold is the clearest case at Coreto, and it is not the only one. Each of these was first
raised as a technical question:

| raised as | what it actually decides |
|---|---|
| how long Catalogue caches seat availability | whether buyers are shown seats that are already gone, and click on them |
| how long buyer data is kept before deletion | what Coreto risks under data-protection law, and whether a buyer can see last year's tickets |
| the availability target for checkout | what Coreto promises venues, and how much engineering time goes to keeping that promise |
| whether Box Office scans tickets with no network | whether a door keeps moving when the venue's Wi-Fi drops, at the risk of one ticket admitted twice |

The **availability cache** is a performance question with a buyer on the other end. Cached longer,
the seat map loads faster and spares the database; cached longer, it also shows seats that sold
moments ago. The buyer who picks one learns it at the payment step, which is the worst place to
learn it.

**Data retention** reads as storage housekeeping. It is a decision about legal exposure on one side
and a feature on the other: a buyer who wants the receipt for a show they saw last year is asking
for data that a short retention period deleted.

The **availability target** was in Davi's first draft in lesson 1 as "reach 99.99%". Whatever the
figure, it is a promise to venues and a claim on engineering's time, because every extra nine costs
work that could have gone into features. `delivery-metrics` lesson 16 covers how error budgets turn
that target into an agreement between product and engineering; the point here is only that the
target is not engineering's to pick alone.

**Offline mode at the door** is the case where the disguise is thinnest. Box Office's app checks
each ticket against the server. When a venue's Wi-Fi fails, the choice is between stopping entry
until it returns and scanning against a copy on the device, which cannot see a ticket already used
at another door. One option builds a queue outside; the other lets a copied ticket in twice. That is
a choice about the venue's evening, and the venue should hear about it before the night it happens.

## Why the disguise works

These decisions slip past product because of how they arrive. They come with a technical
vocabulary — TTL, lock timeout, retention job, SLO, sync strategy — so they land in engineering's
queue. They have a sensible default, so nobody feels a choice is being made. And their cost is paid
later, by somebody else: the buyer at the payment step, the venue at the door, the company in a
legal letter. The next section is about recognising them before that.
