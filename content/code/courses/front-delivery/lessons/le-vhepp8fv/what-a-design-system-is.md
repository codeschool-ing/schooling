---
title: What a design system is, and what it is not
version: 1
---

**A design system is the set of decisions a product's interface is built from, written down so that
people and code can reuse them instead of making them again.** It has three layers, and teams that say
they have one usually have the first and mean all three:

1. **tokens**: the smallest decisions, named. A colour, a size, a gap, a radius. This lesson.
2. **components**: buttons, fields, cards, built only from tokens, documented with every state they can
   be in. Lessons 6 and 8.
3. **the rules around them**: who may change a token, how a change reaches the products that use it, and
   how a product learns that a component it uses is about to go. Lesson 7.

The common picture is a design system as a library of pretty components, often bought or copied from a
company that published theirs. That is a **UI kit**, and it is the visible end of the thing. A kit
without tokens is a set of components with hard-coded colours, which a dark theme or a rebrand has to edit
one by one; a kit without rules is a folder that five teams fork in five directions within a year.

## Why it is a delivery problem

This course is about shipping, and these four lessons sit in it for a reason. A design system's value is
not that it looks consistent on the day it is written. It is that **a change made once reaches every
screen that uses it, and nothing else**. The brand green changes on a Tuesday, and every button, link and
focus ring in three products changes with it, through a version bump and a build, with no screen edited
by hand. That is a delivery pipeline, for decisions rather than code.

## What the planner gets

The planner is small enough to show every layer of this without the noise of a real product:

- in this lesson, **its tokens**, as a JSON file and the CSS generated from it, with a light and a dark
  theme and a check that every colour pair is readable;
- in lesson 6, **its components** documented in Storybook;
- in lesson 7, **the tokens and components as a package** with a version, published to a registry;
- in lesson 8, **one component as a Web Component**, usable from any framework.

None of it depends on a framework, and that is deliberate: a design system serves every product in a
company, and those products rarely agree on one.
