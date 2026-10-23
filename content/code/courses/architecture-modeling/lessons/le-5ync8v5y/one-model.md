---
title: One model, many decks
version: 1
---

**Three presentations in one week is three chances to draw the system three different ways, and a
deck drawn by hand starts disagreeing with the model the day it is made.** The answer is the one
lesson 12 gave for documentation: keep one model and generate every view from it.

## The deck that drifted

Before the review, Carcará's slides had their own copies of the architecture. The deck for the
directors showed the station back office, which lesson 8's programme had already retired. Nobody had
lied; somebody had copied a slide from last year's deck, and a slide does not know it has gone out
of date.

The engineers noticed at once, and from then on they doubted the rest of the slides. **A wrong box
on a slide costs more than the box: it costs the trust of everybody who spotted it.**

## Every slide a view of the model

For the São João week, Tainá made every diagram on every slide a view exported from the Structurizr
workspace of lesson 12:

- the directors' context and the product team's dynamic diagram are **views of the same model**, so
  an element renamed in the model is renamed on both;
- each view carries **the model's version and date** in its footer, the same date the repository
  shows;
- when the model changes after the deck is sent, the export runs again and the slide is replaced,
  rather than edited.

The slides were not prettier than before. They were **consistent**: a person who went to two of the
three meetings saw the same names, in the same places, with the same legend.

## What may differ between the decks

One model does not mean one look. Each view in the workspace can include different elements and
use its own title, and the decks can differ in everything that is not the model: the order, the
words around the diagram, the number of slides. **What the decks may not do is disagree about a
fact**, such as which system owns the bookings or whether the back office still exists.

If a tool to generate views is not available, the rule still stands in a weaker form: keep the
diagrams of a deck in one place, give each an owner and a date as in lesson 11, and copy from
there, never from an old deck.
