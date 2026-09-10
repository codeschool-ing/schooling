# How a question is built

`CONTENT.md` says what an exercise *is* — the file, the types, the graders. This says what makes
one **worth asking**, which is a different subject and has its own failures.

It exists because of a measurement. The first lesson written for this catalogue was reviewed by
somebody who scored **33 of 36** and said the questions felt easy even where they were labelled
hard. That was checked rather than argued about, by simulating a student who **had not read a
single word** and applied one rule — *pick the longest option that does not say "never" or
"always"*:

| | |
|---|---|
| pure guessing | **36%** |
| the rule, without reading anything | **68%** |
| the same rule on the questions labelled *hard* | **60%** |

The questions were not measuring knowledge. They were measuring whether somebody had noticed how
they were written — and the difficulty labels did not survive contact with a reader who skipped the
lesson.

---

## Difficulty is a property of the thinking, never of the options

This is the rule the rest of the document serves.

**A question is not made harder by weakening its distractors, and not made easier by strengthening
them.** Every question at every level has to survive a student who does not know the answer: if
the options can be sorted without the material, the level written in the file is fiction.

| level | what makes it that level |
|---|---|
| **easy** | one concept, stated directly in the material. Recognising it. |
| **medium** | two concepts combined, or one concept applied to an example the material names. |
| **hard** | a situation the material does **not** contain, requiring transfer — or telling apart two things the material deliberately kept separate. |

So a hard question is hard because the reader has to *do* something with what they read. It is
never hard because the wording is slippery, the subject is obscure, or the distractors are
plausible-looking noise. **Trivia is difficult and worthless**; it separates people by memory for
detail rather than by understanding.

---

## A distractor is a belief somebody holds

The single most useful test for an option:

> **Would a student who understood almost everything, and got exactly one thing wrong, choose this?**

If yes, it is a distractor. If nobody would choose it, it is furniture — it does not distract, it
just narrows the field and makes the question easier.

That test also writes the `why`. A good wrong option has a nameable misunderstanding behind it, and
the `why` says which one:

- **Furniture** — *"The database sends the page directly to the browser."* Nobody thinks this.
- **A distractor** — *"Still only a server."* Somebody who believes the role is a property of the
  machine picks exactly this, and the `why` can tell them what they got wrong.

---

## The tells

Ways a question leaks its answer to somebody who did not study. Each row says whether a machine can
see it, because the ones a machine can see are checked rather than remembered.

| | the tell | checked |
|---|---|---|
| 1 | **Length.** The correct option is the longest, or the most qualified. | **yes** |
| 2 | **Absolutes in the wrong options** — *never, always, only, all, must, none*. And the mirror: hedges (*usually, often, can, tends to*) concentrated in the correct one. | **yes** |
| 3 | **Two options.** A coin flip floors the score at 50%. | **yes** |
| 4 | **Furniture** — an option nobody would choose. | no |
| 5 | **Convergence.** Three options say the same thing in different words and one stands apart; the one that stands apart is the answer. | no |
| 6 | **Echo.** The correct option repeats the rare words of the prompt. | **yes** |
| 7 | **Grammar.** Article, number or tense agreeing with the stem in only one option. | partly |
| 8 | **"All of the above", "none of the above".** | **yes** |
| 9 | **Position.** The correct option sitting in the same place across a lesson. | **yes** |
| 10 | **Leakage.** One question's stem answers another question. | no |

**Two options are banned** except where the domain is genuinely binary and the question is about
which side of the line something falls — and even then, prefer three where the third is a real
belief.

`tools/check-exercises` measures the checkable rows across a lesson and fails the build on the ones
that are decidable. It cannot see furniture or convergence; those are why this document is longer
than the check.

---

## What the check cannot do, and what does it instead

A tell is a property of one question. **Discrimination is a property of a question meeting
students**, and no amount of careful writing establishes it.

`internal/analysis` already draws the line the right way:

- **Difficulty** is the proportion who got it right. `TooEasyAbove = 0.95` and
  `TooHardBelow = 0.05` — and a hard question is only ever *reported*, because it may be excellent.
- **Discrimination** is whether the students who did well overall did better on this one.
  `WeakBelow = 0.15` is where a question stops separating anybody, and `InvertedBelow = -0.10`
  means the strong students did *worse*, which is a wrong key or an ambiguous prompt rather than a
  hard question.

So the answer to *"how hard is too hard?"* is that hardness is not the axis. **A hard question that
discriminates is the best question in the pool. An easy one everybody gets right measures
nothing.** What drives students away is not difficulty; it is difficulty that does not discriminate
— trickery, ambiguity, and trivia.

Nothing is measured until thirty students have answered (`MinimumSample`). Until then, write for
discrimination and let the data correct it afterwards.

---

## Practice and assessment are different instruments

`drillable` is a property of the **question**, not of the section it sits in: it means *this is
worth repeating, and it is safe to repeat*. An exam question is never drillable, because drilling
it would leak the paper.

The two instruments want different difficulty:

| | what it is for | where the success rate should sit |
|---|---|---|
| **the drill queue** (`drillable`, spaced repetition) | retention — bringing back something already understood | **high**, deliberately. Failure here is friction, not information |
| **the assessment at the end of a lesson** | separating who understood from who did not | **middle**, roughly half to two thirds |

A lesson's closing section is an assessment. **It must not be the easiest part of the lesson**, and
it must vary its dynamics — a `quiz`, an `ordering`, a `matching`, a `cloze` ask different things
of the same knowledge, and a section of twelve identical two-option questions asks one thing twelve
times.

---

## Still to be decided

This document grows. Written down here so it is not decided by omission:

- **How many distractors.** Four options is convention rather than evidence; three good ones beat
  four where the fourth is furniture.
- **Whether `hint` is a tell.** A hint that names the answer's vocabulary is one, and no rule
  covers it yet.
- **Whether difficulty should be declared at all**, once `cmd/analyse` can measure it. A declared
  level that the data contradicts is a claim waiting to be embarrassed.
