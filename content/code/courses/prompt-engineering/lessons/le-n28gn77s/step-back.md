---
title: Asking for the principle, then the answer
version: 2
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
ana@lab:~/pe$ cat direct.txt
<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.
ana@lab:~/pe$ ask - --temperature 0 < direct.txt
No, the kitchen cannot take the order because it stops taking hot food orders 30 minutes before closing, and it closes at 12:00 on public holidays.
-- llama3.2:3b, finish: stop, prompt 142 tokens, output 34 tokens
```

Every fact needed is in the prompt, and the model got it right: the holiday rule, the 12:00 close,
the 30 minutes. The question still has the shape step-back prompting is for. It says
**Wednesday**, the first line of the handbook says Monday to Saturday, and those two match
strongly; the rule that decides the case is two lines further down, reached through a word,
*holiday*, in the middle of the question. A model that followed the most obvious match would
answer yes, from the weekday hours, which is lesson 1's next-token habit: what is likely given the
text, not what is entailed by it. This one did not, on this run. The technique is for the runs and
the models that do.

## The step back

The first call asks only for the general rules. `step1.txt` is the same handbook block, followed
by the line printed here:

```
ana@lab:~/pe$ tail -1 step1.txt
Do not answer any particular question yet. Step back: what general rules decide the last time the kitchen takes a hot food order on a given day? List the rules from the handbook that apply, and what they give for each kind of day.
ana@lab:~/pe$ ask - --temperature 0 --plain < step1.txt > rules.txt; cat rules.txt
Based on the handbook, the general rules that decide the last time the kitchen takes a hot food order on a given day are:

1. The kitchen stops taking hot food orders 30 minutes before closing.
2. On public holidays, the café follows the Sunday hours.

These rules imply that:

* On weekdays (Monday to Saturday), the kitchen will stop taking hot food orders 30 minutes before the closing time, which is 17:30 (18:00 - 30 minutes).
* On Sundays, the kitchen will stop taking hot food orders 30 minutes before the closing time, which is 11:30 (12:00 - 30 minutes).
* On public holidays, the café follows the Sunday hours, so the kitchen will stop taking hot food orders 30 minutes before the Sunday closing time, which is 11:30.
```

Nothing in it is new: every rule was already in the handbook. **What changed is the order in which
the facts are laid out**, with the holiday rule stated as a rule rather than buried as an
exception, and the arithmetic done once for each kind of day: 17:30, 11:30, 11:30.

The second call is the original question with those rules in front of it. One command builds it
from the handbook block, the reply and the question, and sends it:

```
ana@lab:~/pe$ { sed -n "1,/^<\/handbook>/p" direct.txt; echo; echo "<rules>"; cat rules.txt; echo "</rules>"; echo; echo "Using the rules above, answer the question. $(tail -1 direct.txt)"; } > step2.txt
ana@lab:~/pe$ ask - --temperature 0 < step2.txt
No, the kitchen cannot take the order at 11:45 because it stops taking hot food orders 30 minutes before closing, which would be 11:15 on a public holiday.
-- llama3.2:3b, finish: stop, prompt 327 tokens, output 39 tokens
```

The answer is still no, and **the reason now has a wrong time in it**: 11:15, where the rules in
the same prompt say 11:30, three times. The step back produced correct rules; the second call
did the subtraction again and got it wrong. Nothing about the technique prevents that, and the
next reading section comes back to it.

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
times larger?" invites a guess. The step-back question is "which physical law relates pressure,
temperature and volume?", and its answer goes into the prompt before the question:

```
ana@lab:~/pe$ ask "What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0
If the temperature of a gas is doubled and its volume is made eight times larger, the pressure of the gas will decrease by a factor of 16, since the ideal gas law (PV = nRT) shows that pressure is directly proportional to temperature and inversely proportional to volume.
-- llama3.2:3b, finish: stop, prompt 51 tokens, output 58 tokens
ana@lab:~/pe$ ask "Which physical law relates the pressure, temperature and volume of a gas? State it as a formula, in one line." --temperature 0 --plain > law.txt; cat law.txt
The ideal gas law is: PV = nRT, where P is pressure, V is volume, n is the number of moles, R is the gas constant, and T is temperature.
ana@lab:~/pe$ ask "$(cat law.txt)

Using that law: What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0
If the temperature of a gas is doubled and its volume is made eight times larger, the pressure of the gas will decrease by a factor of 16, since the pressure is directly proportional to the temperature and inversely proportional to the volume, according to the ideal gas law PV = nRT.
-- llama3.2:3b, finish: stop, prompt 94 tokens, output 60 tokens
ana@lab:~/pe$ python3 -c "print(2 / 8)"
0.25
```

The model answered the step-back question right: the ideal gas law. With the law in front of it,
the specific answer was **the same wrong one as without it**, a factor of 16. Pressure is
proportional to temperature divided by volume, so doubling one and multiplying the other by eight
gives 2 / 8, a quarter: the last line, from a real program. **The principle turned a question that
looked like it needed intuition into one that needed a formula**, and the formula is what made
the wrong answer checkable, by Python rather than by the model's word.
