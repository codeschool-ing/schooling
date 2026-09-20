---
title: PowerPoint, where the slide is not where the design lives
version: 1
---

PowerPoint's model is the same shape as Word's and people miss it for the same reason. **A slide
is a layout filled in**, and the layout lives in the *slide master* — one place, applying to every
slide that uses it.

A **placeholder** is a box the layout put there. A **text box** is one you drew yourself. They
look identical and they are not the same object at all.

| | a placeholder | a text box you drew |
|---|---|---|
| where its font comes from | the layout | wherever you set it |
| changes when the master changes | yes | no |
| appears in the outline view | yes | no |
| read by a screen reader in order | yes | last, or not at all |
| survives a change of template | yes | it moves or overlaps |

**The single most common way a deck becomes unmaintainable** is somebody deleting a placeholder
and drawing a text box in its place because it was easier to move. Everything above stops being
true for that slide, and nothing says so.

## What the master buys you

Change the font on the master and the whole deck changes. Change the logo position once. Apply
the company template and every slide adapts, because every slide is a layout and the template is
a set of layouts.

Working the other way — a deck of hand-drawn boxes — means applying a template changes the
background and nothing else, and you reposition ninety slides by hand.

## The honest part about slide design

The advice is old and it is mostly true:

- **A slide is not a document.** If it can be read, it is being read instead of you. Notes exist
  for the sentences.
- **One idea per slide**, and the title says the idea rather than naming the topic. *Sales fell
  in the second quarter* is a title; *Sales* is a filing label.
- **Large type.** Twenty-four points is a floor, and the real test is whether it reads from the
  back of the room you will actually be in.
- **Contrast beats decoration**, and it is the same WCAG arithmetic as any screen: light text on
  a photograph needs a darkened band behind it, not hope.

And the one that is not about design: **the deck is the handout as often as it is the talk.**
If it is going to be read alone afterwards, the sentences have to be somewhere — which is what
the notes pane is for, and what exporting notes pages produces.

## Presenting, in four facts

- **Presenter view** shows your notes, the next slide and a clock on your screen while the
  audience sees only the slide. It is the whole reason to plug in rather than mirror.
- **`F5` starts from the beginning, `Shift+F5` from the current slide.** The second is the one
  you want while building.
- **Press `B` to black the screen.** For the moment somebody asks a question and the slide is a
  distraction.
- **Export to PDF for sending.** It removes the font problem, the animation problem and the
  version problem in one step, and nobody needed to edit it.

## And the thing to check before it matters

**Fonts do not travel inside a `.pptx` unless you embed them.** A deck built in a font the other
machine lacks is re-laid-out on that machine, which moves every line and breaks every carefully
positioned box — in the room, in front of people.

*Save, Options, Embed fonts in the file* solves it, and a PDF solves it more completely. For
anything being presented from a machine that is not yours, send the PDF as well.
