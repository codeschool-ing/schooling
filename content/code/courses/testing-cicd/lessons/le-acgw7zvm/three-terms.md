---
title: Integration, delivery, deployment
version: 1
---

Three phrases share the abbreviation CI/CD, and people use them loosely. They name three different
promises, and the difference between the last two is one decision: **who presses the button that
puts a change in front of users.**

- **Continuous integration**, lessons 5 and 6: every change is merged often and checked
  automatically. The output is a verdict, green or red, on the code.
- **Continuous delivery**: every change that passes is turned into a release **that could go to
  production at any moment**, and is proved deployable by being deployed somewhere like production.
  A person decides when it goes live, and going live is a routine act that takes minutes.
- **Continuous deployment**: every change that passes goes to production **automatically**, with no
  person in the way. The pipeline is the release process.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three rows compare the practices. Continuous integration goes from merge to test and stops there. Continuous delivery goes from merge to test to staging, then a person decides before production. Continuous deployment goes the same way with no person: production follows automatically.\"><text x=\"136\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">integration</text><rect x=\"150\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">test</text><path d=\"M260 50 L279 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 46 L285 50 L278 54 z\" fill=\"var(--paper-dim)\"></path><text x=\"136\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">delivery</text><rect x=\"150\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">test</text><path d=\"M260 125 L279 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 121 L285 125 L278 129 z\" fill=\"var(--paper-dim)\"></path><rect x=\"420\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">staging</text><path d=\"M395 125 L414 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M413 121 L420 125 L413 129 z\" fill=\"var(--paper-dim)\"></path><rect x=\"590\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">production</text><path d=\"M530 125 L584 125\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M583 121 L590 125 L583 129 z\" fill=\"var(--amber)\"></path><circle cx=\"560.0\" cy=\"125\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"560.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a person decides</text><text x=\"136\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">deployment</text><rect x=\"150\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">test</text><path d=\"M260 200 L279 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 196 L285 200 L278 204 z\" fill=\"var(--paper-dim)\"></path><rect x=\"420\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">staging</text><path d=\"M395 200 L414 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M413 196 L420 200 L413 204 z\" fill=\"var(--paper-dim)\"></path><rect x=\"590\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">production</text><path d=\"M530 200 L584 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M583 196 L590 200 L583 204 z\" fill=\"var(--phosphor)\"></path><text x=\"560.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">automatic</text></svg>", "caption": "The three practices share their first steps. They differ in where they stop, and in who moves a release into production."}
```

A common wrong picture is that continuous delivery is continuous deployment done badly, by a team
that has not yet dared to automate the last step. They are different choices. A team practising
continuous delivery can release any green commit within the hour; it simply chooses when. What it
must never have is a release that needs a week of preparation, because that is a team that cannot
deliver continuously at all, whatever its pipeline says.

## What both require

Everything after integration rests on four things, and this lesson builds each of them for
`shipquote`:

1. **One artifact**, built once from a commit, identified by its content, and promoted unchanged
   from environment to environment (sections 03 and 04).
2. **A pipeline** that takes that artifact through its stages in a fixed order (section 05).
3. **A deploy that is a command**, not a procedure in somebody's head, and that checks its own
   result (sections 06 and 07).
4. **A gate** where the decision is made, by a person or by a rule (section 08).

The lab keeps them small. An environment here is a directory with its own configuration and a
process on its own port; lesson 8 says what real environments add. What does not shrink is the
order and the checks: they are the same on one laptop and in a datacentre.
