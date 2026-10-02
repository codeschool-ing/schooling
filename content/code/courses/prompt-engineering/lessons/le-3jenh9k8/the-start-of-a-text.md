---
title: The start of a text the model continues
version: 1
---

The everyday picture of a prompt is an order: you say what you want, and a program that understood
the order carries it out. It explains the times a prompt works and none of the times it fails.
**A prompt is the beginning of a text, and the reply is the model's continuation of it.** Lesson 1
showed the one step underneath: the model scores every possible next piece of the text it was given,
and nothing else goes in.

So the smallest change to the text is a change to the prediction. Lesson 1 asked `toylm` about
`the café opens at` and got `seven` at 75% and `eight` at 25%. Change one word:

```
ana@lab:~/pe$ toylm next "the café closes at"
context: trigram after 'closes at'
  six       66.7%  ###########################
  noon      33.3%  #############
```

Nobody told the model to talk about closing time. **The word `closes` moved the whole
distribution**, from morning hours to `six` and `noon`, because those are what followed it in the
text the model learnt from.

## The layout is part of the prompt

The corpus has a few lines written as questions and answers, in the shape `question : ... answer :
...`. Give `toylm` a question in that shape and it answers in that shape:

```
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
```

`yes.` is a terrible answer to `when`, and it is worth seeing why it came out. The model's window is
two words (lesson 1), so it never saw `when` or `open`; **all it saw was `answer :`**, and after
`answer :` a short reply followed by a full stop is what the text it learnt from does. The layout
reached the model and the question did not.

A large model sees the whole question, so it would not make this mistake. It follows the same rule
on a larger scale, though: **it continues the document you gave it, in that document's language,
register and format.** A prompt written as a terse list tends to get a terse list back; a prompt
that opens a JSON object tends to get the rest of one (lesson 18). Every part of the text is an
instruction, including the parts you did not mean as one.

## A chat is a document with turns

A chat window seems to be a different thing from continuing a text. Lesson 1 showed that it is the
same thing with the turns marked. At the time of writing (2026), the APIs behind chat assistants
take a conversation as a list of messages, each with a role and its text. The field names differ
between providers; the shape is this one (an illustration, not a request that was sent):

```json
[
  {"role": "system", "content": "You answer questions from Café Aurora's customers. Keep replies to two sentences."},
  {"role": "user", "content": "When do you open on Sunday?"}
]
```

Before the model sees it, the list is laid out as one text, with markers that say where each turn
starts and who is speaking, and it ends with an assistant turn that has been opened and not
written. **The model's reply is its continuation of that one open turn.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A single document with three turns stacked. A system turn written by the developer: You answer questions from Café Aurora&#x27;s customers. A user turn written by the person: When do you open on Sunday? Then an assistant turn, open and empty, marked: the model writes from here.\"><defs><marker id=\"chat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"245\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"40\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one text, sent as a whole</text><rect x=\"40\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">system</text><rect x=\"170\" y=\"55\" width=\"510\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">You answer questions from Café Aurora's customers.</text><text x=\"185\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Keep replies to two sentences.</text><rect x=\"40\" y=\"115\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">user</text><rect x=\"170\" y=\"115\" width=\"510\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">When do you open on Sunday?</text><rect x=\"40\" y=\"175\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">assistant</text><rect x=\"170\" y=\"175\" width=\"510\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><path d=\"M190 210 L240 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chat-ah)\"></path><text x=\"250\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the model writes from here</text></svg>", "caption": "What the model receives. The list of messages becomes one text with each turn marked, and it ends inside an assistant turn that has been opened and not written."}
```

The three roles are worth telling apart from the start, because the rest of the course keeps
coming back to them:

| role | who writes it | what it is for |
|---|---|---|
| `system` | the developer of the application | who the assistant is, the rules, the format; the user does not see it (lesson 22) |
| `user` | the person using the application | the request itself |
| `assistant` | the model, one turn at a time | the replies so far, which are sent back with every new request |

The last row has a consequence that surprises people. **The model has no memory between
requests**; the conversation looks continuous because the application sends the whole of it again
each time. And since the earlier assistant turns are only text in the list, a program can write one
itself, and the model has no way to tell that it did not.
