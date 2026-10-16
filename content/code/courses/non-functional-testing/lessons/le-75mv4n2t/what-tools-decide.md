---
title: What a tool can decide
version: 1
---

Lesson 12 planted eight defects. Here is who found them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l13-who-finds\" aria-label=\"The eight defects of book.html against three columns: axe with the WCAG tags, Lighthouse, and what was left for a person. axe found four: the missing lang, the grey note, the logo without alt and the name field without a label. Lighthouse found those four and the positive tabindex. Nothing reported the removed focus outline or the div used as a button, which lesson 14 tests with the keyboard, or the error shown only in red, which lesson 15 tests with a screen reader.\"><text x=\"430.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">axe, WCAG tags</text><text x=\"540.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Lighthouse</text><text x=\"650.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">left for a person</text><rect x=\"24.0\" y=\"42.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"70.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no lang on &lt;html&gt;</text><circle cx=\"430.0\" cy=\"56.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"56.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"56.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"78.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"70.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">grey note, 2.85:1</text><circle cx=\"430.0\" cy=\"92.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"92.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"92.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"114.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"70.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">focus outline removed</text><circle cx=\"430.0\" cy=\"128.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"128.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"117.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lesson 14</text><rect x=\"24.0\" y=\"150.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"70.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">logo without alt</text><circle cx=\"430.0\" cy=\"164.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"164.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"164.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"186.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"70.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">name field without a label</text><circle cx=\"430.0\" cy=\"200.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"540.0\" cy=\"200.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"200.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"222.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"70.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">tabindex=&quot;1&quot;</text><circle cx=\"430.0\" cy=\"236.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"236.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"650.0\" cy=\"236.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"24.0\" y=\"258.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"70.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Book is a &lt;div&gt;</text><circle cx=\"430.0\" cy=\"272.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"272.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"261.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lesson 14</text><rect x=\"24.0\" y=\"294.0\" width=\"690.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"70.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">error only in red</text><circle cx=\"430.0\" cy=\"308.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><circle cx=\"540.0\" cy=\"308.0\" r=\"7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></circle><rect x=\"600.0\" y=\"297.0\" width=\"100.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">lesson 15</text><text x=\"360.0\" y=\"352.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">filled: reported · hollow: not reported</text></svg>", "caption": "Who found which defect. The three that stop a keyboard or a screen reader user booking a seat are the three no tool reported."}
```

**Four for axe, five for Lighthouse, and three that no tool reported.** That is not bad luck with
this page. It is the shape of automated accessibility testing, and it follows from what a program
can know.

## Decidable from the document

A rule can decide what the document says on its own. An `<img>` either has an `alt` or it does
not. An input either has a label the browser can compute or it does not. Two colours have a
ratio, and the ratio is over 4.5 or under. Those are facts about the markup and the computed
styles, and axe's rules are exactly those facts, which is why **when axe reports a violation it is
nearly always right**. Deque designs its rules to report nothing it is not sure of, and to put
the rest in `incomplete`.

## Not decidable from the document

What a rule cannot decide is anything that needs to know what the page is **for**:

- **Whether a control works.** `book.html`'s `<div>` has a click handler. Nothing in the document
  says it is the button that books the seat, so no rule can say a keyboard user needs to reach it.
  A real `<button>` with no handler would pass every rule and do nothing.
- **Whether the focus can be seen.** `outline: none` is legal CSS, and a page may draw focus some
  other way: a background, a border, a shadow. A rule cannot tell a missing indicator from a
  different one, so it says nothing.
- **Whether an order makes sense.** The tab order is computable; whether it matches the order a
  person reads and fills in the form is a judgement.
- **Whether a name is right.** `alt="boxoffice"` passes. So does `alt="image"`, and so does
  `alt="a red rectangle"`. A rule checks that the name exists, not that it says what the picture
  says.
- **What happens later.** The red border appears only after Book is pressed with an empty name. An
  audit of the page as it loads never sees the error state at all, and an audit of the error
  state sees a coloured border, which is not a violation of anything a rule can check.

How large the undecidable share is depends on how you count. Deque's own study of its audits
found automated rules catching a little over half of the issues by **number**, because the
decidable ones, contrast above all, are also the commonest. Counted by **success criterion**, a
large part of WCAG 2.2 AA has no rule that can decide it, and the platform this course runs on
writes its estimate into the head of its accessibility suite: perhaps a third of WCAG, "and it
is the third that regresses silently". Either way, the number that matters is the one in the
picture above: the defects that stop somebody booking a seat were the ones no tool reported.

## The false sense of security

**A green audit is evidence that a list of rules passed, and nothing else.** The danger is a
report that reads "0 violations" or "Accessibility: 90" ending up as the line in a release note
that says the page is accessible. Three things keep the claim honest:

- **Say which tool, which rules, which states.** "axe 4.13.0, WCAG 2.2 A and AA tags, `book2.html`
  as loaded: 0 violations" is a true sentence. "Accessible" is not a test result.
- **Pair every automated gate with a manual pass on the same pages**: the keyboard, lesson 14, and
  a screen reader, lesson 15. The tool runs on every commit; the manual pass runs when a page
  changes and before a release.
- **Write the manual findings down as tests where you can.** Lesson 14 turns "the Book button can
  be reached and pressed with the keyboard" into a script, and once it is a script it is a gate
  like `audit.js`.

The suite this school runs over its own screens says the same thing in its header: axe finds what
is decidable from the document, and what it does not find, "those are read by a person, and saying so
here is the difference between a check and a claim of compliance."
