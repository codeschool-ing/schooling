---
title: Soft prompts, which are numbers and not words
version: 1
---

A prompt looks like a piece of English, and the natural assumption is that the model reads it the
way you do. **It reads numbers.** Lesson 3 showed the first step: the text is cut into tokens, and
each token is an id.

```
ana@lab:~/pe$ tok show "Answer in one word."
"Answer" " in" " one" " word" "."
17045 306 1001 2195 13
5 tokens, 19 characters (o200k_base)
```

The second step happens inside the model. Each id picks out one row of a large table the model
learnt in training, and that row is a list of numbers called an **embedding**: a vector. `17045`
is not used as a number at all; it is an address, and what the model computes with is the vector
stored there. Five tokens go in as five vectors.

The same sentence through a different tokenizer comes out as different ids:

```
ana@lab:~/pe$ tok show "Answer in one word." -e cl100k_base
"Answer" " in" " one" " word" "."
16533 304 832 3492 13
5 tokens, 19 characters (cl100k_base)
```

The pieces are the same and four of the five ids have changed, because each id is an address in
its own model's table; the full stop happens to sit at `13` in both. Hold on to that: it decides what
a learnt prompt can and cannot be moved to.

## Skipping the words

Once you see the prompt as a row of vectors, a question follows. **Every written prompt is a row
of vectors taken from the table. Why limit yourself to those?** A vector somewhere between the
rows, which no token would ever produce, might steer the model better than any word.

That is **prompt tuning**, named in a 2021 paper, "The Power of Scale for Parameter-Efficient
Prompt Tuning". You put a small number of extra vectors in front of the input, a *soft prompt*, and
train them:

1. Start the soft prompt with random numbers, or with the embeddings of some ordinary words.
2. Run a labelled example through the model: soft prompt, then the input, and compare the output
   with the answer you wanted.
3. Work out, by gradient descent, which small change to the soft prompt's numbers would have made
   the right answer more likely, and make it.
4. Repeat over the training set, many times.

**The model's own weights do not change.** They are frozen; the only numbers that move are the
soft prompt's. That is what makes it cheap compared with fine-tuning (lesson 9): what you train and
store is a handful of vectors, and one frozen model can carry a different soft prompt for each
task.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Four learnt vectors, the soft prompt, sit in front of five embeddings looked up for the tokens Answer, in, one, word and full stop. Both go into the model, whose weights are frozen. Its output is compared with the wanted answer, and a dashed arrow from that comparison goes back to the four soft prompt vectors only: training adjusts those numbers and nothing else.\"><defs><marker id=\"soft-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s1</text><rect x=\"88\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"113\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s2</text><rect x=\"146\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s3</text><rect x=\"204\" y=\"70\" width=\"50\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"229\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">s4</text><rect x=\"280\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"316\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Answer</text><rect x=\"360\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">in</text><rect x=\"440\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"476\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">one</text><rect x=\"520\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">word</text><rect x=\"600\" y=\"70\" width=\"72\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"636\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><text x=\"142\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">soft prompt: learnt vectors</text><text x=\"476\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the input: one embedding per token id</text><path d=\"M142 104 L142 138\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><path d=\"M476 104 L476 138\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><rect x=\"30\" y=\"140\" width=\"642\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"351\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model: weights frozen</text><path d=\"M556 190 L556 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#soft-ah)\"></path><rect x=\"440\" y=\"212\" width=\"232\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">output, against the wanted answer</text><path d=\"M440 229 L15 229 L15 87 L28 87\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#soft-ah)\"></path><text x=\"230\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">training adjusts these numbers only</text></svg>", "caption": "Prompt tuning. A few learnt vectors go in front of the input's embeddings; the model is frozen, and training moves only the soft prompt."}
```

## What you get, and what it costs

A trained soft prompt is a short list of vectors. **It is not text, and it cannot be read back as
text.** You can look for the token whose embedding is nearest to each vector, and what comes back
does not read as an instruction, because the vector was never any of those words. You
cannot review it, edit it by hand, or explain it to a colleague the way you would a written prompt.

It is also tied to one model. The vectors were tuned against that model's frozen weights. The capture
above already shows two vocabularies giving one sentence different addresses, and the vectors
behind the addresses differ from model to model as well: another model reads the same numbers as
something else entirely.

And it needs two things a written prompt does not:

- **the model's weights**, to run the training and to place the vectors at the input. Through an
  API you send text, so there is nowhere to put a vector, and nothing to compute a gradient
  against;
- **a training set**: labelled examples of the task, enough for the vectors to settle, and a few
  more held back to check them on.

Prompt tuning is one of a family of **parameter-efficient** methods, which all train a small number
of new numbers beside a frozen model. *Prefix tuning* puts learnt vectors in front at every layer
of the model, not only at the input; *adapters* and *LoRA* add small trainable pieces inside it.
The details differ and the trade is the same: much less to train than the whole model, and much
more to arrange than a sentence.
