---
title: The rules this platform is held to
version: 1
---

The page you are reading is held to the rules in this lesson, by machines, on every change.

## The interface

This school's interface is checked with **axe**, an open-source accessibility engine, at **WCAG 2.2
AA**, on every screen, in **both the light and the dark theme**. The check runs in the repository's
continuous integration, so a change that drops a label's contrast below 4.5:1 fails before it reaches
a student.

Its first run found a case this lesson would recognise. A locked course card had been faded with
transparency to say "you cannot have this", and the fading took its own text to **4.09:1 in the dark
theme and 3.32:1 in the light one**. The fix was the one this lesson teaches: say "locked" in words and
draw a dashed border, and never rely on a fade.

## The figures

axe measures the page, and **it cannot see inside a drawing**: text drawn within an SVG figure is
invisible to it. So the figures have checks of their own:

- every text label inside every figure is measured against what is behind it, **in both themes, at
  AA**;
- every colour a figure names must exist in the palette, because a missing one renders the shape
  invisible with no error at all;
- every figure carries a **text description** for screen readers, like the ones the previous section
  described, and its translation carries its own.

## What no machine checks

Whether a description says the right thing, whether a highlight points at what matters, whether a chart
still works when its colours fail: those are judgements, and they are why this lesson exists. **The
machines catch the measurable failures so that people can spend their attention on the rest.** That is
the arrangement to aim for in your own work: automate the contrast check, and keep the judgement.

## Doing the same in your work

- **Run a contrast checker** on your palette once, and keep the results with the palette.
- **Simulate colour blindness** on every dashboard before it is shared.
- **Write the text alternative** at the same time as the title, while the finding is fresh.
- **Ask someone** who uses a screen reader or has a colour vision deficiency to try your most important
  report. No checklist replaces that.
