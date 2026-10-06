---
title: Why an invented answer is a security problem
version: 1
---

A model generates the text that is likely to follow its input. Whether that text is true is not part of how it is produced. So a model can state a policy that does not exist, cite a source nobody wrote or name a package nobody published, in exactly the tone it uses for facts. This is usually
called **hallucination**. The common view is that it is a quality problem, an annoyance for users. Two
cases show why that view is too small.

**A promise the company did not make, and paid for.** In *Moffatt v. Air Canada* (2024), a customer
asked Air Canada's website chatbot about bereavement fares. The chatbot said a refund could be claimed
after the flight, which the airline's own policy page did not allow. When the customer claimed it,
the airline argued, among other things, that the chatbot was responsible for its own words. British
Columbia's Civil Resolution Tribunal rejected that and ordered the airline to pay. **What the assistant
says to a customer is what the company says.**

**Sources that did not exist, filed in court.** In *Mata v. Avianca* (2023), lawyers in New York filed
a brief citing court decisions that a chatbot had produced and that had never been issued. The judge
sanctioned them. Nothing was broken into; a fluent invention went unchecked into a document that
people relied on.

At Tarefa the same shapes are close at hand. An assistant that tells a client the refund window is 30
days when it is 14 has made Tarefa a promise to argue about. One that invents a *Tarefa Guarantee*
has invented a product.

## Why it belongs with security

Three properties put it in this course rather than only in a quality review:

- **It is exploitable.** When a model reliably invents the same name, such as a software package,
  somebody can register that name and wait. The third section of this lesson is that case.
- **It carries authority it has not earned.** A wrong answer from a form that says *"we will reply in
  two days"* is visibly a guess. A wrong answer in the assistant's confident voice is read as policy.
- **It cannot be fixed inside the model.** Better models invent less; none invents nothing. The
  defence is the same as in lesson 19: checks around the model, written in code, that do not depend on
  the model being right.

Lesson 5 of `prompt-engineering`, which this course assumes, explained why models invent and how a
prompt reduces it. This lesson is about the cases where wrong has a cost beyond the answer, and about
the checks that stop those reaching a client.
