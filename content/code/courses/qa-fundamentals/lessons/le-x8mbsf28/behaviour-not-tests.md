---
title: Behaviour, not tests
version: 1
---

**Behaviour-driven development, BDD, grew out of TDD when people noticed that the word *test* was getting in
the way.** Dan North was teaching TDD in the early 2000s and kept meeting the same questions: where to start,
what to test, what to call a test, how much to test in one go. In an article called *Introducing BDD*, in 2006,
he proposed answering all of them by talking about **behaviour** instead: what should the software do, in this
situation, for this person?

That change of word did more than it sounds. "Write a test for the coupon function" is a sentence only a
developer can act on. "Describe how a coupon should behave" is a sentence Joana can answer, and Célia can
correct. BDD is the set of habits that grew around that: describing behaviour in **examples**, in **a language
the whole team shares**, before the code is written.

## Three practices, in order

Writers on BDD usually split it into three practices, and the order matters.

| practice | what happens | who |
|---|---|---|
| **discovery** | the team talks through a story with concrete examples, until the rule is understood and the open questions are known | product owner, developer and tester together |
| **formulation** | the examples that matter are written down in a structured, readable form | usually the tester or the developer, read back by the product owner |
| **automation** | the written examples are wired to the code, so they run as checks | developers, often with the tester |

Most of the value is in the first one. A team that only automates has a test tool with an unusual syntax. A team
that only discovers has better conversations and nothing to show for them later. Formulation is the bridge: the
written example is the record of the conversation, and the automation keeps it honest.

## A shared language

North borrowed an idea from Eric Evans's *Domain-Driven Design*: the **ubiquitous language**, the words a
business uses for its own things, used everywhere, in conversation, in documents and in code. At Cine Aurora
that means *session*, *matinée*, *half price*, *order*, *coupon*. Not *transaction*, not *discount flag*, not
*price tier 2*.

It sounds like a matter of taste and it is a matter of defects. In lesson 8, the order program called the
refused orders *orders* too, because nobody had asked what an order was. A team that has agreed that an order is
something a customer paid for would have seen at once that a refused order is not one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 200\" role=\"img\" data-fig=\"l16-three\" aria-label=\"Three BDD practices in order, left to right. Discovery: talk through examples; Joana, Rafael and Lia; it produces questions answered, and most of the value. Formulation: write the ones that matter; Lia, read back by Joana; it produces a feature file. Automation: wire them to the code; Rafael, with Lia; it produces scenarios that run daily.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"105.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">discovery</text><text x=\"105.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">talk through examples</text><text x=\"105.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Joana, Rafael, Lia</text><path d=\"M202.0 58.0 L228.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M105.0 98.0 L105.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">questions answered</text><rect x=\"230.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">formulation</text><text x=\"325.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write the ones that matter</text><text x=\"325.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lia, read back by Joana</text><path d=\"M422.0 58.0 L448.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M325.0 98.0 L325.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"240.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a feature file</text><rect x=\"450.0\" y=\"20.0\" width=\"190.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"44.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">automation</text><text x=\"545.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wire them to the code</text><text x=\"545.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Rafael, with Lia</text><path d=\"M545.0 98.0 L545.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"460.0\" y=\"124.0\" width=\"170.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">scenarios that run daily</text><text x=\"105.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">most of the value</text></svg>", "caption": "Discovery, formulation, automation. A team that only automates has a test tool with an unusual syntax."}
```

## What a tester brings

BDD needs the tester's habits most in discovery, which is exactly where lesson 12's acceptance criteria and
lesson 2's questions already put them: the boundary, the combination, the input nobody mentioned, what happens
afterwards. The difference BDD makes is the destination. Those questions and their answers do not end in a
meeting's notes. They end as scenarios in a file, in the team's language, that run against the code every day.
