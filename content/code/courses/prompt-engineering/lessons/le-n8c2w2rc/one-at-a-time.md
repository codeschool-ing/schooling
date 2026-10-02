---
title: Writing a sentence one word at a time
version: 1
---

A probability for the next word is not yet a sentence. **Generation is a loop around that one
step**: score the next word, pick one, add it to the end of the text, and score again with the
longer text. It stops when the model picks the word that means "the end", or when it reaches a
limit somebody set.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A loop. The text so far, the café opens at, goes into the model. The model gives a probability for every next word: seven 75 percent, eight 25 percent. One is picked, seven, and it is added to the text, which goes back into the model for the next step.\"><defs><marker id=\"gen-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the text so far</text><text x=\"105\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the café opens at</text><path d=\"M190 75 L238 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"240\" y=\"40\" width=\"110\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M350 75 L398 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"400\" y=\"20\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a probability for every word</text><text x=\"430\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">seven</text><rect x=\"475\" y=\"59\" width=\"75\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"555\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><text x=\"430\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">eight</text><rect x=\"475\" y=\"89\" width=\"25\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"505\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25%</text><path d=\"M580 75 L618 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><rect x=\"620\" y=\"40\" width=\"85\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"662\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pick one</text><text x=\"662\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">seven</text><path d=\"M662 110 L662 200 L105 200 L105 112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gen-ah)\"></path><text x=\"383\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">add it to the text, and ask again</text><text x=\"383\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the café opens at seven</text></svg>", "caption": "One step of generation. The model never writes a sentence; it scores the next word, one word is picked, and the longer text goes back in."}
```

`toylm generate` runs that loop. With `--temperature 0` it always picks the word with the highest
score, which is the simplest rule there is:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 0
seven.
-- finish: end, prompt 4 tokens, output 2 tokens
```

Two words came out, `seven` and the full stop, and then the model picked the end. You can watch
the second step on its own by giving it the longer text:

```
ana@lab:~/pe$ toylm next "the café opens at seven"
context: trigram after 'at seven'
  .        100.0%  ########################################
```

The last line of `generate` is the accounting every model API returns in some form: **why it
stopped**, and how many tokens went in and came out. `end` means the model chose to stop. Lesson 15
is about the other reason, a limit, and lesson 3 about why a count of tokens is what you pay for.

## What the model can see

`toylm` looks at the last two words and nothing else, and that shows in what it writes:

```
ana@lab:~/pe$ toylm next "the cat sat on the"
context: trigram after 'on the'
  chair     50.0%  ####################
  mat       33.3%  #############
  counter   16.7%  #######
ana@lab:~/pe$ toylm generate "the cat sat on the" --temperature 0
chair by the window.
-- finish: end, prompt 5 tokens, output 5 tokens
```

The file it learnt from says `the cat sat on the mat` twice. It also says `the cat sleeps on the
chair` three times, and **by the time `toylm` reaches `on the`, the word `sat` is out of sight**.
So the chair wins, three against two, and the sentence about sitting ends up on the chair where the
cat sleeps.

A large model's window is enormous by comparison, and it fails the same way at its edge: text that
fell outside the window, or that is buried in the middle of a very long one, has no say in what
comes next. Lesson 4 is about that window.

## Picking is not always the top word

Always taking the highest score gives the same text every time, and that is not what chat
assistants do by default. They **draw** a word, in proportion to the scores: `hot` is drawn about
six times in ten, `bitter` about once in twenty-seven. Five draws, each started from a different
random seed:

```
ana@lab:~/pe$ toylm generate "the coffee is" --samples 5
[seed 1] hot.
[seed 2] cold and the cat wakes.
[seed 3] hot.
[seed 4] hot.
[seed 5] strong.
```

Three of the five are the likely answer and two are not, which is roughly what 59.3% predicts. The
second one is worth reading twice. **`the coffee is cold and the cat wakes` is grammatical, and
every pair of words in it occurs in the file**, and nothing in the file says it. The model wrote a
fluent sentence with no fact behind it, because fluent is what it was built to produce.

That one line is the seed of three later lessons. Lesson 13 controls how adventurous the drawing
is, lesson 14 cuts off the unlikely words before the draw, and lesson 5 explains why a fluent
answer and a correct one are different things.

## From continuing text to answering questions

`toylm` continues text. A chat assistant seems to do something different: it answers. The gap is
smaller than it looks. **A conversation is also a text**, with the turns marked: who spoke, and
what they said. The model is given that text and asked for the next piece, which is the
assistant's turn.

What makes the next piece a helpful answer, and not another question in the same style, is more
training after the first. The model is trained further on many conversations in which the
assistant's turn is a good answer, and then adjusted using people's judgements of which answers
were better. After that, **the most likely continuation of a question is an answer to it**. The
mechanism did not change; what it learnt to find likely did.
