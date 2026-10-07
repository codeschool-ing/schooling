---
title: Estimating by analogy
version: 1
---

The simplest technique is also one of the most accurate: find a piece of work like this one that has already been done, see how long it took, and adjust for the differences.

## A worked example

The Agenda team has to estimate **online booking** for the clinic network. Last year it built **clinic onboarding** — the screens and the API that let a new clinic register, configure its rooms and invite its staff. The two features are similar in shape: a few screens, an API, a third-party integration and a pilot in one clinic. Onboarding took **18 working days**.

Online booking is judged to be somewhat larger: its payment integration is more complex than onboarding's email integration, and it has more rules. The team estimates it at about **1.2 times** onboarding, which gives **21.6 working days**.

The arithmetic is trivial. The work is in the two judgements: that the features are comparable, and how much larger the new one is. Those judgements are made better by people who worked on the old feature, and worse by people who only read its ticket.

## Why it beats imagination

Analogy works because the past feature's 18 days already contain everything the planning fallacy leaves out: the sick day, the misunderstood requirement, the dependency that was late. Nobody had to imagine them, because they happened. Daniel Kahneman, writing about the planning fallacy, called this taking the **outside view**: looking at how similar projects actually went, rather than at the inside view of how this one will go if everything goes to plan. Bent Flyvbjerg later developed it for large public projects as **reference class forecasting**.

## What it needs

Analogy needs **records**: how long past work actually took, not how long it was estimated to take. A team that never writes down actual durations has no analogies to draw on, which is one more argument for the cycle times of lesson 3, recorded by the board at no extra cost. It also needs **honest comparison**. The most common error is to choose the analogy that gives the answer somebody wants — the smallest similar project, the one that went unusually well — and a team should name more than one comparable piece of work and look at the spread.
