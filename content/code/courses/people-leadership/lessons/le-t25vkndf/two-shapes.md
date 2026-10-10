---
title: The tech lead and the engineering manager
version: 1
---

"Leading a team of engineers" describes two different jobs, and most of the confusion in this area
comes from treating them as one. **One of them answers for how the software is built. The other
answers for the people building it and what they deliver.** A small team can give both to one
person. A team of seven usually cannot, and the first conversation Renata needed to have was about
which of the two she had.

## Two jobs, often under one word

The **tech lead** is the engineer who leads. They own the technical direction of the team: the
design of what is being built, the quality bar in review, the decision between two approaches when
the team cannot agree, and the unblocking of anybody stuck on a technical problem. They still write
code, and their credibility depends on it, because a technical decision from somebody who no longer
works in the codebase is a guess with authority.

The **engineering manager** answers for the team as a group of people. They own hiring, growth,
feedback and performance, the commitments the team makes to the rest of the company, the process
it works by, and whether people are still there and well a year from now. Some write code, most
write very little, and almost none should write code that the team's plans depend on, for the
reason lesson 1 gave: their week is cut into pieces, and the critical path cannot wait for the gaps.

Companies name these jobs inconsistently. Some call the first a staff engineer, a principal, an
architect. Some combine both into one role with a title like tech lead manager, which works for a
team of three or four and strains well before ten. Will Larson's *Staff Engineer* (2021) lists
the tech lead as one of four shapes a senior engineer's job takes, beside the architect, the solver
and the right hand, which says something on its own: **leading technically is a senior engineering
job, not a junior management one.**

## What each owns, and where they overlap

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"Two overlapping areas. The tech lead, on the left, owns the technical direction, the design, the quality bar in review and technical unblocking, and still writes code. The engineering manager, on the right, owns hiring decisions, growth and feedback, performance, the team’s commitments to the company, its process and whether people stay. In the overlap sit four things both touch: estimates and plans, interviews, incidents, and who works on what.\"><rect x=\"30.0\" y=\"50.0\" width=\"400.0\" height=\"225.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"290.0\" y=\"50.0\" width=\"400.0\" height=\"225.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><rect x=\"290.0\" y=\"50.0\" width=\"140.0\" height=\"225.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M290.0 50.0 L290.0 275.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M430.0 50.0 L430.0 275.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 50.0 L430.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 275.0 L430.0 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"160.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">tech lead</text><text x=\"560.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">engineering manager</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">both touch</text><text x=\"50.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">technical direction</text><text x=\"50.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the design</text><text x=\"50.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the quality bar in review</text><text x=\"50.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">technical unblocking</text><text x=\"50.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">still writes code</text><text x=\"670.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hiring decisions</text><text x=\"670.0\" y=\"119.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">growth and feedback</text><text x=\"670.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">performance</text><text x=\"670.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">commitments to the company</text><text x=\"670.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the team’s process</text><text x=\"670.0\" y=\"251.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">whether people stay</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estimates</text><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">and plans</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">interviews</text><text x=\"360.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incidents</text><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">who works</text><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">on what</text></svg>", "caption": "The two halves are rarely in dispute. The middle is where two people both act, and disagree in front of the team."}
```

The two halves of the figure are clear enough. The middle is where the friction is, and it is worth
looking at item by item.

- **Estimates and plans.** The tech lead knows what the work involves; the manager knows what the
  company needs and when. A plan made by either alone is wrong in a predictable direction.
- **Interviews.** The tech lead judges technical skill better; the manager owns the hiring decision
  and the rest of what the job needs.
- **Incidents.** During one, the person best placed to lead the technical response leads it. After
  it, the manager owns whether the follow-up work gets scheduled.
- **Who works on what.** The tech lead knows who could do a task. The manager knows who needs it
  to grow, who is overloaded, and who asked for something different in their last one-to-one.

None of these has a correct owner in general. Each needs one at Caju, written down, because the
cost of nobody owning them is that both people do them, and disagree in front of the team.

## How Agenda split it

In her listening tour, Renata asked Diego the question lesson 1 recommended, in private: what he
wanted from the next year. His answer surprised her. He had wanted the manager's job in the sense
that he wanted to decide how Agenda's software was built, and had assumed that came with it. When
they listed what the manager's job actually contained, he did not want most of it. **He wanted
the left half of the figure, and nobody had ever offered it to him without the right.**

So Agenda ended up with both roles, held by two people: Diego as tech lead, Renata as engineering
manager. Renata does not overrule Diego on design, and Diego still reports to her as his
manager. That combination is common and it is workable, but only with the next two sections:
a clear idea of what each person is giving up, and a written agreement about the middle.
