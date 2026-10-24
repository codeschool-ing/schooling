---
title: Levels A, AA and AAA
version: 1
---

**Every success criterion carries a level, A, AA or AAA, and a page conforms at a level when it meets
every criterion of that level and of the levels below it.** The levels sort the criteria by how much they
matter and how much they cost, not by difficulty for the developer.

| level | what it holds | in WCAG 2.2 | for example |
|---|---|---|---|
| **A** | the barriers that shut people out completely | 31 criteria | 1.1.1 Non-text Content: an image that carries meaning has a text alternative |
| **AA** | the barriers that make a page hard to use for many people | 24 more, 55 in all | 1.4.3 Contrast (Minimum): text is at least 4.5:1 against its background |
| **AAA** | refinements that help some people a great deal and cannot always be met | 31 more, 86 in all | 1.4.6 Contrast (Enhanced): at least 7:1 |

**AA is the target**, and it is what the laws of the last section but one and almost every organisation's
policy point at. The W3C itself does not recommend requiring AAA for a whole site, because some content
cannot meet some AAA criteria at all. That is not permission to ignore them: a criterion like 2.4.13
*Focus Appearance* costs a few lines of CSS, and lesson 11 meets it anyway.

**A conformance claim is about a page, complete.** "Mostly AA" is not a level; one failing criterion and
the page conforms at the level below, or not at all. That is why this course tests the planner's pages
whole, with a machine for what a machine can decide and a person for the rest.
