---
title: Deciding with several criteria, and checking the decision
version: 1
---

Some decisions have one trade-off at their heart and the previous section's scenarios are enough.
Others have five criteria pulling in different directions, three options, and a room full of
people who each care about a different criterion. **A weighted decision matrix does not make
that decision for you. It makes the disagreement visible, puts it in numbers, and shows which
part of it actually changes the answer.** Used that way it is one of the most useful tools an
architect has. Used as an oracle, it launders opinions into decimals.

## The decision: where shipper invoicing lives

Once a delivery is paid, Carreto has to invoice the shipper: a monthly statement of every load,
each linked to its authorised CT-e, with the shipper's payment terms. Today a finance analyst
builds it in a spreadsheet. Bruno's Payments team and the Shipper team have to choose where the
new invoicing lives, and three options are on the table:

- **A: a module inside the monolith**, which already holds the shipper records and the CT-e keys;
- **B: a new Invoicing service** owned by Payments, with its own database;
- **C: a hosted billing product**, integrated with Carreto through its API.

Before any scoring, Renata separated one thing out. **Every invoice must reference its authorised
CT-e.** That is not a criterion to be weighed against speed; it is a constraint, and an option that
cannot meet it is out, whatever it scores elsewhere. All three can meet it, C with integration work,
so all three go forward. Mixing constraints into the weights is the commonest way a matrix lies: a
legal requirement scored at 25% can be outvoted by convenience.

## Building the matrix

The criteria come from the quality attributes and from the six questions of lesson 5, and the
weights come from the people who own them. They agreed on five, after an hour's argument that was
itself the most useful part of the exercise:

| criterion | weight | A: monolith module | B: new service | C: hosted product |
|---|---|---|---|---|
| time to first invoice | 30% | 5 | 2 | 4 |
| team independence (deploy without the monolith) | 20% | 2 | 5 | 4 |
| running cost | 15% | 5 | 2 | 3 |
| fit with the CT-e data | 25% | 4 | 4 | 2 |
| exit cost | 10% | 4 | 4 | 1 |
| **weighted total** | 100% | **4.05** | **3.30** | **3.05** |

Each total is the sum of weight times score. For A: 0.30 × 5 + 0.20 × 2 + 0.15 × 5 + 0.25 × 4 +
0.10 × 4 = 1.50 + 0.40 + 0.75 + 1.00 + 0.40 = 4.05. The scores are on a scale of 1 to 5, and each one is a judgement the team justified in a sentence.
The monolith module scores 5 on time because the shipper records are already there. It scores 2 on
independence because every invoicing change waits for the monolith's deploy, which happens twice a
week.

**Three rules keep the matrix honest:**

- **Agree the weights before anyone scores.** Weights set after the scores are known get tuned,
  consciously or not, until the favourite wins.
- **Keep criteria independent.** "Running cost" and "cost of the cloud bill" scored separately
  count the same thing twice and quietly double its weight.
- **Write the reason beside each score.** A 4 nobody can explain is a guess, and the matrix is then
  a guess multiplied by a weight.

A wins, 4.05 against 3.30 and 3.05. The matrix's work is not finished there.

## The sensitivity check

The weights are the softest numbers in the table. Thirty per cent for time to first invoice was
Helena's argument; twenty for team independence was Bruno's concession. **The question that
matters is whether the winner survives a reasonable change to them**, and it takes five minutes to
answer.

