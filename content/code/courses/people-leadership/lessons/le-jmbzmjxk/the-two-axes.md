---
title: Alignment and autonomy are two axes, not two ends
version: 1
---

The usual picture of team freedom is a single slider. At one end the manager decides everything
and the team executes; at the other the team decides everything and the manager stays out of the
way. **On that picture, every gain in autonomy is a loss in alignment, and a manager's job is to
pick a point on the slider.** It is wrong, and the mistake shows up as a team that is either
told what to do or left to drift.

## The drawing that replaced the slider

Henrik Kniberg drew the alternative in his 2014 videos about Spotify's engineering culture, and
the drawing spread well beyond Spotify because it fixed the picture. It puts **alignment** on one
axis and **autonomy** on the other, and treats them as independent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l04-axes\" aria-label=\"A two-by-two grid. The horizontal axis is autonomy, low to high; the vertical axis is alignment, low to high. Bottom left, low on both: told what to do without knowing why. Top left, high alignment and low autonomy: the goal and the solution both come from the manager. Bottom right, low alignment and high autonomy: everybody free, nobody pulling the same way. Top right, high on both: aligned autonomy, where the manager explains the problem and the team finds the solution.\"><defs><marker id=\"l04-axes-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"110.0\" y=\"30.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">the goal and the solution</text><text x=\"245.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">both come from the manager</text><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“build this bridge, this way”</text><rect x=\"390.0\" y=\"30.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"525.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">aligned autonomy</text><text x=\"525.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the manager explains the problem</text><text x=\"525.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“we need to cross; this is why”</text><rect x=\"110.0\" y=\"175.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">told what to do</text><text x=\"245.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">without knowing why</text><text x=\"245.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“do this”</text><rect x=\"390.0\" y=\"175.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"525.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">everybody free</text><text x=\"525.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nobody pulling the same way</text><text x=\"525.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“do what you think best”</text><path d=\"M110.0 330.0 L660.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-axes-pl-ah-paper-dim)\"></path><text x=\"385.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">autonomy</text><path d=\"M88.0 310.0 L88.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-axes-pl-ah-paper-dim)\"></path><text x=\"70.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">alignment</text></svg>", "caption": "After Henrik Kniberg’s drawing. The two axes are independent: more autonomy is paid for with a clearer goal, not with less alignment."}
```

Kniberg illustrated the four corners with a river and a bridge, and it is worth keeping because it
makes each corner concrete:

- **Low alignment, low autonomy.** Nobody explains the goal and nobody gets to choose. People do
  what they are told without knowing why, which is the worst of both and more common than anybody
  admits.
- **High alignment, low autonomy.** "We need to cross the river. Build a bridge here, of this
  design." Everybody knows the goal and the manager has also decided the solution. It works while
  the manager is right and available, and the team learns to wait.
- **Low alignment, high autonomy.** Everybody is free to do what they think best, and nobody knows
  what the others are trying to achieve. Each team builds its own way across the river, or decides
  it would rather stay on this side.
- **High alignment, high autonomy.** "We need to get across the river, and this is why." The
  problem is explained thoroughly and the team works out the solution. Kniberg called this
  **aligned autonomy**: the manager's effort goes into making the goal clear, and the team's into
  meeting it.

## Why the slider is the wrong picture

On the slider, a manager who wants more autonomy for the team says less. On the two axes, they
say **more about the goal** and less about the method. The total amount of communication does not
go down. It moves.

Lesson 3 already made this point for one piece of work: an outcome with its context is longer to
write than a task. Aligned autonomy is the same trade at the scale of a team's quarter. It costs
the manager time up front, explaining the problem until the team could explain it back, and saves
it every week afterwards, because the team stops needing decisions from the manager about how.

## Agenda's quarter

Renata's first full quarter shows the difference. Caju's leadership wanted fewer missed
appointments, because clinics lose money on every patient who books and does not turn up. Otávio's
first version of Agenda's goal was a list: build two-way confirmation by message, add a waiting
list, send a second reminder the day before.

That is high alignment and low autonomy. It tells the team the solution. Renata asked Otávio for
the problem instead, and came back to the team with this:

> This quarter, Caju wants clinics on our product to lose fewer appointments to no-shows. Today
> about one appointment in nine is a no-show, measured over the last quarter. Clinics that have
> told us why say most of those patients forgot, or could not come and did not know how to cancel.
> The goal is to bring that rate down, and to know by how much. Otávio's ideas are confirmation by
> message, a waiting list and a second reminder. They are ideas, not a plan.

The team looked at the data and found that most no-shows came from appointments booked more than
three weeks ahead, which none of the three ideas specifically addressed. They built an easy
cancellation link into the existing reminder first, because a cancelled slot can be given to
somebody else and a forgotten one cannot. Two of Otávio's three ideas shipped later in the quarter.
The third was dropped, with a reason, written down.

## What alignment needs from the manager

The corner the team wants to be in has a price, and the manager pays most of it. Four things have
to be true before a team can be trusted with "how":

1. **The goal is stated as a problem and a measure**, the way an outcome was in lesson 3.
2. **The team knows why it matters** to the company, in numbers if there are any.
3. **The limits are explicit**: what must not change, what it may cost, and by when.
4. **There is a way to know** whether the work is moving the measure.

If any of the four is missing, a team with autonomy drifts, and the usual reaction is to take the
autonomy away. The next section is about why that reaction makes the problem worse.
