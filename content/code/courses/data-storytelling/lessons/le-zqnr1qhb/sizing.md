---
title: Sizing the effect with a range
version: 1
---

"It should help" is not an effect. **A recommendation says how much it should help, in the reader's unit,
and how sure you are.** The honest way to say both at once is a range.

## The arithmetic

If the change brings late first deliveries across the whole company from 17.3% down to 8%, and late
customers then cancel like on-time ones, the number of customers kept each year is:

```localised
=2*6113*(1058/6113-0.08)*(439/1058-881/5055)
```

Two half-years of 6,113 new subscribers, times the share of them who stop being late, times the extra
cancellation rate that lateness brings. LibreOffice Calc answers **273.8**, so about 274 customers a year.
Each early cancellation avoided keeps about R$ 1,554 of lifetime margin (lesson 11), so the whole effect
is worth about **R$ 426 thousand a year**.

## Why a range, and which one

That figure assumes two things that may not hold:

- **That the pilot reaches 8%.** It might reach 12%.
- **That a customer whose first box arrives on time behaves like the on-time customers in the data.** Some
  of the gap may come from something else that late customers share; lesson 10 tests the obvious candidate
  and lesson 12 the less obvious ones.

Neither assumption has a number attached yet, which is what the pilot is for. So Marina gives a range: **the
whole effect as the top, half of it as the bottom, R$ 210 to 430 thousand a year**, and says in a sentence why
the bottom is half. That is a judgement, stated as one. A reader who thinks a third is more realistic can
say so, and the conversation is about an assumption rather than about whether to trust the analyst.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 170\" role=\"img\" data-fig=\"l09-range\" aria-label=\"A horizontal scale of yearly margin kept, from zero to R$ 500 thousand. A thick bar runs from about R$ 210 thousand, half the effect, to about R$ 430 thousand, the whole effect. At zero, a mark shows the cost of the recommended option: no new spending.\"><path d=\"M60.0 110.0 L640.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 110.0 L60.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 0k</text><path d=\"M176.0 110.0 L176.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"176.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 100k</text><path d=\"M292.0 110.0 L292.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"292.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 200k</text><path d=\"M408.0 110.0 L408.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"408.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 300k</text><path d=\"M524.0 110.0 L524.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"524.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 400k</text><path d=\"M640.0 110.0 L640.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 500k</text><path d=\"M307.0 76.0 L554.0 76.0 L554.0 96.0 L307.0 96.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"307.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">half the effect: about R$ 210 thousand</text><text x=\"554.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">whole effect: about R$ 430 thousand</text><path d=\"M60.0 70.0 L60.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"66.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cost</text><text x=\"350.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">margin kept each year if the pilot is rolled out</text></svg>", "caption": "The range is wide and its bottom still clears the cost by a long way, so the decision does not depend on which end turns out to be right."}
```

## What a range does for the decision

The cost of the recommended option is no new spending. **Even the bottom of the range pays for that many
times over**, so the decision does not depend on which end is right. That is the most useful thing a range
can show: whether the uncertainty matters. When the cheaper end of the range would not justify the cost, the
recommendation should say so, and usually become a test, which is the next section.
