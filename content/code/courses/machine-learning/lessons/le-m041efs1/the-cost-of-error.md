---
title: Two kinds of being wrong, and what each one costs
version: 1
---

**A model that is right 95% of the time can lose money**, and a model that is right 60% of the
time can make it. The usual picture of error is one number, "how often it was wrong", and it
hides the thing that matters: there are two different ways to be wrong, and they almost never
cost the same.

A churn model looks at a subscriber and says *will cancel* or *will stay*. The subscriber then
does one or the other. That makes four outcomes, and every classifier in this course is judged by
how many of each it produces:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 285\" role=\"img\" data-fig=\"l01-four-outcomes\" aria-label=\"A two by two grid. Columns: what the subscriber did, cancelled or stayed. Rows: what the model said, cancel or stay. The four cells are true positive, false positive, false negative and true negative, each with what it means for the R$ 40 credit.\"><text x=\"390.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what the subscriber did</text><text x=\"290.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cancelled</text><text x=\"490.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stayed</text><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what the model said</text><text x=\"176.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cancel: credit sent</text><text x=\"176.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stay: no credit</text><rect x=\"194.0\" y=\"74.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"290.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">true positive</text><text x=\"290.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">some are kept: +R$ 104</text><rect x=\"394.0\" y=\"74.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"490.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">false positive</text><text x=\"490.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">credit wasted: −R$ 40</text><rect x=\"194.0\" y=\"174.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"290.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">false negative</text><text x=\"290.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">left, never asked</text><rect x=\"394.0\" y=\"174.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"490.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">true negative</text><text x=\"490.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing happens</text></svg>", "caption": "Two ways to be right and two ways to be wrong, and the two wrong ones do not cost the same."}
```

- **A true positive**: the model said *cancel*, the credit went out, and the person was about to
  leave. Some of them stay because of it.
- **A false positive**: the model said *cancel*, the credit went out, and the person was staying
  anyway. R$ 40 given away.
- **A false negative**: the model said *stay*, no credit, and the person left. A customer lost who
  might have been kept.
- **A true negative**: the model said *stay*, and they stayed. Nothing happens, which is the point.

## Putting a price on each

The numbers come from the business, never from the data. Feira em Casa's finance team gives Ana
three:

| | |
|---|---|
| the credit | **R$ 40**, paid whoever receives it |
| what a kept subscriber is worth | **R$ 480**: a margin of R$ 60 a month, for the eight months a subscriber stays on average |
| how often the credit keeps somebody who meant to leave | **30%** |

So a credit sent to a true positive is worth 0.3 × 480 − 40 = **R$ 104** on average, and a credit
sent to a false positive costs **R$ 40**. A false negative costs nothing that month, compared with
doing nothing, but it is R$ 104 the business could have had. **The two errors are not symmetric**,
and that asymmetry is the whole of lesson 11: it is why the line between *send* and *do not send*
belongs somewhere other than the 0.5 every library starts from.

## Three policies, priced

December 2025 had 4,146 subscribers, and 248 of them cancelled. Price three ways of choosing whom
to send the credit to, before any model exists:

| policy | credits sent | cost | subscribers kept | worth | net |
|---|---|---|---|---|---|
| send nobody | 0 | R$ 0 | 0 | R$ 0 | **R$ 0** |
| send everybody | 4,146 | R$ 165,840 | 74.4 | R$ 35,712 | **−R$ 130,128** |
| send exactly the 248 who leave | 248 | R$ 9,920 | 74.4 | R$ 35,712 | **R$ 25,792** |

Sending everybody the credit is the policy a company falls into when it cannot tell people apart,
and it loses money: the credit lands on 3,898 people who were staying. Sending it to exactly the
right 248 is what a perfect model would do, and it is worth about R$ 25,800 a month. **That last
figure is the ceiling**: no model can be worth more than it, and a real one gets some fraction of
it, by sending some credits to the wrong people and missing some of the right ones.

This is the frame every later number fits into. Lesson 10 defines **precision**, and a
precision of 0.3 here would mean that three credits in ten land on somebody who was leaving; this
table is what says whether that makes money. **A metric is only worth reading when you know which row of a
table like this it moves.**
