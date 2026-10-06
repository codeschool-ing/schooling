---
title: Instructions and data
version: 1
---

Every prompt in this course has had two kinds of text in it. **Instructions**, which the team wrote:
lesson 7's system prompt, what to cite, when to refuse. And **data**, which came from somewhere else:
the policies, a customer's message, a remembered turn, a summary. The program always knew which was
which, because it put each one in its place.

The model does not know. It receives one sequence of tokens, and nothing in that sequence is marked as
"obey this" or "only read this" in a way the model is guaranteed to respect. A system message is a
strong hint, and models are trained to give it weight; it is not a wall. So any text that reaches the
prompt can, in principle, act as an instruction, and **the question every pipeline has to answer is
where its text comes from and who could have written it**.

For the documents in this course the answer was comfortable: Marginalia wrote them. As soon as a
pipeline reads text written by somebody else, it is reading text that somebody else chose:

- **customers**, in every message to a support chat;
- **sellers**, in the listings and descriptions of a marketplace;
- **the web**, in a page an agent fetched;
- **other systems**, in an e-mail, a ticket, a file uploaded for summarising, a tool's output.

Text placed there to change what a model does is called **prompt injection**. This lesson treats it
the way a defender treats any untrusted input: show that the weakness exists with something harmless,
then build the layers that keep it from mattering, and test each one. The example is a canary, a
sentence asking for the word PINEAPPLE, chosen because a word cannot do anything and a test can see at
once whether it was obeyed.
