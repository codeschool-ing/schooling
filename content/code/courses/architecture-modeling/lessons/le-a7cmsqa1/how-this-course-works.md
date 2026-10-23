---
title: How this course works, and what you need for it
version: 1
---

**This course teaches you to draw architecture so that somebody else understands it, and to keep
the drawing, the decision behind it and the document around it true for as long as the system
lives.** It is about notations, records and frameworks, and every one of them is judged by the same
standard: did the reader understand what the writer meant?

## Carcará, the company in every lesson

The examples come from one company the whole way through. **Carcará is fictional**: an intercity
bus company based in Salvador, with 140 routes across Bahia, about 300 buses and roughly 9,000
tickets sold on an ordinary day. Around the São João festivals in June, and again at Christmas,
that number goes up four times, and the week before is when everything that was fragile breaks.

Forty engineers work there in five teams: **Sales** builds the passenger site and app, **Boarding**
builds the app the drivers use to check tickets at the door of the bus, **Payments** owns the
integration with the payment gateway, **Fleet** looks after the link with the old system that
knows about buses and drivers, and **Platform** runs the infrastructure for everybody.

You will meet a few people more than once:

| | who | what they want from a diagram |
| --- | --- | --- |
| **Tainá** | the architect, a staff engineer the others call when a decision crosses teams | to be understood the first time, by people who were not in the room |
| **Otávio** | head of product | what a change will let customers do, and when |
| **Celeste** | operations director, responsible for the buses actually leaving | what can stop a bus from boarding passengers |
| **Rui** | leads the Platform team | what runs where, and what talks to what |
| **Joana** | business analyst, the person who turns a request into requirements | what the system must do, written so that it can be checked |
| **Bento** | an engineer in the first month of the job | where to start |

The same system is drawn again and again in different notations, which is deliberate. By lesson 4
you will have seen Carcará's ticket sale as a use case, a sequence of messages, a set of containers
and a state machine, and the comparison between those pictures teaches more than any one of them.

## Nothing to install, for thirteen of the fourteen lessons

**This course has no runtime.** There is no program to run in lessons 1 to 11, 13 and 14, and no
machine to prepare. What you will use is ordinary and free:

| | what it is for | free options |
| --- | --- | --- |
| **paper and a pencil** | the first draft of every diagram, which should be quick and disposable | — |
| **a diagram tool** | the drawing you keep | [diagrams.net](https://www.drawio.com/), also called draw.io, free and open source, in the browser or as a desktop program; [Excalidraw](https://excalidraw.com/) for sketches that look like sketches |
| **a text editor** | decision records, requirement lists and the documents in lessons 5 to 11 | whatever you write code in; Visual Studio Code is free and so is any plain-text editor |
| **a place to keep the records** | so that the decision records in lesson 5 are kept in order and have a history | a folder of Markdown files, best inside a Git repository next to your code |

**Lesson 12 is the exception.** Diagrams written as text need three small programs to turn the text
into a picture, and that lesson starts by showing you how to set them up on your own computer, in
a virtual machine or in the browser, before it asks you to type anything.

## What the questions can and cannot ask

**A course about drawing, on a platform that cannot receive a drawing, is a real compromise**, and it
is better said here than discovered in lesson 3. The questions in each lesson check what a machine
can mark: they show you a finished diagram and ask what is wrong with it, ask you to put names on
the parts of one, to order the steps of a method or to choose between two records. That is the
reading half of the skill, and it is the half most diagrams fail on.

The drawing half is yours to do. **Many sections end with something to draw for Carcará**, and the
section after it, or the figure in it, shows one good answer. Draw yours first, on paper, before you
look; then compare it against the checklist in this lesson's section on the reading test. A
diagram you drew and then corrected teaches you more than ten you only read.
