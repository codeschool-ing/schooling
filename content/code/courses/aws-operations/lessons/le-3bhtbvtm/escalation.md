---
title: Escalation, when nobody answers
version: 1
---

A page that nobody answers is worse than no page at all, because everybody believes it was handled.
**Escalation** is the rule for what happens next: if the person paged has not acknowledged within a
set time, the next person is paged, and so on up a short ladder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline from 0 to 20 minutes. At 0 minutes the primary is paged. With no acknowledgement, at 5 minutes the secondary is paged. With still none after 10 more, at 15 minutes the lead is paged. A note under the line: an acknowledgement at any step stops the ladder, meaning I have it, not I fixed it.\"><defs><marker id=\"esc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 140 L670 140\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M70 134 L70 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"70\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 min</text><path d=\"M220 134 L220 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"220\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5 min</text><path d=\"M370 134 L370 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"370\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10 min</text><path d=\"M520 134 L520 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M670 134 L670 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"670\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20 min</text><rect x=\"8\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">primary paged</text><path d=\"M70 104 L70 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><rect x=\"158\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">secondary paged</text><path d=\"M220 104 L220 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><rect x=\"458\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lead paged</text><path d=\"M520 104 L520 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><text x=\"145.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no acknowledgement</text><text x=\"370\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">still none, 10 more</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">An acknowledgement at any step stops the ladder: \"I have it\", not \"I fixed it\".</text></svg>", "caption": "The ladder climbs only while nobody has acknowledged, and its last step is one person, never a group."}
```

| step | who is paged | after |
|---|---|---|
| 1 | the primary | at once |
| 2 | the secondary | 5 minutes with no acknowledgement |
| 3 | the team's lead, who may take command | 10 more minutes |

Acknowledging is a single press on the phone, and it means *I have it*, not *I have fixed it*. It stops
the ladder and starts the clock on the incident, which from that point is lesson 13's. Five minutes is a
common first step: long enough to find the phone and wake up, short enough that a page lost in a pocket
costs little. The last step is a person and never a group, because a page to twelve people is a page
each of them expects another to answer.

## What SNS does not do

The topic from lesson 10 delivers. **It does not know whether anybody read what it delivered**: an
e-mail sent and an SMS sent are the end of its job, and no message ever comes back to it saying *I have
it*. There is nothing in SNS to escalate on, so the ladder lives in a **paging service**, a product built
for exactly this, subscribed to the topic through an HTTPS endpoint. The alarm publishes, the topic
delivers to the service, and the service holds the rotation, the acknowledgement and the ladder, and
rings the phone with a sound that wakes people, which an e-mail does not.

The lab has no paging service, and teaching one product's screens would age as fast as the product, so
this course stops at the topic. What stays the same whichever service a team picks is what to configure
in it: the rotation of the previous section, the ladder above, and **one test page a week**, sent on
purpose at the handoff, so a broken route is found by the people who expect it.

## Two kinds of alert

Not everything worth knowing is worth waking somebody for. A team that has only one destination for its
alarms ends up paging on things that could wait for the morning. **Two destinations, two topics**:

- **a page**: customers are affected now, or will be within the hour, and a person can do something;
  it goes to `shop-page`, and from there to the phone;
- **a ticket**: something to look at in working hours, a disk filling slowly, a certificate due in three
  weeks; it goes to `shop-ticket`, and from there to the team's queue of work.

Deciding which one an alarm is, alarm by alarm, is the fatigue section's work, and moving it is the last
section's.
