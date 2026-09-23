---
title: The definition of done
version: 1
---

Ask four people on a team when a ticket is done and you can get four answers: when it works for me, when it
is merged, when Diego has tested it, when customers have it. Each one is somebody's honest idea of done,
and the team loses a day every time two of them meet:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Seven rungs of a ladder, from the bottom: it works on my machine, which only the author knows; pushed; reviewed and merged; checks green on a clean machine, done by CI; tested by somebody else, done by QA; released; checked where customers see it. A line above the top rung marks the bakery’s definition of done.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"304\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">it works on my machine</text><text x=\"352\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only the author knows</text><rect x=\"80\" y=\"260\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"94\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pushed</text><rect x=\"120\" y=\"216\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reviewed and merged</text><rect x=\"160\" y=\"172\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">checks green on a clean machine</text><text x=\"472\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CI</text><rect x=\"200\" y=\"128\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tested by somebody else</text><text x=\"512\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"240\" y=\"84\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">released</text><rect x=\"280\" y=\"40\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">checked where customers see it</text><path d=\"M260 34 L700 34\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"700\" y=\"22\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the bakery’s definition of done</text></svg>", "caption": "Every rung is somebody saying done. The team agrees once which rung the word means, and that agreement is the definition of done."}
```

A **definition of done** is the team choosing one rung, once, and writing down what it takes to get there. It
applies to **every** ticket, which is what separates it from acceptance criteria:

| | acceptance criteria | definition of done |
|---|---|---|
| belongs to | one ticket | the whole team |
| says | what *this* change must do | what *every* change must have been through |
| example | the menu shows gluten, milk and eggs | reviewed, checks green, tested by QA, released |

A ticket is done when **both** are met.

## The bakery's, written down

1. Acceptance criteria met.
2. Reviewed and approved by somebody other than the author.
3. Checks green on the pull request.
4. Tested by Diego on the release candidate, on a phone and a computer.
5. Released, and looked at on the live site.
6. Ticket updated, with anything learnt written on it.

Short enough to remember, specific enough that nobody argues about it. It lives in the same
`CONTRIBUTING.md` as lesson 9's workflow, and the board's *done* column means exactly this list.

## What it changes

It changes what "I'm done" means in a stand-up. **Ana's #34 was not done when it worked on her machine, and
it is not done at merge either**; the definition says so in advance, so nobody has to say it to her
afterwards. It also makes estimates honest: a 3-point ticket includes the testing and the release, because
done includes them.

And it moves the cost back where it is cheapest. Each rung of the ladder is a place a problem can be caught,
and **the lower it is caught, the less it costs**: a missing file is one command on Ana's laptop, twenty
minutes of Bruno's time in review, an hour of Diego's in testing, and a customer's trust in production.
