---
title: What each one changes
version: 1
---

Fine-tuning has a reputation as the grown-up version of prompting: when a prompt is not good
enough, you train the model on your own data and it learns your business. That gets the order and
the strengths wrong. **A prompt changes the input; fine-tuning changes the weights.** They solve
different problems, and the one fine-tuning is famous for, teaching a model your facts, is the one
it does worst.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two rows. Top row, prompt engineering: your prompt goes into the model, whose weights are unchanged, and a reply comes out; this happens on every request. Bottom row, fine-tuning: your examples go into a training run, which produces a new model with changed weights; a shorter prompt then goes into that new model and a reply comes out.\"><defs><marker id=\"ft-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">prompt engineering: change the input, every request</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your prompt</text><path d=\"M170 68 L268 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"40\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"355\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">weights unchanged</text><path d=\"M440 68 L538 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"540\" y=\"40\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reply</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">fine-tuning: change the weights, once per training run</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your examples</text><path d=\"M170 188 L268 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"160\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a training run</text><path d=\"M355 216 L355 238\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"270\" y=\"240\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a new model</text><text x=\"355\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">weights changed</text><text x=\"95\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a shorter prompt</text><path d=\"M170 265 L268 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><path d=\"M440 265 L538 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ft-ah)\"></path><rect x=\"540\" y=\"240\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reply</text></svg>", "caption": "Where each change lands. A prompt is new text on every request, and the model stays the same; fine-tuning changes the model once, and every later request goes to the changed one."}
```

Lesson 8 showed that the weights do not move while a model is used. Every improvement you have
made so far in this course, and every one in lessons 20 to 29, changes only the text sent with the
request. **Fine-tuning is training continued on your own examples**: the weights are nudged, the
way they were in the original training, towards making your examples' answers more likely. The
result is a new model, and every request after that goes to it.

## What the examples look like

A fine-tuning job takes a file of examples, each one a conversation with the answer you want. A
common shape is one JSON object per line, here with three examples for sorting the café's customer
messages into categories:

```
ana@lab:~/pe$ wc -l train.jsonl
3 train.jsonl
ana@lab:~/pe$ head -1 train.jsonl
{"messages": [{"role": "user", "content": "Are you open on Sunday afternoon?"}, {"role": "assistant", "content": "hours"}]}
```

Three is far too few; a real job wants hundreds or thousands, each one checked by somebody who
knows the right answer. Nothing was trained here. The workbench has no model to train, and the
point of the file is its shape: **every line is a question with the answer you have decided is
right.**

## What fine-tuning is good at

Training on examples changes what is likely, and it is good at things that are a matter of habit:

- a format: always the same JSON fields, always one word from your list of categories;
- a style: the tone of your support team, the length your readers expect;
- a narrow task done many times: sorting tickets, tagging products, extracting the same five
  fields from the same kind of document;
- shorter prompts: instructions and examples that a prompt would carry on every request are
  carried by the weights instead.

## What it is bad at

**Facts that change.** If the café's opening hours were trained into the weights, changing them
would mean training again, and the old hours would still be in there, spread across billions of
numbers with no way to delete them. A model trained on a fact can also still produce something
else, because it produces likely text, not stored records (lesson 5). Putting the current fact in
the prompt is cheaper and can be checked, and lesson 11 shows how to do that for a whole handbook.

**A vague specification.** If you cannot say what a good answer is, you cannot write the examples
either, and training on inconsistent examples teaches the inconsistency. A model that sorts messages
badly because nobody decided whether "Nobody signed for the milk" is `deliveries` or `other` will be
fixed by deciding, and the decision belongs in the prompt first. **Fine-tuning makes a behaviour
cheaper and more consistent; it does not tell you what the behaviour should be.**
