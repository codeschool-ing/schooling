---
title: Two ways people arrive
version: 1
---

A load test has to say how its requests arrive, and there are two answers that behave very
differently once the server slows down. Most tools default to one of them, and most people pick a
number of "users" without noticing that they have chosen a model at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-models\" aria-label=\"Two models side by side. On the left, the closed model: a fixed group of virtual users goes round a loop, sending a request to the server, waiting for the answer, thinking, and sending again; no more requests can be in flight than there are users, and a slow server slows the users down. On the right, the open model: requests arrive at a rate, so many a second, from outside, whether or not earlier ones have been answered; a slow server builds a queue in front of it, and nothing slows the arrivals.\"><defs><marker id=\"l03-models-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-models-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">closed: N virtual users</text><rect x=\"40.0\" y=\"70.0\" width=\"120.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><circle cx=\"70.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"70.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"70.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"100.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the users</text><rect x=\"240.0\" y=\"95.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server</text><path d=\"M160.0 105.0 L238.0 105.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"199.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">request</text><path d=\"M240.0 155.0 L162.0 155.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"201.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">answer</text><path d=\"M100 70 C100 40, 60 40, 60 58\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-amber)\"></path><text x=\"118.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">think, then again</text><text x=\"180.0\" y=\"238.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a slow server slows the users:</text><text x=\"180.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never more in flight than N</text><path d=\"M360.0 30.0 L360.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">open: λ arrivals a second</text><circle cx=\"395.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"411.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"427.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"443.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"459.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"475.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M390.0 110.0 L490.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"440.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">arrive on schedule</text><rect x=\"500.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"514.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"528.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"542.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"528.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">queue</text><rect x=\"570.0\" y=\"95.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server</text><path d=\"M660.0 130.0 L705.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"540.0\" y=\"238.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a slow server grows a queue:</text><text x=\"540.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing slows the arrivals</text></svg>", "caption": "A closed model counts users; an open model counts arrivals. They agree while the server keeps up and part ways the moment it does not."}
```

## The closed model: a fixed number of users

In a **closed model** there is a fixed population of virtual users, and each one goes round a
loop: send a request, wait for the answer, think, send the next. A new request can only come from a
user who has finished the last one. So the load is stated as **a number of virtual users** and a
think time, and the request rate is whatever comes out of them.

That has a consequence that surprises people the first time. **When the server slows down, a
closed test slows down with it.** Every user is stuck waiting for an answer, nobody sends anything
new, and the number of requests in flight can never exceed the number of users. The server is
never asked for more than it can eventually finish, so the test reports long response times and a
throughput that stopped growing, and rarely the collapse a real crowd would cause.

Closed is the right model when the population really is fixed: forty staff using an internal
system, a pool of eight workers draining a queue, a mobile app that sends one request at a time and
waits. In each of those, nobody new arrives while the system is slow.

## The open model: a rate of arrivals

In an **open model** requests arrive at a rate, so many a second, whether or not earlier ones
have been answered. That is how a public website meets its visitors: the person who opens the box
office at 10:00:03 has no idea that the server is still busy with the person who opened it at
10:00:02. Lesson 2's `hammer.py` is an open generator, and this is what it did to the box office at
150 requests a second, in the same session as the closed runs in the next section:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 150:5
second  sent  done  errors  median ms  max ms
     0   150   109       0        134    2293
     1   150   145       0        120    4119
     2   150   112       0        257    4384
     3   150   119       0        184    2393
     4   150   131       0        196    2241
134 answers came back after second 4; the last at 7.0 s
```

The `sent` column never moved: 150 in every second, while `done` stayed short of it in each one
and 134 answers were still arriving after the schedule ended. Nothing in an open test waits for the
server, so a server that cannot keep up builds a queue, and the queue is what the test measures.
Lesson 2's spike, at 200 a second, showed where that ends: medians in seconds and errors.

## Why the choice matters

Run a closed test with too few users against a public site and **the result flatters the system
in exactly the situation the test exists to find**. The slowdown suppresses the very load that
would have exposed it. Measurement people call the related error *coordinated omission*: the
generator and the server coordinate, without meaning to, to leave out the requests that would have
been sent while the server was stuck, and those were the slow ones.

So the question to ask before choosing is whether the users of this system wait for each other.
For the box office, the people arriving at a sale do not, and its requirement is written as a rate,
50 requests a second in lesson 1. An open model expresses that directly. A closed model can still
produce it, as long as you size the users and the think time to the rate you want, which is what
Little's law, two sections on, is for. Lesson 5's k6 offers both kinds of executor by name, and
lesson 4's JMeter is closed at heart.
