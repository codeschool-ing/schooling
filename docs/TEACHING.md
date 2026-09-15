# How the material is written

`CONTENT.md` is the format — the files, the front matter, the section kinds. `EXERCISES.md` is how
a question is built. This is the craft of the material itself: the prose, the pictures and the
spoken scripts.

It exists for the same reason as the other two. A rule that lives only in somebody's judgement is a
rule that holds for the first course and drifts by the fifth, and this catalogue is 122 courses
written by an agent working with a person — the exact conditions under which drift is invisible
until it is everywhere.

---

## Say it once, unless the second time is a different approach

Repetition is not automatically waste. Saying the same thing twice **the same way** is.

A concept may be met more than once when each meeting does something the last could not:

- prose explains it, and a **diagram** shows a shape the sentence cannot hold;
- prose explains it in general, and a **worked example** puts numbers on it;
- prose explains it, and a **video** shows it happening in sequence;
- an early section introduces it, and a later one **uses** it on harder material.

What is forbidden is the second paragraph that restates the first in new words because the first
felt thin. If a paragraph needs shoring up, the paragraph is wrong — write it once, properly.

**The test:** if you deleted the second treatment, what would the reader lose? If the answer is
"nothing, they read it above", delete it.

---

## When a diagram earns its place

The catalogue's design sweep counted roughly **6,600 diagrams** across 122 courses. A number that
size is reached by drawing pictures nobody needed, so the bar has to be stated.

> **A diagram earns its place when it carries something the prose cannot say in one sentence.**

Four things qualify, and they are worth naming because they are what pictures are *for*:

| | example |
|---|---|
| **a sequence in time** | four exchanges where the fourth depends on the third having returned |
| **a nesting or a boundary** | three endpoints inside one host, one address between them |
| **a count** | fifteen requests overlapping, which prose can only assert |
| **two axes at once** | response time against load, where the *shape* is the argument |

A diagram that restates its own caption is worse than no diagram: it costs drawing, it costs
maintenance, and it teaches nothing. **A picture is not decoration and the page is not improved by
having one.**

Two consequences worth holding:

**Draw the concept, not the product.** A diagram of an idea is right in ten years. A diagram of
somebody's console is wrong when they redesign it, and `VIDEO.md` already carries that distinction
for the screen — it applies to stills as well.

**A diagram is also a question.** `labelling` is one of the eight graders that exist and the one
that fits conceptual material best, and it cannot exist without a picture. When a diagram is
drawn, ask what it now makes askable.

---

## Prose

**Lead with the shape, then the detail.** A reader who stops after the first two paragraphs of a
section should still have gained the thing the section is named for.

**Say what is wrong before saying what is right, where a wrong idea is common.** Most readers of a
beginner course arrive holding a picture. Material that only adds the correct picture leaves both
in their head; material that names the wrong one first replaces it.

**Every claim a reader could doubt gets a concrete instance.** Not an analogy — an instance.
"Fifteen exchanges to load a page" beats "many exchanges", and it can be checked.

**Forward references point at a lesson number, or they do not exist.** "You will meet this later"
is a promise nobody can hold you to; "lesson 6 gives it a vocabulary" is one a reader can act on
and a reviewer can verify.

**A lesson number, and never a position in the course.** The lesson screen numbers sections
**within** a lesson — `ui/app/screens/lesson.js` draws `String(i + 1).padStart(2, '0')` down the
tabs — and nothing in the interface reports how far into the course a section sits. So "lesson 13"
resolves, "two sections on" resolves by counting tabs, "lesson 1 section 04" resolves exactly, and
**"section 184" resolves nowhere**: it is a number the reader cannot see in the product.

`linux-terminal` carries **551 of these, 478 of them bare** — `section 29`, `section 32`,
`section 184` — against **0 in `web-fundamentals`**, which references lessons and neighbours
instead. The numbering is internally correct and it was checked against `course.json`, which is
exactly why it survived three reviews: everything verifiable about it verified. Nobody opened
the screen.

Leaving them is the current position, and it is a **known cost, not an oversight**: a reader
meets a precise citation they cannot follow. Two things would settle it — the lesson screen
learning to show a course-wide number, or those 478 becoming lesson references — and whichever
is chosen, the measurement above is what it should be argued from. Until then, write new
references as a lesson, a neighbour, or `lesson N section NN`.

**Do not teach the next lesson's subject.** A section that explains what it was told to introduce
takes the later lesson's material and leaves it with nothing. The line is that the reader should be
able to *recognise* the idea and not yet *use* it.

---

## Video scripts

`VIDEO.md` decides how a video is made and what it costs. This is what goes in the words.

**A script is spoken, so it is written to be said.** Short sentences. No parenthesis a voice cannot
carry. No list of five things, because a listener cannot hold five and cannot scroll back.

**Video is for what moves.** A sequence, a demonstration, a thing changing over time. A definition
belongs in prose, where a reader can stop and re-read it — putting it in a video makes it *harder*
to consult and costs money per minute.

**The opening is the most expensive minute of the course**, because `C-30` makes the presenter
absent by default and an opening is the one place he is on screen throughout. Sixty to ninety
seconds, and it must say what the lesson is for. An opening that only greets is money spent on
nothing.

**Marks are anchored to words, never to seconds** (`C-33`), and a mark exists where the scene has
to change. If a script has no marks, either the video is a talking head — which is the expensive
mode — or somebody forgot the screen.

---

## Still to be decided

- **How much of a course may be video.** `C-36` removed the quotas and put nothing in their place
  on purpose; the honest number arrives with the first real production cost.
- **Whether a section may hold an interactive widget.** `delivery-metrics` wants a Monte Carlo the
  student can run, and `reading`, `video` and `practice` are the three kinds — none of them is
  that.
- **Where illustration stops being authorable.** Conceptual diagrams are SVG and can be written.
  Annotated screenshots and pictorial work (a motherboard, a connector) are not, and the boundary
  has not been drawn precisely. One piece of it moved: a **terminal** screenshot is authorable,
  because `tools/term-capture` runs the program under a pseudo-terminal and writes the screen it
  painted as SVG. Everything a terminal can show is on the writable side of the line now; a
  photograph of hardware still is not.
