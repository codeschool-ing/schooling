---
title: Activating a role, and what it records
version: 1
---

**Activation is the moment an eligible assignment becomes an active one, for a while.** The person
asks for the role, PIM checks the conditions the role's settings demand, and the role is active
until the hours asked for run out. Nothing in this section was run, for the reason the previous one
gave; the steps and the limits are Microsoft's documentation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-activation\" aria-label=\"One activation of an eligible role, as a timeline. ana is eligible for Owner on shop-prod. At the first step ana asks for four hours, with a second factor, a justification and a ticket number. At the second step another engineer approves. From then the role is active, for the four hours asked. At the end it switches itself off and ana is eligible again. Below the line, every step is written to the audit history.\"><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40.0\" y=\"96.0\" width=\"130.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">eligible</text><text x=\"105.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no power yet</text><circle cx=\"250.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"250.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">request</text><text x=\"250.0\" y=\"147.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">second factor</text><text x=\"250.0\" y=\"160.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">justification, ticket</text><circle cx=\"400.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"400.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">approval</text><text x=\"400.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another engineer</text><rect x=\"450.0\" y=\"96.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"535.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">active</text><text x=\"535.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 hours at most</text><circle cx=\"650.0\" cy=\"120.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"650.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expires</text><text x=\"650.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eligible again</text><rect x=\"40.0\" y=\"210.0\" width=\"650.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"56.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">audit history</text><text x=\"365.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">who · which role · where · how long · why</text></svg>", "caption": "The role is held for the hours asked, and every step leaves a line behind."}
```

## What the role's settings may demand

Every role in PIM has **settings**, chosen per role and per scope by whoever administers PIM, and
they decide what an activation costs the person asking:

- **a maximum duration**, from **1 to 24 hours**. The person asks for any number of hours up to it,
  and the role switches itself off at the end, whether or not anybody remembers;
- **multifactor authentication on activation.** Microsoft's documentation adds a warning worth
  repeating: somebody who already passed a second factor earlier in the session may not be asked
  again. Where every activation must prove itself afresh, the setting to use is a conditional access
  **authentication context**, which lesson 11 places in context;
- **a justification**, a sentence saying why, and optionally a **ticket number** from the
  incident or change system, so that the activation can be joined to the reason it happened;
- **approval.** One or more approvers must accept the request before the role is active. Microsoft
  recommends at least two approvers, so that the request does not wait on one person's holiday, and
  an approver needs no role of their own to approve.

Each setting is a trade between friction and control, and the honest way to choose is by what the
role can break. Reader on production needs none of them and should not be in PIM at all. Owner on
production justifies all four: an approval at three in the morning is slower than a standing role,
and that slowness is the point, because an attacker holding a stolen session has to get a second
person to agree.

## The shop's settings

`ana` and two other platform engineers are **eligible** for Owner on the subscription `shop-prod`,
time-bound to six months. The role's settings ask for:

| setting | value | why |
|---|---|---|
| maximum activation | 4 hours | an incident or a change, not a working day |
| second factor | required | the role is worth stealing |
| justification and ticket | required | each activation can be traced to its reason |
| approval | one of the other two engineers | nobody grants Owner to themselves |

The on-call developers are **eligible** for the narrow role lesson 9 wrote, `Shop App Restarter`,
on `rg-shop-prod`, with a justification and no approval: restarting the web app at night must not
wait for somebody to wake up, and what it can break is small.

## What PIM leaves behind

**Every request, approval, denial, activation and expiry is written to PIM's audit history**, with
who, which role, at which scope, for how long and with what justification. That record is half of
what PIM is for. "Who had Owner on production last Tuesday at 2 a.m., and why?" has an answer, and
the answer names a person and a ticket rather than "everybody in the platform team, always".

PIM can also send **notifications**: to the administrators when a role is activated, to the
approvers when a request waits for them. And it can run **access reviews**, a periodic question to
a reviewer, "should these people still be eligible?", which is how six-month eligibility gets
renewed on purpose rather than by default. A role that nobody has activated in six months is the
easiest one to remove, and the review is where somebody notices.
