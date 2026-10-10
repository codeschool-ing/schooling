---
title: Three gaps, and the instinct that widens them
version: 1
---

Plans go wrong between the people who make them and the people who carry them out. Stephen
Bungay, a historian who went on to advise companies, named three places where they go wrong in
*The Art of Action* (2011), drawing on the same Prussian tradition of mission command that lesson
3 mentioned. **The useful part of the book is less the three gaps than what managers instinctively
do about each, and why every instinct makes the gap wider.**

## The three gaps

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l04-gaps\" aria-label=\"Three boxes in a triangle: plans at the top, actions at the bottom left, outcomes at the bottom right. Between plans and outcomes is the knowledge gap: what we would like to know against what we do know. Between plans and actions is the alignment gap: what we want people to do against what they do. Between actions and outcomes is the effects gap: what we expect our actions to achieve against what they achieve.\"><rect x=\"290.0\" y=\"30.0\" width=\"140.0\" height=\"40.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">plans</text><rect x=\"80.0\" y=\"210.0\" width=\"140.0\" height=\"40.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">actions</text><rect x=\"500.0\" y=\"210.0\" width=\"140.0\" height=\"40.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">outcomes</text><path d=\"M290.0 62.0 L200.0 210.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M430.0 62.0 L520.0 210.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M220.0 230.0 L500.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"212.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">alignment gap</text><text x=\"212.0\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what we want done</text><text x=\"212.0\" y=\"154.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">against what is done</text><text x=\"508.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">knowledge gap</text><text x=\"508.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what we would like to know</text><text x=\"508.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">against what we know</text><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">effects gap</text><text x=\"360.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what we expect our actions to achieve</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">against what they achieve</text></svg>", "caption": "Stephen Bungay’s three gaps. The instinct in front of each is more detail, and more detail widens all three."}
```

- **The knowledge gap** is between the plan and what is really out there. The manager plans on
  incomplete information, because complete information does not exist. Otávio's list of three
  features assumed no-shows came evenly from all bookings; they did not.
- **The alignment gap** is between the plan and what people actually do. People do something
  other than what was meant, because they understood it differently. A developer told to "add a
  second reminder" might add one at a fixed hour, or a fixed number of hours before, and both are
  reasonable readings.
- **The effects gap** is between what people do and what it achieves. The work is done as intended
  and does not have the effect intended, because the world reacts in ways nobody predicted. A
  second reminder might reduce forgetting and also teach patients to ignore the first.

## The instinct, three times

Each gap triggers a natural response, and Bungay's observation is that the three responses have
the same shape: **more detail.**

| the gap | the instinct | what it does |
|---|---|---|
| knowledge | gather more information before planning | delays the plan, and the information is still incomplete |
| alignment | write more detailed instructions | leaves less room to adapt when the instructions meet reality |
| effects | add more detailed controls | people manage to the controls rather than to the effect |

All three increase the manager's work and decrease the team's ability to respond to what it finds.
The more detailed the plan, the more ways it can be wrong, and the less permission anybody has to
notice.

## What to do instead

Bungay's answer is the same for all three, and it is the answer lessons 3 and 4 have been building:

- **Against the knowledge gap, decide only what you must**, at the level you are at. Otávio's level
  needed to decide that no-shows mattered this quarter. It did not need to decide which feature
  would fix them.
- **Against the alignment gap, explain the intent**, not more instructions. If the team knows that
  the point is fewer lost appointments, a developer choosing when to send a reminder can choose
  by that, even in a case nobody anticipated.
- **Against the effects gap, give people freedom to adjust** within limits. A team that sees the
  second reminder teaching patients to ignore the first can change it, without asking, because the
  goal was the no-show rate and not the reminder.

## What it looked like on Agenda

Midway through the quarter, the cancellation link had brought the no-show rate down, and the
team found a side effect: some clinics complained that slots freed late in the day stayed empty,
because nobody was told about them. That is an effects gap. The instinct would have been for
Otávio to add a control, a target for slot reuse reported weekly.

What happened instead was smaller. Renata told the team about the complaint, reminded them that the
goal was appointments kept, not cancellations made, and the team moved the waiting list, one of
Otávio's original ideas, up the queue. **Nobody had to issue an instruction for the plan to
change, because the people who saw the problem knew what the plan was for.**

## The test for a manager

A short test follows from Bungay's argument, for whether an instruction carries enough intent: could the
person who receives it explain back what it is for, and decide what to do in a situation the
instruction did not cover? Try it on the last thing you asked somebody to do, or the last thing
somebody asked of you. If the honest answer is "they would have to come back and ask", the
instruction was a task in a goal's clothing.
