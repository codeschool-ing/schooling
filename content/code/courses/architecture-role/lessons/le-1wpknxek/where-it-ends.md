---
title: Where the architect's role ends
version: 1
---

**The architect does not manage people, does not own the product's priorities, does not approve
every pull request and is not on the critical path of any team's delivery.** Each of those is a real
job that somebody at Carreto does well, and each of them, taken on by the architect, damages the
part of the work that is the architect's. The boundaries are easier to defend once the damage is
visible, so this section goes through them one at a time, with what crossing each one costs.

The mistaken idea underneath all four is that an architect's influence grows with the number of
things the architect controls. Lesson 3 argued the opposite: the authority that makes an architect
useful is earned, and it is spent every time the architect takes something that belongs to somebody
else.

## Not a manager of people

Renata manages nobody. Hiring, performance reviews, promotions and moving people between teams
belong to Carreto's engineering managers, and the decision-rights table from the previous section
gives them that row explicitly.

The reason is not that managers make poor architects. It is what happens to disagreement. **When
the person whose design you are questioning also writes your performance review, disagreeing with
the design becomes expensive, and people stop doing it.** Advice turns into instruction without
anybody intending it, and the architect loses the thing that catches bad decisions early: a
developer who says "that will not work, and here is why". Ícaro telling Renata that her proposed
retry policy would double-charge a shipper on a timeout is worth more to Carreto than any review
she could write of him, and he is far more likely to say it to somebody who has no say over his
salary.

In a small company one person may hold both, and the previous section said what to do then:
name the hat. A manager taking an architectural decision can say so, ask for advice as anybody
would, and accept being argued with. What does not work is pretending the combination changes
nothing.

## Not the owner of product priorities

Helena Prado, the product director, decides what Carreto builds and why. The architect's part is to
make the **structural cost** of each option visible before she decides, and then to accept the
decision.

A real case: Helena wants drivers paid by Pix the moment the proof of delivery arrives, instead of
within 24 hours of delivery as the flow from lesson 4 does now. For drivers, many of whom wait on
that money to fill the tank for the next load, it is a strong feature. Renata's part is not to say
yes or no. It is to say what changes underneath:

- Payments would act on Tracking's proof of delivery as it arrives, so a wrong or disputed proof
  would pay a driver before anybody had looked at it, and **a Pix transfer is very hard to take
  back once it has been sent**.
- The 24-hour window currently absorbs Tracking's delays; without it, an outage in Tracking stops
  payments rather than slowing them.
- Her estimate, as a range in the manner of lesson 14, is **9 to 14 engineer-weeks**, most of it in
  checks that today happen by waiting.

Then Helena decides, perhaps for instant payment only to drivers with a long clean record. The
architect who quietly slows a feature she disagrees with, or who refuses to estimate it until it is
dropped, has taken a product decision by other means. Lesson 10 is about doing this side of the work
well, and `architect-communication` lesson 13 about negotiating it.

## Not the approver of every pull request

The arithmetic settles this one faster than any argument. Carreto merges about 320 pull requests a
week. At ten minutes each, reviewing all of them would take Renata 3,200 minutes, which is **53 hours
and 20 minutes a week** — longer than her whole working week, before a single meeting or a line of
her own. And because she would be one person in front of 50, every one of those pull requests would
wait for her calendar.

What she does instead is put her judgement where it scales:

- **Standards enforced by machines.** The fitness function from lesson 9 fails the build when a
  module imports another it should not, on every pull request, at no cost to her week.
- **Reviews of designs, before the code.** Lesson 11's design review catches a structural mistake
  when it costs a conversation, instead of a rewrite.
- **Reading a sample of pull requests**, a few a week across different teams. That is how lesson 15
  says an architect stays calibrated, and it is reading, not approving: nobody waits for her to
  finish.

The teams' tech leads and senior engineers review each other's code, which is where the knowledge
needed to review it lives.

## Not on the critical path

Lesson 15 argued that the architect must keep writing code and said which code: never the task a
team's delivery is waiting on. Carreto learned why the hard way, in the sprint where Renata took the
ticket for the Pix payout adapter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two timelines over thirteen working days. Planned: Renata builds the Pix adapter on days 1 to 4, the team runs integration tests on days 5 to 7, and the release is on day 8. What happened: Renata works on the adapter on day 1, spends days 2 to 6 on the new CT-e layout, finishes the adapter on days 7 to 9; integration tests run on days 10 to 12 and the release is on day 13, five working days late.\"><text x=\"12\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">planned</text><text x=\"132\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Pix adapter (Renata)</text><rect x=\"140\" y=\"40\" width=\"168\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">integration tests</text><rect x=\"308\" y=\"68\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"434\" y=\"68\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">release</text><text x=\"12\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what happened</text><text x=\"132\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Pix adapter (Renata)</text><rect x=\"140\" y=\"140\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"392\" y=\"140\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">other work</text><rect x=\"182\" y=\"168\" width=\"210\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"287.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the new CT-e layout</text><text x=\"132\" y=\"206\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">integration tests</text><rect x=\"518\" y=\"196\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"644\" y=\"196\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"665.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">release</text><path d=\"M455.0 92 L455.0 134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><path d=\"M665.0 92 L665.0 192\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"560.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the release moved five working days</text><path d=\"M140 232 L686 232\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"161.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"203.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"287.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"329.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"371.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"413.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"455.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"497.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><text x=\"539.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"581.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><text x=\"623.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"665.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13</text><text x=\"686\" y=\"268\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">working day</text></svg>", "caption": "Nobody on the team was slow. The release waited for the one task held by the person with the most other claims on her week."}
```

The plan was sound and the adapter was well within her ability. What the plan did not price in was
that **the architect's week is the one most likely to be taken by something else**. On day 2 a new
CT-e layout was announced, and the work of deciding how Carreto would meet it (lesson 13 follows
that story) was hers. The adapter stopped for five days, the integration tests could not start
without it, and the release moved from day 8 to day 13. Nobody on the team was idle by choice, and
nobody could have picked the ticket up halfway without starting it again.

The alternatives were available all along. Renata could have **paired with Ícaro on the adapter
while he held the ticket**, which gives her the same feel for the code and leaves the task with
someone whose week is predictable. Or she could have taken work that nothing waits on: a spike, the
fitness function for Payments' imports, a tool the team wanted and had no time for.

## What is left inside the boundary

Take away the four, and the architect's work is still a full week:

- the structural decisions that cross teams, and their records (lessons 5 and 6);
- the quality attributes and the requirements behind them (lesson 7);
- the standards, and the automation that keeps them true (lesson 9);
- the technical risks, written down and watched (lesson 14);
- the forum where the teams and the architect argue the cross-team questions (lesson 10).

Put as one sentence: **the architect answers for the decisions that cross team boundaries or cost
a lot to change, and makes their consequences visible to the people who decide everything else.**
Lesson 17 is about what happens when an architect crosses these boundaries in either direction: by
taking too much, or by leaving the structural decisions to nobody.
