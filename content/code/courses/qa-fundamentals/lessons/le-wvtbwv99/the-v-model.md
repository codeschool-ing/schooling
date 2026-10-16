---
title: The V model
version: 1
---

**The V model takes the waterfall's phases and folds them in half.** The left side goes down, from the
broadest description of the system to the smallest piece of code: requirements, system design,
architecture, module design. The bottom of the V is the code. The right side comes back up, testing at
each level what the matching level on the left described: unit tests, integration tests, system tests,
acceptance tests.

The model came out of systems engineering in the 1980s, in Germany and the United States, for large
government projects, and it is still the official process model of the German federal government under
the name V-Modell XT. It is the waterfall drawn so that **every specification has a test that checks it**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" data-fig=\"l09-v\" aria-label=\"A V shape. The left arm goes down through requirements, system design, architecture and module design to code at the bottom. The right arm goes up through unit testing, integration testing, system testing and acceptance testing. Horizontal dashed lines join each level on the left to the test on the right that checks it: requirements to acceptance testing, system design to system testing, architecture to integration testing, module design to unit testing.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"qa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirements</text><rect x=\"490.0\" y=\"24.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">acceptance testing</text><path d=\"M174.0 40.0 L486.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"330.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tested against</text><path d=\"M60.0 57.0 L80.0 79.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M580.0 79.0 L600.0 57.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"60.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">system design</text><rect x=\"450.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">system testing</text><path d=\"M214.0 96.0 L446.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M100.0 113.0 L120.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M540.0 135.0 L560.0 113.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"100.0\" y=\"136.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">architecture</text><rect x=\"410.0\" y=\"136.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">integration testing</text><path d=\"M254.0 152.0 L406.0 152.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M140.0 169.0 L160.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M500.0 191.0 L520.0 169.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><rect x=\"140.0\" y=\"192.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">module design</text><rect x=\"370.0\" y=\"192.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">unit testing</text><path d=\"M294.0 208.0 L366.0 208.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"255.0\" y=\"248.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">code</text><path d=\"M220.0 225.0 L255.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M405.0 262.0 L440.0 225.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-phosphor)\"></path><text x=\"20.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">described, on the way down</text><text x=\"640.0\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tested, on the way up</text></svg>", "caption": "Each horizontal line is a pair: a description, and the test level whose expected results come from it. The tests on the right can be designed as soon as the description on the left exists."}
```

## Each level, and what it is tested against

The horizontal lines across the V are the point of the drawing. Each one pairs a description with the test
level that checks the system against it:

| left side: what is described | right side: what tests it | the question the test answers |
|---|---|---|
| **requirements**: what the users need | **acceptance testing** | is this what was wanted? |
| **system design**: what the system does as a whole | **system testing** | does the whole system do what was specified? |
| **architecture**: which parts there are and how they talk | **integration testing** | do the parts work together? |
| **module design**: what each piece does | **unit testing** | does each piece do what it should, on its own? |

Each test level has its own **test basis**, the document the expected results come from. A unit test is
judged against the module's design; an acceptance test is judged against the users' needs. A test at the
wrong level answers the wrong question: unit tests that pass say nothing about whether the shop does what
Célia needs.

## Testing designed on the way down

The V's most useful idea is about time. The right side is *executed* after the code exists, but it can be
*designed* on the way down, as each document on the left is written. When Joana writes the price rule, the
acceptance tests for it can be written the same week. When the architecture says `orders.py` calls
`tickets.py`, the integration tests for that call can be planned before either exists.

That is shift left inside a sequential process. It does not move the running of tests earlier, but it
moves the **thinking** earlier, and thinking about how to test a requirement is the moment ambiguities
like *over-60s* surface. A tester who designs acceptance tests while the requirement is still a draft is
doing prevention, even in the most traditional project there is.

## What the V keeps from the waterfall

It keeps the sequence. Code still arrives all at once, at the bottom; tests still run, level by level, up
the right side; a defect found in acceptance testing still sends the team back to the top-left corner,
months later. The V improves where testing is **designed**, not where it **happens**. The models in the
following lessons attack the second problem, by making the whole V small and running it many times.
