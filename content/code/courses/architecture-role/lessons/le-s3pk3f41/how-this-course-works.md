---
title: How this course works
version: 1
---

This is a course about a role, not about a technology. **You already know how to build a back end;
this course is about the person who decides how the pieces of one fit together, and who answers for
that decision afterwards.** It opens the software architecture track, and it assumes the back-end
track behind it: you have written an API, designed tables, put a service in a container, and in
`architecture` and `scale` you met the monolith, microservices, queues, replicas and back pressure.
Those courses taught the styles. This one is about choosing between them, writing the choice down,
and living with it.

## Nothing to install

**The practice in this course is reading, writing and drawing.** There is no server to run and no
environment to build. What you need is three ordinary tools, each with a free option:

| tool | free options | where the course uses it |
|---|---|---|
| a text editor | the one you have used since the start of the back-end track | every lesson: decision records in lesson 5, standards in lesson 9, your own notes throughout |
| a diagram tool | diagrams.net, free in the browser or as a desktop app, saving files to your own disk; Excalidraw, free and open source; paper and a pencil | boxes and arrows from this lesson on, and choosing views in lesson 8 |
| a spreadsheet | LibreOffice Calc, free; any other spreadsheet works the same way | a weighted decision matrix in lesson 6, three options priced in lesson 13, estimates in lesson 14 |

Paper is not a lesser choice. **A diagram tool tempts you to make the drawing tidy; paper makes you
decide what the boxes are**, and the second is the skill.

**There is one program in the whole course, in lesson 9**, and running it is optional. It is a short
Python 3 script, standard library only, that reads a small example project and fails when one module
imports another it is not allowed to. Reading it and its output is enough to follow the lesson. If
you want to run it, you need Python 3: if you took the Python path of the back-end track, `python`
lesson 1 installed it; otherwise it comes from python.org or from your system's package manager.
Nothing else is needed, because the script uses nothing outside the standard library.

## The company you will follow

Every lesson follows one company. **Carreto is invented**: a freight marketplace in Curitiba,
founded in 2017, that connects *shippers* with independent truck drivers and small carriers. A
shipper is a company with loads to move — a furniture factory, a grain cooperative, the distribution
centre of a supermarket chain. A shipper posts a load, Carreto quotes the freight, offers the load
to suitable drivers, tracks the truck, and when the delivery is proved it pays the driver and
invoices the shipper.

About **50 engineers in 7 teams** build it:

| team | what it owns |
|---|---|
| Shipper | the web app where shippers post loads and follow them |
| Driver | the drivers' mobile app |
| Matching | offering each load to suitable drivers |
| Pricing | quoting the freight |
| Payments | paying drivers and invoicing shippers |
| Tracking | GPS positions and proof of delivery |
| Platform | infrastructure, CI and observability |

The system began as **one Django application with one PostgreSQL database**, which everybody at
Carreto calls "the monolith". Over the years some parts were taken out of it. Tracking runs as its
own service with its own database, Pricing is a separate service, and a message broker carries
events for a few of the teams. By the time this course starts there are **14 deployable services for
50 engineers**. Some of them earned their place and some did not; lesson 12 counts them.

Carreto also works under rules it did not write. Brazilian freight is regulated. Every freight
service needs an electronic waybill, the CT-e, authorised by the state tax authority before the
truck leaves. The national transport agency publishes a minimum freight floor that no quote may go
below. And drivers want to be paid quickly, many of them by Pix. Section 05 of this lesson treats
those rules as part of the architecture, which is what they are.

## The people

The protagonist is **Renata Okubo**, a staff engineer who has worked at Carreto for six years. She
wrote a good part of the original Payments code and has been the person other teams call when a
problem crosses their boundaries. This week the CTO, Tomás Viana, creates a role Carreto never had
and gives it to her: she becomes the company's first software architect. The course follows what she
does with it, including the parts she gets wrong.

| person | role |
|---|---|
| Renata Okubo | staff engineer, now Carreto's first software architect |
| Tomás Viana | CTO, who created the role |
| Helena Prado | product director |
| Sílvio Matos | finance director |
| Bruno Farias | tech lead of Payments |
| Kátia Lemos | tech lead of Matching |
| Diego Araújo | tech lead of the Driver app |
| Ícaro Nunes | junior developer on Payments, two years out of university |
| Paula Reis | senior engineer on Platform |

Everybody in that table is fictional, and so are Carreto's numbers. The ideas they illustrate are
not: each one is named with its source, so you can read the original.

## How a lesson is laid out

Every lesson has the same shape: a short video that says what the lesson is for, three reading
sections, and a practice section at the end. This first lesson has a fourth reading section, the one
you are reading.

**The questions in a lesson carry no mark.** A wrong answer shows you why it is wrong, and you carry
on. Many of them are about judgement rather than fact — which decision is architectural, which style
of deciding fits a situation — and for those the course commits to one answer and explains the
reasoning in the option itself. If you disagree after reading the explanation, you have done what
the question was for. The course exam at the end is the one place that does carry a mark.

## A habit worth starting now

Keep a folder of plain text files, one per lesson. **When a lesson does something at Carreto, write
down what the same thing looks like where you work**, or in the last system you built. Carreto is
tidy because it was invented for teaching; your own system is not, and the gap between the two is
where most of what this course teaches gets tested.
