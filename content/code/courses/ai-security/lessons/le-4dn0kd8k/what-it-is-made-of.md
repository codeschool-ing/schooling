---
title: What an LLM application is made of
version: 1
---

The picture most people start from is a model with a text box in front of it, and the security
question becomes whether the model can be made to say something it should not. **The model is one part
of the application, and usually not the part that does the damage.** A reply only harms somebody when
something acts on it: a client who believes it, a tool that runs it, a log that keeps it, a page that
displays it. The attack surface is everything around the model through which text comes in or effects
go out.

Tarefa's assistant, which every lesson of this course works on, is typical. It has five kinds of part:

| part | at Tarefa | what goes wrong there |
|---|---|---|
| **inputs** | clients' chat messages, tickets, partner requests, attached files | text the platform did not write reaches the prompt |
| **context** | the system prompt, help centre pages | instructions and reference text sit beside the client's words |
| **outputs** | replies shown to clients, summaries sent by e-mail | the model's text is published as the company's |
| **actions** | tools: lookups, messages, refunds | a proposal becomes an effect in the world |
| **records and third parties** | the call log, the model provider | copies of everything, kept elsewhere |

## One stream of text

The property that makes this different from an ordinary web application is in the second row. In a web
application, code and data travel separately: a query is code, and the value a user typed is a
parameter, kept apart by the database driver. **A model receives its instructions and the text it is
working on as one stream**, and nothing in that stream marks which words are orders and which are
material. A model is trained to follow instructions, and it cannot reliably tell the instructions it
was meant to follow from instruction-like text that arrived inside a ticket or a file.

That is the root of prompt injection, which lessons 2 and 3 cover. Here it gives the one question that
organises everything else: **for every piece of text that reaches the model, who wrote it, and what can
the model do once it has read it?** A system prompt written by Tarefa and a help centre page reviewed
by Tarefa are trusted. A client's message, a ticket, a file a client attached and a page fetched from
the web are not, whatever they say about themselves.

## Where the damage happens

Following the question to its end gives the defensive principle of this course. If untrusted text can
reach the model, then whatever the model can do, untrusted text can try to make it do. So the damage is
bounded by the model's reach rather than by the model's judgement:

- a model that can only answer can, at worst, answer badly, and lesson 19's checks and lesson 15's
  filters stand between that answer and the client;
- a model that can call tools can, at worst, call them badly, and lesson 20's gate and confirmation
  stand between the proposal and the effect.

The rest of this lesson turns that question into a list, and the list into a plan.
