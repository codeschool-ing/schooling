---
title: When the extra call is worth it
version: 2
---

Step-back prompting is not a better default for every question. **It helps when the specific
wording hides the principle that decides the answer**, and it costs a second call every time,
whether it helped or not.

## Where it helps

The holiday toastie is the typical case: the facts are all present, and the wording points at the
wrong one. This model happened not to be misled, and that is the first thing to measure before
adding a call: whether the direct question fails at all. Three kinds of question share that shape:

- a question that is an instance of a rule stated elsewhere, especially an exception to a more
  obvious rule. Holidays follow Sunday hours; refunds above R$ 100 need the manager.
- a question from a field with laws or definitions, where naming the law is most of the work:
  physics, chemistry, tax, a contract clause.
- a question about one moment in a longer history. "Which team did this player belong to in March
  2009?" is easier once the step-back question, "what was this player's career, club by club?",
  has put the whole list in the prompt to read the date against.

## Where it does not

A question that is already general gains nothing from being generalised. "What is the guest Wi-Fi
network called?" has no principle behind it to step back to; the answer is one line of the
handbook. **Stepping back there is a second call that restates the first**, and the most it can
do is leave the answer where it was.

It also does not do the last step for you. The toastie's rules were right and the second call
still wrote 11:15; the gas law was right and the answer was still a factor of 16. **A correct
principle in the prompt is not a correct calculation in the reply.** Where the last step is
arithmetic, a program does it, as lesson 6's calculator did.

And it does not create knowledge. If the model does not know the rule, or the prompt does not
contain it, the step-back reply states a plausible rule instead, and the second call answers
faithfully from the wrong principle. That is lesson 5's failure moved one step earlier, where it
is harder to see because the final answer follows logically from what precedes it. **Read the
step-back reply, not only the final answer**: it is the part that can be checked against the
handbook.

## What it costs

The two calls each send a prompt, and the second waits for the first. `tok` counts the prompts:

```
ana@lab:~/pe$ tok count direct.txt step1.txt step2.txt
tokens  words  chars  file
   116     81    457  direct.txt
   122     92    516  step1.txt
   301    220   1247  step2.txt
```

The direct question sends 116 tokens. The step-back version sends 122 and then 301, which is 423
tokens of input, more than three and a half times as many. On top of that, the first call's reply is output you pay for and wait for before the second call can start. **Twice the round trips and more than three times
the input is the price of one answer**, so it is worth paying where a wrong answer is costly and
the principle is easy to miss, and not on every request.

The two calls can be folded into one prompt: "first state the general rules that apply, then
answer". That saves the round trip and keeps what mattered in the holiday case: the rules are
still written before the answer. It also lets you see, in one reply, whether the rules were right.

## Next to chain of thought

Writing something down before the answer is also what chain of thought does, and lesson 26 is
about it. The difference is in what gets written. **Chain of thought writes the steps from this
question to its answer; step-back writes the general rule the question is an instance of**, and
does it before looking at the specifics. The two combine: step back to the principle, then reason
through the case. Lesson 26 shows the second half.
