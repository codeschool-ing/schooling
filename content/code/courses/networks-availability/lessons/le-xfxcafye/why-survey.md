---
title: Why survey, and the three kinds
version: 1
---

The usual way to place access points is a rule of area: one per so many square metres, in the middle of
each room, at the range the data sheet promises. **It fails because a building is not open space.** A
concrete lift shaft can cost more signal than thirty metres of open office, and a window of coated glass
that looks transparent can block more than a brick wall. A floor plan shows neither. A **site survey**
replaces the rule with measurements, taken before the design is fixed and again after the APs are up.

As in lessons 6 to 9, **this lab has no radio**, so there is no survey to show. What this lesson can do is
compute what a survey would measure, with the same formulas survey software uses, and say plainly which
numbers are rules of thumb.

## Requirements first

A survey measures against something, and that something is written down before anybody walks a floor:

- which applications, and so which targets: e-mail tolerates a weaker signal than a voice call;
- how many devices are active at once, and where (the capacity arithmetic of lesson 9);
- **which is the weakest client**, because it decides the design: a handheld scanner with a small antenna
  hears less, and is heard less, than the laptop the survey was walked with;
- which bands, and whether 6 GHz clients will be there.

## Three kinds, and two helpers

| | how it works | what it shows | its limit |
|---|---|---|---|
| **predictive** | software models the APs on a floor plan, with a loss for each wall | a design and a budget before anything is bought | only as good as the wall materials somebody entered |
| **passive** | walk the floor with a survey adapter that listens to every beacon, from every AP, yours and the neighbours' | the signal, the noise and the channels actually on the air | says nothing about what a connected user gets |
| **active** | walk the floor connected to the network, measuring throughput, loss, delay and roams | what a user actually gets | needs the network to exist already |

**Predictive is the cheapest and the least certain.** It is how most designs start, and the result is
only as good as its wall materials. One mislabelled wall, plasterboard where the building has concrete,
moves a cell edge by metres. Passive and active are measurements, and they need a building and, for the
active one, a network.

Two helpers fill the gaps. **An AP on a stick** is a real access point on a tripod, placed where the design
puts it, with a survey walked around it to find where its cell really ends. It is the way to settle an
argument about one difficult area, a warehouse with metal racks or a hospital ward, before the cabling is
paid for. **A spectrum analyser** sees energy that is not Wi-Fi at all, the microwave ovens and video
senders of lesson 7, which a Wi-Fi adapter only experiences as a channel that is mysteriously busy.

The usual sequence is all of them in order: **predict, check the doubtful walls on site, install, then
measure again**. The last step is the one most often skipped, and the last section of this lesson says why it
should not be.
