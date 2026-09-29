---
title: "PaaS: you hand over code, and the platform runs it"
version: 1
---

With **platform as a service** there is no machine to log in to. You hand the platform your
application, and it builds it, starts it, restarts it when it crashes, and sends it the requests that
arrive for it. What you hand over is one of two things: the source code, with a file naming the
packages it needs and a line saying which command starts it; or a **container image**, the application
already packaged with its runtime, which comes back under CaaS in the section on FaaS, CaaS and
DBaaS.

Heroku was one of the first to sell this shape, and Google App Engine, AWS Elastic Beanstalk and Azure
App Service are others. They differ in detail and share the idea: the line has moved up past the
operating system and past the runtime, and **the platform runs everything up to the edge of your
code**.

## What the platform takes

Measured against the stack, the platform now does the jobs that filled most of the IaaS list:

- it chooses the operating system, installs it and patches it;
- it installs the runtime you named, Python 3.11 say, and applies its security fixes;
- it runs as many copies of your application as you ask for, and replaces one that dies;
- it puts a load balancer in front of them and gives you an address, often with a TLS certificate
  already on it;
- it collects what your application writes to its logs.

For a team of three developers with a shop to run, that list is most of a job nobody on the team
wanted. **That is what PaaS sells: operations as a feature of the product.**

## What you give up

The same list, read the other way, is what you no longer control.

The **runtime versions are the platform's menu**. If it supports Python 3.11 and 3.12, those are your
choices; when it retires one, it announces a date, and moving your application off it before then is
your work. You cannot install an arbitrary system package or change a kernel setting, because there
is no machine of yours to install it on.

Platforms also set **limits a server would not**: how long a single request may take before it is cut
off, how much memory one copy may use, and whether a file your application writes to its local disk
survives a restart. On many platforms it does not. The copies are thrown away and replaced freely, so
anything written locally goes with them, and a shop that saves uploaded product photos to its own disk
loses them at the next deploy. They belong in object storage, which lesson 5 describes.

## What is still yours

The line sits at the application, so the application is on your side of it, **with everything it
imports**. The platform patches the Python interpreter; it does not patch the web framework your code
lists among its packages. A known hole in that framework is yours to fix, exactly as it would be on a
virtual machine.

The configuration is yours as well: the database password the application reads, the settings that
differ between test and production, which on most platforms are set as environment variables through
the platform's own interface. So are the data, wherever the application keeps it, and the question of
who in your team has access to the platform account, because anybody who can deploy to it can replace
your shop with something else.

PaaS removes the largest block of routine work in the stack and leaves you the parts that are specific
to your business. **Whether that is a good trade depends on whether you needed the parts it took**,
and the last reading section of this lesson turns that into a table.
