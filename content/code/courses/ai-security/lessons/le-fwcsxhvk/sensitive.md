---
title: Sensitive data, and why the tool stops instead of guessing
version: 1
---

Art. 5, II of the LGPD names a short list of personal data that is **sensitive**: racial or ethnic
origin, religious conviction, political opinion, membership of a trade union or of a religious,
philosophical or political organisation, and data about health, sex life, genetics or biometrics.
They are on the list because their misuse does a particular kind of damage, such as being refused a
job, an insurance policy or a loan.

The consequence that matters for a model call is in art. 11, which sets the bases for processing
sensitive data, and **the list is shorter than art. 7's**. Legitimate interest, the flexible basis
that covers a great deal of ordinary processing, is not on it. Specific consent given for the
purpose is, and so are a handful of situations the article names. Whether one of them fits a
support summary is a question for Tarefa's encarregado. The cheap answer is to ask first whether
the summary needs the information at all.

## What the summary needs to know

Juliana wrote that she was in hospital with a kidney infection. What the support agent has to know
is that she gave a health reason for the delay and offers to deliver by Friday, because that is
what decides between a refund and an extension. **Which illness she had decides nothing in this
dispute**, so sending it to a provider would be processing sensitive data for no purpose, which is
the very thing the principle of necessity forbids.

That is why `guard minimise` refuses by default. It stops with exit status 3 and writes nothing,
and its message names the two ways forward: remove the sentence, or record the legal basis under
art. 11 and change the purpose so that it says why the health data is needed. A default that sent
the message and logged a warning would be a default in which nobody ever decides.

With `--sensitive remove`, the sentence is replaced and the rest of the message survives:

```
   "text": "[removed: a health matter] I can deliver by Friday."
```

The marker is deliberate. Deleting the sentence without a trace would leave the model reading a
freelancer who is late and offers no reason, and the summary would be unfair to her. The marker
tells the model that a reason was given, and the reply the course wrote for this lesson says *"a
health matter stopped the work"*, which is all the agent needs.

## The word list sees words

The check behind the hold is a list of words per category, and it is exactly as good as the list:

```
ana@lab:~/guard$ guard sensitive 'I was in hospital for a week with a kidney infection'
health: hospital, infection
ana@lab:~/guard$ guard sensitive 'I spent a week in bed with a fever and the doctor said rest'
nothing found
ana@lab:~/guard$ guard sensitive 'My son has autism and I can only work at night'
nothing found
```

The second message is about illness and contains no word on the list. The third is about a child's
health, which is sensitive data about a third party, and the list has never heard of autism. Both
would go to the provider unchanged.

A longer list moves the line without removing it. A classifier moves it further, whether it is a model or a moderation endpoint like the ones in lesson 16, and its error rate is one you would have to measure on your own tickets. So the list is a net with holes in it, and **the design decisions stay where the
safety is**:

- **Do not ask for it.** A form that offers *"reason for the delay"* as a free text box will collect
  diagnoses. One that offers a choice of *health*, *family*, *technical* and *other* collects
  categories.
- **Keep the high-risk surfaces out of the model's path.** If disputes about health are common,
  the summary feature can skip those tickets entirely, and a person reads them.
- **Say it in the privacy notice.** Clients and freelancers should know that their messages may be
  summarised by a third-party model, which is required anyway under the rights in the next section.
