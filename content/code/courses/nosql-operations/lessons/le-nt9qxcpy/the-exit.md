---
title: The exit, priced before you need it
version: 1
---

Nobody plans to leave a provider on the day they join it, which is why **the exit is cheapest to
plan on that day**. Prices change, a licence changes, a region you need is not offered, a company
is bought. The question is not whether you will leave but what it would cost if you had to, and
four costs make up the answer.

## Egress

Cloud providers charge little or nothing for data coming in and charge for data going out of their
network, per gigabyte. Moving a database out is the largest single transfer most applications ever
make, and it is billed at that rate. The price list of your provider gives the figure; multiply it
by the size of the data and of its backups, and the first number of the exit plan exists.

## The window

**Copying is not instantaneous, and writes do not stop to wait for it.** The simplest route is the
one lesson 11 used: a dump on one side, a restore on the other, with the application stopped in
between so that nothing is written to the old side after the dump. The arithmetic is the plan. A
dump that reads at 50 MB/s takes about 5.6 hours for a terabyte, before the restore and its index
builds. A shop that can be closed for a night can do that. One that cannot needs the other
route, replicating continuously into the new place and switching over in minutes, which is a
project of its own. Measure your own dump and restore rate in a drill rather than trusting this
paragraph's 50.

## Features the other side lacks

This is the cost that hides. Every service grows features beyond the database it runs: a search
index built in, triggers that call a function when a document changes, a global table replicated
by the provider, a console query editor everybody got used to. Each is convenient, and each is a
piece of the application that lives in the provider. **List them as you adopt them**, one line per
feature with what replaces it outside, and the list will be short enough to be useful on the day
it matters. A compatible engine works in both directions: code written against a translation's
quirks has to be retested against the real product on the way out.

## The restore into your own lab

The one exit test you can run without leaving is the backup. Most services let you export one to
storage you control: a dump, an RDB file for Redis, a snapshot of data files. Take the provider's
backup, restore it into containers like the ones this course started, and run the application's
reads against it. **That was not run for this course**, for want of a provider; with one, it is an
afternoon's work, and it proves three things at once:

1. the backup is complete and readable by software you run yourself;
2. the export format and its tools are ones you know how to use under pressure;
3. the time it took is the floor of the window above.

A database you can restore into your own lab is one you can leave. One you cannot is one the
provider's price list decides about for you.
