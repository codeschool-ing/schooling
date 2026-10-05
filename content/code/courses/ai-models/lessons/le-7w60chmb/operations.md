---
title: What you take on
version: 1
---

Section 06 compared a machine's rent with an API's bill. The comparison left out the largest line
on a self-hosted bill, which is **the time of the people who keep it running**. An API provider
spreads that time over every customer; a self-hosted model puts all of it on you.

Here is what that time is spent on, in roughly the order it arrives:

- **Setting it up.** Choosing a runtime and a format, getting the drivers and the runtime to agree,
  finding the quantisation that fits, putting an authenticated endpoint in front of it. Days, the
  first time.
- **Watching it.** Latency, memory, errors, queue length. A model server that has run out of memory
  can fail on long prompts while answering short ones normally, which is the kind of failure a
  health check that sends "hello" never finds.
- **Updating it.** The runtime ships fixes, some of them for security; the operating system and the
  drivers need patches; a new version of the model appears and has to go through lesson 5's
  evaluation before it replaces the old one.
- **Scaling it.** When the load doubles, a second machine, and something in front to share the
  requests between the two.
- **Being woken by it.** If the support desk depends on it, somebody is responsible when it stops on
  a Sunday. With an API that somebody is the provider, and your job is to retry and wait (lesson 21).

## Turning time into the comparison

Put a number on it before deciding. If keeping the model running takes **four hours of somebody's
month**, those hours belong in section 06's sum at whatever they cost Lantern Books, beside the
$1,500 machine. For ana's volume they make an already lopsided comparison more so. For a company
sending millions of requests a day they may be the small line, which is why large users self-host
and small ones rarely should.

## What an API also does that is easy to forget

It **absorbs the peaks**. A provider's fleet serves thousands of customers, and Lantern Books' Monday
morning is a rounding error in it. A single self-hosted machine has exactly the capacity it has, and
the four hundred e-mails a day do not arrive evenly: they bunch after a newsletter, after a courier
strike, after a holiday. **The machine has to be sized for the bunch**, and section 06's break-even
assumed it would be busy all month.
