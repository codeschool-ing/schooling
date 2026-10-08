---
title: Base models and tuned models
version: 1
---

A model that has only been pretrained does exactly one thing: it **continues text**. Give it the
start of a sentence and it writes what plausibly comes next. Give it a question and it may answer,
or it may write three more questions, because in the text it learnt from a question is often
followed by more questions. That is a **base model**.

Meta's prompt-format document shows one, with an input it wrote and the reply its base model gave:

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/prompt_format.md
  31: <|begin_of_text|>Color of sky is blue but sometimes can also be
  36: red, orange, yellow, green, purple, pink, brown, gray, black, white, and even rainbow
      colors. The color of the sky can change due to various reasons such as time of day,
      weather conditions, pollution, and atmospheric phenomena.
```

Nobody asked for a list of colours. The model saw the start of a sentence and kept going, the way
the end of an encyclopaedia paragraph would. It did its job perfectly; its job is not answering
you.

## What tuning adds

An **instruction-tuned** model (Llama calls it *Instruct*, other providers call it *chat*) is the
same network trained further on conversations: a request, then the reply a helpful assistant would
give. After that it treats your text as a turn in a dialogue, answers, and **stops**. Stopping is
learnt too, and the document says how each kind ends:

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/prompt_format.md
   7: - `<|end_of_text|>`: Model will cease to generate more tokens. This token is generated
      only by the base models.
  11: - `<|eot_id|>`: End of turn. Represents when the model has determined that it has
      finished interacting with the user message that initiated its response. This is used in
      two scenarios:
```

The base model ends when the text would end. The tuned model emits a token meaning *my turn is
over*, and whatever is serving it stops generating there. That one token is the difference between
a reply and a ramble.

A third kind has appeared since: **reasoning models**, tuned further to write out working before
they answer. Lessons 6 to 8 meet them under each provider's name. For choosing, they behave like a
tuned model that spends more tokens, and more time, on each answer.

## Which one you are offered

- **Every chat API serves tuned models.** When lesson 16 sends Lantern Books' e-mail to an API,
  there is no base model behind it. You never have to think about this in the API lessons.
- **Open collections publish both**, side by side, often with the same size in the name. On a
  model hub, a name without *Instruct*, *chat* or *it* is usually the base, and downloading the
  wrong one is a common first mistake: it loads, it runs, and it answers a support e-mail by
  writing another support e-mail.
- **A base model is what you fine-tune**, when you fine-tune at all (section 11). The tuning a
  provider did is a choice made for the general case; starting from the base means making that
  choice yourself.

**For ana's three tasks**, sorting, extracting an order number and drafting a reply, a tuned model
is the only sensible start. Every model she evaluates in lesson 5 is one.
