---
title: What a control is worth
version: 1
---

Lesson 8 wrote nineteen requirements, and every one of them is a good idea. A small company cannot
build nineteen good ideas this quarter, so the question changes from *is this worth doing?* to
*which first?* The arithmetic that answers it uses lesson 9's numbers and one new one, **the cost of
the control.**

### The value of a control

A control is worth **the expected loss it removes**: the risk before, minus the risk after.

> value per year = expected loss before − expected loss after

For C1, a second factor for staff, judged on T03 alone:

> before: 0.3 a year × R$ 250,000 = R$ 75,000
> after: removes 80% of the frequency, so 0.06 a year × R$ 250,000 = R$ 15,000
> value: R$ 60,000 a year

The 80% is an estimate like any other: the team's judgement of how many of the phishing attempts
that work today would still work with a second factor. It sits in `controls.csv` beside the
control, where somebody can argue with it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l11-c1-worth\" aria-label=\"What C1, a second factor for staff, is worth on T03. Before it, T03’s expected loss is R$ 75,000 a year. C1 removes 80% of its frequency, leaving R$ 15,000. The difference, R$ 60,000 a year, is C1’s value; it costs R$ 3,000 a year, so it saves twenty reais for each real it costs.\"><rect x=\"120.0\" y=\"35.0\" width=\"110.0\" height=\"165.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"23.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R$ 75,000</text><text x=\"175.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T03 before</text><rect x=\"300.0\" y=\"167.0\" width=\"110.0\" height=\"33.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R$ 15,000</text><text x=\"355.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T03 after C1</text><rect x=\"300.0\" y=\"35.0\" width=\"110.0\" height=\"132.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">value R$ 60,000</text><rect x=\"500.0\" y=\"193.4\" width=\"110.0\" height=\"6.6\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"181.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R$ 3,000</text><text x=\"555.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C1’s cost a year</text><text x=\"555.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">saved ÷ cost = 20</text></svg>", "caption": "A control’s value is the expected loss it removes; its ratio is that value over what it costs, every year."}
```

### The cost of a control

**Everything it costs, per year**, so it can be set against a yearly loss:

| | example for C1 |
|---|---|
| licences and hardware | authenticator app licences, two spare keys per clinic |
| building it | two days to wire the second factor into the console's sign-in |
| running it | resetting lost factors, perhaps one a month |
| friction | forty people spending a few seconds more at each sign-in |

A one-off cost is spread over the years the control will last: two days of work, about R$ 4,000,
spread over three years, is about R$ 1,400 a year, which is how C3, the webhook signature check,
gets its number. **Friction is the line people forget**, and it is the one that decides whether a
control survives: a second factor that takes a minute every time gets switched off by somebody in a
hurry, and then it costs nothing and protects nothing.

### Return on security investment

The ratio of the two is sometimes called **return on security investment (ROSI)**, usually written
as (value − cost) ÷ cost. This lesson uses the simpler **saved ÷ cost**: a control that saves R$ 20
for every real spent is plainly better value than one that saves R$ 2, and the two forms put
controls in the same order. Any ratio above 1 means the control saves more than it costs, on
average; below 1 it does not, and the decision has to be made on other grounds, which the section
on beyond the money is about.