Move ten points from time to independence, so time is 20% and independence 30%. A drops to 3.75
and B rises to 3.60. A still wins, by less. Move twenty points, to 10% and 40%, and A falls to 3.45
while B reaches 3.90. **B wins.** C, as it happens, does not move at all: it scores 4 on both
criteria, so shifting weight between them changes nothing for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"A line chart. Across, the weight given to team independence, from 0 to 50 per cent, with time to first invoice getting the rest of 50 per cent. Up, the weighted score, from 2.5 to 5. Option A, the monolith module, falls from 4.65 to 3.15. Option B, a new service, rises from 2.70 to 4.20. Option C, a hosted product, stays flat at 3.05. Today's weight, 20 per cent, is marked, where A leads. The lines for A and B cross at 32.5 per cent, and above that B wins.\"><path d=\"M90 300 L660 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M90 300 L90 36\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M90 248 L650 248\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><path d=\"M90 144 L650 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><path d=\"M90 40 L650 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></path><text x=\"82\" y=\"252\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">3.0</text><text x=\"82\" y=\"148\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">4.0</text><text x=\"82\" y=\"44\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">5.0</text><text x=\"96\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">weighted score</text><text x=\"90\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">0%</text><text x=\"202\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">10%</text><text x=\"314\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">20%</text><text x=\"426\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">30%</text><text x=\"538\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">40%</text><text x=\"650\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">50%</text><text x=\"660\" y=\"342\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">weight on team independence</text><path d=\"M314 44 L314 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><text x=\"320\" y=\"292\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">today: 20%</text><path d=\"M90 76.4 L650 232.4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M90 279.2 L650 123.2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M90 242.8 L650 242.8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><text x=\"110\" y=\"66\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">A: monolith module</text><text x=\"650\" y=\"112\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">B: new service</text><text x=\"650\" y=\"264\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">C: hosted product</text><circle cx=\"454\" cy=\"177.8\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M457 172 L472 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"466\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">B wins above 32.5%</text></svg>", "caption": "The same matrix, recomputed as weight moves from time to first invoice to team independence. At today's 20% A leads clearly; the lines cross at 32.5%. The decision rests on that one weight, so that weight is the argument to have."}
```

The crossover is at 32.5%. Below it, A wins; above it, B. **That turns a vague debate into one
question with a number: is team independence worth a third of this decision?** It also tells
Renata which arguments are not worth having. Nobody needs to spend another hour on running cost or
exit cost; moving ten points into or out of either, from or to any other criterion, leaves A
the winner.

The check also protects against false precision. A at 4.05 and B at 3.30 looks like a clear result.
The chart shows that the margin depends almost entirely on one weight that two people set in a
conversation. If that weight had been 35% rather than 20%, the same table would have chosen
differently with the same confidence.

What the team did with this was simple. Bruno argued that independence would matter more in two
years, when invoicing grows rules of its own; Helena argued that the first invoices had to go out
this quarter. Tomás settled it: A, the module in the monolith, built behind an interface so it could be
extracted later. The decision record names the 32.5% crossover and says what would make the team
revisit it: more than one change a week to invoicing blocked by the monolith's deploy schedule. **The record carries the matrix, the sensitivity check and the
condition for changing course.**

## Other ways to decide well

The matrix is one tool. A few habits from earlier lessons do as much work, and they belong
together:

- **Decide at the last responsible moment**, which lesson 2 introduced: not before the information
  that would change the answer can arrive, and not after waiting starts to cost options. The
  invoicing decision waited until the 24-hour payout had shipped, because that settled how
  Payments would know a delivery was paid.
- **Match the effort to the door.** Lesson 5's two axes decide how much of this a decision gets. A
  two-way door inside one team does not need a matrix; it needs someone to pick and move on.
- **Ask before deciding.** The advice process from lesson 3 means the people affected and the
  people who know were consulted. The matrix's weights are one place where that advice becomes
  visible.
- **Consider doing nothing.** The finance analyst's spreadsheet is a fourth option. It lost because
  Carreto's volume was growing faster than one person could invoice by hand, but it should be on
  the list, and lesson 14 makes it a habit.
- **Write the decision down**, with the matrix and the check, so the next person who asks why
  invoicing is in the monolith finds the crossover and the condition rather than a shrug.

## What the architect owns in all this

Not the answer. In the invoicing decision Renata scored nothing herself and set none of the
weights. **She owned the method**: separating the constraint from the criteria, making sure the
weights were set before the scores, running the sensitivity check, and getting the crossover in
front of the people whose disagreement it measured. The decision was Tomás's, with Bruno and Helena
on either side of it, and it was better for being visibly theirs.

That is the line this lesson has drawn three times. Structural decisions that are expensive to
reverse or cross teams are architectural; trade-offs between quality attributes are made explicit
with scenarios; decisions among several criteria are made with a matrix and checked for
sensitivity. **In each case the architect's contribution is to make the decision decidable**, and
then to make sure it is written down.
