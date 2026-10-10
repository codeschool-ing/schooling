---
title: Decision tables
version: 1
---

**Lesson 4 tested one field at a time, and some rules cannot be tested that way.** R5, the price
rule, depends on three things at once: whether the buyer is a student, whether their account is a
member's, and whether the order has five tickets or more. The obvious plan is a case for each
discount: one order as a student, one as a member, one of five tickets. Three cases, three
discounts seen, and the sentence that makes R5 hard is still untested: "Discounts do not add up:
the largest one applies." That sentence only does anything when two discounts meet, and none of
the three cases lets them meet.

A **decision table** is the technique for rules like this one. It lists every combination of the
conditions, and beside each combination the result the requirement asks for. Nothing is left to
the tester's sense of which combinations look interesting; the table makes them all visible, and
then a decision about which to run is a decision somebody can see.

## The parts of a table

A decision table has three parts, and the names are worth knowing because test tools and other
testers use them:

- **conditions**, the questions the rule asks, one per row at the top. For R5: is the buyer a
  student? is the account a member's? are there 5 tickets or more?
- **actions**, what the system does, one per row at the bottom. For R5 there is one: the discount
  applied, as a percentage;
- **rules**, the columns. Each rule is one combination of answers to the conditions, and the action
  it should produce.

When every condition is a yes or a no, the number of rules is 2 raised to the number of
conditions: one condition gives 2, two give 4, three give 8. R5 has three, so its full table has
eight rules.

## Filling it in without missing one

Eight columns of Y and N are easy to get wrong by hand, writing one combination twice and leaving
another out. The pattern that prevents it halves at each row: the first condition is Y for the
first half of the columns and N for the second; the next alternates in pairs; the last alternates
column by column. Every combination then appears exactly once, and a missing one shows as a break
in the pattern.

Then each column gets its action, read from the requirement and nothing else. Rules 1 to 4 have a
student in them, and half price, 50%, is larger than either other discount, so all four are 50.
Rule 6 is a member buying fewer than five, 10%. Rule 7 is a non-member buying five or more, 15%.
Rule 8 qualifies for nothing, 0%. **Rule 5 is the one to read slowly**: a member buying five or
more qualifies for 10% and for 15%, the discounts do not add up, the largest applies, and so the
answer is 15%, not 25%.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" data-fig=\"l05-discount-table\" aria-label=\"A decision table with eight rule columns. Conditions: student, Y for rules 1 to 4 and N for 5 to 8; member, Y Y N N Y Y N N; 5 tickets or more, alternating Y and N. Action, the discount: 50, 50, 50, 50, 15, 10, 15 and 0 percent. Rules 1 to 4 are bracketed as a student, 50% whatever else is true. Rule 5 is outlined: 10% and 15% both apply, and the larger one wins.\"><path d=\"M214 42 L214 34 L438 34 L438 42\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"326.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a student: 50%, whatever else is true</text><rect x=\"20.0\" y=\"52.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"55.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rule</text><text x=\"239.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"297.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"355.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"413.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"471.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"529.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"587.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"645.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"20.0\" y=\"82.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"85.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">student?</text><text x=\"239.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"297.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"355.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"413.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"471.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"529.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"587.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"645.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"112.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"115.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">member?</text><text x=\"239.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"297.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"355.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"413.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"471.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"529.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"587.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"645.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"142.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"145.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 tickets or more?</text><text x=\"239.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"297.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"355.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"413.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"471.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"529.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><text x=\"587.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Y</text><text x=\"645.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">N</text><rect x=\"20.0\" y=\"172.0\" width=\"654.0\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445.0\" y=\"175.0\" width=\"52.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"30.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">discount (R5)</text><text x=\"239.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"297.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"355.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"413.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">50%</text><text x=\"471.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><text x=\"529.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10%</text><text x=\"587.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">15%</text><text x=\"645.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0%</text><path d=\"M20.0 170.0 L674.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"471.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rule 5: 10% and 15% both apply; the larger one wins</text></svg>", "caption": "R5 as a full decision table: three conditions, eight rules, and the discount the requirement asks for in each. Rule 5 is the column where the sentence \"the largest one applies\" decides the answer."}
```

Writing that row is already testing. Doing it forces a question out of the requirement for every
combination, and sometimes the requirement has no answer: if R5 had not said what happens when
discounts meet, rule 5 would be a blank with nothing to put in it, and the right move is to ask the
theatre's manager before anybody writes code against a guess. A decision table finds gaps in a
requirement as well as defects in a program, and it finds them earlier.

## Collapsing a table

Rules 1 to 4 all say 50%, whatever the other two conditions are. A table can say that in one
column, with a dash in the conditions that do not matter, read as "either": student Y, member –,
five or more –, discount 50%. The eight rules collapse to five, and five cases cover them.

**Collapsing is a bet about the code, and it is made without seeing the code.** It assumes that a
program which gives a student 50% does so whatever else is true, the way the requirement reads. If
the program checks the member discount first and returns early, a student who is also a member is
handled by a different line than a student who is not, and the collapsed table runs only one of
them. For most rules the bet is reasonable and saves real effort: a rule with five conditions has
32 columns. For the price, which lesson 1 put at the top of boxoffice's risk grid as risk A, eight
cases are cheap and the bet is not worth making. This lesson runs all eight.

## Conditions that are not yes or no

"Five tickets or more" is a condition on a number, and lesson 4's techniques decide what to type
for it. It splits the valid quantities into two partitions, 1 to 4 and 5 or more, with a boundary
between 4 and 5. The table needs one value for Y and one for N; this lesson uses 5 for Y, the
boundary itself, and 2 for N. Six would be the other choice for Y, and lesson 4 section 04 showed
that boxoffice 1.0 refuses six, so five is the only quantity the program accepts in that
partition. Combining techniques like this is normal: a condition in a decision table is often a
partition, and its values come from boundary analysis.
