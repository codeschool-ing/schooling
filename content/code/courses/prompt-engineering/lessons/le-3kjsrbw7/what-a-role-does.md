---
title: What a role changes in a reply
version: 2
---

A role prompt tells the model who to be: "You are a head barista", "You are a patient teacher",
"You are a lawyer reviewing a lease". It is one line, it usually comes first, and in an
application it sits in the system message of lesson 22, since it holds for the whole conversation.

**A role is a way of choosing which kind of text the reply resembles.** A model produces likely
text (lesson 1), and the text it learnt from was written by many kinds of people for many kinds of
reader. A barista explaining coffee to a customer writes differently from a roaster teaching
trainees, and a role line makes one of those styles the likely one to continue.

## Four things a role sets

- The register: how formal, how warm, how many words. A barista at the counter is brief and
  friendly; an instructor is thorough.
- The vocabulary: which terms are used, and which are explained. "Extraction" is ordinary for a
  roaster and needs a gloss for a customer.
- The angle: what the answer is about. Asked why a coffee is bitter, a barista thinks about what to
  do now and an instructor about why it happens.
- The audience the reply assumes: what it takes for granted, and what it stops to explain.

**The fourth is the one people forget they are setting**, and the next reading section comes back
to it.

## The same question, two roles

The question is the same in both: a bitter flat white. With the role of a barista talking to a
customer:

```
ana@lab:~/pe$ cat prompts/role-barista.txt
You are a barista at Café Aurora, talking to a customer at the counter.
Reply in three sentences or fewer.

Customer: My flat white tastes really bitter today. Why?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-barista.txt
I'd be happy to help you troubleshoot. Can you tell me when you last had a flat white from us that you enjoyed, and have you noticed any changes in your coffee beans or brewing method recently?
-- llama3.2:3b, finish: stop, prompt 61 tokens, output 43 tokens
```

With the role of a coffee instructor teaching new staff:

```
ana@lab:~/pe$ cat prompts/role-instructor.txt
You are a coffee instructor at Café Aurora, teaching new staff.
Reply in three sentences or fewer.

Trainee: A customer said their flat white tasted really bitter. Why?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-instructor.txt
That's a great question, trainee! A flat white's bitterness can be caused by over-extraction of the coffee, which can happen if the brewing time is too long or the coffee-to-water ratio is off. Let's review the brewing technique and make sure we're aiming for a balanced extraction to bring out the smooth, velvety texture and flavors we want in a flat white.
-- llama3.2:3b, finish: stop, prompt 60 tokens, output 80 tokens
```

Both are reasonable, and they are not interchangeable. The barista did not explain anything: it
asked the customer two questions, about the last flat white they enjoyed and about their own beans
and brewing, as if the customer had made the coffee. The instructor named a cause,
"over-extraction", gave two ways it happens, and turned to what the trainee should check, with a
"great question" on the way in. **Neither role gave the model knowledge it did not already have**: what makes coffee
bitter came from what the model learnt in training, and the instructor put it forward while the
barista did not. What changed is which part of that knowledge was used, in which words, for whom.

The barista's reply also shows what a role does not settle. It sounds like a person at a counter,
and it answers a complaint with questions the customer cannot answer. A role chooses a voice; it
does not choose a good reply.

## A role is cheap, and that is its strength

One line changes the register of every reply that follows. That is a good trade wherever the
register matters: a website assistant that should sound like the café, a tutor that should
explain rather than show off, a reviewer that should be blunt. The café's system prompt in lesson
22 has a small role in its first line for exactly that reason.

It is not a substitute for saying what you want. "You are a concise assistant" is a weaker way of
writing "answer in at most three sentences", and the explicit version can be tested against a
reply. **Use a role for the voice, and an instruction for anything you will check.**
