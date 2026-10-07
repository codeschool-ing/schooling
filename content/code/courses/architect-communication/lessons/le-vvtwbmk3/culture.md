---
title: A culture where bad news travels fast
version: 1
---

**The point of blameless postmortems is not the documents. It is a team in which people report
problems early, because reporting has never cost anybody anything.** That is a property of the culture,
and it can be measured roughly by how fast bad news reaches the people who can act on it.

## Westrum's three cultures

The sociologist Ron Westrum, studying safety in organisations, described three kinds of culture by how
they treat information:

| | pathological | bureaucratic | generative |
|---|---|---|---|
| information is | hoarded, used as power | handled through channels | sought out |
| messengers are | shot | neglected | trained |
| failure leads to | scapegoating | justice | inquiry |
| new ideas are | crushed | create problems | welcomed |

The DevOps research programme described in *Accelerate*, by Nicole Forsgren, Jez Humble and Gene Kim,
used Westrum's typology in its surveys and found that generative cultures were associated with better
software delivery and better organisational performance. The causation is hard to prove from surveys,
and the authors say so. The direction is consistent with what every engineer who has worked in both
kinds of team already believes.

## What moves a team towards generative

None of it is a policy. All of it is behaviour that people see repeated:

- **Thank the person who reported it**, in public, especially when the report was about their own
  mistake. Paulo's account of 6 March was the most useful in the review, and Lívia said so in the
  meeting.
- **Write up near misses as well as incidents.** In April a second backfill nearly ran at peak and was
  caught by the new runbook line. The two-paragraph write-up showed the action working, which is the
  best argument for the next action.
- **Publish postmortems where everybody can read them**, not only engineering. Support, product and
  leadership read Marola's; Sofia's team uses them to answer customers' questions.
- **Leaders go first.** When Otávio's decision to launch a feature without a load test contributed to a
  slowdown in 2025, he wrote that in the postmortem himself. Nobody below him had to.

## The test

Ask the newest engineer on a team: "If you broke production tomorrow, what would happen to you?" In a
generative team the answer is something like "we'd fix it, and there'd be a review about how the system
let me". In a pathological one it is a pause, and then a careful answer. **The answer to that question is
the culture, more accurately than any document about it.**
