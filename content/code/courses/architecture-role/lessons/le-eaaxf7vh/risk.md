---
title: Risk as likelihood times impact
version: 1
---

A risk is something that has not happened yet and might. Once it happens it is an **issue**, and an
issue is handled rather than assessed. The common picture of risk management is a slide near the
end of a proposal titled "Risks", with three bullets nobody reads again. **A risk is worth writing
down only when it carries a likelihood, an impact, an owner and a response**, and the response is
the part that changes anything.

## Where the risks come from

The previous section left Renata with a question she had asked of every row: "What would make this
take nine weeks?" Each answer is a risk in its first form. Bruno's team said the bank's sandbox
might not behave like its production system; that Tracking might not keep enough evidence at
delivery to trust an instant payment; that Bruno is the only person who understands the
reconciliation code.

That is a start, and it has a blind spot: it only finds what one team already worries about.
**Risk-storming**, a technique Simon Brown describes, widens the room. Everybody involved looks at
the same architecture diagram — a container diagram is enough, and lesson 8 introduced it — and for
ten minutes each person writes risks on sticky notes **alone**, without discussion. Then the notes
go onto the diagram, next to the box or the arrow they are about, and the group talks about the
clusters.

The two rules carry the technique. Writing alone stops the most senior voice from deciding what
everybody else noticed. Sticking notes on the diagram puts the risks where they live: on the parts
and, as lesson 1 argued, just as often on the connections between them. Renata ran one session
with people from Payments, Tracking, the Driver app and Platform. Thirty-one notes went up. Many said
the same thing in different words, and they collapsed into **five risks**, three of which nobody in
Payments had mentioned. Most of the notes sat on one arrow: the call from Payments to the bank.

## Likelihood times impact

Each risk gets two ratings. **Likelihood** is how probable it is within the period you care about.
**Impact** is how bad it is if it happens. The simplest version rates both on a scale of 1 to 5
and multiplies them into a score from 1 to 25, which gives the list an order.

| id | risk | likelihood | impact | score | owner |
|---|---|---|---|---|---|
| R1 | a fake proof of delivery is paid out before anybody notices | 2 | 5 | 10 | Bruno |
| R2 | the bank's sandbox behaves differently from production | 3 | 3 | 9 | Bruno |
| R3 | the bank's payout API is down on a Friday evening, at the peak | 4 | 2 | 8 | Paula |
| R4 | only Bruno understands the reconciliation code | 2 | 3 | 6 | Renata |
| R5 | app store review delays the Driver app release by days | 3 | 1 | 3 | Diego |

The table is a **risk register**: one row per risk, kept where the team works, with a name beside
each row. The grid below draws the same five risks, because where a risk sits says more than its
score.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" aria-label=\"A five by five grid, likelihood from 1 to 5 across and impact from 1 to 5 up. R1, a fake proof of delivery paid out, sits at likelihood 2 and impact 5, in a high-score cell; a dashed copy of R1 sits one row lower, at impact 4, after the R$ 3,000 cap. R2, the sandbox, is at 3 and 3. R3, the bank API down at the Friday peak, at 4 and 2. R4, one person knowing reconciliation, at 2 and 3. R5, an app store review delay, at 3 and 1.\"><defs><marker id=\"l14grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"90\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"142\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"194\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"246\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"228\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"176\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"124\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"72\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"298\" y=\"20\" width=\"52\" height=\"52\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"116\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"80\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"168\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"80\" y=\"202\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"220\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"80\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"272\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"80\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"324\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"80\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"220\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">likelihood →</text><text x=\"8\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impact</text><text x=\"8\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">↑</text><path d=\"M168 77 L168 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l14grid-ah)\"></path><circle cx=\"168\" cy=\"98\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></circle><text x=\"168\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R1</text><circle cx=\"168\" cy=\"46\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"168\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R1</text><circle cx=\"220\" cy=\"150\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"220\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R2</text><circle cx=\"272\" cy=\"202\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"272\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R3</text><circle cx=\"168\" cy=\"150\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"168\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R4</text><circle cx=\"220\" cy=\"254\" r=\"14\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"220\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R5</text><text x=\"380\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R1</text><text x=\"408\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fake proof of delivery paid out</text><text x=\"380\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R2</text><text x=\"408\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sandbox differs from production</text><text x=\"380\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R3</text><text x=\"408\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bank API down at the Friday peak</text><text x=\"380\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R4</text><text x=\"408\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one person knows reconciliation</text><text x=\"380\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">R5</text><text x=\"408\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">app store review delay</text><text x=\"380\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dashed: R1 after the R$ 3,000 cap</text><rect x=\"380\" y=\"222\" width=\"16\" height=\"16\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"404\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">score 10 or more</text><rect x=\"380\" y=\"248\" width=\"16\" height=\"16\" rx=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.12\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"404\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">score 5 to 9</text></svg>", "caption": "Carreto's five risks for instant payout. The score sorts them; the position shows why R1 and R3 need different answers, and the dashed R1 is where the cap moves it."}
```

**The score is a way to sort, not a measurement.** A 1-to-5 scale is ordered but its steps are not
equal, so multiplying two of them is a convenience rather than arithmetic. And the product hides
the shape: a rare catastrophe at 1 × 5 scores the same as a weekly nuisance at 5 × 1. One rule
fixes most of it — **read the impact column on its own for every 5**, and ask of each one whether
Carreto would survive it, whatever its likelihood.

Where a risk can be priced, a number does better than a score. R1 is the one Sílvio, the finance
director, cared about, so Renata and his team put money on it. A fraud ring faking deliveries to
collect instant payouts: they judged a 20% chance of one in a quarter, and about R$ 180,000 paid out
before anybody noticed. Likelihood times impact is then a real product, the **expected loss** or
**exposure**:

```localised
exposure = probability × impact
         = 0.20 × R$ 180,000
         = R$ 36,000 per quarter
