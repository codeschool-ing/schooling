---
title: What "cut 10%" means
version: 1
---

While next year's budget is being drawn up, Otávio asks every department for the same thing: 10%
less than this year. Helena
passes the request to Davi with one line — "where would it come from?" — and the first answer in
the room is the one most engineering organisations give. **Trim the cloud, review the licences,
find some efficiency.** It sounds responsible, and the sheet from the last section shows that it
cannot add up.

## The size of the ask

On the same sheet, three formulas in empty cells. The cut itself:

```localised
=SUM(B2:B5)*10%      1738400
```

The cut in engineers, dividing by the R$ 264,000 an engineer costs a year:

```localised
=ROUND(SUM(B2:B5)*10%/264000,1)      6.6
```

And the cut as a share of the cloud line, B3:

```localised
=ROUND(SUM(B2:B5)*10%/B3*100,0)      68
```

**A 10% cut is R$ 1,738,400, which is 6.6 engineers, or 68% of the cloud bill.** Nobody is going to
remove two thirds of Coreto's cloud in a year while ticket sales grow; the largest single saving
lesson 12 finds, staging environments left running overnight, is R$ 117,600 a year. Take the comparison one step
further: everything that is not people adds up to R$ 3,656,000 (the total minus the people line),
so a cut taken entirely from those three lines would remove 47.5% of them. Zeroing the tooling line
alone, R$ 380,000, covers 21.9% of the ask.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l11-cut\" aria-label=\"Two bars on the same scale. The top bar is everything in Coreto's budget that is not people, R$ 3,656,000: cloud R$ 2,544,000, licences and SaaS R$ 732,000, tooling R$ 380,000. The bottom bar is the 10% cut, R$ 1,738,400, almost half the length of the top bar.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Everything that is not people: R$ 3,656,000</text><rect x=\"20.0\" y=\"32.0\" width=\"473.2\" height=\"44.0\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"493.2\" y=\"32.0\" width=\"136.1\" height=\"44.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"629.3\" y=\"32.0\" width=\"70.7\" height=\"44.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"256.6\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Cloud</text><text x=\"256.6\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--ink)\">R$ 2,544,000</text><text x=\"561.2\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Licences</text><text x=\"561.2\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">R$ 732,000</text><text x=\"664.7\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tooling</text><text x=\"664.7\" y=\"67.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">R$ 380,000</text><text x=\"20.0\" y=\"106.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">The 10% cut: R$ 1,738,400</text><rect x=\"20.0\" y=\"116.0\" width=\"323.3\" height=\"44.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"181.7\" y=\"143.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">47.5% of the bar above</text></svg>", "caption": "A 10% cut of the whole budget, measured against the three lines that are not people. Taken from them alone, it would remove almost half of everything Coreto spends outside its payroll."}
```

## A cut is a decision about people

With people at 79.0% of the budget, **most of any real cut lands on the people line**, whatever the
first meeting says. It lands in one of three ways: open roles that are not filled, people who leave
and are not replaced, or redundancies. Each one is a decision about who does the work next year,
and calling it "efficiency" does not change which one it is.

Saying that plainly matters for two reasons. Otávio needs to know what he is buying: a 10% cut that
is really six or seven fewer engineers is a different decision from a 10% cut in waste, and he
should take it knowingly. And the team needs to hear it from Davi before they work it out from an
empty desk.

**The cuts that look free come back as hours.** Cancelling a licence moves its cost to the people
line, as the last section showed. Delaying an upgrade moves it to next year, with interest of the
kind lesson 5 measured. A cut that shows up as a smaller invoice and a busier team has saved less
than the invoice says, and sometimes nothing.

## Timing halves it

A budget is for a year, and a cut decided in the middle of one only saves the months left. A
hiring freeze that starts in July saves half a year of each role it leaves empty, so reaching 6.6
engineer-years that way means 13.2 roles frozen for six months (6.6 × 2). The arithmetic is simple
and it is regularly missed, which is how a "10% cut" agreed in a meeting becomes a 5% cut on the
books and a second round of cuts in the new year.

## Turning the number into options

Davi does not answer "where would it come from?" with a single plan, and he does not refuse. He
writes the request as options, each with what it stops and who would notice:

| option | where the R$ 1,738,400 comes from | what stops | who notices |
|---|---|---|---|
| A | 6.6 engineer-years, from roles not filled | the work the strategy already postponed: the microservices migration and the front-end framework move from "next year" to "not planned" | the teams who were waiting for them |
| B | cloud and licence savings first, the rest from people | the same as A, smaller; plus an engineer on cost work for a quarter | Platform, and finance when the savings land late |
| C | a smaller cut, with the risk of the full one written beside it | nothing on the on-sale path | Otávio, who has to find the difference elsewhere |

**The strategy is what makes this table possible.** Lesson 1's guiding policy, "protect the on-sale
first", says where the cut may not land: the Reservations team and the load test stay. Lesson 3's
list of things Coreto will not do says where it can land with the least damage, because that work
was already waiting. A team with no strategy meets a budget cut by cutting a little everywhere,
which spreads the damage across every priority at once.

The options go to Helena and Otávio as a choice with consequences, which is a different
conversation from a negotiation over a percentage. Architect-communication lesson 13 covers that
negotiation; lesson 19 of this course covers the shape of a refusal, for the day the right answer
is no. The other direction comes first: the next section is how Davi asks for money.
