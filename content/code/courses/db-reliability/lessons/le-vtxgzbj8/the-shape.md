---
title: Four things, in this order
version: 1
---

Everything in this course so far is machinery. An **incident** is what happens to the people around
it: something is broken, customers notice or soon will, and somebody has to act with incomplete
information and a clock running. It goes better when its shape is decided beforehand, and the shape
has four parts, in this order:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Four phases along a time axis. Detect starts at the failure and ends when the first person knows. Decide follows, and overlaps with communicate, which runs from the first message until the incident is over, with updates at a regular interval. Write it up comes after the end, and produces actions.\"><defs><marker id=\"l22p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 180 L700 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22p-pa)\"></path><path d=\"M40 172 L40 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"40\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">failure</text><path d=\"M180 172 L180 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"180\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">somebody knows</text><path d=\"M520 172 L520 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">over</text><rect x=\"40\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">detect</text><rect x=\"180\" y=\"70\" width=\"340\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">decide</text><rect x=\"190\" y=\"110\" width=\"330\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">communicate</text><path d=\"M330 112 L330 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M400 112 L400 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M470 112 L470 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"435\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">update</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">write it up</text><text x=\"620\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actions, with owners</text></svg>", "caption": "The four parts of an incident. Detecting ends when somebody knows; deciding and communicating run side by side until it is over; the write-up comes after, and ends in changes."}
```

1. **Detect.** Learn that something is wrong, ideally from an alert (lessons 5 and 13), at worst from a
   customer. The time from the failure to the first person knowing is the first number of every
   write-up.
2. **Decide.** Choose what to do: fail over, wait, restore, roll back a release. Lesson 15's three
   questions are the core of it, and a cluster manager answers them for the cases it covers. The
   decisions left for a person are the ones nobody automated, which are the hard ones.
3. **Communicate.** Tell the people affected what is known, what is being done, and when they will hear
   next, from the start and at a regular interval, including when nothing has changed.
4. **Write it up**, after it is over: what happened, when, why, and what changes so that it does not
   happen the same way again.

Two roles keep the first three from getting in each other's way, even when the same two people do
everything else. The **incident lead** decides and keeps a running note of what was done and when; the
**communicator** talks to everybody outside the room. The person typing commands on the database is
neither, if there are enough people: fixing, deciding and explaining at once is how a step gets
skipped.

The rest of this lesson runs one incident on the cluster from lessons 16 to 19, with `orders.sh`
standing in for the customers, and goes through the four parts with what it left behind.
