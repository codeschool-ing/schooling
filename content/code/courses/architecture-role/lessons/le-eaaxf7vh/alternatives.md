---
title: Spikes, alternatives and the pre-mortem
version: 1
---

An estimate and a risk register describe one plan. A decision needs at least two, and the one most
often left off the page is **doing nothing**. This section covers the three moves that come before
a choice: buying the information an estimate is missing, comparing the options against the cost of
not acting, and imagining the plan has already failed so that the reasons can be found while they
are still cheap.

## A spike buys information

A **spike** is a short piece of work whose output is an answer rather than a feature. The word comes
from Extreme Programming, and the discipline is in four parts: a written question, a time box, a
written answer, and code that is thrown away or clearly marked as a prototype. A spike without a
question becomes a project; a spike without a time box becomes the feature, built in a hurry and
never cleaned up.

**Spend a spike where the range is widest and a few days can narrow it.** In Renata's table the
widest row was the proof-of-delivery checks, from 1 to 9 weeks, and its width came from a question
nobody at the table could answer: what does Tracking record at the moment of delivery, and can
Payments trust it enough to pay at once? Ícaro and an engineer from Tracking took three days to
find out.

Their answer, two paragraphs long, was better than the team had feared. Tracking already stores a
GPS fix and a photo for every delivery, signed by the Driver app, beside the delivery record. What was missing was a rule for the cases where the fix is far from the delivery address,
and a way for Payments to ask. The team estimated the piece again, now at 1, 2 and 4 weeks:

| | before the spike | after the spike |
|---|---|---|
| proof-of-delivery checks, PERT mean | 3.67 weeks | 2.17 weeks |
| its standard deviation | 1.33 | 0.50 |
| total, PERT mean | 13.5 weeks | 12.0 weeks |
| total, about the 85th percentile | 15.5 weeks | 13.5 weeks |

**Six person-days bought two weeks off the number to plan against**, and a narrower range around it.
The spike would have been worth running if the answer had been bad, too. A result that confirmed the
9 weeks would have made the plan honest and Helena's commitment safer, which is the information
either way. What a spike cannot do is promise good news, and one run in the hope of a smaller number
is a spike that will be read selectively.

## Comparing alternatives, starting with doing nothing

With the range narrowed, Renata wrote down the options. Three were on the table:

- **A**, build instant payout on the bank's own Pix payout API, as estimated so far;
- **B**, buy it from a payout provider, which connects to several banks and charges per payout;
- **C**, do nothing: keep the payout run as it is.

The Payments team estimated B the same way, at 4, 6 and 11 weeks, a PERT mean of 6.5. Carreto's
finance team puts a week of the Payments team at about R$ 30,000, and the payouts would run at about
30,000 a month. Every figure is an estimate and has its range in the appendix of Renata's page; the
means are enough to compare:

| | A: the bank's API | B: a provider | C: do nothing |
|---|---|---|---|
| effort, PERT mean | 12.0 weeks | 6.5 weeks | none |
| engineering cost | R$ 360,000 | R$ 195,000 | none |
| fee per payout | R$ 0.30 | R$ 1.10 | none |
| fees per month, 30,000 payouts | R$ 9,000 | R$ 33,000 | none |
| bank outage (R3) | Carreto's problem | mostly the provider's | does not arise |
| leaving later | cheap | a contract and a migration | nothing to leave |
| drivers waiting for pay | no | no | yes, as today |

A costs R$ 165,000 more to build and R$ 24,000 a month less to run, so it pays back its extra cost
in about seven months; over three years it is about R$ 699,000 cheaper. B is live about five and a
half weeks earlier and carries less of R3. **Neither number decides on its own**, which is why the
page shows both rather than a winner.

**Option C is never free, and it has to be estimated as seriously as the others.** Its cost is the
reason Helena asked in the first place: drivers leaving for a competitor who pays faster. Carreto
has about 9,000 active drivers, and Helena's own estimate, from exit interviews and the
competitor's launch, is that between 1% and 3% more of them a quarter will leave if nothing changes:
90 to 270 drivers. That range is as much an estimate as Bruno's weeks, and writing it down lets
Sílvio argue with it. Leaving C off the page makes A and B look like the only choices, when the real
question is whether either is worth more than standing still.

Writing the options side by side also produced one that was not on the list. **B with an exit
door**: start with the provider, put the payout behind an interface that Payments owns, and move to
the bank's API when the volume makes the fee difference worth the work. In lesson 5's terms, that
turns a one-way door into a two-way one. The extra cost is the interface, about a week, and it buys the
right to change the decision later at a known price. The full comparison of building against buying,
over years and with exit costs, is the subject of `tech-strategy` lessons 8 and 9, in the tech lead
track.

**Who chooses is not the architect.** Helena owns what drivers get, Sílvio owns the money, and
lesson 13 drew that line. Renata's page sets out the options, the ranges, the top risks and what
each option assumes, and asks for a decision by a date. Making the consequences explicit is her
work; picking among them is theirs.

## The pre-mortem

Once a plan has been chosen, a team stops looking for reasons it might fail: the reasons now sound
like disloyalty. Gary Klein's **pre-mortem**, described in the *Harvard Business Review* in 2007,
uses that moment. The group is told that the project has already failed and is asked to explain why.

The wording matters more than it looks. "What could go wrong?" invites a polite list. "It is six
months from now, instant payout was switched off last week, and it was a disaster. Take five minutes
and write down why" makes failure a fact to explain rather than a forecast to defend, and it gives
everybody permission to say the thing they had been keeping quiet.

Renata ran one when Helena and Sílvio chose B with an exit door. Nine people, twenty minutes, notes
written alone first, the same rule as risk-storming. Most of what came up was already in the
register. Two things were not:

- **Finance froze the payouts.** Sílvio's team reconciles the ledger with the bank statement once a
  month. Instant payouts every few minutes, through a provider, would make the first month's
  reconciliation a week of work, and the first mismatch would stop everything. It went into the
  register as R6, owned by Bruno, reduced by a daily automatic reconciliation report.
- **Support could not answer drivers.** A driver whose payout is late calls support, and support had
  no screen showing where a payout is. Nobody on the project worked in support, which is exactly why
  nobody had thought of it. It became a piece of work in the estimate, at 1, 1 and 2 weeks.

**A pre-mortem looks at the whole plan; risk-storming walks the diagram.** The first finds failures
in how the system meets people — finance, support, the board — and the second finds them in the
parts and the arrows. They catch different things, and both together took less than an hour.

What Renata had sent Helena before the decision fitted on one page: a range to plan against, the five largest
risks with owners and responses, three options including doing nothing, the one the spike changed,
and the question she needed answered. How to write that page for a director is the subject of
`architect-communication` lesson 4. What goes on it is this lesson.
