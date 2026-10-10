---
title: Quality attributes pull against each other
version: 1
---

Ask any team what it wants from a system and the answer is a list of good things: fast, always
available, secure, cheap, easy to change. **Every structural decision buys some of those by
spending others**, and there is no arrangement that maximises them all. The architect's job is not
to find the design without trade-offs, which does not exist, but to make the trade visible, put
numbers on both sides and get the people who own each side to agree to it.

## The trades that come up again and again

Four pairs account for most of the arguments at Carreto, and each has a concrete case.

**Availability against consistency.** Matching could offer a new load to five drivers at once and
take the first acceptance, which gets loads moving faster. It could also end with two drivers
driving to the same warehouse for the same load. Offering to one driver at a time for sixty
seconds is consistent and slower. The `architecture` course gave this its theory in lesson 8, the
CAP theorem; at Carreto it is a decision about how often a driver is disappointed against how
long a shipper waits.

**Performance against modifiability.** The adapter that hides the bank partner from the rest of
Payments costs a layer of indirection and some code that does nothing but translate. It buys the
ability to change bank in weeks rather than months. At Payments' volume the cost in speed is
invisible; in a system answering in microseconds it might not be.

**Availability against cost.** A second bank partner for Pix would let payouts continue when the
first is down, which protects the 24-hour promise. It would also double the integration work, the
reconciliation and the contracts. Whether that is worth it depends on how often the first partner
is down, which is a number, not an opinion.

**Security against usability.** The Driver app could ask for a fresh login before every payout
change, which makes a stolen phone less useful and annoys every driver every time. The decision
is about which annoyance is cheaper.

None of these has a right answer in general. **Each has a right answer for a particular set of
requirements**, and the trouble is that the requirements usually arrive as adjectives.

## An adjective cannot be traded

"Payments must be reliable" sounds like a requirement. It cannot settle a single decision. Does
reliable mean never down, never wrong, never late, or never paying twice? Down for how long, how
often, measured how? Two engineers can agree with the sentence and design opposite systems, and
neither can show the other is wrong.

The Software Engineering Institute's answer, set out by Bass, Clements and Kazman in *Software
Architecture in Practice*, is the **quality attribute scenario**: a requirement written as a short
story in six parts, specific enough to test.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The six parts of a quality attribute scenario, drawn left to right with Carreto's example. Source: the bank partner. An arrow labelled stimulus: the Pix API stops answering. A large box labelled environment, Friday at the 18:00 peak, containing the artefact: the Payments payout service. An arrow labelled response: payouts queued and retried, no duplicates. Last, the response measure: every payout made within 2 hours of recovery, none paid twice.\"><defs><marker id=\"qas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"90\" width=\"130\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Source</text><text x=\"75\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the bank partner</text><path d=\"M142 135 L236 135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#qas-ah)\"></path><text x=\"190\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Stimulus</text><text x=\"190\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pix API stops</text><text x=\"190\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">answering</text><rect x=\"240\" y=\"30\" width=\"220\" height=\"200\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Environment</text><text x=\"350\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Friday, 18:00 peak</text><rect x=\"270\" y=\"100\" width=\"160\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Artefact</text><text x=\"350\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the Payments</text><text x=\"350\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payout service</text><path d=\"M462 135 L556 135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#qas-ah)\"></path><text x=\"510\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Response</text><text x=\"510\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payouts queued</text><text x=\"510\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and retried,</text><text x=\"510\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no duplicates</text><rect x=\"560\" y=\"90\" width=\"150\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Response measure</text><text x=\"635\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every payout made</text><text x=\"635\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">within 2 h of recovery;</text><text x=\"635\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">none paid twice</text></svg>", "caption": "A requirement in six parts. Each part removes an ambiguity the adjective \"reliable\" left open: who causes the event, what it is, when, to which part of the system, what the system does, and how anyone would know it did it well enough."}
```

The six parts, with the Payments example:

- **Source**: who or what causes the event. Here, the bank partner. It could as well be a driver, a
  developer or an attacker, and each makes a different scenario.
- **Stimulus**: the event itself. The bank's Pix API stops answering.
- **Environment**: the conditions at the time. Friday at the 18:00 peak, when most deliveries of
  the week are proved. The same failure at four in the morning is a smaller problem.
- **Artefact**: the part of the system that receives it. The Payments payout service, not "the
  platform".
- **Response**: what the system does. Payouts are queued and retried; nothing is paid twice;
  finance is alerted if a payout is still pending at hour 20.
- **Response measure**: how anyone would know the response was good enough. Every queued payout
  completed within 2 hours of the partner recovering, and zero duplicate payments.

**The response measure is the part that turns an opinion into a test.** Without it, "retried" is
satisfied by one retry a day. With it, a design can be checked on paper now and in a test
environment later, and an argument between two designs has something to be settled against.

The form is not only for availability. Here is a modifiability scenario for Pricing, written the same way. A **developer** on Pricing
(source) receives a **new ANTT floor table** (stimulus) during **normal development** (environment),
for the **floor stage of the quote** (artefact). The table is loaded, tested and deployed
(response), and it is **in production within two working days, with no code changed outside the
floor module** (response measure). That scenario is why the table is data and
not code, and why the floor stage is the only way out.

Lesson 7 is about getting scenarios like these out of the business, from people who say "fast" and
"always". This section needs them for a different reason: **a trade-off can only be argued about
between two scenarios with numbers in them.**

## Trade-off points

The SEI's evaluation method for architectures, ATAM, has a useful name for the place where trades
happen: a **trade-off point** is a single decision that affects two quality attributes in opposite
directions. Finding them is most of the work of evaluating a design, because each one is a place
where two stakeholders want different things.

The 24-hour payout has a clear one, and it is not technical. **The shipper's contest window
protects Sílvio's finance team and costs drivers time.** Twelve hours protects Carreto against
paying for loads that did not arrive; every hour taken from it reaches the driver's account an hour
sooner. A scenario for each side makes the trade explicit:

- *Driver scenario*: a driver completes a delivery (stimulus) on a weekday (environment); the
  payout (response) reaches the driver's account within 24 hours in 99% of deliveries (measure).
- *Finance scenario*: a shipper contests a delivery that did not happen (stimulus); the payout
  for it is held (response) in every case contested within the window (measure).

The window length moves both measures at once. With the numbers on the table, the conversation
between Helena, who speaks for the drivers, and Sílvio, who speaks for the money, is about one
number of hours, and each of them can see what the other gives up.

Retries are a second trade-off point, a technical one. **More retries improve the availability
scenario and threaten the "none paid twice" measure**, unless each payout carries the delivery id
as an idempotency key, which record 7 requires. Naming the trade-off point is what led to naming
the safeguard.

## What the architect does with a trade-off

Renata's habit with every trade-off point is the same, and it is short:

1. **Write the scenarios on both sides**, with response measures.
2. **Name who owns each side.** Drivers' speed is Helena's; financial exposure is Sílvio's;
   duplicate payments are Bruno's to prevent.
3. **Put the options in front of the owners with the numbers**, and say what each option costs
   which side.
4. **Write down what was chosen**, as a decision record, with the scenarios in the context.

Step 3 is where architects most often go wrong, in one of two directions: choosing on the owners'
behalf because the trade looks technical, or presenting so many options that the owners cannot
choose. Lesson 13 comes back to presenting options with cost, time and risk. The next section
turns to the case where there are several criteria at once, and a single trade is not enough.
