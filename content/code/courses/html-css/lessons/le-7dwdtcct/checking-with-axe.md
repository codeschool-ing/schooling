---
title: Checking a page with axe
version: 1
---

Lesson 1 checked HTML against the rules of the language. **axe** checks it against rules about accessibility: an image with no text alternative, a field with no label, a page with no main landmark, text whose colour is too close to its background. It is the engine inside the accessibility checks of Chrome's Lighthouse and of many browser extensions, and this repository runs it on every screen of the platform you are reading this on. `probe axe` runs version 4.13.0 against the page, with the rules for WCAG 2.2 at level AA, the standard most laws point to, plus axe's own best practices.

Here is the soup page:

```
ana@laptop:~/site$ probe soup.html axe
landmark-one-main (moderate, 1 element): Document should have one main landmark
page-has-heading-one (moderate, 1 element): Page should contain a level-one heading
region (moderate, 3 elements): All page content should be contained by landmarks
target-size (serious, 3 elements): All touch targets must be 24px large, or leave sufficient space
```

Four rules, and three of them are this lesson: **landmark-one-main**, no `<main>`; **page-has-heading-one**, no `<h1>`; **region**, three elements outside every landmark. The fourth, **target-size**, is about the three links of the menu, and the next run shows why. Here is the semantic page, with the menu's links measured after the rules:

```
ana@laptop:~/site$ probe semantic.html axe box "nav a"
target-size (serious, 3 elements): All touch targets must be 24px large, or leave sufficient space
a  x 48     y 50     width 43.55  height 17
a  x 48     y 68     width 84.42  height 17
a  x 48     y 86     width 94.66  height 17
```

The structure rules are gone. **target-size** is still there, and the boxes say why: each link is 17 pixels tall and the next one starts 18 pixels below it. WCAG 2.2 asks for targets of at least 24 by 24 pixels, or enough space around a smaller one, so that a finger or an unsteady hand hits the one it meant. That is correct to leave for later, because making a link bigger is not a matter of which element it is in. It is CSS, padding on the links, which is lesson 6.

## What a pass does not mean

axe reports what a program can decide by reading the page. It cannot tell whether a heading describes what is under it, whether `alt` text says the right thing, whether the order in which Tab moves makes sense, or whether a link's text is clear: *Click here* is a name, and axe accepts it. Automated checks find only part of what is wrong with a page; how much depends on the page, and published estimates run from about a third to about a half. **A page with no violations has passed the part a machine can check**, and the rest is still somebody's job: try the page with only the keyboard, and listen to it with a screen reader. Both are built into every operating system: VoiceOver on macOS and iOS, Narrator on Windows, TalkBack on Android, Orca on Linux.
