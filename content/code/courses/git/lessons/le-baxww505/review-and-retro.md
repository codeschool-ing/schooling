---
title: Review and retrospective
version: 1
---

The sprint ends with two meetings that are easy to confuse, because both look back. **The review looks at the
product; the retrospective looks at the team.**

## The sprint review

The people who asked for the work (the bakery's owner, the product owner, anybody who uses the site) see
what was finished, **working, not on slides**. Ana orders a loaf for 07:30 on her phone and pays by Pix, in
front of them.

What makes it worth an hour is the feedback: *"Can the confirmation say the pickup time again?"* That is a new
ticket for the backlog, found two weeks after the work started instead of two months after it was released.
A review where nobody outside the team comes, or where nobody is allowed to change their mind, is a demo, and
it has lost the point.

Only work that meets the definition of done is shown. Showing the half-finished card-payment screen invites
feedback on something that is not ready, and makes it look nearly done when it is not.

## The retrospective

Then the team, alone, looks at **how it worked**. The simplest format asks three questions:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A retrospective board with three columns. Went well: pickup times shipped, and reviews within a day. Did not go well: 35 started with no criteria, a missing picture found in review, and stand-ups ran to 30 minutes. Try next sprint, two actions, each with an owner: no ticket enters a sprint without acceptance criteria, owned by Carla; check-links.sh runs on every pull request, owned by Bruno.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">went well</text><rect x=\"30\" y=\"50\" width=\"200\" height=\"31\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pickup times shipped</text><rect x=\"30\" y=\"91\" width=\"200\" height=\"31\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reviews within a day</text><rect x=\"260\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">did not go well</text><rect x=\"270\" y=\"50\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">#35 started with</text><text x=\"280\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no criteria</text><rect x=\"270\" y=\"106\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">missing picture</text><text x=\"280\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">found in review</text><rect x=\"270\" y=\"162\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stand-ups ran</text><text x=\"280\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">to 30 minutes</text><rect x=\"500\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">try next sprint</text><rect x=\"510\" y=\"50\" width=\"200\" height=\"61\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no ticket enters a sprint</text><text x=\"520\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">without criteria</text><text x=\"520\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">owner: Carla</text><rect x=\"510\" y=\"121\" width=\"200\" height=\"61\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">check-links.sh runs on</text><text x=\"520\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every pull request</text><text x=\"520\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">owner: Bruno</text></svg>", "caption": "Three problems, two actions, each with a name beside it. The stand-up running long waits for another retro; trying to fix everything at once fixes nothing."}
```

Three rules make it useful rather than a complaint session:

- **Blameless.** The question is what about the process let #35 start without criteria, not who started it.
  Many retros open by reading one line: everybody did the best they could with what they knew at the time.
  It is what makes people willing to say what actually went wrong.
- **Few actions, each with an owner.** Two changes that happen are worth more than eight that do not. The
  bakery picks two: Carla will refuse tickets without acceptance criteria at planning, and Bruno will put
  `check-links.sh` into CI, which is lesson 17's workflow.
- **Start with the last retro's actions.** Did they happen? Did they help? A retro that never checks its own
  actions teaches the team that nothing said in it matters.

## The cost of meetings

Four people in a one-hour meeting is four hours of work. That is worth paying when the meeting prevents a
week of wrong work, and not otherwise. The test for any recurring meeting is the question this lesson opened
with: **what would go wrong without it?** If nobody can answer, try a sprint without it, and bring it back
if something does go wrong.
