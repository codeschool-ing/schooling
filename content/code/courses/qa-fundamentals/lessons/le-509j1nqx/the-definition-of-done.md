---
title: The definition of done
version: 1
---

**The definition of done is the team's shared statement of what has to be true before any piece of work
counts as finished.** The Scrum Guide calls it a formal description of the state of the increment when it
meets the quality measures required for the product. In plain words: the bar, written down, that every story
has to clear, the same bar for every story.

Without one, "done" means whatever the person saying it meant: Rafael's done is "the code is written",
Lia's is "I have tested it", Joana's is "customers can use it". Three people reporting the same story as done
mean three different things, and the gap between them is where untested work slips into a release.

## Cine Aurora's

After the sprint where three stories reached Lia on day nine, the team wrote this one:

> A story is done when:
> 1. the code has been reviewed by another developer;
> 2. its acceptance criteria each have a test, and the tests pass;
> 3. the automated checks for everything built before still pass;
> 4. Lia, or another developer, has explored it for at least half an hour beyond the criteria;
> 5. any question it raised about a rule has an answer from Joana, written as an example;
> 6. it is in the version that could be released today, without anyone remembering to do something first.

Each line exists because of something that went wrong. Line 3 is lesson 10's regression pile. Line 4 exists
because acceptance criteria only cover what was thought of, and lesson 6 found the Wednesday stacking by
looking past them. Line 5 is the Wednesday answer, turned into a habit. Line 6 is the one teams most often
leave out, and it is what "usable increment" means.

## Definition of done and acceptance criteria

The two are often confused, and the difference is simple:

- the **definition of done** applies to **every** story: the same six lines, whatever the story is about;
- **acceptance criteria** apply to **one** story: what this particular piece of work has to do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" data-fig=\"l12-done\" aria-label=\"A large frame labelled definition of done, every story, lists six conditions: reviewed, criteria tested, old checks pass, explored, answers written, releasable. Inside it sit three stories: students pay half, older customers pay half, coupons. Each story carries its own small box of acceptance criteria, for that story only.\"><rect x=\"10.0\" y=\"10.0\" width=\"640.0\" height=\"230.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"24.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">definition of done: every story</text><text x=\"24.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ reviewed</text><text x=\"234.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ criteria tested</text><text x=\"444.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ old checks pass</text><text x=\"24.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ explored</text><text x=\"234.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ answers written</text><text x=\"444.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ releasable</text><rect x=\"30.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"122.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">students pay half</text><rect x=\"42.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M54.0 150.0 L190.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M54.0 166.0 L190.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M54.0 182.0 L190.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"235.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">older customers pay half</text><rect x=\"247.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M259.0 150.0 L395.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M259.0 166.0 L395.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M259.0 182.0 L395.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"440.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"532.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">coupons</text><rect x=\"452.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M464.0 150.0 L600.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M464.0 166.0 L600.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M464.0 182.0 L600.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">acceptance criteria: this story only</text></svg>", "caption": "The definition of done is one bar for every story; acceptance criteria are what one story has to do. A story meets both, or it is not done."}
```

For the story *students pay half*, the acceptance criteria might be: a student at an evening session pays
R$ 18,00; a student at a matinée pays R$ 14,00; a student on a Wednesday pays R$ 18,00, not R$ 9,00. The
definition of done says each of those three must have a passing test, along with everything else on the
list. A story can meet all its acceptance criteria and still not be done, because nobody explored it or
because it broke an older check.

## A definition the team actually keeps

A definition of done is only worth what the team does when a story fails it. The honest outcome is that the
story is not done, goes back to the backlog or stays in progress, and is not shown at the review as finished.
The dishonest outcome, common under deadline pressure, is to call it done anyway and "fix it next sprint",
which is lesson 11's testing debt in its purest form.

A tester's job here is less to police the definition than to keep it honest: point out when a story is being
called done that is not, and bring the gap to the retrospective, where the team can decide whether the
definition is wrong or the sprint was.
