---
title: The words, and what each one covers
version: 1
---

"AI" is used in announcements as if it named one thing, usually the newest chat assistant, and as if
the next step from that thing were obvious. Both halves mislead. **AI is a field with many parts,
and a large language model is one kind of system inside one of them.** AGI, the word attached to
the next step, names a goal rather than a system, and there is no agreed test for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Four nested boxes. The outermost is artificial intelligence, with the example of a chess program whose rules are written by hand. Inside it, machine learning, with a spam filter trained on examples, and toylm. Inside that, deep learning, with recognising objects in photographs. Innermost, large language models, the models behind chat assistants.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">artificial intelligence: programs that do tasks people call intelligent</text><text x=\"26\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a chess program with rules written by hand</text><rect x=\"40\" y=\"70\" width=\"640\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">machine learning: behaviour learnt from examples</text><text x=\"56\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a spam filter trained on examples</text><text x=\"664\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">toylm</text><rect x=\"70\" y=\"130\" width=\"580\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"86\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">deep learning: neural networks with many layers</text><text x=\"86\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recognising objects in photographs</text><rect x=\"100\" y=\"190\" width=\"520\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">large language models</text><text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the models behind chat assistants</text></svg>", "caption": "Each term is a part of the one around it. A large language model is one kind of deep learning, which is one kind of machine learning, which is one approach to artificial intelligence. toylm learns from data, so it sits in machine learning, outside deep learning."}
```

## From the outside in

**Artificial intelligence** is the field of computer science that builds programs to do tasks
people call intelligent: playing a game, planning a route, recognising speech, translating. The
name dates from the 1950s, and much of what the field built does not learn at all. A chess program
whose rules and scoring were written by hand is AI in this sense, and so is a route planner.

**Machine learning** is the part of AI where the behaviour is learnt from examples instead of
written as rules. A spam filter trained on messages people marked as spam is machine learning.
So is `toylm`: nobody wrote a rule that `hot` follows `coffee is`; it counted that from its
corpus, which is learning in the simplest form there is.

**Deep learning** is machine learning with neural networks of many layers, the kind of model whose
parameters are learnt weights (lesson 8). It is what made recognising objects in photographs and
transcribing speech work well, and it is what large language models are built with.

**Large language models** are deep-learning models trained to predict the next token of text, at a
very large scale: lesson 1's loop, with billions of weights behind each score. The chat assistant is
one of these with further training to answer rather than continue (lesson 1).

## Two words that cut across the layers

**Generative** describes a model that produces new content: text, images, audio, code. A large
language model is generative, and so are image generators. A spam filter is not: it outputs a
label, not new content. "Generative AI" is therefore the producing kind, whatever it produces.

**Narrow** describes a system built for one task or one kind of task. A chess engine is narrow, a
spam filter is narrow, and in a real sense a language model is too. It does one thing, predict the
next token, and that one thing turns out to cover a great many tasks that can be written as text.
That breadth is why language models are surprising, and it is also why it is easy to forget the
single mechanism underneath.

## AGI

**Artificial general intelligence** is used for a system that could do most intellectual tasks a
person can, across domains, at least as well as a person. It is a goal, and three things about it
are worth holding on to:

- there is no agreed definition. Organisations that use the term define it differently, some by
  ability, some by economic value, some by learning new tasks without being trained on them;
- there is no agreed test. Without one, a claim that something "is AGI" or "is close to AGI"
  cannot be checked, only argued;
- predictions of when it will arrive are predictions, made by people with interests in the answer.
  This course makes none.

What a large language model demonstrably is can be checked, and you have checked it: a next-token
predictor whose scores come from learnt weights (lessons 1 and 8). **That description stays true
however impressive the output becomes**, and it is the right starting point for reading any claim,
which is the next section.
