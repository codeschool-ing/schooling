---
title: What WCAG is
version: 1
---

Accessibility has the same problem as speed: "it has to be accessible" is a wish, and no test
can fail it. **The Web Content Accessibility Guidelines, WCAG, are what turns the wish into a list
somebody can check.** They are published by the W3C, the body that also standardises HTML and
CSS, and the current version is WCAG 2.2, a W3C Recommendation since 5 October 2023. Lesson 1
wrote the requirement this third works to as "conforms to WCAG 2.2 at level AA on the booking
flow", and this section says what each word of that sentence means.

The common mistake is to picture a list of tips: add alt text, make the buttons big. WCAG is
closer to a specification. Each item in it is a statement about a page that is either true or
false, written so that two testers looking at the same page reach the same verdict. That is what
lets it sit in a contract.

## Four principles, thirteen guidelines, success criteria

WCAG is built in three layers, and only the last one is tested.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l12-layers\" aria-label=\"WCAG 2.2 in three layers. Four principles: perceivable, with 4 guidelines and 29 success criteria; operable, with 5 guidelines and 34; understandable, with 3 guidelines and 21; robust, with 1 guideline and 2. Only the success criteria are tested, for example 1.4.3 Contrast (Minimum), level AA. Below, the levels nest: 31 criteria at A, 24 more at AA for 55 in all, and 31 more at AAA for 86.\"><defs><marker id=\"l12-layers-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">principle</text><text x=\"330.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">guidelines</text><text x=\"560.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">success criteria</text><rect x=\"40.0\" y=\"52.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">perceivable</text><path d=\"M184.0 69.0 L246.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"52.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.1 – 1.4</text><text x=\"372.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 guidelines</text><path d=\"M414.0 69.0 L466.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"52.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">29</text><text x=\"590.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.4.3 · AA</text><rect x=\"40.0\" y=\"98.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">operable</text><path d=\"M184.0 115.0 L246.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"98.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.1 – 2.5</text><text x=\"372.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 guidelines</text><path d=\"M414.0 115.0 L466.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"98.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">34</text><text x=\"590.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.1.1 · A</text><rect x=\"40.0\" y=\"144.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">understandable</text><path d=\"M184.0 161.0 L246.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"144.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.1 – 3.3</text><text x=\"372.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 guidelines</text><path d=\"M414.0 161.0 L466.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"144.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">21</text><text x=\"590.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.3.1 · A</text><rect x=\"40.0\" y=\"190.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">robust</text><path d=\"M184.0 207.0 L246.0 207.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"190.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1</text><text x=\"372.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 guideline</text><path d=\"M414.0 207.0 L466.0 207.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"190.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"590.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1.2 · A</text><text x=\"560.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">only these are tested</text><rect x=\"40.0\" y=\"266.0\" width=\"640.0\" height=\"80.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"50.0\" y=\"276.0\" width=\"400.0\" height=\"60.0\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"286.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A · 31 criteria</text><text x=\"340.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AA · 24 more, 55 in all</text><text x=\"565.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AAA · 31 more, 86</text></svg>", "caption": "Principles hold guidelines, guidelines hold success criteria, and only a criterion passes or fails. Conforming at AA means meeting every criterion in the two inner boxes."}
```

**The principles** are four, known by their initials as POUR. Content has to be:

| principle | the question | an instance on the booking page |
|---|---|---|
| **perceivable** | can every user take in what is there, whatever sense they use? | the logo needs a text alternative a screen reader can say |
| **operable** | can every user work every control? | the Book control has to answer the keyboard, not only the mouse |
| **understandable** | can every user follow it and recover from a mistake? | an empty name field needs an error that says what to do |
| **robust** | does it work with the browsers and assistive technologies people actually use? | a control has to expose its name and role to them |

**The guidelines** sit under the principles, thirteen of them: 1.1 Text Alternatives, 1.4
Distinguishable, 2.1 Keyboard Accessible, 2.4 Navigable, 3.3 Input Assistance and so on. A
guideline is a goal, and it has no level and no pass or fail of its own.

**The success criteria** are what a test checks. Each one has a number, a short name, a level and
a sentence that a page meets or does not. *1.4.3 Contrast (Minimum)*, level AA, says that text has
a contrast ratio of at least 4.5:1 against its background, with exceptions for large text, logos
and text that is pure decoration. **The number is the address you write in a defect report**:
"fails 1.4.3" names one sentence in one standard, and nobody has to argue about what was meant.
WCAG 2.2 has 86 of them.

## Levels A, AA and AAA

Every success criterion carries one of three levels, and the levels nest:

- **A** is the floor. Without it, some people cannot use the page at all: an image with no text
  alternative (1.1.1), a control that needs a mouse (2.1.1), a page whose language is not declared
  (3.1.1).
- **AA** adds what removes the commonest serious barriers: the 4.5:1 contrast (1.4.3), a visible
  focus indicator (2.4.7), text that can be enlarged to 200% (1.4.4).
- **AAA** is the strictest: 7:1 contrast (1.4.6), sign language for recorded video (1.2.6).

Conformance is claimed per page, and at a level. A page conforms at AA when it meets every A
criterion and every AA criterion, 55 in WCAG 2.2. There is no partial credit and no average: a
booking page that meets 54 of them does not conform, which is the same rule as the five parts of
a performance requirement in lesson 1. One further rule is easy to miss: a process conforms only
when every page in it does, so a booking flow with one bad step fails as a whole.

**The W3C itself does not recommend AAA as a target for whole sites**, because some content
cannot meet some AAA criteria at all. AAA is a set to reach for where it fits: a public service
whose users are older, say, can choose 7:1 contrast on purpose.

## What changed in 2.2

WCAG versions are backwards compatible: a page that meets 2.2 meets 2.1 and 2.0 at the same level.
2.1, in 2018, added criteria for phones and for low vision, such as *1.4.10 Reflow* and *1.4.11
Non-text Contrast*. **2.2 added nine criteria and removed one.** The ones a tester meets on a
booking page:

| criterion | level | what it asks |
|---|---|---|
| 2.4.11 Focus Not Obscured (Minimum) | AA | the control with the focus is not entirely hidden by something the page drew, such as a sticky banner |
| 2.5.7 Dragging Movements | AA | anything done by dragging can also be done with single clicks or taps |
| 2.5.8 Target Size (Minimum) | AA | a target is at least 24 by 24 CSS pixels, or has that much space around it |
| 3.3.8 Accessible Authentication (Minimum) | AA | signing in does not depend on remembering or transcribing something, such as a puzzle, unless there is another way or help such as letting the browser paste the password |
| 3.3.7 Redundant Entry | A | what a user already typed in this process is not asked for again |
| 3.2.6 Consistent Help | A | help, where a site offers it, is in the same place on every page |

The other three are 2.4.12 and 2.4.13, two stricter AAA versions of the focus criteria, and 3.3.9,
the AAA version of accessible authentication. **4.1.1 Parsing is gone**: it asked for valid markup,
and browsers now repair broken markup the same way everywhere, so it no longer protected anybody.
An audit report written against 2.1 that lists a 4.1.1 failure is reporting something 2.2 does
not test.

Lesson 13 runs an automated audit against these criteria, and lesson 14 tests the operable ones
by hand, with the keyboard. This lesson writes the page they test.
