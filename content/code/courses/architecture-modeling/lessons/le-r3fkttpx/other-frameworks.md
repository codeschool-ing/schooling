---
title: The other frameworks you will meet
version: 1
---

**Beyond TOGAF and IAF there are frameworks made for governments, for defence and by analyst firms,
and lighter ones made for single systems.** You will not use most of them, but you will meet their
names in tenders, job descriptions and inherited documents, and it helps to know what kind of thing
each one is.

## Frameworks for governments and defence

- **FEAF, the Federal Enterprise Architecture Framework**, is the United States federal government's
  framework, revised as version 2 in 2013. Its contribution is a set of **reference models** that
  give every agency the same vocabulary for business functions, data and technology, so that
  investments can be compared across agencies.
- **DoDAF**, the US Department of Defense Architecture Framework, organises architecture descriptions
  into **viewpoints** such as capability, operational, systems and services, each with defined models.
  It exists because defence programmes involve many contractors whose descriptions must fit together.
- **MODAF** was the UK Ministry of Defence's equivalent; it has been replaced by **NAF**, the **NATO
  Architecture Framework**, whose version 4 was published in 2018, so that allied nations describe
  systems the same way.

What these share is the problem they solve: **many organisations, or many suppliers, must produce
architecture descriptions that can be compared and combined**. Their size follows from that. A
company of Carcará's size has no such problem and gains nothing from their weight.

## An analyst firm's approach

Gartner's approach to enterprise architecture is not a published framework in the same sense; it is
a body of advice, sold to clients, that emphasises **business outcomes over complete models**. Start from what the business is trying to achieve, model only what helps decide, and measure the
architecture function by the decisions it improves. Much of lesson 8's last section, *produce only
the documents somebody will read*, is the same position.

## Lighter frameworks for one system

Three things often called frameworks work at the scale of one system, and you have already used two:

| | what it is | where in this course |
| --- | --- | --- |
| **4+1** | a set of viewpoints for one software architecture | lesson 1 |
| **C4** | a set of abstractions and diagrams for one software system | lesson 3 |
| **arc42** | a template for documenting one system's architecture, in twelve sections | lesson 11 |

They answer the question *how do we describe this system?*, not *how do we change this enterprise?*,
and for most engineering teams that is the question that matters.

## Three kinds of thing called *framework*

The word covers very different things, and confusing them causes most of the arguments:

- **a method**: a process for doing the work, like TOGAF's ADM;
- **a taxonomy**: a way of classifying the descriptions, like the grid of IAF or the Zachman framework
  of lesson 10;
- **a notation or template**: a way of writing a description down, like ArchiMate, C4 or arc42.

A method and a taxonomy combine well; two methods rarely do. When somebody asks *should we use TOGAF
or ArchiMate?*, the answer is that they are different kinds of thing, and many organisations use
both.
