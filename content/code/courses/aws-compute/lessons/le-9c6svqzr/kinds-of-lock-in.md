---
title: Four kinds of lock-in, and where each compute choice sits
version: 1
---

Lock-in is usually spoken of as one thing, a trap a provider sets and a careful team avoids. **It
is four different things, each bought with something you wanted**, and a compute choice carries
some of them and not others. Talking about them separately is what turns "we are locked in" from a
mood into a list.

## API lock-in: what your code says

Code that calls a provider's interface has to be rewritten to leave it. A Lambda handler receives
an `event` dictionary whose shape is AWS's: an S3 notification, an SQS batch and an API Gateway
request each look different, and none of them looks like an HTTP request on another provider. A
state machine in Amazon States Language (lesson 20) runs on Step Functions and nowhere else. A
task definition (lesson 8) is ECS's format; Kubernetes reads manifests, and another provider's
container service reads its own.

What you get for it is real: the trigger, the retries, the scaling and the dead-letter queue that
somebody else wrote and operates. **API lock-in is the price of a managed feature**, and the more
of the work the platform does, the more of your code is shaped like the platform.

## Data gravity and egress: where your data is

Data is heavy in two senses. Moving it costs money by the gigabyte (section 04 reads the price
list), and moving it takes time, during which two copies have to be kept in step. The longer
a service runs, the more data it accumulates and the heavier it gets.

This kind belongs to the storage rather than to the compute: an S3 bucket or a database weighs the
same whether Lambda or Fargate reads it. What compute decides is how close the code has to stay to
the data. A function in São Paulo reading a database in São Paulo pays little or nothing to cross
between them; move the function and leave the database, and every query becomes a request between
providers, slow and billed by the gigabyte.

## Skills: what your team knows

A team that has spent two years learning ECS, IAM roles for tasks and CloudWatch has knowledge
that does not travel whole. The concepts do, which is why this course teaches them by name; the
details, the failure modes and the reflexes at three in the morning do not. **Skills lock-in is
the one nobody puts on a diagram**, and for a small team it is often the largest, because a move
costs weeks of three people learning instead of building.

It is also the one that runs in both directions. A team of Kubernetes specialists asked to run
everything on Lambda is locked out of its own experience as surely as a Lambda team is locked in.

## Contracts: what you signed

A Savings Plan or a Reserved Instance is a commitment of one or three years in exchange for a lower
rate (`aws-foundations` lesson 14). **It is the only kind of lock-in with an end date written on
it**, and the only one that is purely financial: nothing in the code changes. A three-year
commitment signed in the first month of a service is a bet that the service, its size and its
platform will all still be right in the thirty-sixth.

## Where each choice sits

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A table of judgements with six compute choices as rows and three kinds of lock-in as columns. API lock-in: EC2 low, ECS on Fargate some, EKS low, Lambda high, Step Functions high, Elastic Beanstalk some. Skills lock-in: EC2 low, ECS on Fargate some, EKS high, Lambda some, Step Functions some, Elastic Beanstalk low. Contract lock-in: if you commit for every row except Step Functions, which has none. A note says data gravity is left out because it belongs to the storage.\"><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API: what your code says</text><text x=\"460\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">skills: what your team knows</text><text x=\"620\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">contract: what you signed</text><text x=\"30\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EC2</text><rect x=\"230\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"390\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"550\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ECS on Fargate</text><rect x=\"230\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"390\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EKS</text><rect x=\"230\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"390\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"550\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Lambda</text><rect x=\"230\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"390\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Step Functions</text><rect x=\"230\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">high</text><rect x=\"390\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"550\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">none</text><text x=\"30\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Elastic Beanstalk</text><rect x=\"230\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">some</text><rect x=\"390\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low</text><rect x=\"550\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if you commit</text><text x=\"30\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data gravity is left out: it belongs to the storage, and weighs the same whatever compute reads it</text></svg>", "caption": "A judgement, row by row: the more a service does for you, the more of your code takes its shape. Contracts attach to the bill, not to the platform."}
```

The figure is a judgement, not a measurement, and every row can be argued with: an EKS cluster
that uses ten AWS-specific controllers has more API lock-in than its row says, and an EC2 fleet
built from a provider's own images has more than its row says. What it shows is the pattern.
**The more a service does for you, the more of your code takes its shape**, and the skills follow
the service rather than the code. Contracts read the same in every row that a Savings Plan or a
reservation can cover, because they attach to the bill and not to the platform; Step Functions
offers no commitment to sign.

Two consequences carry into the rest of the lesson. Lock-in is a cost to be weighed against what it
buys, like any other cost in lesson 23. And it can be reduced in exactly one place, the code
between your rules and the provider, which is section 03.
