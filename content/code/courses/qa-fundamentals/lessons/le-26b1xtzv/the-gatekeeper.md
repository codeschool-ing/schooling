---
title: The gatekeeper, and why the job is not a gate
version: 1
---

**The most common picture of a tester is a guard at the door: nothing ships until QA says it may.** It
is a flattering picture, and some testers are hired into it on purpose. It is also, in almost every team
that tries it, the arrangement that makes software worse. This lesson argues that position; you are
free to disagree with it, and you should know the argument before you do.

## How the gate is supposed to work

Developers build. When they think a feature is finished, they hand it to the tester. The tester checks
it, and either sends it back with defects or approves it for release. Quality is assured because nothing
passes the gate without the tester's approval, and if a defect reaches customers, everybody knows whose
signature was on the release.

Every sentence of that sounds responsible. Watch what each one does to a team over six months.

## What the gate does to everybody else

**Developers stop owning quality.** If somebody downstream will check everything, checking it yourself
is duplicated effort, and there is always a deadline that makes skipping it reasonable. Rafael, under the
gate, sends `tickets.py` over after trying four inputs, because Lia will try the rest. Each person
lowers their own bar by exactly the height of the bar after them.

**Work arrives late and all at once.** The gate is at the end, so every feature reaches the tester when
it is finished, which means in the last days of every cycle. The tester becomes the bottleneck the
release waits behind, and the pressure on them to approve is highest at exactly the moment they have had
the least time to look.

**The relationship turns adversarial.** A tester whose job is to find reasons to refuse becomes the
person developers argue with. Defects are reported as verdicts and defended as accusations. Information
that would have helped earlier, *I am not sure this rule is right*, stops being shared, because sharing
it hands the gatekeeper a reason.

**And the promise was never keepable.** A tester cannot guarantee that a release has no defects; lesson
1 quoted Dijkstra on why. A signature on a release is a claim nobody can honestly make, and the day a
defect escapes, the team discovers that what the gate actually provided was somebody to blame.

## Throwing it over the wall

The gate has a matching posture on the other side, and it has a name: **throwing it over the wall.**
Work is finished, handed across, and forgotten; whatever comes back is a new problem. The wall is the
real defect in this arrangement. On one side, people who know how the code works and do not test it; on
the other, people who test it and do not know how it works. Neither side can see the whole, and both
can point at the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l05-gate-or-loop\" aria-label=\"Two arrangements. Top: a gate at the end. Rule, code and finished run left to right; then a wall, then a box marked QA approves, then release; an arrow labelled defects, sent back returns from the gate to code. Bottom: a tester in every step. Rule, code, finished and release run left to right, and under each one the tester does something: asks, pairs, explores, informs; at release, Joana decides.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a gate at the end</text><rect x=\"20.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rule</text><rect x=\"130.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">code</text><rect x=\"240.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finished</text><path d=\"M111.0 58.0 L129.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M221.0 58.0 L239.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M352.0 32.0 L352.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"4\" fill=\"none\"></path><text x=\"352.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the wall</text><path d=\"M331.0 58.0 L380.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"40.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"437.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">QA approves?</text><path d=\"M493.0 58.0 L539.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"541.0\" y=\"40.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">release</text><path d=\"M437 77 L437 118 L175 118 L175 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"306.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">defects, sent back</text><text x=\"20.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a tester in every step</text><rect x=\"20.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rule</text><path d=\"M82.0 231.0 L82.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"32.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">asks</text><rect x=\"185.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"247.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">code</text><path d=\"M146.0 212.0 L184.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M247.0 231.0 L247.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"197.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"247.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pairs</text><rect x=\"350.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">finished</text><path d=\"M311.0 212.0 L349.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M412.0 231.0 L412.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"362.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">explores</text><rect x=\"515.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">release</text><path d=\"M476.0 212.0 L514.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M577.0 231.0 L577.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"527.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">informs</text><text x=\"577.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Joana decides</text></svg>", "caption": "Above, everything reaches the tester at once, at the end, across a wall. Below, the tester is in each step, and the release is the product owner’s decision with the tester’s information in it."}
```

## What replaces the gate

Not nothing. The release decision still has to be made, by somebody, with the best information
available. What changes is who makes it, what the tester contributes to it, and when.

- **The decision to ship belongs to whoever owns the product.** At Cine Aurora that is Joana. She
  weighs what the tester found against what the cinema needs, and she is the one who knows both.
- **The tester's contribution is information**, delivered as early as possible, about what is known,
  what is not known, and what the risks are. The next section is about what that means in practice.
- **Quality is the whole team's job**, and the tester's particular skill is making it easier for
  everybody else to do theirs. The section after next describes what that looks like in a week.

None of this makes the tester less important. It makes them important for a different reason: not
because they can stop a release, but because the release is a better decision with them in the room.
