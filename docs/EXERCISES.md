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
| 1 | **Length.** The correct option is the longest, or the most qualified. | **its rank by length, across a lesson** |
| 2 | **Absolutes in the wrong options** — *never, always, only, all, must, none*. And the mirror: hedges (*usually, often, can, tends to*) concentrated in the correct one. | **as a strategy, scored; the hedges per question** |
| 3 | **Two options.** A coin flip floors the score at 50%. | **yes** |
| 4 | **Furniture** — an option nobody would choose. | no |
| 5 | **Convergence.** Three options say the same thing in different words and one stands apart; the one that stands apart is the answer. | no |
| 6 | **Echo.** The correct option repeats the rare words of the prompt. | **long words, not rare ones** |
| 7 | **Grammar.** Article, number or tense agreeing with the stem in only one option. | no |
| 8 | **"All of the above", "none of the above".** | **yes** |
| 9 | **Position.** The correct option sitting in the same place across a lesson. | **yes** |
| 10 | **Leakage.** One question's stem answers another question. | no |

**Two options are banned** except where the domain is genuinely binary and the question is about
which side of the line something falls — and even then, prefer three where the third is a real
belief.

Three rows carried a stronger word than the code earns, and this is what they say now.

**Row 7 said "partly" and nothing was ever written.** There is no grammar check — not a partial
one, not a weak one. It was an aspiration in a column that reads as a fact, which is the failure
this whole document exists to name, committed in the document itself.

**Row 1 is a share across a lesson, never a rule per question.** One question whose correct option
happens to be longest is not flagged and should not be — see `RankShareCeiling`. And *"the most
qualified"* is not measured at all: the closest thing to it is row 2's hedge rule.

**And it is the rank rather than the end, which it was not until it cost something.** The check
asked only whether the correct option was the LONGEST, while this row has always said the tell is
*length*. The code was narrower than the document, and three lessons of this catalogue shipped with
the correct option the SHORTEST in 97%, 100% and 100% of their questions — passed with the same
ruler held the other way up, and reported clean on every run.

The narrowing was worse than a blind spot, because it steered the repair. Trimming the correct
option until it stops being longest does not remove the habit; it moves it. One such pass took a
lesson from 39% longest to 0%, and to 90% SECOND-longest in the same edit — an improvement by the
only number anybody was measuring, and a worse paper. What is counted now is how often the correct
option lands on any ONE rank, at either end or in the middle, and a question whose options tie in
length is counted at no rank at all, because a ruler separates none of them.

**`guess` scores a family of strategies and reports the best**, for the same reason. A student does
not use the rule this tool imagined; they use whichever rule works on the paper in front of them,
and they find it by trying. Scoring one strategy measured our imagination. The family is small on
purpose — the long answer, the short one, the long one that does not overclaim, the one just under
the longest — because adding strategies until something scores would turn the check into a search
for an accusation.

**Row 6 counts words of six letters or more,** which is a proxy for rare and not the thing itself.
A prompt and an option sharing "database" three times reads as an echo to it; a shared *rare short*
word does not.

**Row 2's absolutes are scored and no longer refused per question**, and the measurement is the
argument. The rule failed any question with an absolute among its distractors and none in its key
— which reads as this row and is not it, because those words are also the ordinary vocabulary of a
short factual answer. Run over this catalogue's Portuguese for the first time it raised 156 of
them, and they were *"Nada, sem saber do disco"*, *"Nenhum — a versão é antiga demais para ter
suporte"*, *"Nunca, porque os dois campos de dia se contradizem"*: correct answers, each one the
whole answer, each asked to change to hide a word.

A habit is a rate. If absolutes are written without regard to which option is correct, the rate in
the wrong options and the rate in the right ones are the same number, and the tell is the gap. Over
the 57 lesson-languages here with enough absolutes to measure at all, the largest gap is **five
points**, and most are negative — the keys carry them slightly more often. So the rate is printed
beside the score as evidence, and the refusal moved to where it belongs: **eliminating the
absolutes is a strategy**, `pickLongestClean` and `pickShortestClean` are it at both ends of the
ruler, and a lesson whose distractors all overclaim is one where those two score near 100% and fail
against `GuessCeiling` with a number attached. The hedge rule stays per question, because the same
run raised four of those rather than 156: a key that says *geralmente* is hedging, and a key that
says *nada* is answering.

---

## Two things the check does not look at at all

Rows 4, 5 and 10 are honest limits, and they are why this document is longer than the check: no
machine separates an option somebody believes from one nobody would pick. Row 7 is not a limit, it
is unwritten. And the two below are neither — they are places the check does not reach at all, so
a question can carry every tell in the table and pass because it sits in one of them.

