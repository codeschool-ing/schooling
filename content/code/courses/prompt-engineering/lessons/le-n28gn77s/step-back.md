---
title: Asking for the principle, then the answer
version: 1
---

When a model gets a question wrong, the instinct is to add detail to the question: more
specifics, more emphasis on the tricky part. Step-back prompting goes the other way. **Before
the specific question, you ask a more general one: what principle, rule or category is this an
instance of?** The model's answer to that goes into the prompt, and the specific question is
answered with the principle already written in front of it.

## A question whose wording hides its rule

The opening-hours page of Café Aurora's handbook has four lines. Ana put it into a prompt with a
question from the counter, and saved it as `direct.txt`:

```
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
```

Every fact needed is in the prompt. The course wrote this reply as an illustration of the
mistake a model can make with it; it is not a capture:

```localised
Yes. On Wednesdays the café is open until 18:00, so the kitchen takes
hot food orders until 17:30.
```

The question says **Wednesday**, the first line of the handbook says Monday to Saturday, and
those two match strongly. The rule that decides the case is two lines further down and is
reached through a word, *holiday*, that sits in the middle of the question. The reply follows
the most obvious match and stops there, which is the same next-token habit lesson 1 showed:
what is likely given the text, not what is entailed by it.

## The step back

The first call asks only for the general rules. `step1.txt` is the same handbook block,
followed by:

```
Do not answer any particular question yet. Step back: what general rules decide the last time the kitchen takes a hot food order on a given day? List the rules from the handbook that apply, and what they give for each kind of day.
```

Here the course's illustration of a reply to it:

```localised
1. The closing time depends on the day: 18:00 from Monday to Saturday,
   12:00 on Sunday.
2. A public holiday follows the Sunday hours, whatever day of the week
   it falls on.
3. The kitchen stops taking hot food orders 30 minutes before closing.
So the last hot food order is at 17:30 on an ordinary day from Monday to
Saturday, and at 11:30 on a Sunday or a public holiday.
```

Nothing in it is new: every rule was already in the handbook. **What changed is the order in
which the facts are laid out**, with the holiday rule stated as a rule rather than buried as an
exception, and the arithmetic done once for each kind of day.

The second call is the original question with those rules in front of it. Ana pasted the reply
between `<rules>` tags and saved `step2.txt`:

```
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

<rules>
1. The closing time depends on the day: 18:00 from Monday to Saturday, 12:00 on Sunday.
2. A public holiday follows the Sunday hours, whatever day of the week it falls on.
3. The kitchen stops taking hot food orders 30 minutes before closing.
So the last hot food order is at 17:30 on an ordinary day from Monday to Saturday, and at 11:30 on a Sunday or a public holiday.
</rules>

Using the rules above, answer the question. Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
```

And the course's illustration of the answer it gets:

```localised
No. A public holiday follows the Sunday hours, so the café closes at
12:00 and the kitchen stopped taking hot food orders at 11:30.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two rows. Call 1: the step-back question, what rules decide this, goes into the model, which returns the general rules, among them that holidays follow the Sunday hours. An arrow carries those rules down into call 2: the rules plus the original question about 11:45 on a Wednesday holiday go into the model, which returns the answer: no, the last order is at 11:30.\"><defs><marker id=\"sb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">call 1</text><text x=\"40\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">call 2</text><rect x=\"80\" y=\"40\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the step-back question</text><text x=\"180\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what rules decide this?</text><path d=\"M280 70 L318 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"320\" y=\"45\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M420 70 L458 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"460\" y=\"40\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the general rules</text><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">holidays follow Sunday</text><path d=\"M560 100 L560 135 L180 135 L180 168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><text x=\"370\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pasted into the second prompt</text><rect x=\"80\" y=\"170\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the rules + the question</text><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">11:45, Wednesday holiday</text><path d=\"M280 200 L318 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"320\" y=\"175\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M420 200 L458 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sb-ah)\"></path><rect x=\"460\" y=\"170\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the answer</text><text x=\"560\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no: last order 11:30</text></svg>", "caption": "Step-back prompting as two calls. The first asks for the principle behind the question; its reply goes into the second prompt beside the original question."}
```

The shape is always the same: **call one turns the question into its general form and answers
that; call two answers the specific question with the general answer in the prompt.** The
general question is written by you, or by the model itself if you ask it first to "state the
more general question behind this one".

## The same move outside the café

Step-back prompting was introduced with science questions, and the shape is clearest there.
"What happens to the pressure of a gas if its temperature is doubled and its volume made eight
times larger?" invites a guess about doubling. The step-back question is "which physical law
relates pressure, temperature and volume?", and its answer, the ideal gas law, makes pressure
proportional to temperature divided by volume. With that in the prompt the specific question is
one division:

```
ana@lab:~/pe$ python3 -c "print(2 / 8)"
0.25
```

The pressure falls to a quarter of what it was. **The principle turned a question that looked
like it needed intuition into one that needed a formula**, and a formula is something you can
check, as here, with a real program rather than the model's word for it.
