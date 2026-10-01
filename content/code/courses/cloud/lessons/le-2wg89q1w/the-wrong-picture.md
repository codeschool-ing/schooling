---
title: Somebody else's computer
version: 1
---

There is a line printed on stickers and mugs: *there is no cloud, it's just somebody else's
computer*. **It is true.** Every service in this course runs on physical servers in buildings, with
power, cooling and people who replace failed disks. A virtual machine in `sa-east-1` is a slice of a
real server in a real building in the São Paulo area, and when that building loses power the machine
stops like any other.

It is also useless, because it describes a hosting company from the 1990s just as well. Renting
somebody else's computer is older than the web: colocation, dedicated servers and shared hosting all
did it. If the sentence were the whole story, nothing would have changed, and a great deal did.

## What the sentence leaves out

Compare two ways of getting a server for a shop that expects a busy December.

The older way: you write to a hosting company, agree a contract for a year, and wait while a
technician installs a machine in a rack. You pay the same every month whether the shop sells
anything or not. When December triples the traffic, you order a second machine and wait again, and
in January you are still paying for both.

The cloud way: a program you run, or a form that runs it for you, sends one request to the
provider's API. **Software answers it, not a salesperson**, and the machine exists minutes later.
It is a slice of a larger server that other customers share, sized to what you asked for. In
December you ask for three more; in January you hand them back, and the bill stops counting them.
The São Paulo price for the smallest machine on this course's sheet is 0.01680 dollars an hour, so a
whole month of it, 730 hours (365 days times 24, divided by 12), costs 12.26 dollars.

Four things differ, and none of them is whose computer it is:

- how you get it: by asking an API, with no person in the loop;
- what you get: a slice of shared hardware, as small as you need;
- how long you keep it: until you hand it back, which can be tomorrow;
- how you pay: by the unit you used, an hour or a gigabyte or a request.

The next section gives those four their official names, plus one more.

## The second thing it hides

The sentence also hides a question that matters more than the price. With the server in your own
room, every job was yours: the power, the disks, the operating system, the backups. With somebody
else's computer, **some of those jobs become theirs**, and which ones depends entirely on what you
rented. A virtual machine leaves you the operating system and everything above it. A finished
application, like webmail, leaves you almost nothing, but not nothing.

"We moved to the cloud" is therefore not an answer to *who patches the server*. It is the start of
the question, and the three names this lesson is about, IaaS, PaaS and SaaS, are three answers to
it.

A second wrong picture is worth naming while you are here: **the cloud as the place files go**, the
folder that syncs between a phone and a laptop. That is one kind of cloud service, a finished
application for storing files, and it is one corner of the subject. This course is about all of it:
the machines, disks and networks that services like that are built on, and the services built for
people who write software rather than for people who save photos.
