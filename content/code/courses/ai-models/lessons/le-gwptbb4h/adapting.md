---
title: Using it as it is, or changing it
version: 1
---

A pretrained model does a general job. Your task is particular: five labels that mean something
at Lantern Books, an order format nobody else uses, a tone the shop wants in its replies. There are
four ways to close the gap between the two, and the common mistake is starting at the most
expensive one because it sounds the most serious.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Four ways to make a pretrained model do your task, from cheapest to dearest: write a better prompt, add worked examples, retrieve your own documents into the prompt, fine-tune the weights. Each step costs more to build and to keep, and each fixes a different gap.\"><defs><marker id=\"l1lad-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"190\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. the prompt</text><text x=\"105\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">say the task plainly</text><text x=\"105\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">minutes</text><text x=\"105\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fixes: unclear task</text><rect x=\"200\" y=\"145\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. examples</text><text x=\"275\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">show cases in the prompt</text><text x=\"275\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">hours</text><text x=\"275\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fixes: unclear format</text><rect x=\"370\" y=\"100\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3. retrieval</text><text x=\"445\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fetch your own facts</text><text x=\"445\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">days</text><text x=\"445\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fixes: missing facts</text><rect x=\"540\" y=\"55\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4. fine-tuning</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">change the weights</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">weeks</text><text x=\"615\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fixes: behaviour</text><line x1=\"40\" y1=\"286\" x2=\"690\" y2=\"286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1lad-ah)\"></line><text x=\"690\" y=\"274\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cost to build and to keep</text></svg>", "caption": "Climb only as far as the gap you measured. Each step up costs more to build and more to keep."}
```

**1. The prompt.** Say the task plainly, give the labels, say what to answer with. ana's
`prompts/triage.txt` is three lines and does exactly this. It costs minutes, it changes the moment
you edit a file, and it fixes the most common gap there is: the model did not know what you wanted.

**2. Examples in the prompt.** When the model understands the task but gets the format or the
borderline cases wrong, show it some: an e-mail, the right label, another e-mail, its label.
`prompt-engineering` covers how many and which. It costs hours of choosing good examples and some
tokens on every request, because the examples are sent every time.

**3. Retrieval.** When what is missing is a fact, section 06's gap, fetch the relevant text and put
it in the prompt: the order's status, the refund policy, the book's page count. This is a system to
build and keep running, which is why it is measured in days, and it is the only one of the four
that keeps up with facts that change.

**4. Fine-tuning.** Train the weights further on your own examples, so the behaviour is in the model
rather than in the prompt. It is the right tool for a behaviour that dozens of examples cannot
teach, or for a high-volume task where a small tuned model can replace a large general one. It is
the wrong tool for facts: a model fine-tuned on last month's stock does not know this month's, and
retraining it is the expensive way to discover that retrieval was the answer.

## Why the order matters

Each step **costs more to build and more to keep**. A prompt is a text file. A fine-tuned model is
a dataset, a training run, an evaluation, a hosting decision and a plan for re-tuning when the base
model it started from is retired, which lesson 2 shows happens on the provider's schedule rather
than yours.

And each step **fixes a different gap**. Fine-tuning cannot supply a fact the training examples did
not contain, and retrieval cannot teach a format. So the order is not only cheapest first. It is:
**measure what is wrong, then take the lowest step that fixes that.** Lesson 5 is the measuring.

For ana, the plan that follows from this is short. Her tasks need no recent public facts and no
private facts beyond the e-mail itself, so retrieval is not on her path yet. She starts at step 1
with every candidate, moves to step 2 for any model that fails on format, and treats fine-tuning
as a question to ask only if no ready-made model, prompted well, passes her cases.