**Only `quiz` and `multiple-choice` are examined.** `ordering`, `matching`, `cloze`, `numeric`,
`labelling` and `expression-answer` go through untouched. In the first lesson written that is 7
questions of 36. Those types have their own tells — a `cloze` whose blank accepts one word the
prose used four times, an `ordering` whose items are already in order in the material — and nothing
looks for them.

**The aggregate rows need a quorum.** Position and length need six questions, the end-to-end score
needs eight. A section with four questions is invisible to the three checks that matter most, and a
lesson can stay under the threshold by being short.

Two more used to stand here and were the same defect twice: the word lists were English, and
`exercises.pt.json` was never read. Both are closed — see *Every language, because a student reads
one of them* below — and they are worth remembering for what they cost. Every lesson in this
catalogue ships a Portuguese translation, every one of these students reads it, and the first run
that looked at one found six lessons over the ruler ceiling that were clean in English, three of
them in a pull request that had just repaired the English of those same lessons.

Neither of the two above is hard to fix and neither is fixed. They are written down so that the
next person to read a green run knows what green does not mean.

---

## Every language, because a student reads one of them

A tell is a property of the words in front of somebody, and half of these students have Portuguese
in front of them. The check reads `exercises.json` **and every `exercises.<locale>.json` beside
it**, merging each one the way `cmd/load` does — through `catalog.Translated`, so that a checker
with its own merge cannot drift towards passing by forgetting a field the translation carries.

Each language is reported and refused on its own line, labelled `[en]` or `[pt]`, because a lesson
is not one paper: it is one paper per language, and they fail differently.

**Length, position, option count and the end-to-end score are arithmetic on whatever text the
student reads,** so they run in every language unchanged — and they are where the damage was. A
translation is written free, its options come out at different lengths from the English, and the
ruler works again on a battery that had just been repaired.

**The word rows need a list per language, and each list is the other one translated** — never,
only, all, none, cannot, no one → nunca, somente, todos, nenhum, não pode, ninguém. A longer
Portuguese list because Portuguese has more ways to overclaim would make the two languages measure
different things, and a lesson would then pass or fail on which half of the file somebody edited.

**A locale with no list is refused, not measured halfway.** Three of the checkable rows would score
zero and the run would still print a number — the failure this document names in its own first
paragraph about limits. So the third language fails the build on the day it is added, with the
words to write in the message, which is the day somebody is already thinking about it.

*Two details that would each have shipped looking finished.* Go's `\b` is ASCII, so `\bsó\b` never
matches — the boundary it wants after the word is already there — and every accented Portuguese
absolute would have been invisible; the patterns are built against `\p{L}` instead. And `não pode`
carries `pode` inside it, where English splits `cannot` from `can`, so the commonest refusal in the
language would have been reported as a hedge on every question that used it.

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
| **the closing section of a lesson** | separating who understood from who did not | **middle**, roughly half to two thirds |
| **the course exam** | asserting that the student knows, once | the pass mark decides it, and the paper is drawn from a pool |

A lesson's closing section **must not be the easiest part of the lesson**, and it must vary its
dynamics — a `quiz`, an `ordering`, a `matching`, a `cloze` ask different things of the same
knowledge, and a section of twelve identical two-option questions asks one thing twelve times.

But it is not a test, and this is the part that changes how the questions are written.

> **Nothing in a lesson carries a mark** (`A-10`). Wrong is marked, the option's own `why` says
> what the misunderstanding was, and the student carries on. There is no score to repair and
> nothing to sit again.

Two consequences fall straight out of that.

**The `why` is the deliverable, not the key.** In an exam the key is the point and the explanation
is a courtesy. Here it is the reverse: the moment a reader is wrong and still cares why is the best
teaching the lesson will ever do, and an option whose `why` only says *"that is not right"* has
thrown it away. Write every `why`, including the ones on the correct option.

**The question set is fixed and everybody answers all of it** (`A-12`). There is no bank, no
rotation, no draw — and that is what makes a lesson the cheapest place in the system to find out a
question is bad. Thirty students is a verdict here; an exam question inside a pool five times the
draw needs a hundred and fifty attempts to reach the same confidence.

So the two instruments face opposite ways. **A lesson question is written to be measured. An exam
question is written to be survived.**

---

## Still to be decided

This document grows. Written down here so it is not decided by omission:

- **How many distractors.** Four options is convention rather than evidence; three good ones beat
  four where the fourth is furniture.
- **Whether `hint` is a tell.** A hint that names the answer's vocabulary is one, and no rule
  covers it yet.
- **Whether difficulty should be declared at all**, once `cmd/analyse` can measure it. A declared
  level that the data contradicts is a claim waiting to be embarrassed.
