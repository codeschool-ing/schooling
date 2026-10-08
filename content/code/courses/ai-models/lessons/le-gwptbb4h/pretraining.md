---
title: What pretraining makes
version: 1
---

Every model this course names began the same way. Somebody collected an enormous amount of text,
and a network was trained on one task over and over: **given the text so far, predict the next
token.** Nobody taught it grammar, facts or arithmetic as separate subjects. It picked up whatever
helped it predict, and it turns out that predicting the next word of a recipe, a court ruling and a
bug report well enough requires a great deal of all three.

The result is a **pretrained model**: the thing a company spent months and a very large bill
producing, so that you do not have to. This course is about choosing one and using it, so it is
worth being precise about what that thing physically is.

Meta's model card for Llama 3.1 is one of the few that says it in numbers. This course quotes a
document the way it does here: the first line names the repository, the commit it was read at and
the file, and every quoted line starts with its line number in that file. So you can open the same
file on GitHub at that commit and read around it. Nothing in a quotation is for you to type.

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
   3: The Meta Llama 3.1 collection of multilingual large language models (LLMs) is a
      collection of pretrained and instruction tuned generative models in 8B, 70B and 405B
      sizes (text in/text out). The Llama 3.1 instruction tuned text only models (8B, 70B,
      405B) are optimized for multilingual dialogue use cases and outperform many of the
      available open source and closed chat models on common industry benchmarks.
 186: **Overview:** Llama 3.1 was pretrained on ~15 trillion tokens of data from publicly
      available sources. The fine-tuning data includes publicly available instruction
      datasets, as well as over 25M synthetically generated examples.
```

Three things in those two paragraphs come up again in every lesson of this course:

- **"pretrained and instruction tuned"**. There are two kinds of model in the collection, and
  section 07 of this lesson is about the difference.
- **"8B, 70B and 405B"**: the number of parameters, in billions. A parameter is one number
  in the network, and this one comes in three sizes. Lesson 3 turns a parameter count into the
  memory a machine needs to run it.
- **"~15 trillion tokens of data from publicly available sources"**: what it learnt from. Public
  text is the whole of what it knows. Lantern Books' order history was never in it and never will
  be, which is section 10's subject.

## What comes in the box

What you get when you take a pretrained model is more than the network. Four other things travel
with the weights, and each of them can stop you if it is missing:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"What a pretrained model is when you receive it: one set of weights at the centre, and around it the four things you need to use them — a tokenizer, a chat template, a model card and a licence. Through an API you hold none of them; the provider runs all five behind one endpoint.\"><defs><marker id=\"l1box-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"100\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">the weights</text><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">billions of numbers</text><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">learnt from text</text><rect x=\"30\" y=\"30\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tokenizer</text><text x=\"120.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">text into numbers</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chat template</text><text x=\"600.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roles into one string</text><rect x=\"30\" y=\"200\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">model card</text><text x=\"120.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it was made for</text><rect x=\"510\" y=\"200\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">licence</text><text x=\"600.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what you may do</text><line x1=\"210\" y1=\"56\" x2=\"250\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"510\" y1=\"56\" x2=\"470\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"210\" y1=\"226\" x2=\"250\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"510\" y1=\"226\" x2=\"470\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">an open model hands you all five</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">an API hands you an endpoint</text></svg>", "caption": "What comes in the box. An open model ships every part; an API keeps them all behind one address."}
```

- **the weights**, the billions of numbers themselves;
- **a tokenizer**, which turns text into the numbers the weights expect. The wrong tokenizer
  produces nonsense, not an error;
- **a chat template**, the exact string a conversation has to become before the model reads it
  (section 08);
- **a model card**, which says what it was trained on and for, and where it fails (section 09);
- **a licence**, which says what you may do with all of it. Lesson 2 reads three of them.

**An open model hands you all five.** **A model behind an API hands you none of them**: the
provider keeps the weights, tokenizes for you, applies its own template, and tells you as much
of the card as it chooses. You send a list of messages to an address and get text back. That
difference is the subject of lesson 2, and it decides almost everything about cost and control.