```

An exposure is what the risk costs on average, and it is the number to compare with what a response
costs. Neither the 20% nor the R$ 180,000 is known; both are estimates, and like every estimate in
this lesson they deserve a range and their assumptions written beside them.

## Four responses

There are four things to do with a risk, and the register should say which one was chosen.

**Avoid** means changing the plan so the risk cannot happen. The first design let a driver type any
Pix key when asking for a payout. Somebody holding a stolen phone could then send a driver's money
anywhere. The team changed the design: an instant payout goes only to the Pix key verified when the
driver registered. That risk did not get smaller; it left the plan, together with a feature nobody
had asked for.

**Reduce** means lowering the likelihood, the impact, or both. For R1, Bruno's team proposed a cap:
instant payouts of at most R$ 3,000 per load for drivers with fewer than ten completed deliveries,
which is where fake accounts sit. The judged loss from a fraud ring fell to about R$ 45,000, so the
exposure fell from R$ 36,000 to R$ 9,000 a quarter, at the price of about a week of work and some
irritated new drivers. In the grid, that is R1 moving down a row. R4 is reduced on the other axis:
Ícaro Nunes pairs with Bruno on the reconciliation code, which makes Bruno's absence less likely to
stop the work.

**Transfer** means handing the consequence to somebody better placed to carry it, usually for money:
an insurer, or a contract in which a provider takes the liability. A payout provider that routes
through several banks would transfer most of R3, at a fee per payout. Whether that is worth it is a
comparison between alternatives, and the next section makes it.

**Accept** means deciding to live with the risk, and it is a decision only when it is written down.
R5 is accepted: app store review delays are short and common, and nothing Carreto does changes
them. The team adds a **contingency** instead, shipping the Driver app's new screen a week before
the payout is switched on, hidden behind a flag. Accepting with a plan for when it happens is
different from not having looked.

## Keeping the register alive

A register is reviewed or it is decoration. Each row has an **owner**, a person rather than a team,
whose job is to watch it and say when the likelihood changes. Each row also has a **date** to look
at it again. Renata's register lives in the same repository as the decision records of lesson 5, and
the first ten minutes of each architecture forum (lesson 10) go through whatever has moved.

Two things change a register more than anything else. A risk that happens becomes an issue, leaves
the register and goes into the team's ordinary work. And a spike or a decision removes uncertainty,
which lowers a likelihood or deletes a row. R2, the sandbox, is exactly that kind: one call to the
bank and three days of trying the sandbox would say how much it differs from production.

**Risks that share a cause also break the estimate of the last section.** The arithmetic that added
variances assumed the four pieces vary independently. If R2 happens, it delays the bank integration
and the reconciliation testing together, so the real spread is wider than 1.89 weeks.
`process-management` lesson 11 covers this, and contingency reserves, at the depth a project
manager needs. An architect needs the habit: when two rows of an estimate depend on the same unknown,
write that unknown down as a risk.
