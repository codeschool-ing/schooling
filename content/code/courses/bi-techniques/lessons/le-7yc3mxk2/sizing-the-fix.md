---
title: Sizing the fix, and testing it
version: 1
---

A broken step is a reason to act; the size of the prize decides how urgently. The standard estimate
asks what the step would produce if it worked as well as it does elsewhere:

```schooling-example
{"language": "python", "file": "sizing.py", "parts": [{"code": "import pandas as pd\n\nsessions = pd.read_csv(\"sessions.csv\")\nat_checkout = sessions[sessions[\"step\"] >= 4]\nrate = at_checkout.groupby(\"device\")[\"step\"].apply(lambda s: (s == 5).mean())\nmobile = at_checkout[at_checkout[\"device\"] == \"mobile\"]", "note": "Only the sessions that reached checkout, and the share of them that paid, per device."}, {"code": "paid_now = (mobile[\"step\"] == 5).sum()\npaid_if = len(mobile) * rate[\"desktop\"]\nprint(f\"checkout to paid: desktop {rate['desktop']:.1%}, mobile {rate['mobile']:.1%}\")\nprint(f\"mobile sessions at checkout in March: {len(mobile):,}, of which paid: {paid_now:,}\")\nprint(f\"if mobile paid like desktop: {paid_if:,.0f}, that is {paid_if - paid_now:,.0f} more in a month\")", "note": "What the mobile step would produce at the desktop's rate, as an upper bound on what fixing it is worth."}], "output": "checkout to paid: desktop 82.8%, mobile 48.3%\nmobile sessions at checkout in March: 9,242, of which paid: 4,467\nif mobile paid like desktop: 7,652, that is 3,185 more in a month"}
```

**If mobile checkout paid at the desktop's rate, March would have had 3,185 more paid sessions.**
Against the 8,062 that the whole funnel produced, that is a large number, and it is worth stating
carefully.

- **It is a ceiling, not a forecast.** Phones may never match laptops: typing a card number on a
  small screen will always lose somebody. The honest phrasing is "up to".
- **It counts sessions.** Some mobile failures came back and paid on another visit or device, so the
  extra orders are fewer than the extra paid sessions; the person funnel of the last section is how
  to bound that.
- **It assumes the people stay the same.** Fixing checkout changes nothing about who reaches it, so
  the estimate holds the upper steps fixed, which is reasonable for a fix this far down the funnel.

## From funnel to experiment

A funnel finds where to look and how much is at stake; **it does not show that a change works**.
That is an A/B test's job. The one-step checkout of lessons 7 to 11 is exactly this story: the funnel
pointed at the mobile payment step, the hypothesis of lesson 7 named it, and the experiment measured
what the new page did. A funnel compared before and after a redesign, instead, is the before-and-after
comparison lesson 7 showed to be unreliable.

## What a funnel cannot see

A funnel records the steps someone defined. A visitor who leaves at the menu because a recipe they
wanted is missing looks the same as one who was only browsing. **Why people stop is a question for
other evidence**: the search terms used on the site, the errors logged at each step, and, at least
sometimes, asking a few customers.
